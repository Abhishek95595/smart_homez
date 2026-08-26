"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.syncDevices = exports.getDashboard = exports.sendDeviceCommand = exports.getDevice = exports.getDevices = exports.getRooms = exports.getFloors = exports.getHomes = exports.resendTenantRegistrationOtp = exports.verifyTenantClient = exports.registerTenantClient = exports.getTenantSession = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const axios_1 = __importDefault(require("axios"));
const https = __importStar(require("https"));
// Initialize Keep-Alive agent for fast connection reuse to AuraBrain
const httpsAgent = new https.Agent({
    keepAlive: true,
    maxSockets: 50,
    keepAliveMsecs: 1000,
});
axios_1.default.defaults.httpsAgent = httpsAgent;
axios_1.default.defaults.timeout = 8000; // 8s global timeout for all AuraBrain calls
// Initialize Firebase Admin SDK
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
// Load Environment Configurations
const TENANT_BASE_URL = process.env.TENANT_BASE_URL || "https://tenant-api-qa.omnihome.in";
// Secure Secrets from Google Cloud Secret Manager
const TENANT_CLIENT_ID = (0, params_1.defineSecret)("TENANT_CLIENT_ID");
const TENANT_CLIENT_SECRET = (0, params_1.defineSecret)("TENANT_CLIENT_SECRET");
const tokenCache = {
    token: null,
    expiresAt: 0,
};
let inFlightTokenPromise = null;
/**
 * Concurrency-safe Tenant token manager.
 * Uses a single in-flight Promise during token refresh.
 */
async function getTenantToken() {
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
            const response = await axios_1.default.post(`${TENANT_BASE_URL}/api/Auth/token`, {
                clientId: TENANT_CLIENT_ID.value(),
                clientSecret: TENANT_CLIENT_SECRET.value(),
            }, { timeout: 10000 });
            const data = response.data;
            if (!data || data.success !== true || !data.token) {
                throw new Error(data.error?.message || data.error || "Failed to exchange Tenant API token.");
            }
            tokenCache.token = data.token;
            const expiryDuration = data.expiresIn ? data.expiresIn * 1000 : 3600000;
            tokenCache.expiresAt = Date.now() + expiryDuration;
            console.log("[BFF] Successfully acquired and cached Tenant JWT token.");
            return tokenCache.token;
        }
        catch (error) {
            console.error("[BFF] Error acquiring Tenant token:", error.message || error);
            throw new https_1.HttpsError("unauthenticated", "Unable to authenticate with AuraBrain Tenant API.");
        }
        finally {
            inFlightTokenPromise = null;
        }
    })();
    return inFlightTokenPromise;
}
/**
 * Returns the verified phone and email from Firebase Claims.
 */
function getVerifiedClaims(auth) {
    const phone = auth.token.phone_number;
    const email = auth.token.email_verified === true ? auth.token.email : undefined;
    return { phone, email };
}
/**
 * Resolves the client ID mapped to a Firebase user UID.
 */
async function getMappedClientId(uid) {
    const userDoc = await db.collection("userTenantMappings").doc(uid).get();
    if (!userDoc.exists || !userDoc.data()?.auraClientId) {
        throw new https_1.HttpsError("failed-precondition", "AuraBrain Client ID mapping not found. Complete your sign-in first.");
    }
    return userDoc.data()?.auraClientId;
}
/**
 * Checks if a particular device belongs to the client ID.
 */
async function verifyDeviceOwnership(clientId, deviceId) {
    const token = await getTenantToken();
    try {
        const res = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/${deviceId}`, { headers: { Authorization: `Bearer ${token}` } });
        if (!res.data || res.data.client_id !== clientId) {
            throw new https_1.HttpsError("permission-denied", "Unauthorized access to device resource.");
        }
    }
    catch (error) {
        throw new https_1.HttpsError("permission-denied", "Device resource ownership check failed.");
    }
}
/**
 * Checks if a home belongs to the client ID.
 */
async function verifyHomeOwnership(clientId, homeId) {
    const token = await getTenantToken();
    try {
        const res = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes/${homeId}`, { headers: { Authorization: `Bearer ${token}` } });
        // AuraBrain payload validation
        if (!res.data || res.data.client_id !== clientId) {
            throw new https_1.HttpsError("permission-denied", "Unauthorized access to home resource.");
        }
    }
    catch (error) {
        throw new https_1.HttpsError("permission-denied", "Home resource ownership check failed.");
    }
}
/**
 * Masks phone number for safe logs/responses.
 */
function maskPhone(phone) {
    if (phone.length < 5)
        return "***";
    return phone.substring(0, 3) + "*".repeat(phone.length - 5) + phone.substring(phone.length - 2);
}
/**
 * Masks email address for safe logs/responses.
 */
function maskEmail(email) {
    const parts = email.split("@");
    if (parts.length !== 2)
        return "***";
    const name = parts[0];
    const domain = parts[1];
    if (name.length < 3)
        return `*@${domain}`;
    return `${name.substring(0, 2)}***${name.substring(name.length - 1)}@${domain}`;
}
/**
 * 1. getTenantSession (Callable)
 * Resolves mapped user or queries AuraBrain resolve.
 */
exports.getTenantSession = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false, // production will enforceAppCheck
    minInstances: 1, // Keep warm to prevent cold starts
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
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
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
        throw new https_1.HttpsError("failed-precondition", "No verified phone or email claims found.");
    }
    try {
        const token = await getTenantToken();
        console.log(`[BFF] Resolving contact details for UID ${uid}`);
        const resolveResponse = await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/resolve`, { phone, email }, { headers: { Authorization: `Bearer ${token}` } });
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
                createdAt: firestore_1.FieldValue.serverTimestamp(),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            });
            // Register FCM if exists
            const fcmToken = request.data.fcmToken;
            if (fcmToken) {
                await db.collection("userPushTokens").doc(uid).set({
                    fcmToken: fcmToken,
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
    }
    catch (error) {
        console.error("[BFF] Resolve error details:", error.response?.data || error.message || error);
        if (error.response?.status === 401) {
            throw new https_1.HttpsError("unauthenticated", "Authentication failure on backend connection.");
        }
        // Any generic resolve failure results in temporarilyUnavailable status
        return {
            success: false,
            status: "temporarilyUnavailable",
            message: "AuraBrain resolve service is currently offline. Please try again.",
        };
    }
});
/**
 * 2. registerTenantClient (Callable)
 * Triggers client registration and SMS/Email OTP code.
 */
exports.registerTenantClient = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const name = request.data.name;
    const { phone, email } = getVerifiedClaims(request.auth);
    if (!name || name.trim().length === 0 || name.trim().length > 100) {
        throw new https_1.HttpsError("invalid-argument", "Name must be provided (max 100 characters).");
    }
    if (!phone && !email) {
        throw new https_1.HttpsError("failed-precondition", "No verified phone or email claims found.");
    }
    // Verify mapping doesn't exist
    const mappingDoc = await db.collection("userTenantMappings").doc(uid).get();
    if (mappingDoc.exists) {
        throw new https_1.HttpsError("failed-precondition", "User is already mapped to a tenant client.");
    }
    // Verify rate limit / cooldown on pending registration
    const pendingDoc = await db.collection("pendingTenantRegistrations").doc(uid).get();
    if (pendingDoc.exists) {
        const pData = pendingDoc.data();
        const now = Date.now();
        if (pData?.resendAvailableAt && now < pData.resendAvailableAt) {
            throw new https_1.HttpsError("resource-exhausted", `Please wait before requesting another code.`);
        }
    }
    try {
        const token = await getTenantToken();
        console.log(`[BFF] Calling createClient for UID ${uid}`);
        const createResponse = await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/createClient`, { name: name.trim(), email: email || "", phone: phone || "" }, { headers: { Authorization: `Bearer ${token}` } });
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
    }
    catch (error) {
        console.error("[BFF] createClient error:", error.response?.data || error.message || error);
        // Handle 409 conflict
        if (error.response?.status === 409) {
            console.log(`[BFF] Conflict (409) detected. Retrying client resolution...`);
            try {
                const token = await getTenantToken();
                const resolveResponse = await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/resolve`, { phone, email }, { headers: { Authorization: `Bearer ${token}` } });
                if (resolveResponse.data && resolveResponse.data.id) {
                    // Confirm mapping owner is safe and matches
                    const mappedId = resolveResponse.data.id;
                    await db.collection("userTenantMappings").doc(uid).set({
                        auraClientId: mappedId,
                        name: name,
                        verifiedPhone: phone || "",
                        verifiedEmail: email || "",
                        createdAt: firestore_1.FieldValue.serverTimestamp(),
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
            }
            catch (resolveErr) {
                console.error("[BFF] Retry resolve failed:", resolveErr);
            }
            throw new https_1.HttpsError("already-exists", "This contact detail belongs to another client. Verification failed.");
        }
        throw new https_1.HttpsError("internal", error.message || "Failed to create registration client.");
    }
});
/**
 * 3. verifyTenantClient (Callable)
 * Verifies client creation OTP code and creates permanent mapping.
 */
exports.verifyTenantClient = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const code = request.data.code;
    if (!code || code.trim().length === 0) {
        throw new https_1.HttpsError("invalid-argument", "Verification code is required.");
    }
    const pendingRef = db.collection("pendingTenantRegistrations").doc(uid);
    const pendingDoc = await pendingRef.get();
    if (!pendingDoc.exists) {
        throw new https_1.HttpsError("failed-precondition", "No active pending registration found.");
    }
    const pData = pendingDoc.data();
    if (!pData) {
        throw new https_1.HttpsError("failed-precondition", "Registration data is missing.");
    }
    if (Date.now() > pData.expiresAt) {
        await pendingRef.delete();
        throw new https_1.HttpsError("deadline-exceeded", "Registration OTP expired. Please register again.");
    }
    if (pData.attempts >= 5) {
        await pendingRef.delete();
        throw new https_1.HttpsError("resource-exhausted", "Too many failed attempts. Please restart registration.");
    }
    try {
        const token = await getTenantToken();
        console.log(`[BFF] Verifying OTP code for pending client ID ${pData.pendingClientId}`);
        const verifyResponse = await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/createClient/verify`, { client_id: pData.pendingClientId, code: code.trim() }, { headers: { Authorization: `Bearer ${token}` } });
        const verifyData = verifyResponse.data;
        if (verifyData && verifyResponse.status === 200) {
            // Verification succeeded: create permanent mapping transactionally
            await db.runTransaction(async (transaction) => {
                const mappingRef = db.collection("userTenantMappings").doc(uid);
                const currentMapping = await transaction.get(mappingRef);
                if (currentMapping.exists) {
                    throw new https_1.HttpsError("failed-precondition", "A mapping for this user already exists.");
                }
                transaction.set(mappingRef, {
                    auraClientId: pData.pendingClientId,
                    name: pData.name || "Smart Home User",
                    verifiedPhone: pData.verifiedPhone || "",
                    verifiedEmail: pData.verifiedEmail || "",
                    createdAt: firestore_1.FieldValue.serverTimestamp(),
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                });
            });
            // Register FCM if exists
            const fcmToken = pData.fcmToken;
            if (fcmToken) {
                await db.collection("userPushTokens").doc(uid).set({
                    fcmToken: fcmToken,
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
    }
    catch (error) {
        console.error("[BFF] OTP Verify error:", error.response?.data || error.message || error);
        // Increment attempt count ONLY when AuraBrain explicitly confirms OTP is invalid (400 Bad Request)
        if (error.response?.status === 400) {
            const nextAttempts = (pData?.attempts || 0) + 1;
            if (nextAttempts >= 5) {
                await pendingRef.delete();
                throw new https_1.HttpsError("resource-exhausted", "Too many invalid OTP attempts. Registration cancelled.");
            }
            else {
                await pendingRef.update({ attempts: nextAttempts });
            }
            throw new https_1.HttpsError("invalid-argument", "Invalid OTP verification code.");
        }
        throw new https_1.HttpsError("internal", error.message || "Failed to verify registration code.");
    }
});
/**
 * 4. resendTenantRegistrationOtp (Callable)
 * Resends/restarts OTP verification for registration.
 */
exports.resendTenantRegistrationOtp = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const uid = request.auth.uid;
    const pendingRef = db.collection("pendingTenantRegistrations").doc(uid);
    const pendingDoc = await pendingRef.get();
    if (!pendingDoc.exists) {
        throw new https_1.HttpsError("failed-precondition", "No pending registration found.");
    }
    const pData = pendingDoc.data();
    if (!pData) {
        throw new https_1.HttpsError("failed-precondition", "Registration data is missing.");
    }
    const now = Date.now();
    if (now < pData.resendAvailableAt) {
        throw new https_1.HttpsError("resource-exhausted", "Please wait before resending OTP.");
    }
    try {
        const token = await getTenantToken();
        console.log(`[BFF] Resending OTP code for client name: ${pData.name}`);
        await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/createClient`, { name: pData.name, email: pData.verifiedEmail, phone: pData.verifiedPhone }, { headers: { Authorization: `Bearer ${token}` } });
        // Update cooldown limits
        await pendingRef.update({
            resendAvailableAt: Date.now() + 60 * 1000,
            createdAt: Date.now(),
        });
        return {
            success: true,
            resendAvailableIn: 60,
        };
    }
    catch (error) {
        console.error("[BFF] Resend OTP failed:", error.message || error);
        throw new https_1.HttpsError("internal", "Failed to resend registration verification code.");
    }
});
/**
 * 5. getHomes (Callable)
 */
exports.getHomes = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const clientId = await getMappedClientId(request.auth.uid);
    const token = await getTenantToken();
    try {
        const response = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes`, { headers: { Authorization: `Bearer ${token}` } });
        return response.data;
    }
    catch (error) {
        throw new https_1.HttpsError("internal", error.message || "Failed to fetch client homes.");
    }
});
/**
 * 6. getFloors (Callable)
 */
exports.getFloors = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const homeId = request.data.homeId;
    if (!homeId) {
        throw new https_1.HttpsError("invalid-argument", "homeId is required.");
    }
    const clientId = await getMappedClientId(request.auth.uid);
    await verifyHomeOwnership(clientId, homeId);
    const token = await getTenantToken();
    try {
        const response = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes/${homeId}/floors`, { headers: { Authorization: `Bearer ${token}` } });
        return response.data;
    }
    catch (error) {
        throw new https_1.HttpsError("internal", error.message || "Failed to fetch floors.");
    }
});
/**
 * 7. getRooms (Callable)
 */
exports.getRooms = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const { homeId, floorId } = request.data;
    if (!homeId || !floorId) {
        throw new https_1.HttpsError("invalid-argument", "homeId and floorId are required.");
    }
    const clientId = await getMappedClientId(request.auth.uid);
    await verifyHomeOwnership(clientId, homeId);
    const token = await getTenantToken();
    try {
        const response = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes/${homeId}/floors/${floorId}/rooms`, { headers: { Authorization: `Bearer ${token}` } });
        return response.data;
    }
    catch (error) {
        throw new https_1.HttpsError("internal", error.message || "Failed to fetch rooms.");
    }
});
/**
 * 8. getDevices (Callable)
 */
exports.getDevices = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const clientId = await getMappedClientId(request.auth.uid);
    const token = await getTenantToken();
    try {
        const response = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices`, { headers: { Authorization: `Bearer ${token}` } });
        return response.data;
    }
    catch (error) {
        throw new https_1.HttpsError("internal", error.message || "Failed to fetch devices.");
    }
});
/**
 * 9. getDevice (Callable)
 */
exports.getDevice = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const deviceId = request.data.deviceId;
    if (!deviceId) {
        throw new https_1.HttpsError("invalid-argument", "deviceId is required.");
    }
    const clientId = await getMappedClientId(request.auth.uid);
    await verifyDeviceOwnership(clientId, deviceId);
    const token = await getTenantToken();
    try {
        const response = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/${deviceId}`, { headers: { Authorization: `Bearer ${token}` } });
        return response.data;
    }
    catch (error) {
        throw new https_1.HttpsError("internal", error.message || "Failed to fetch device details.");
    }
});
/**
 * 10. sendDeviceCommand (Callable)
 * Sends command with strict validations: Command must be on strict allowlist
 * on, off, toggle, brightness, speed, color, set
 */
exports.sendDeviceCommand = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const { deviceId, command, value, deviceName } = request.data;
    if (!deviceId || !command) {
        throw new https_1.HttpsError("invalid-argument", "deviceId and command are required.");
    }
    // Command Validation Allowlist (No temperature)
    const validCommands = ["on", "off", "toggle", "brightness", "speed", "color", "set"];
    if (!validCommands.includes(command)) {
        throw new https_1.HttpsError("invalid-argument", `Command ${command} is not supported.`);
    }
    // Value Validations
    if (["on", "off", "toggle"].includes(command)) {
        if (value !== undefined && value !== null) {
            throw new https_1.HttpsError("invalid-argument", `Command ${command} does not accept a value.`);
        }
    }
    else if (command === "brightness") {
        const numVal = Number(value);
        if (isNaN(numVal) || numVal < 0 || numVal > 100) {
            throw new https_1.HttpsError("invalid-argument", "Brightness value must be a number between 0 and 100.");
        }
    }
    else if (command === "speed") {
        const numVal = Number(value);
        if (isNaN(numVal) || numVal < 1 || numVal > 3) {
            throw new https_1.HttpsError("invalid-argument", "Fan speed value must be a number between 1 and 3.");
        }
    }
    else if (command === "color") {
        const hexPattern = /^#[0-9A-F]{6}$/i;
        if (typeof value !== "string" || !hexPattern.test(value)) {
            throw new https_1.HttpsError("invalid-argument", "Color value must be a valid hex color string (e.g. #FF5733).");
        }
    }
    else if (command === "set") {
        if (typeof value !== "string") {
            throw new https_1.HttpsError("invalid-argument", "Set command value must be a string.");
        }
    }
    const clientId = await getMappedClientId(request.auth.uid);
    await verifyDeviceOwnership(clientId, deviceId);
    const token = await getTenantToken();
    try {
        console.log(`[BFF] Sending command ${command} with value ${value} to device ${deviceId}`);
        const response = await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/${deviceId}/command`, { command, value }, { headers: { Authorization: `Bearer ${token}` } });
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
                (0, messaging_1.getMessaging)().send(message)
                    .then((msgId) => console.log(`[BFF] Notification sent successfully: ${msgId}`))
                    .catch((fcmErr) => console.error("[BFF] FCM Notification failed:", fcmErr));
            }
        }
        return response.data;
    }
    catch (error) {
        throw new https_1.HttpsError("internal", error.message || "Failed to execute command.");
    }
});
/**
 * 11. getDashboard (Callable)
 * period must be hourly, daily, weekly, monthly.
 */
exports.getDashboard = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
    minInstances: 1, // Keep warm to prevent cold starts
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const { homeId, period } = request.data;
    if (!homeId || !period) {
        throw new https_1.HttpsError("invalid-argument", "homeId and period are required.");
    }
    const validPeriods = ["hourly", "daily", "weekly", "monthly"];
    if (!validPeriods.includes(period)) {
        throw new https_1.HttpsError("invalid-argument", `Period ${period} is invalid. Choose from: hourly, daily, weekly, monthly.`);
    }
    const clientId = await getMappedClientId(request.auth.uid);
    await verifyHomeOwnership(clientId, homeId);
    const token = await getTenantToken();
    try {
        const response = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes/${homeId}/dashboard`, {
            headers: { Authorization: `Bearer ${token}` },
            params: { period },
        });
        return response.data;
    }
    catch (error) {
        throw new https_1.HttpsError("internal", error.message || "Failed to fetch dashboard details.");
    }
});
/**
 * 12. syncDevices (Callable)
 */
exports.syncDevices = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [TENANT_CLIENT_ID, TENANT_CLIENT_SECRET],
    enforceAppCheck: false,
}, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required.");
    }
    const clientId = await getMappedClientId(request.auth.uid);
    const token = await getTenantToken();
    try {
        const response = await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/sync`, {}, { headers: { Authorization: `Bearer ${token}` } });
        return response.data;
    }
    catch (error) {
        throw new https_1.HttpsError("internal", error.message || "Failed to sync devices.");
    }
});
//# sourceMappingURL=index.js.map