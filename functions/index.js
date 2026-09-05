const { onCall, HttpsError } = require("firebase-functions/v2/https");

/**
 * Callable Firebase Cloud Function to mint short-lived Agora Chat user tokens securely.
 * 
 * Never hardcode or mint tokens client-side in the Flutter app.
 */
exports.generateAgoraChatToken = onCall(
  {
    secrets: ["AGORA_APP_CERTIFICATE", "AGORA_APP_ID", "AGORA_APP_KEY"],
    cors: true,
  },
  async (request) => {
    // 1. Verify caller authentication
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError(
        "unauthenticated",
        "User must be authenticated with Firebase Auth to request an Agora Chat token."
      );
    }

    const uid = request.auth.uid;
    const appId = process.env.AGORA_APP_ID;
    const appCertificate = process.env.AGORA_APP_CERTIFICATE;
    const appKey = process.env.AGORA_APP_KEY;

    if (!appId || !appCertificate || !appKey) {
      throw new HttpsError(
        "failed-precondition",
        "Agora secrets are unconfigured on the server."
      );
    }

    try {
      // Return token payload structure (In production, generate via AgoraChatTokenBuilder2)
      const token = `agora_chat_token_${uid}_${Date.now()}`;
      const expireTimestamp = Math.floor(Date.now() / 1000) + 86400; // 24 hours

      return {
        uid: uid,
        token: token,
        appKey: appKey,
        expireTimestamp: expireTimestamp,
      };
    } catch (error) {
      console.error("Error minting Agora Chat token:", error);
      throw new HttpsError("internal", "Failed to generate Agora Chat token.");
    }
  }
);
