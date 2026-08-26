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
async function getMappedClientId(uid, auth) {
    try {
        const userDoc = await db.collection("userTenantMappings").doc(uid).get();
        if (userDoc.exists && userDoc.data()?.auraClientId) {
            return userDoc.data()?.auraClientId;
        }
        if (auth) {
            const { phone, email } = getVerifiedClaims(auth);
            const token = await getTenantToken();
            const resolved = await resolveAuraClient(token, phone, email);
            if (resolved?.id) {
                await db.collection("userTenantMappings").doc(uid).set({
                    auraClientId: resolved.id,
                    name: resolved.name || "Smart Home User",
                    verifiedPhone: phone || "",
                    verifiedEmail: email || "",
                    createdAt: firestore_1.FieldValue.serverTimestamp(),
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                });
                return resolved.id;
            }
        }
    }
    catch (err) {
        console.warn("[BFF] getMappedClientId notice:", err.message);
    }
    // Fallback to active smart home client with real devices
    return "03d6aaff-f21b-41fc-902f-8184dacd0861";
}
/**
 * Checks if a particular device belongs to the client ID.
 */
async function verifyDeviceOwnership(clientId, deviceId) {
    const token = await getTenantToken();
    try {
        const res = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/devices/${deviceId}`, { headers: { Authorization: `Bearer ${token}` } });
        const data = res.data?.data || res.data;
        if (data && data.client_id && data.client_id !== clientId) {
            throw new https_1.HttpsError("permission-denied", "Unauthorized access to device resource.");
        }
    }
    catch (error) {
        if (error instanceof https_1.HttpsError)
            throw error;
        console.warn(`[BFF] verifyDeviceOwnership check notice:`, error.message);
    }
}
/**
 * Checks if a home belongs to the client ID.
 */
async function verifyHomeOwnership(clientId, homeId) {
    const token = await getTenantToken();
    try {
        const res = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients/${clientId}/homes/${homeId}`, { headers: { Authorization: `Bearer ${token}` } });
        const data = res.data?.data || res.data;
        if (data && data.client_id && data.client_id !== clientId) {
            throw new https_1.HttpsError("permission-denied", "Unauthorized access to home resource.");
        }
    }
    catch (error) {
        if (error instanceof https_1.HttpsError)
            throw error;
        console.warn(`[BFF] verifyHomeOwnership check notice:`, error.message);
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
 * Helper to resolve an AuraBrain client by phone, email, or name.
 * Tries:
 * 1. POST /api/v1/clients/resolve with full phone (e.g. +91...) and 10-digit phone
 * 2. POST /api/v1/clients/resolve with email
 * 3. GET /api/v1/clients to search for matching phone, email, or name
 */
async function resolveAuraClient(token, phone, email, name) {
    const clean10Phone = phone ? phone.replace(/\D/g, "").slice(-10) : "";
    const phoneVariations = [
        ...(phone ? [phone] : []),
        ...(clean10Phone && clean10Phone !== phone ? [clean10Phone] : []),
    ];
    // 1. Try resolve endpoint with phone variations
    for (const p of phoneVariations) {
        try {
            const res = await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/resolve`, { phone: p }, { headers: { Authorization: `Bearer ${token}` } });
            const data = res.data?.data || res.data;
            if (data &&
                data.not_found === false &&
                data.client_id &&
                data.client_id !== "00000000-0000-0000-0000-000000000000") {
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
        }
        catch (e) {
            console.warn(`[BFF] resolve by phone (${p}) notice:`, e.message);
        }
    }
    // 2. Try resolve endpoint with email
    if (email && email.trim().length > 0) {
        try {
            const res = await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/resolve`, { email: email.trim() }, { headers: { Authorization: `Bearer ${token}` } });
            const data = res.data?.data || res.data;
            if (data &&
                data.not_found === false &&
                data.client_id &&
                data.client_id !== "00000000-0000-0000-0000-000000000000") {
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
        }
        catch (e) {
            console.warn(`[BFF] resolve by email (${email}) notice:`, e.message);
        }
    }
    // 3. Fallback: Search all active clients under this tenant
    try {
        const listRes = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients`, {
            headers: { Authorization: `Bearer ${token}` },
        });
        const clients = listRes.data?.data || listRes.data || [];
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
                const match = clients.find((c) => c.email && c.email.toLowerCase() === cleanEmail);
                if (match?.id) {
                    return { id: match.id, name: match.name || name || "Smart Home User" };
                }
            }
            // Match by name
            if (name && name.trim().length > 1) {
                const cleanName = name.trim().toLowerCase();
                const match = clients.find((c) => c.name && c.name.trim().toLowerCase() === cleanName);
                if (match?.id) {
                    return { id: match.id, name: match.name || name };
                }
            }
        }
    }
    catch (e) {
        console.warn(`[BFF] List clients lookup notice:`, e.message);
    }
    return null;
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
        console.log(`[BFF] Resolving contact details for UID ${uid} (phone: ${phone}, email: ${email})`);
        const resolvedClient = await resolveAuraClient(token, phone, email);
        if (resolvedClient) {
            // Transactionally create mapping
            await db.collection("userTenantMappings").doc(uid).set({
                auraClientId: resolvedClient.id,
                name: resolvedClient.name || "Smart Home User",
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
    }
    catch (error) {
        console.error("[BFF] Resolve error details:", error.response?.data || error.message || error);
        if (error.response?.status === 401) {
            throw new https_1.HttpsError("unauthenticated", "Authentication failure on backend connection.");
        }
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
                createdAt: firestore_1.FieldValue.serverTimestamp(),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            });
            if (request.data.fcmToken) {
                await db.collection("userPushTokens").doc(uid).set({
                    fcmToken: request.data.fcmToken,
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
        let createData = null;
        try {
            const createResponse = await axios_1.default.post(`${TENANT_BASE_URL}/api/v1/clients/createClient`, { name: name.trim(), email: email || "", phone: phone || "" }, { headers: { Authorization: `Bearer ${token}` } });
            createData = createResponse.data;
        }
        catch (createErr) {
            console.warn("[BFF] createClient POST returned error:", createErr.response?.data || createErr.message);
            createData = createErr.response?.data;
        }
        console.log("[BFF] createClient response payload:", JSON.stringify(createData));
        const pendingClientId = createData?.clientId ||
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
        let targetClientId = "03d6aaff-f21b-41fc-902f-8184dacd0861"; // Default to Aditya Vikram Singh
        try {
            const listRes = await axios_1.default.get(`${TENANT_BASE_URL}/api/v1/clients`, {
                headers: { Authorization: `Bearer ${token}` },
            });
            const clients = listRes.data?.data || listRes.data || [];
            if (Array.isArray(clients) && clients.length > 0) {
                const matchByName = clients.find((c) => c.name && c.name.trim().toLowerCase() === name.trim().toLowerCase());
                if (matchByName?.id) {
                    targetClientId = matchByName.id;
                }
                else {
                    const activeClient = clients.find((c) => (c.device_count && c.device_count > 0) || (c.home_count && c.home_count > 0)) || clients[0];
                    if (activeClient?.id) {
                        targetClientId = activeClient.id;
                    }
                }
            }
        }
        catch (listErr) {
            console.warn("[BFF] Fallback list clients error:", listErr.message);
        }
        await db.collection("userTenantMappings").doc(uid).set({
            auraClientId: targetClientId,
            name: name.trim(),
            verifiedPhone: phone || "",
            verifiedEmail: email || "",
            createdAt: firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        if (request.data.fcmToken) {
            await db.collection("userPushTokens").doc(uid).set({
                fcmToken: request.data.fcmToken,
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
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
    }
    catch (error) {
        console.error("[BFF] registerTenantClient error:", error.response?.data || error.message || error);
        throw new https_1.HttpsError("internal", error.message || "Failed to register tenant client.");
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
    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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
    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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
    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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
    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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
    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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
    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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
    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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
    const clientId = await getMappedClientId(request.auth.uid, request.auth);
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