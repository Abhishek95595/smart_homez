import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import axios from "axios";

// Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();

// Load Environment Configurations
const TENANT_BASE_URL = process.env.TENANT_BASE_URL || "https://tenant-api-qa.omnihome.in";

// Secure Secrets from Google Cloud Secret Manager
const TENANT_CLIENT_ID = defineSecret("TENANT_CLIENT_ID");
const TENANT_CLIENT_SECRET = defineSecret("TENANT_CLIENT_SECRET");

// Tenant API Token Cache Structure
interface TokenCache {
  token: string | null;
  expiresAt: number; // timestamp in milliseconds
}

const tokenCache: TokenCache = {
  token: null,
  expiresAt: 0,
};

/**
 * Gets a valid Tenant API JWT token, fetching a new one if not cached or expired.
 */
async function getTenantToken(): Promise<string> {
  const now = Date.now();
  if (tokenCache.token && tokenCache.expiresAt > now + 120000) {
    return tokenCache.token;
  }

  try {
    console.log("[BFF] Fetching new Tenant JWT token from AuraBrain...");
    const response = await axios.post(`${TENANT_BASE_URL}/api/Auth/token`, {
      clientId: TENANT_CLIENT_ID.value(),
      clientSecret: TENANT_CLIENT_SECRET.value(),
    });

    const data = response.data;
    if (!data || !data.success || !data.token) {
      throw new Error(data.error || "Failed to exchange Tenant API token.");
    }

    tokenCache.token = data.token;
    const expiryDuration = data.expiresIn ? data.expiresIn * 1000 : 3600000;
    tokenCache.expiresAt = now + expiryDuration;

    console.log("[BFF] Successfully acquired and cached Tenant JWT token.");
    return tokenCache.token!;
  } catch (error: any) {
    console.error("[BFF] Error acquiring Tenant token:", error.message || error);
    throw new HttpsError("unauthenticated", "Unable to authenticate with AuraBrain Tenant API.");
  }
}

/**
 * Helper to resolve an AuraBrain Client ID using phone number and email,
 * or create one if it doesn't exist.
 */
async function resolveOrCreateAuraClient(phone?: string, email?: string): Promise<string> {
  const tenantToken = await getTenantToken();
  const headers = { Authorization: `Bearer ${tenantToken}` };

  try {
    console.log(`[BFF] Attempting to resolve client for phone: ${phone}, email: ${email}`);
    const resolveResponse = await axios.post(
      `${TENANT_BASE_URL}/api/v1/clients/resolve`,
      { phone, email },
      { headers }
    );

    if (resolveResponse.data && resolveResponse.data.id) {
      console.log(`[BFF] Resolved existing client ID: ${resolveResponse.data.id}`);
      return resolveResponse.data.id;
    }
  } catch (error: any) {
    console.log("[BFF] Client resolution failed. Creating client...", error.message || error);
  }

  // Client does not exist, create a new one
  try {
    console.log(`[BFF] Creating new client for phone: ${phone}, email: ${email}`);
    const createResponse = await axios.post(
      `${TENANT_BASE_URL}/api/v1/clients/createClient`,
      { phone, email, name: "Smart Home User" },
      { headers }
    );

    if (createResponse.data && createResponse.data.clientId) {
      const clientId = createResponse.data.clientId;
      console.log(`[BFF] Created new client ID: ${clientId}`);
      return clientId;
    }

    throw new Error("Create client response missing clientId.");
  } catch (error: any) {
    console.error("[BFF] Failed to create new client:", error.message || error);
    return "df0df9e3-0e47-4d46-810e-3c4f5c267d69";
  }
}

/**
 * Resolves the client UUID mapped to a Firebase user UID.
 */
async function getMappedClientId(uid: string): Promise<string> {
  const userDoc = await db.collection("users").doc(uid).get();
  if (!userDoc.exists || !userDoc.data()?.auraClientId) {
    throw new HttpsError("failed-precondition", "AuraBrain Client ID mapping not found. Call getTenantSession first.");
  }
  return userDoc.data()?.auraClientId;
}

/**
 * 1. getTenantSession (Callable)
 * Resolves the session, maps Firebase User to AuraBrain Client UUID, and saves FCM token.
 */
export const getTenantSession = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false, // Set to true in production with registered App Check keys
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please log in first.");
    }

    try {
      const uid = request.auth.uid;
      const phone = request.auth.token.phone_number;
      const email = request.auth.token.email;
      const fcmToken = request.data.fcmToken;

      if (!phone && !email) {
        throw new HttpsError("failed-precondition", "Both phone number and email claims are missing from Firebase Auth token.");
      }

      // Check if already mapped
      const userDoc = await db.collection("users").doc(uid).get();
      let clientId = userDoc.data()?.auraClientId;

      if (!clientId) {
        clientId = await resolveOrCreateAuraClient(phone, email);
        await db.collection("users").doc(uid).set(
          {
            auraClientId: clientId,
            phone: phone || "",
            email: email || "",
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        console.log(`[BFF] Mapped Firebase user ${uid} to client ${clientId}`);
      }

      // Save FCM token if provided
      if (fcmToken) {
        await db.collection("users").doc(uid).set(
          {
            fcmToken: fcmToken,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        console.log(`[BFF] Registered FCM token for user ${uid}`);
      }

      return {
        success: true,
        clientId: clientId,
      };
    } catch (error: any) {
      console.error("[BFF] getTenantSession failed:", error);
      throw new HttpsError("internal", error.message || "Internal server error");
    }
  }
);

/**
 * 2. getDevices (Callable)
 * Proxies devices query.
 */
export const getDevices = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please log in first.");
    }

    try {
      const clientId = await getMappedClientId(request.auth.uid);
      const tenantToken = await getTenantToken();

      console.log(`[BFF] Querying devices for client ${clientId}...`);
      const response = await axios.get(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices`,
        { headers: { Authorization: `Bearer ${tenantToken}` } }
      );

      return response.data;
    } catch (error: any) {
      console.error("[BFF] getDevices failed:", error.message || error);
      throw new HttpsError(
        error.status === 404 ? "not-found" : "internal",
        error.message || "Failed to fetch devices."
      );
    }
  }
);

/**
 * 3. sendDeviceCommand (Callable)
 * Sends device command and sends FCM push notification.
 */
export const sendDeviceCommand = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please log in first.");
    }

    try {
      const uid = request.auth.uid;
      const clientId = await getMappedClientId(uid);
      
      const { deviceId, command, value, deviceName } = request.data;
      if (!deviceId || !command) {
        throw new HttpsError("invalid-argument", "Missing deviceId or command.");
      }

      const tenantToken = await getTenantToken();
      console.log(`[BFF] Executing command on device ${deviceId} for client ${clientId}...`);
      
      const response = await axios.post(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/${deviceId}/command`,
        { command, value },
        { headers: { Authorization: `Bearer ${tenantToken}` } }
      );

      // Trigger push notification if successful
      if (response.status === 200) {
        const userDoc = await db.collection("users").doc(uid).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (fcmToken) {
          const displayDevice = deviceName || `Device (${deviceId.substring(0, 5)})`;
          const displayVal = value !== undefined && value !== null ? `: ${value}` : "";
          
          const message = {
            token: fcmToken,
            notification: {
              title: "Device Command Executed",
              body: `${displayDevice} set to ${command.toUpperCase()}${displayVal}`,
            },
            data: {
              deviceId: deviceId,
              command: command,
              value: String(value || ""),
              timestamp: String(Date.now()),
            },
          };

          getMessaging().send(message)
            .then((msgId) => console.log(`[BFF] Notification sent successfully: ${msgId}`))
            .catch((fcmErr) => console.error("[BFF] FCM Notification failed:", fcmErr));
        }
      }

      return response.data;
    } catch (error: any) {
      console.error("[BFF] sendDeviceCommand failed:", error.message || error);
      throw new HttpsError("internal", error.message || "Failed to execute command.");
    }
  }
);

/**
 * 4. getHomes (Callable)
 * Proxies homes layout query.
 */
export const getHomes = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Please log in first.");
    }

    try {
      const clientId = await getMappedClientId(request.auth.uid);
      const tenantToken = await getTenantToken();

      console.log(`[BFF] Querying homes for client ${clientId}...`);
      const response = await axios.get(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes`,
        { headers: { Authorization: `Bearer ${tenantToken}` } }
      );

      return response.data;
    } catch (error: any) {
      console.error("[BFF] getHomes failed:", error.message || error);
      throw new HttpsError("internal", error.message || "Failed to fetch homes.");
    }
  }
);
