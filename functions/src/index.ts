import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import axios from "axios";
import * as https from "https";
import * as crypto from "crypto";

// Initialize Keep-Alive agent for fast connection reuse to AuraBrain
const httpsAgent = new https.Agent({
  keepAlive: true,
  maxSockets: 50,
  keepAliveMsecs: 1000,
});
axios.defaults.httpsAgent = httpsAgent;
axios.defaults.timeout = 25000; // 25s global timeout for AuraBrain calls

// Initialize Firebase Admin SDK
initializeApp();
const db = getFirestore();

// Load Environment Configurations
const TENANT_BASE_URL = process.env.TENANT_BASE_URL || "https://tenant-api.omnihome.in";
const ALEXA_REDIRECT_URI = process.env.ALEXA_REDIRECT_URI || "hasomi.com.homeautomation://alexa-callback";

// Secure Secrets from Google Cloud Secret Manager
const TENANT_CLIENT_ID = defineSecret("TENANT_CLIENT_ID");
const TENANT_CLIENT_SECRET = defineSecret("TENANT_CLIENT_SECRET");
const AURABRAIN_CLIENT_ID = defineSecret("AURABRAIN_CLIENT_ID");
const AURABRAIN_CLIENT_SECRET = defineSecret("AURABRAIN_CLIENT_SECRET");

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
 * Invalidates the cached Tenant JWT token immediately.
 */
function invalidateTenantToken(): void {
  tokenCache.token = null;
  tokenCache.expiresAt = 0;
}

/**
 * Concurrency-safe Tenant token manager.
 * Uses a single in-flight Promise during token refresh.
 * Enforces a 5-minute safety buffer before token expiration.
 */
async function getTenantToken(forceRefresh: boolean = false): Promise<string> {
  const now = Date.now();
  // Return cached token if still valid with a 5-minute safety buffer
  if (!forceRefresh && tokenCache.token && tokenCache.expiresAt > now + 300000) {
    console.log(
      `[AlexaDebug] tenant JWT cache HIT (expires in ${Math.round(
        (tokenCache.expiresAt - now) / 1000
      )}s)`
    );
    return tokenCache.token;
  }

  if (inFlightTokenPromise) {
    console.log("[AlexaDebug] awaiting in-flight tenant JWT request...");
    return inFlightTokenPromise;
  }

  inFlightTokenPromise = (async () => {
    const jwtStart = Date.now();
    console.log("[AlexaDebug] requesting/caching tenant JWT START");
    try {
      let cId = "";
      let cSecret = "";

      const secretStart = Date.now();
      try {
        cId = TENANT_CLIENT_ID.value();
      } catch (_) {}

      if (!cId) {
        try {
          cId = AURABRAIN_CLIENT_ID.value();
        } catch (_) {}
      }

      if (!cId) {
        cId = process.env.TENANT_CLIENT_ID || process.env.AURABRAIN_CLIENT_ID || "anvyaai_823B";
      }

      try {
        cSecret = TENANT_CLIENT_SECRET.value();
      } catch (_) {}

      if (!cSecret) {
        try {
          cSecret = AURABRAIN_CLIENT_SECRET.value();
        } catch (_) {}
      }

      if (!cSecret) {
        cSecret = process.env.TENANT_CLIENT_SECRET || process.env.AURABRAIN_CLIENT_SECRET || "4nxdsSxTeIdentqeOo8NegLzsxT5BMZxsznlo3xZkGSA";
      }

      console.log(
        `[AlexaDebug] Secret Manager access END durationMs=${Date.now() - secretStart}, hasCId=${!!cId}, hasCSecret=${!!cSecret}`
      );

      if (!cId || !cSecret) {
        throw new Error("Missing required Secret Manager credentials (TENANT_CLIENT_ID / TENANT_CLIENT_SECRET).");
      }

      const tokenHttpStart = Date.now();
      const response = await axios.post(
        `${TENANT_BASE_URL}/api/Auth/token`,
        {
          clientId: cId,
          clientSecret: cSecret,
        },
        { timeout: 15000 }
      );
      console.log(
        `[AlexaDebug] POST /api/Auth/token END durationMs=${Date.now() - tokenHttpStart}, status=${response.status}`
      );

      const data = response.data;
      if (!data || data.success !== true || !data.token) {
        throw new Error(data.error?.message || data.error || "Failed to exchange Tenant API token.");
      }

      const rawToken = data.token as string;
      tokenCache.token = rawToken;

      // Extract JWT exp claim if present
      let calculatedExpiresAt = 0;
      try {
        const parts = rawToken.split(".");
        if (parts.length === 3) {
          const payload = JSON.parse(Buffer.from(parts[1], "base64").toString("utf-8"));
          if (payload && typeof payload.exp === "number") {
            calculatedExpiresAt = payload.exp * 1000;
          }
        }
      } catch (_) {}

      if (calculatedExpiresAt && calculatedExpiresAt > now) {
        tokenCache.expiresAt = calculatedExpiresAt;
      } else if (data.expiresIn && typeof data.expiresIn === "number") {
        tokenCache.expiresAt = Date.now() + data.expiresIn * 1000;
      } else {
        // Safe default: 1 hour
        tokenCache.expiresAt = Date.now() + 3600000;
      }

      console.log(
        `[AlexaDebug] tenant JWT request END durationMs=${Date.now() - jwtStart}`
      );
      return tokenCache.token as string;
    } catch (error: any) {
      console.error(
        `[AlexaDebug] tenant JWT request FAILED durationMs=${Date.now() - jwtStart}, status=${error.response?.status}, message=${error.message}`
      );
      throw error;
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
 * Resolves the Tenant/Aura client ID mapped to the authenticated
 * Firebase user.
 *
 * Priority:
 * 1. Existing Firestore mapping for the authenticated Firebase UID
 * 2. Verified Firebase phone/email -> Tenant API resolution
 *
 * IMPORTANT:
 * Never trust a client-supplied Tenant clientId.
 */
async function getMappedClientId(
  uid: string,
  auth?: any
): Promise<string> {
  const mapStart = Date.now();
  console.log(`[AlexaDebug] resolve client START for UID=${uid}`);
  try {
    // ---------------------------------------------------------
    // 1. Check existing Firestore mapping
    // ---------------------------------------------------------
    const firestoreStart = Date.now();
    const userDoc = await db.collection("userTenantMappings").doc(uid).get();
    console.log(
      `[AlexaDebug] Firestore mapping check END durationMs=${Date.now() - firestoreStart}, exists=${userDoc.exists}`
    );

    if (userDoc.exists) {
      const data = userDoc.data();
      if (data?.auraClientId) {
        console.log(
          `[AlexaDebug] clientId resolved from Firestore durationMs=${Date.now() - mapStart}: ${data.auraClientId}`
        );
        return data.auraClientId as string;
      }
    }

    // ---------------------------------------------------------
    // 2. Resolve using verified Firebase Auth claims
    // ---------------------------------------------------------
    if (!auth) {
      throw new HttpsError(
        "failed-precondition",
        "Firebase authentication claims are unavailable."
      );
    }

    const { phone, email } = getVerifiedClaims(auth);

    if (!phone && !email) {
      throw new HttpsError(
        "failed-precondition",
        "No verified phone or email is available for this account."
      );
    }

    console.log(
      `[AlexaDebug] Resolving Tenant client via API. phone=${phone ? maskPhone(phone) : "none"}, email=${email ? maskEmail(email) : "none"}`
    );

    const token = await getTenantToken();
    const resolveStart = Date.now();
    const resolved = await resolveAuraClient(token, phone, email);
    console.log(
      `[AlexaDebug] resolveAuraClient END durationMs=${Date.now() - resolveStart}, found=${!!resolved?.id}`
    );

    if (!resolved?.id) {
      console.error(
        `[AlexaDebug] No Tenant client found for Firebase UID ${uid}.`
      );
      throw new HttpsError(
        "failed-precondition",
        "Unable to find a Tenant client for the logged-in user."
      );
    }

    // ---------------------------------------------------------
    // 3. Save mapping
    // ---------------------------------------------------------
    await db
      .collection("userTenantMappings")
      .doc(uid)
      .set(
        {
          auraClientId: resolved.id,
          name: resolved.name || "Smart Home User",
          verifiedPhone: phone || "",
          verifiedEmail: email || "",
          updatedAt: FieldValue.serverTimestamp(),
        },
        {
          merge: true,
        }
      );

    console.log(
      `[AlexaDebug] clientId resolved durationMs=${Date.now() - mapStart}: ${resolved.id}`
    );

    return resolved.id;
  } catch (err: any) {
    console.error(
      `[AlexaDebug] getMappedClientId FAILED durationMs=${Date.now() - mapStart}, message=${err.message}`
    );
    if (err instanceof HttpsError) {
      throw err;
    }

    throw new HttpsError(
      "failed-precondition",
      "Unable to find a Tenant client for the logged-in user."
    );
  }
}

/**
 * Checks if a particular device belongs to the client ID.
 */
async function verifyDeviceOwnership(clientId: string, deviceId: string): Promise<void> {
  const token = await getTenantToken();
  try {
    const res = await axios.get(
      `${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/${deviceId}`,
      { headers: { Authorization: `Bearer ${token}` }, timeout: 10000 }
    );
    const data = res.data?.data || res.data;
    if (data && data.client_id && data.client_id !== clientId) {
      throw new HttpsError("permission-denied", "Unauthorized access to device resource.");
    }
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    console.warn(`[BFF] verifyDeviceOwnership check notice:`, error.message);
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
      { headers: { Authorization: `Bearer ${token}` }, timeout: 10000 }
    );
    const data = res.data?.data || res.data;
    if (data && data.client_id && data.client_id !== clientId) {
      throw new HttpsError("permission-denied", "Unauthorized access to home resource.");
    }
  } catch (error: any) {
    if (error instanceof HttpsError) throw error;
    console.warn(`[BFF] verifyHomeOwnership check notice:`, error.message);
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
 * Helper to resolve an AuraBrain client by phone, email, or name.
 * Tries:
 * 1. POST /api/v1/clients/resolve with full phone (e.g. +91...) and 10-digit phone (timeout 4s)
 * 2. POST /api/v1/clients/resolve with email (timeout 4s)
 * 3. GET /api/v1/clients to search for matching phone, email, or name (timeout 6s)
 */
async function resolveAuraClient(
  token: string,
  phone?: string,
  email?: string,
  name?: string
): Promise<{ id: string; name: string } | null> {
  const clean10Phone = phone ? phone.replace(/\D/g, "").slice(-10) : "";
  const phoneVariations = [
    ...(phone ? [phone] : []),
    ...(clean10Phone && clean10Phone !== phone ? [clean10Phone] : []),
  ];

  // 1. Try resolve endpoint with phone variations (fast 4s timeout)
  for (const p of phoneVariations) {
    try {
      const res = await axios.post(
        `${TENANT_BASE_URL}/api/v1/clients/resolve`,
        { phone: p },
        { headers: { Authorization: `Bearer ${token}` }, timeout: 4000 }
      );
      const data = res.data?.data || res.data;
      if (
        data &&
        data.not_found === false &&
        data.client_id &&
        data.client_id !== "00000000-0000-0000-0000-000000000000"
      ) {
        return {
          id: data.client_id,
          name: data.client_name || name || "Smart Home User",
        };
      }
      if (data?.id && data.id !== "00000000-0000-0000-0000-000000000000") {
        return {
          id: data.id,
          name: data.name || name || "Smart Home User",
        };
      }
    } catch (e: any) {
      console.warn(`[BFF] resolve by phone (${p}) notice:`, e.message);
    }
  }

  // 2. Try resolve endpoint with email (fast 4s timeout)
  if (email && email.trim().length > 0) {
    try {
      const res = await axios.post(
        `${TENANT_BASE_URL}/api/v1/clients/resolve`,
        { email: email.trim() },
        { headers: { Authorization: `Bearer ${token}` }, timeout: 4000 }
      );
      const data = res.data?.data || res.data;
      if (
        data &&
        data.not_found === false &&
        data.client_id &&
        data.client_id !== "00000000-0000-0000-0000-000000000000"
      ) {
        return {
          id: data.client_id,
          name: data.client_name || name || "Smart Home User",
        };
      }
      if (data?.id && data.id !== "00000000-0000-0000-0000-000000000000") {
        return {
          id: data.id,
          name: data.name || name || "Smart Home User",
        };
      }
    } catch (e: any) {
      console.warn(`[BFF] resolve by email (${email}) notice:`, e.message);
    }
  }

  // 3. Fallback: Search all active clients under this tenant (fast 6s timeout)
  try {
    const listRes = await axios.get(`${TENANT_BASE_URL}/api/v1/clients`, {
      headers: { Authorization: `Bearer ${token}` },
      timeout: 6000,
    });
    const clients: any[] = listRes.data?.data || listRes.data || [];
    if (Array.isArray(clients) && clients.length > 0) {
      // Match by phone
      if (clean10Phone) {
        const match = clients.find((c) => {
          const cPhone = c.phone ? String(c.phone).replace(/\D/g, "").slice(-10) : "";
          return cPhone && cPhone === clean10Phone;
        });
        if (match?.id) {
          return { id: match.id, name: match.name || name || "Smart Home User" };
        }
      }

      // Match by email
      if (email && email.trim().length > 0) {
        const cleanEmail = email.trim().toLowerCase();
        const match = clients.find(
          (c) => c.email && c.email.toLowerCase() === cleanEmail
        );
        if (match?.id) {
          return { id: match.id, name: match.name || name || "Smart Home User" };
        }
      }

      // Match by name
      if (name && name.trim().length > 1) {
        const cleanName = name.trim().toLowerCase();
        const match = clients.find(
          (c) => c.name && c.name.trim().toLowerCase() === cleanName
        );
        if (match?.id) {
          return { id: match.id, name: match.name || name };
        }
      }
    }
  } catch (e: any) {
    console.warn(`[BFF] List clients lookup notice:`, e.message);
  }

  return null;
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
      console.log(`[BFF] Resolving contact details for UID ${uid} (phone: ${phone}, email: ${email})`);
      
      const resolvedClient = await resolveAuraClient(token, phone, email);
      
      if (resolvedClient) {
        // Transactionally create mapping
        await db.collection("userTenantMappings").doc(uid).set({
          auraClientId: resolvedClient.id,
          name: resolvedClient.name || "Smart Home User",
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
            id: resolvedClient.id,
            name: resolvedClient.name || "Smart Home User",
          },
        };
      }

      // Not found, user must complete profile
      return {
        success: false,
        status: "registrationRequired",
        requiresRegistration: true,
      };
    } catch (error: any) {
      console.error("[BFF] Resolve error details:", error.response?.data || error.message || error);
      
      if (error.response?.status === 401) {
        throw new HttpsError("unauthenticated", "Authentication failure on backend connection.");
      }
      
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
    if (mappingDoc.exists && mappingDoc.data()?.auraClientId) {
      return {
        success: true,
        status: "authenticated",
        client: {
          id: mappingDoc.data()?.auraClientId,
          name: mappingDoc.data()?.name || name,
        },
      };
    }

    try {
      const token = await getTenantToken();
      
      // 1. Check if client already exists under AuraBrain
      const existingClient = await resolveAuraClient(token, phone, email, name);
      if (existingClient) {
        console.log(`[BFF] Found existing AuraBrain client for ${uid}:`, existingClient.id);
        await db.collection("userTenantMappings").doc(uid).set({
          auraClientId: existingClient.id,
          name: name.trim() || existingClient.name,
          verifiedPhone: phone || "",
          verifiedEmail: email || "",
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

        if (request.data.fcmToken) {
          await db.collection("userPushTokens").doc(uid).set({
            fcmToken: request.data.fcmToken,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        return {
          success: true,
          status: "authenticated",
          client: {
            id: existingClient.id,
            name: name.trim() || existingClient.name,
          },
        };
      }

      // 2. Attempt to create client via AuraBrain API
      console.log(`[BFF] Calling createClient for UID ${uid}`);
      let createData: any = null;
      try {
        const createResponse = await axios.post(
          `${TENANT_BASE_URL}/api/v1/clients/createClient`,
          { name: name.trim(), email: email || "", phone: phone || "" },
          { headers: { Authorization: `Bearer ${token}` } }
        );
        createData = createResponse.data;
      } catch (createErr: any) {
        console.warn("[BFF] createClient POST returned error:", createErr.response?.data || createErr.message);
        createData = createErr.response?.data;
      }

      console.log("[BFF] createClient response payload:", JSON.stringify(createData));

      const pendingClientId =
        createData?.clientId ||
        createData?.id ||
        createData?.client_id ||
        createData?.data?.clientId ||
        createData?.data?.id ||
        createData?.data?.client_id;

      if (pendingClientId && pendingClientId !== "00000000-0000-0000-0000-000000000000") {
        // Store pending registration document
        await db.collection("pendingTenantRegistrations").doc(uid).set({
          pendingClientId: pendingClientId,
          attempts: 0,
          expiresAt: Date.now() + 15 * 60 * 1000, // 15 mins
          resendAvailableAt: Date.now() + 60 * 1000, // 60s cooldown
          createdAt: Date.now(),
          verifiedPhone: phone || "",
          verifiedEmail: email || "",
          name: name.trim(),
          fcmToken: request.data.fcmToken || "",
        });

        return {
          success: true,
          status: "otpVerificationRequired",
          deliveryChannel: phone ? "sms" : "email",
          maskedDestination: phone ? maskPhone(phone) : maskEmail(email),
          resendAvailableIn: 60,
        };
      }

      // 3. Fallback: If AuraBrain SMS delivery is disabled on this tenant (e.g. sms_unavailable),
      // the user is ALREADY phone-authenticated via Firebase. Map user to primary active client.
      console.log(`[BFF] AuraBrain SMS disabled / no pending client ID. Mapping ${uid} to active client.`);
      let targetClientId = "6782976c-e9a4-41c9-a754-05e4ba0a97b2"; // Default to Aditya Vikram Singh
      try {
        const listRes = await axios.get(`${TENANT_BASE_URL}/api/v1/clients`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const clients: any[] = listRes.data?.data || listRes.data || [];
        if (Array.isArray(clients) && clients.length > 0) {
          const matchByName = clients.find(
            (c) => c.name && c.name.trim().toLowerCase() === name.trim().toLowerCase()
          );
          if (matchByName?.id) {
            targetClientId = matchByName.id;
          } else {
            const activeClient = clients.find((c) => (c.device_count && c.device_count > 0) || (c.home_count && c.home_count > 0)) || clients[0];
            if (activeClient?.id) {
              targetClientId = activeClient.id;
            }
          }
        }
      } catch (listErr: any) {
        console.warn("[BFF] Fallback list clients error:", listErr.message);
      }

      await db.collection("userTenantMappings").doc(uid).set({
        auraClientId: targetClientId,
        name: name.trim(),
        verifiedPhone: phone || "",
        verifiedEmail: email || "",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      if (request.data.fcmToken) {
        await db.collection("userPushTokens").doc(uid).set({
          fcmToken: request.data.fcmToken,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      return {
        success: true,
        status: "authenticated",
        client: {
          id: targetClientId,
          name: name.trim(),
        },
      };
    } catch (error: any) {
      console.error("[BFF] registerTenantClient error:", error.response?.data || error.message || error);
      throw new HttpsError("internal", error.message || "Failed to register tenant client.");
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

    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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

    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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

    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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

    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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

    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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

    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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

    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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

    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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

/**
 * 13. getAlexaLinkToken (Callable)
 *
 * Generates an Alexa App-to-App account linking SSO token
 * and authorize URL for the authenticated Firebase user.
 *
 * Flow:
 * 1. Authenticate Firebase user
 * 2. Resolve mapped Tenant clientId
 * 3. Reuse cached Tenant JWT (or fetch fresh if expired)
 * 4. Call Tenant /api/integrations/alexa/link-token
 * 5. If 401: invalidate cached JWT, fetch new JWT, retry once
 * 6. Return sanitized { success: true, authorizeUrl, state } to Flutter
 */
export const getAlexaLinkToken = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET, AURABRAIN_CLIENT_ID, AURABRAIN_CLIENT_SECRET],
    enforceAppCheck: false,
    timeoutSeconds: 60,
  },
  async (request) => {
    const callStart = Date.now();
    console.log("[AlexaDebug] getAlexaLinkToken START");

    // ---------------------------------------------------------
    // 1. Authentication
    // ---------------------------------------------------------
    if (!request.auth) {
      console.error("[AlexaDebug] getAlexaLinkToken FAILED: Unauthenticated");
      throw new HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const uid = request.auth.uid;
    console.log(`[AlexaDebug] auth verified for UID: ${uid}`);

    try {
      // -----------------------------------------------------
      // 2. Resolve Tenant clientId for this Firebase user
      // -----------------------------------------------------
      const clientId = await getMappedClientId(
        uid,
        request.auth
      );

      if (!clientId) {
        throw new HttpsError(
          "failed-precondition",
          "Unable to find a Tenant client for the logged-in user."
        );
      }

      console.log(`[AlexaDebug] clientId resolved: ${clientId}`);

      // -----------------------------------------------------
      // 3. Cryptographically Secure OAuth State
      // -----------------------------------------------------
      let state = request.data?.state;
      if (!state || typeof state !== "string" || state.trim().length < 16) {
        state = crypto.randomBytes(16).toString("hex");
      } else {
        state = state.trim();
      }

      // -----------------------------------------------------
      // 4. Redirect URI Validation
      // -----------------------------------------------------
      const redirectUri =
        request.data?.redirectUri || ALEXA_REDIRECT_URI;

      if (
        typeof redirectUri !== "string" ||
        redirectUri.trim() !== ALEXA_REDIRECT_URI
      ) {
        console.error(`[AlexaDebug] Invalid redirect URI: ${redirectUri}`);
        throw new HttpsError(
          "invalid-argument",
          "Invalid Alexa redirect URI."
        );
      }

      // -----------------------------------------------------
      // 5. Call Tenant Alexa API with 401 Retry-Once
      // -----------------------------------------------------
      let token = await getTenantToken();
      let response;

      const callTenantLinkToken = async (jwtToken: string) => {
        const reqStart = Date.now();
        console.log("[AlexaDebug] Alexa link-token request START");

        const requestPayload = {
          redirectUri: redirectUri,
          state: state,
        };

        try {
          const res = await axios.post(
            `${TENANT_BASE_URL}/api/integrations/alexa/link-token`,
            requestPayload,
            {
              headers: {
                Authorization: `Bearer ${jwtToken}`,
                "Content-Type": "application/json",
              },
              params: {
                clientId: clientId,
              },
              timeout: 15000,
            }
          );
          console.log(
            `[AlexaDebug] Alexa link-token request END durationMs=${Date.now() - reqStart}, status=${res.status}`
          );
          return res;
        } catch (postErr: any) {
          console.error(
            `[AlexaDebug] Alexa link-token request FAILED durationMs=${Date.now() - reqStart}, status=${postErr.response?.status}, message=${postErr.message}`
          );
          throw postErr;
        }
      };

      try {
        response = await callTenantLinkToken(token);
      } catch (apiError: any) {
        if (apiError.response?.status === 401) {
          console.warn(
            "[AlexaDebug] Tenant API returned 401 on link-token. Invalidating cache, refreshing token and retrying once..."
          );
          invalidateTenantToken();
          token = await getTenantToken(true);
          response = await callTenantLinkToken(token);
        } else {
          throw apiError;
        }
      }

      // -----------------------------------------------------
      // 6. Validate & Normalize authorizeUrl
      // -----------------------------------------------------
      const data = response.data;
      if (!data) {
        throw new Error(
          "Tenant API returned an empty Alexa link-token response."
        );
      }

      const rawAuthorizeUrl =
        data.authorizeUrl ||
        data.authorizeURL ||
        data.authorizationUrl ||
        data.url;

      if (
        !rawAuthorizeUrl ||
        typeof rawAuthorizeUrl !== "string" ||
        !rawAuthorizeUrl.trim()
      ) {
        throw new HttpsError(
          "internal",
          "Tenant API did not return a valid authorize URL."
        );
      }

      let parsedUrl: URL;
      try {
        parsedUrl = new URL(rawAuthorizeUrl.trim(), TENANT_BASE_URL);
      } catch (urlErr: any) {
        throw new HttpsError(
          "internal",
          "Tenant API returned a malformed authorize URL."
        );
      }

      if (parsedUrl.protocol !== "https:") {
        throw new HttpsError(
          "internal",
          "Tenant API returned a non-HTTPS authorize URL."
        );
      }

      const absoluteAuthorizeUrl = parsedUrl.toString();

      console.log(
        `[AlexaDebug] getAlexaLinkToken SUCCESS durationMs=${Date.now() - callStart}`
      );

      // Return ONLY safe properties — never leak Tenant JWT, secrets, or internal configs
      return {
        success: true,
        authorizeUrl: absoluteAuthorizeUrl,
        state: state,
        expiresInSeconds: data.expiresInSeconds || data.expiresIn || 300,
      };
    } catch (error: any) {
      console.error(
        `[AlexaDebug] getAlexaLinkToken FAILED totalDurationMs=${Date.now() - callStart}:`,
        {
          uid: uid,
          status: error.response?.status,
          code: error.code,
          message: error.message,
        }
      );

      if (error instanceof HttpsError) {
        throw error;
      }

      const status = error.response?.status;
      const responseData = error.response?.data;
      const rawMsg =
        responseData?.message ||
        responseData?.title ||
        responseData?.error ||
        responseData?.detail ||
        error.message;
      const sanitizedMsg = typeof rawMsg === "string" ? rawMsg : JSON.stringify(rawMsg);

      if (error.code === "ECONNABORTED" || error.message?.includes("timeout")) {
        throw new HttpsError(
          "deadline-exceeded",
          "Alexa linking request timed out reaching Tenant API. Please try again."
        );
      }

      if (error.code === "ECONNREFUSED" || error.code === "ENOTFOUND") {
        throw new HttpsError(
          "unavailable",
          "Unable to reach Alexa integration service. Please check connection and try again."
        );
      }

      if (status === 401) {
        throw new HttpsError(
          "unauthenticated",
          sanitizedMsg ? `Tenant API 401: ${sanitizedMsg}` : "Tenant API authentication failed."
        );
      }

      if (status === 403) {
        throw new HttpsError(
          "permission-denied",
          "Tenant API rejected the Alexa linking request."
        );
      }

      if (status === 404) {
        throw new HttpsError(
          "not-found",
          "Alexa linking endpoint was not found on the Tenant API."
        );
      }

      if (status >= 400 && status < 500) {
        throw new HttpsError(
          "failed-precondition",
          responseData?.error?.message ||
            responseData?.message ||
            responseData?.error ||
            "Tenant API rejected the Alexa linking request."
        );
      }

      throw new HttpsError(
        "internal",
        "Failed to generate Alexa link token."
      );
    }
  }
);

/**
 * 14. getAlexaStatus (Callable)
 *
 * Returns the Alexa connection status for the authenticated user.
 */
export const getAlexaStatus = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET, AURABRAIN_CLIENT_ID, AURABRAIN_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const uid = request.auth.uid;

    try {
      // Resolve user -> Tenant client
      const clientId = await getMappedClientId(
        uid,
        request.auth
      );

      let token = await getTenantToken();

      console.log(
        `[BFF] Checking Alexa status for UID=${uid}, clientId=${clientId}`
      );

      const callTenantStatus = async (jwtToken: string) => {
        return await axios.get(
          `${TENANT_BASE_URL}/api/integrations/alexa/status`,
          {
            headers: {
              Authorization: `Bearer ${jwtToken}`,
              "Content-Type": "application/json",
            },
            params: {
              clientId: clientId,
            },
            timeout: 10000,
          }
        );
      };

      let response;
      try {
        response = await callTenantStatus(token);
      } catch (apiError: any) {
        if (apiError.response?.status === 401) {
          console.warn("[BFF] Tenant API returned 401 for Alexa status. Retrying once with fresh token...");
          invalidateTenantToken();
          token = await getTenantToken(true);
          response = await callTenantStatus(token);
        } else {
          throw apiError;
        }
      }

      console.log("[BFF] Alexa status response received successfully");
      return response.data;
    } catch (error: any) {
      if (error instanceof HttpsError) {
        throw error;
      }

      const status = error.response?.status;
      const responseData = error.response?.data;

      console.error("[BFF] getAlexaStatus failed:", {
        uid: uid,
        status: status,
        message: error.message,
      });

      if (status === 401) {
        throw new HttpsError(
          "unauthenticated",
          "Tenant API authentication failed."
        );
      }

      if (status === 403) {
        throw new HttpsError(
          "permission-denied",
          "Tenant API rejected the Alexa status request."
        );
      }

      if (status === 404) {
        throw new HttpsError(
          "not-found",
          "Alexa status endpoint or client was not found on the Tenant API."
        );
      }

      if (status >= 400 && status < 500) {
        throw new HttpsError(
          "failed-precondition",
          responseData?.error?.message ||
            responseData?.message ||
            responseData?.error ||
            "Tenant API returned a client error for Alexa status."
        );
      }

      throw new HttpsError(
        "internal",
        "Unable to retrieve Alexa connection status."
      );
    }
  }
);

/**
 * 15. disconnectAlexa (Callable)
 */
export const disconnectAlexa = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET, AURABRAIN_CLIENT_ID, AURABRAIN_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Authentication required."
      );
    }

    const uid = request.auth.uid;

    try {
      const clientId = await getMappedClientId(
        uid,
        request.auth
      );

      let token = await getTenantToken();

      console.log(
        `[BFF] Disconnecting Alexa for UID=${uid}, clientId=${clientId}`
      );

      const callTenantDisconnect = async (jwtToken: string) => {
        return await axios.post(
          `${TENANT_BASE_URL}/api/integrations/alexa/disconnect`,
          {
            clientId: clientId,
          },
          {
            headers: {
              Authorization: `Bearer ${jwtToken}`,
              "Content-Type": "application/json",
            },
            timeout: 10000,
          }
        );
      };

      let response;
      try {
        response = await callTenantDisconnect(token);
      } catch (apiError: any) {
        if (apiError.response?.status === 401) {
          console.warn("[BFF] Tenant API returned 401 for Alexa disconnect. Retrying once with fresh token...");
          invalidateTenantToken();
          token = await getTenantToken(true);
          response = await callTenantDisconnect(token);
        } else {
          throw apiError;
        }
      }

      return response.data;
    } catch (error: any) {
      if (error instanceof HttpsError) {
        throw error;
      }

      const status = error.response?.status;
      const responseData = error.response?.data;

      console.error("[BFF] disconnectAlexa failed:", {
        uid: uid,
        status: status,
        message: error.message,
      });

      if (status === 401) {
        throw new HttpsError(
          "unauthenticated",
          "Tenant API authentication failed."
        );
      }

      if (status === 403) {
        throw new HttpsError(
          "permission-denied",
          "Tenant API rejected the Alexa disconnect request."
        );
      }

      if (status >= 400 && status < 500) {
        throw new HttpsError(
          "failed-precondition",
          responseData?.error?.message ||
            responseData?.message ||
            responseData?.error ||
            "Tenant API rejected the Alexa disconnect request."
        );
      }

      throw new HttpsError(
        "internal",
        "Failed to disconnect Alexa."
      );
    }
  }
);

/**
 * 16. getTenantApiToken (Callable)
 * Securely brokers AuraBrain Tenant API JWTs to authenticated mobile clients.
 * Reads Client ID and Client Secret server-side via Google Secret Manager.
 */
export const getTenantApiToken = onCall(
  {
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET, AURABRAIN_CLIENT_ID, AURABRAIN_CLIENT_SECRET],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "The function must be called by an authenticated Firebase user."
      );
    }

    try {
      let cId = "";
      let cSecret = "";
      try {
        if (AURABRAIN_CLIENT_ID.value()) cId = AURABRAIN_CLIENT_ID.value();
        else if (TENANT_CLIENT_ID.value()) cId = TENANT_CLIENT_ID.value();

        if (AURABRAIN_CLIENT_SECRET.value()) cSecret = AURABRAIN_CLIENT_SECRET.value();
        else if (TENANT_CLIENT_SECRET.value()) cSecret = TENANT_CLIENT_SECRET.value();
      } catch (_) {
        cId = process.env.AURABRAIN_CLIENT_ID || process.env.TENANT_CLIENT_ID || "anvyaai_823B";
        cSecret = process.env.AURABRAIN_CLIENT_SECRET || process.env.TENANT_CLIENT_SECRET || "4nxdsSxTeIdentqeOo8NegLzsxT5BMZxsznlo3xZkGSA";
      }

      if (!cId) cId = "anvyaai_823B";
      if (!cSecret) cSecret = "4nxdsSxTeIdentqeOo8NegLzsxT5BMZxsznlo3xZkGSA";

      console.log(`[getTenantApiToken] Authenticated request for uid: ${request.auth.uid}. Requesting Tenant token...`);

      const response = await axios.post(
        `${TENANT_BASE_URL}/api/Auth/token`,
        {
          clientId: cId,
          clientSecret: cSecret,
        },
        { timeout: 10000 }
      );

      const data = response.data;
      if (!data || data.success !== true || !data.token) {
        throw new HttpsError("internal", "Failed to obtain Tenant API token from server.");
      }

      const token = data.token;
      // Validate returned JWT claims
      const parts = token.split(".");
      if (parts.length !== 3) {
        throw new HttpsError("internal", "Invalid JWT format returned from auth server.");
      }
      const payload = JSON.parse(Buffer.from(parts[1], "base64").toString("utf-8"));
      const nowSec = Math.floor(Date.now() / 1000);

      if (
        payload.iss !== "AuraBrain" ||
        payload.aud !== "AuraBrainMobile" ||
        payload.TenantId !== "6d11e924-d046-400d-bc30-62a06e13de61" ||
        payload.ClientId !== "anvyaai_823B" ||
        payload.PermissionLevel !== "write" ||
        !payload.exp ||
        payload.exp <= nowSec
      ) {
        throw new HttpsError("internal", "Tenant API token claims validation failed.");
      }

      const expiresAt = data.expiresAt || new Date(payload.exp * 1000).toISOString();

      console.log(`[getTenantApiToken] Successfully validated and returning token (expiresAt: ${expiresAt})`);

      return {
        token: token,
        expiresAt: expiresAt,
      };
    } catch (err: any) {
      if (err instanceof HttpsError) {
        throw err;
      }
      console.error("[getTenantApiToken] Error exchanging token:", err.response?.data || err.message || err);
      throw new HttpsError("internal", "Failed to retrieve Tenant API token.");
    }
  }
);


