/// Base URL for the Agora RTC token endpoint.
///
/// This currently points at the free Vercel-hosted replacement for the
/// Firebase `generateAgoraRtcToken` callable function (used because the
/// Firebase project's Blaze billing isn't active yet).
///
/// To move back to Firebase Cloud Functions later, once billing is fixed:
///   1. Redeploy functions/index.js (firebase deploy --only functions).
///   2. In each of the 3 call sites, swap the http.post(...) block back to
///      FirebaseFunctions.instance.httpsCallable('generateAgoraRtcToken')
///      .call({'channelName': ...}).
///   3. This file can then be deleted.
const String kAgoraTokenServerUrl =
    'https://agora-token-server-eoq8.vercel.app/api/generateAgoraRtcToken';
