const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret, defineString} = require("firebase-functions/params");
const {setGlobalOptions} = require("firebase-functions/v2");

setGlobalOptions({region: "us-central1", maxInstances: 20});

const geminiApiKey = defineSecret("GEMINI_API_KEY");
const geminiModel = defineString("GEMINI_MODEL", {default: "gemini-2.5-flash"});

const SYSTEM_INSTRUCTION =
  "You are an AI performing as the precise digital twin of the user. " +
  "Adhere strictly to the conversation flow and context.";

/**
 * Authenticated behavioral chat (Gemini). Client must be signed in with Firebase Auth.
 * @param {{ prompt?: string }} data
 * @returns {{ text: string }}
 */
exports.behavioralChat = onCall(
    {
      secrets: [geminiApiKey],
      enforceAppCheck: false,
      cors: true,
    },
    async (request) => {
      if (!request.auth?.uid) {
        throw new HttpsError("unauthenticated", "Sign in required for live chat.");
      }

      const prompt = request.data?.prompt;
      if (typeof prompt !== "string" || prompt.trim().length === 0) {
        throw new HttpsError("invalid-argument", "Missing prompt.");
      }
      if (prompt.length > 48000) {
        throw new HttpsError("invalid-argument", "Prompt too long.");
      }

      const modelId = geminiModel.value();
      const key = geminiApiKey.value();
      const url =
        `https://generativelanguage.googleapis.com/v1beta/models/${modelId}:generateContent?key=${encodeURIComponent(key)}`;

      const res = await fetch(url, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({
          systemInstruction: {parts: [{text: SYSTEM_INSTRUCTION}]},
          contents: [{role: "user", parts: [{text: prompt}]}],
        }),
      });

      const rawText = await res.text();
      if (!res.ok) {
        console.error("Gemini HTTP", res.status, rawText.slice(0, 500));
        throw new HttpsError("internal", "Assistant request failed.");
      }

      let data;
      try {
        data = JSON.parse(rawText);
      } catch (e) {
        console.error("Gemini JSON parse", e);
        throw new HttpsError("internal", "Assistant response invalid.");
      }

      const text =
        data?.candidates?.[0]?.content?.parts?.map((p) => p.text || "").join("") || "";

      if (!text.trim()) {
        console.error("Gemini empty candidates", JSON.stringify(data).slice(0, 400));
        throw new HttpsError("internal", "Assistant returned no text.");
      }

      return {text};
    },
);
