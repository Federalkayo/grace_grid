const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { RtcTokenBuilder, RtcRole } = require("agora-token");

exports.generateAgoraRtcToken = onCall(
  { secrets: ["AGORA_APP_ID", "AGORA_APP_CERTIFICATE"], cors: true },
  async (request) => {
    if (!request.auth || !request.auth.uid) {
      throw new HttpsError("unauthenticated", "Must be signed in to join a call.");
    }
    const { channelName } = request.data;
    if (!channelName || typeof channelName !== "string") {
      throw new HttpsError("invalid-argument", "channelName is required.");
    }

    const appId = process.env.AGORA_APP_ID;
    const appCertificate = process.env.AGORA_APP_CERTIFICATE;
    if (!appId || !appCertificate) {
      throw new HttpsError("failed-precondition", "Agora RTC secrets are unconfigured.");
    }

    const uid = 0; // 0 lets Agora assign an internal uid; the channel name is what matters for routing
    const expireSeconds = 3600; // 1 hour
    const privilegeExpireTs = Math.floor(Date.now() / 1000) + expireSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      privilegeExpireTs,
      privilegeExpireTs
    );

    return { token, appId, channelName, uid };
  }
);
