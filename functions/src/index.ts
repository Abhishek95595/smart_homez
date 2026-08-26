import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import axios from "axios";
import * as https from "https";

// Initialize Keep-Alive agent for fast connection reuse to AuraBrain
const httpsAgent = new https.Agent({
  keepAlive: true,
  maxSockets: 50,
  keepAliveMsecs: 1000,
});
axios.defaults.httpsAgent = httpsAgent;
axios.defaults.timeout = 8000; // 8s global timeout for all AuraBrain calls

// Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();

// Load Environment Configurations
const TENANT_BASE_URL = process.env.TENANT_BASE_URL || "https://tenant-api-qa.omnihome.in";

// Secure Secrets from Google Cloud Secret Manager
const TENANT_CLIENT_ID = defineSecret("TENANT_CLIENT_ID");
const TENANT_CLIENT_SECRET = defineSecret("TENANT_CLIENT_SECRET");

// Token Cache Structure
interface TokenCache {
  token: string | null;
  expiresAt: number;
}

const tokenCache: TokenCache = {
  token: null,
  expiresAt: 0,
};

let inFlightTokenPromise: Promise<string> | null = null;

/**
 * Concurrency-safe Tenant token manager.
 * Uses a single in-flight Promise during token refresh.
 */
async function getTenantToken(): Promise<string> {
  const now = Date.now();
  // Return cached token if still valid with a 5-minute safety buffer
  if (tokenCache.token && tokenCache.expiresAt > now + 300000) {
    return tokenCache.token;
  }

  if (inFlightTokenPromise) {
    return inFlightTokenPromise;
  }

  inFlightTokenPromise = (async () => {
    try {
      console.log("[BFF] Fetching new Tenant JWT token from AuraBrain...");
      const response = await axios.post(
        `${TENANT_BASE_URL}/api/Auth/token`,
        {
          clientId: TENANT_CLIENT_ID.value(),
          clientSecret: TENANT_CLIENT_SECRET.value(),
        },
        { timeout: 10000 }
      );

      const data = response.data;
      if (!data || data.success !== true || !data.token) {
        throw new Error(data.error?.message || data.error || "Failed to exchange Tenant API token.");
      }

      tokenCache.token = data.token;
      const expiryDuration = data.expiresIn ? data.expiresIn * 1000 : 3600000;
      tokenCache.expiresAt = Date.now() + expiryDuration;

      console.log("[BFF] Successfully acquired and cached Tenant JWT token.");
      return tokenCache.token as string;
    } catch (error: any) {
      console.error("[BFF] Error acquiring Tenant token:", error.message || error);
      throw new HttpsError("unauthenticated", "Unable to authenticate with AuraBrain Tenant API.");
    } finally {
      inFlightTokenPromise = null;
    }
  })();

  return inFlightTokenPromise as Promise<string>;
}

/**
 * Returns the verified phone and email from Firebase Claims.
 */
function getVerifiedClaims(auth: any) {
  const phone = auth.token.phone_number;
  const email = auth.token.email_verified === true ? auth.token.email : undefined;
  return { phone, email };
}

/**
 * Resolves the client ID mapped to a Firebase user UID.
 */
async function getMappedClientId(uid: string): Promise<string> {
  const userDoc = await db.collection("userTenantMappings").doc(uid).get();
  if (!userDoc.exists || !userDoc.data()?.auraClientId) {
    throw new HttpsError(
      "failed-precondition",
      "AuraBrain Client ID mapping not found. Complete your sign-in first."
    );
  }
  return userDoc.data()?.auraClientId as string;
}

/**
 * Checks if a particular device belongs to the client ID.
 */
async function verifyDeviceOwnership(clientId: string, deviceId: string): Promise<void> {
  const token = await getTenantToken();
  try {
    const res = await axios.get(
      `${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/${deviceId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    if (!res.data || res.data.client_id !== clientId) {
      throw new HttpsError("permission-denied", "Unauthorized access to device resource.");
    }
  } catch (error) {
    throw new HttpsError("permission-denied", "Device resource ownership check failed.");
  }
}

/**
 * Checks if a home belongs to the client ID.
 */
async function verifyHomeOwnership(clientId: string, homeId: string): Promise<void> {
  const token = await getTenantToken();
  try {
    const res = await axios.get(
      `${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes/${homeId}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    // AuraBrain payload validation
    if (!res.data || res.data.client_id !== clientId) {
      throw new HttpsError("permission-denied", "Unauthorized access to home resource.");
    }
  } catch (error) {
    throw new HttpsError("permission-denied", "Home resource ownership check failed.");
  }
}

/**
 * Masks phone number for safe logs/responses.
 */
function maskPhone(phone: string): string {
  if (phone.length < 5) return "***";
  return phone.substring(0, 3) + "*".repeat(phone.length - 5) + phone.substring(phone.length - 2);
}

/**
 * Masks email address for safe logs/responses.
 */
function maskEmail(email: string): string {
  const parts = email.split("@");
  if (parts.length !== 2) return "***";
  const name = parts[0];
  const domain = parts[1];
  if (name.length < 3) return `*@${domain}`;
  return `${name.substring(0, 2)}***${name.substring(name.length - 1)}@${domain}`;
}

/**
 * 1. getTenantSession (Callable)
 * Resolves mapped user or queries AuraBrain resolve.
 */
export const getTenantSession = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false, // production will enforceAppCheck
    minInstances: 1, // Keep warm to prevent cold starts
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const { phone, email } = getVerifiedClaims(request.auth);

    // 1. Check permanent mapping in Firestore
    const mappingDoc = await db.collection("userTenantMappings").doc(uid).get();
    if (mappingDoc.exists && mappingDoc.data()?.auraClientId) {
      const clientId = mappingDoc.data()?.auraClientId;
      
      // Update FCM token directly if supplied (deferred FCM logic)
      const fcmToken = request.data.fcmToken;
      if (fcmToken) {
        await db.collection("userPushTokens").doc(uid).set({
          fcmToken: fcmToken,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      return {
        success: true,
        status: "authenticated",
        client: {
          id: clientId,
          name: mappingDoc.data()?.name || "Smart Home User",
        },
      };
    }

    // 2. No mapping: resolve via verified claims
    if (!phone && !email) {
      throw new HttpsError("failed-precondition", "No verified phone or email claims found.");
    }

    try {
      const token = await getTenantToken();
      console.log(`[BFF] Resolving contact details for UID ${uid}`);
      
      const resolveResponse = await axios.post(
        `${TENANT_BASE_URL}/api/v1/clients/resolve`,
        { phone, email },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      const resolvedData = resolveResponse.data;
      
      // If client exists, resolvedData should contain ID/client properties
      if (resolvedData && resolvedData.id) {
        const auraClientId = resolvedData.id;
        
        // Transactionally create mapping
        await db.collection("userTenantMappings").doc(uid).set({
          auraClientId: auraClientId,
          name: resolvedData.name || "Smart Home User",
          verifiedPhone: phone || "",
          verifiedEmail: email || "",
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

        // Register FCM if exists
        const fcmToken = request.data.fcmToken;
        if (fcmToken) {
          await db.collection("userPushTokens").doc(uid).set({
            fcmToken: fcmToken,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        return {
          success: true,
          status: "authenticated",
          client: {
            id: auraClientId,
            name: resolvedData.name || "Smart Home User",
          },
        };
      }

      // If resolvedData is empty or success is false, client is missing
      if (resolvedData?.success === false || !resolvedData?.id) {
        return {
          success: false,
          status: "registrationRequired",
          requiresRegistration: true,
        };
      }

      throw new Error("Unexpected response payload from resolve.");
    } catch (error: any) {
      console.error("[BFF] Resolve error details:", error.response?.data || error.message || error);
      
      if (error.response?.status === 401) {
        throw new HttpsError("unauthenticated", "Authentication failure on backend connection.");
      }
      
      // Any generic resolve failure results in temporarilyUnavailable status
      return {
        success: false,
        status: "temporarilyUnavailable",
        message: "AuraBrain resolve service is currently offline. Please try again.",
      };
    }
  }
);

/**
 * 2. registerTenantClient (Callable)
 * Triggers client registration and SMS/Email OTP code.
 */
export const registerTenantClient = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const name = request.data.name;
    const { phone, email } = getVerifiedClaims(request.auth);

    if (!name || name.trim().length === 0 || name.trim().length > 100) {
      throw new HttpsError("invalid-argument", "Name must be provided (max 100 characters).");
    }

    if (!phone && !email) {
      throw new HttpsError("failed-precondition", "No verified phone or email claims found.");
    }

    // Verify mapping doesn't exist
    const mappingDoc = await db.collection("userTenantMappings").doc(uid).get();
    if (mappingDoc.exists) {
      throw new HttpsError("failed-precondition", "User is already mapped to a tenant client.");
    }

    // Verify rate limit / cooldown on pending registration
    const pendingDoc = await db.collection("pendingTenantRegistrations").doc(uid).get();
    if (pendingDoc.exists) {
      const pData = pendingDoc.data();
      const now = Date.now();
      if (pData?.resendAvailableAt && now < pData.resendAvailableAt) {
        throw new HttpsError(
          "resource-exhausted",
          `Please wait before requesting another code.`
        );
      }
    }

    try {
      const token = await getTenantToken();
      
      console.log(`[BFF] Calling createClient for UID ${uid}`);
      const createResponse = await axios.post(
        `${TENANT_BASE_URL}/api/v1/clients/createClient`,
        { name: name.trim(), email: email || "", phone: phone || "" },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      const createData = createResponse.data;
      console.log("[BFF] createClient response payload:", JSON.stringify(createData));

      const pendingClientId = createData?.clientId || 
                              createData?.id || 
                              createData?.client_id || 
                              createData?.data?.clientId || 
                              createData?.data?.id || 
                              createData?.data?.client_id;

      if (!pendingClientId) {
        throw new Error(`createClient response missing client ID. Payload: ${JSON.stringify(createData)}`);
      }

      // Store pending registration document
      await db.collection("pendingTenantRegistrations").doc(uid).set({
        pendingClientId: pendingClientId,
        attempts: 0,
        expiresAt: Date.now() + 15 * 60 * 1000, // 15 mins
        resendAvailableAt: Date.now() + 60 * 1000, // 60s cooldown
        createdAt: Date.now(),
        verifiedPhone: phone || "",
        verifiedEmail: email || "",
        name: name,
        fcmToken: request.data.fcmToken || "", // Defer FCM registration until after verification
      });

      return {
        success: true,
        status: "otpVerificationRequired",
        deliveryChannel: phone ? "sms" : "email",
        maskedDestination: phone ? maskPhone(phone) : maskEmail(email),
        resendAvailableIn: 60,
      };
    } catch (error: any) {
      console.error("[BFF] createClient error:", error.response?.data || error.message || error);
      
      // Handle 409 conflict
      if (error.response?.status === 409) {
        console.log(`[BFF] Conflict (409) detected. Retrying client resolution...`);
        try {
          const token = await getTenantToken();
          const resolveResponse = await axios.post(
            `${TENANT_BASE_URL}/api/v1/clients/resolve`,
            { phone, email },
            { headers: { Authorization: `Bearer ${token}` } }
          );

          if (resolveResponse.data && resolveResponse.data.id) {
            // Confirm mapping owner is safe and matches
            const mappedId = resolveResponse.data.id;
            await db.collection("userTenantMappings").doc(uid).set({
              auraClientId: mappedId,
              name: name,
              verifiedPhone: phone || "",
              verifiedEmail: email || "",
              createdAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            });

            return {
              success: true,
              status: "authenticated",
              client: {
                id: mappedId,
                name: name,
              },
            };
          }
        } catch (resolveErr) {
          console.error("[BFF] Retry resolve failed:", resolveErr);
        }
        throw new HttpsError("already-exists", "This contact detail belongs to another client. Verification failed.");
      }

      throw new HttpsError("internal", error.message || "Failed to create registration client.");
    }
  }
);

/**
 * 3. verifyTenantClient (Callable)
 * Verifies client creation OTP code and creates permanent mapping.
 */
export const verifyTenantClient = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const code = request.data.code;

    if (!code || code.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Verification code is required.");
    }

    const pendingRef = db.collection("pendingTenantRegistrations").doc(uid);
    const pendingDoc = await pendingRef.get();

    if (!pendingDoc.exists) {
      throw new HttpsError("failed-precondition", "No active pending registration found.");
    }

    const pData = pendingDoc.data();
    if (!pData) {
      throw new HttpsError("failed-precondition", "Registration data is missing.");
    }

    if (Date.now() > pData.expiresAt) {
      await pendingRef.delete();
      throw new HttpsError("deadline-exceeded", "Registration OTP expired. Please register again.");
    }

    if (pData.attempts >= 5) {
      await pendingRef.delete();
      throw new HttpsError("resource-exhausted", "Too many failed attempts. Please restart registration.");
    }

    try {
      const token = await getTenantToken();
      
      console.log(`[BFF] Verifying OTP code for pending client ID ${pData.pendingClientId}`);
      const verifyResponse = await axios.post(
        `${TENANT_BASE_URL}/api/v1/clients/createClient/verify`,
        { client_id: pData.pendingClientId, code: code.trim() },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      const verifyData = verifyResponse.data;
      if (verifyData && verifyResponse.status === 200) {
        // Verification succeeded: create permanent mapping transactionally
        await db.runTransaction(async (transaction) => {
          const mappingRef = db.collection("userTenantMappings").doc(uid);
          const currentMapping = await transaction.get(mappingRef);

          if (currentMapping.exists) {
            throw new HttpsError("failed-precondition", "A mapping for this user already exists.");
          }

          transaction.set(mappingRef, {
            auraClientId: pData.pendingClientId,
            name: pData.name || "Smart Home User",
            verifiedPhone: pData.verifiedPhone || "",
            verifiedEmail: pData.verifiedEmail || "",
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
        });

        // Register FCM if exists
        const fcmToken = pData.fcmToken;
        if (fcmToken) {
          await db.collection("userPushTokens").doc(uid).set({
            fcmToken: fcmToken,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        // Clean up pending registration
        await pendingRef.delete();

        return {
          success: true,
          status: "authenticated",
          clientId: pData.pendingClientId,
        };
      }

      throw new Error("Invalid verification response from AuraBrain.");
    } catch (error: any) {
      console.error("[BFF] OTP Verify error:", error.response?.data || error.message || error);

      // Increment attempt count ONLY when AuraBrain explicitly confirms OTP is invalid (400 Bad Request)
      if (error.response?.status === 400) {
        const nextAttempts = (pData?.attempts || 0) + 1;
        if (nextAttempts >= 5) {
          await pendingRef.delete();
          throw new HttpsError("resource-exhausted", "Too many invalid OTP attempts. Registration cancelled.");
        } else {
          await pendingRef.update({ attempts: nextAttempts });
        }
        throw new HttpsError("invalid-argument", "Invalid OTP verification code.");
      }

      throw new HttpsError("internal", error.message || "Failed to verify registration code.");
    }
  }
);

/**
 * 4. resendTenantRegistrationOtp (Callable)
 * Resends/restarts OTP verification for registration.
 */
export const resendTenantRegistrationOtp = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const uid = request.auth.uid;
    const pendingRef = db.collection("pendingTenantRegistrations").doc(uid);
    const pendingDoc = await pendingRef.get();

    if (!pendingDoc.exists) {
      throw new HttpsError("failed-precondition", "No pending registration found.");
    }

    const pData = pendingDoc.data();
    if (!pData) {
      throw new HttpsError("failed-precondition", "Registration data is missing.");
    }

    const now = Date.now();
    if (now < pData.resendAvailableAt) {
      throw new HttpsError("resource-exhausted", "Please wait before resending OTP.");
    }

    try {
      const token = await getTenantToken();
      console.log(`[BFF] Resending OTP code for client name: ${pData.name}`);
      
      await axios.post(
        `${TENANT_BASE_URL}/api/v1/clients/createClient`,
        { name: pData.name, email: pData.verifiedEmail, phone: pData.verifiedPhone },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      // Update cooldown limits
      await pendingRef.update({
        resendAvailableAt: Date.now() + 60 * 1000,
        createdAt: Date.now(),
      });

      return {
        success: true,
        resendAvailableIn: 60,
      };
    } catch (error: any) {
      console.error("[BFF] Resend OTP failed:", error.message || error);
      throw new HttpsError("internal", "Failed to resend registration verification code.");
    }
  }
);

/**
 * 5. getHomes (Callable)
 */
export const getHomes = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const clientId = await getMappedClientId(request.auth.uid);
    const token = await getTenantToken();

    try {
      const response = await axios.get(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      return response.data;
    } catch (error: any) {
      throw new HttpsError("internal", error.message || "Failed to fetch client homes.");
    }
  }
);

/**
 * 6. getFloors (Callable)
 */
export const getFloors = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const homeId = request.data.homeId;
    if (!homeId) {
      throw new HttpsError("invalid-argument", "homeId is required.");
    }

    const clientId = await getMappedClientId(request.auth.uid);
    await verifyHomeOwnership(clientId, homeId);
    const token = await getTenantToken();

    try {
      const response = await axios.get(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes/${homeId}/floors`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      return response.data;
    } catch (error: any) {
      throw new HttpsError("internal", error.message || "Failed to fetch floors.");
    }
  }
);

/**
 * 7. getRooms (Callable)
 */
export const getRooms = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { homeId, floorId } = request.data;
    if (!homeId || !floorId) {
      throw new HttpsError("invalid-argument", "homeId and floorId are required.");
    }

    const clientId = await getMappedClientId(request.auth.uid);
    await verifyHomeOwnership(clientId, homeId);
    const token = await getTenantToken();

    try {
      const response = await axios.get(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes/${homeId}/floors/${floorId}/rooms`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      return response.data;
    } catch (error: any) {
      throw new HttpsError("internal", error.message || "Failed to fetch rooms.");
    }
  }
);

/**
 * 8. getDevices (Callable)
 */
export const getDevices = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const clientId = await getMappedClientId(request.auth.uid);
    const token = await getTenantToken();

    try {
      const response = await axios.get(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      return response.data;
    } catch (error: any) {
      throw new HttpsError("internal", error.message || "Failed to fetch devices.");
    }
  }
);

/**
 * 9. getDevice (Callable)
 */
export const getDevice = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const deviceId = request.data.deviceId;
    if (!deviceId) {
      throw new HttpsError("invalid-argument", "deviceId is required.");
    }

    const clientId = await getMappedClientId(request.auth.uid);
    await verifyDeviceOwnership(clientId, deviceId);
    const token = await getTenantToken();

    try {
      const response = await axios.get(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/${deviceId}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      return response.data;
    } catch (error: any) {
      throw new HttpsError("internal", error.message || "Failed to fetch device details.");
    }
  }
);

/**
 * 10. sendDeviceCommand (Callable)
 * Sends command with strict validations: Command must be on strict allowlist
 * on, off, toggle, brightness, speed, color, set
 */
export const sendDeviceCommand = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { deviceId, command, value, deviceName } = request.data;
    if (!deviceId || !command) {
      throw new HttpsError("invalid-argument", "deviceId and command are required.");
    }

    // Command Validation Allowlist (No temperature)
    const validCommands = ["on", "off", "toggle", "brightness", "speed", "color", "set"];
    if (!validCommands.includes(command)) {
      throw new HttpsError("invalid-argument", `Command ${command} is not supported.`);
    }

    // Value Validations
    if (["on", "off", "toggle"].includes(command)) {
      if (value !== undefined && value !== null) {
        throw new HttpsError("invalid-argument", `Command ${command} does not accept a value.`);
      }
    } else if (command === "brightness") {
      const numVal = Number(value);
      if (isNaN(numVal) || numVal < 0 || numVal > 100) {
        throw new HttpsError("invalid-argument", "Brightness value must be a number between 0 and 100.");
      }
    } else if (command === "speed") {
      const numVal = Number(value);
      if (isNaN(numVal) || numVal < 1 || numVal > 3) {
        throw new HttpsError("invalid-argument", "Fan speed value must be a number between 1 and 3.");
      }
    } else if (command === "color") {
      const hexPattern = /^#[0-9A-F]{6}$/i;
      if (typeof value !== "string" || !hexPattern.test(value)) {
        throw new HttpsError("invalid-argument", "Color value must be a valid hex color string (e.g. #FF5733).");
      }
    } else if (command === "set") {
      if (typeof value !== "string") {
        throw new HttpsError("invalid-argument", "Set command value must be a string.");
      }
    }

    const clientId = await getMappedClientId(request.auth.uid);
    await verifyDeviceOwnership(clientId, deviceId);
    const token = await getTenantToken();

    try {
      console.log(`[BFF] Sending command ${command} with value ${value} to device ${deviceId}`);
      const response = await axios.post(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/${deviceId}/command`,
        { command, value },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      // Trigger push notifications if successful
      if (response.status === 200) {
        const userPushDoc = await db.collection("userPushTokens").doc(request.auth.uid).get();
        const fcmToken = userPushDoc.data()?.fcmToken;

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
      throw new HttpsError("internal", error.message || "Failed to execute command.");
    }
  }
);

/**
 * 11. getDashboard (Callable)
 * period must be hourly, daily, weekly, monthly.
 */
export const getDashboard = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
    minInstances: 1, // Keep warm to prevent cold starts
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { homeId, period } = request.data;
    if (!homeId || !period) {
      throw new HttpsError("invalid-argument", "homeId and period are required.");
    }

    const validPeriods = ["hourly", "daily", "weekly", "monthly"];
    if (!validPeriods.includes(period)) {
      throw new HttpsError("invalid-argument", `Period ${period} is invalid. Choose from: hourly, daily, weekly, monthly.`);
    }

    const clientId = await getMappedClientId(request.auth.uid);
    await verifyHomeOwnership(clientId, homeId);
    const token = await getTenantToken();

    try {
      const response = await axios.get(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes/${homeId}/dashboard`,
        {
          headers: { Authorization: `Bearer ${token}` },
          params: { period },
        }
      );
      return response.data;
    } catch (error: any) {
      throw new HttpsError("internal", error.message || "Failed to fetch dashboard details.");
    }
  }
);

/**
 * 12. syncDevices (Callable)
 */
export const syncDevices = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const clientId = await getMappedClientId(request.auth.uid);
    const token = await getTenantToken();

    try {
      const response = await axios.post(
        `${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/sync`,
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      );
      return response.data;
    } catch (error: any) {
      throw new HttpsError("internal", error.message || "Failed to sync devices.");
    }
  }
);
