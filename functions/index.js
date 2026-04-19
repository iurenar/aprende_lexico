import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";

const GROQ_API_KEY = defineSecret("GROQ_API_KEY");


// 🎤 ================== TRANSCRIBE ==================
export const transcribe = onRequest(
  { secrets: [GROQ_API_KEY] },
  async (req, res) => {
    try {
      const apiKey = GROQ_API_KEY.value();
      const audioBuffer = req.rawBody;

      if (!audioBuffer) {
        return res.status(400).send("No audio recibido");
      }

      const boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW";

      const body = Buffer.concat([
        Buffer.from(`--${boundary}\r\n`),
        Buffer.from(
          `Content-Disposition: form-data; name="file"; filename="audio.m4a"\r\n`
        ),
        Buffer.from(`Content-Type: audio/m4a\r\n\r\n`),
        audioBuffer,
        Buffer.from(`\r\n--${boundary}\r\n`),
        Buffer.from(`Content-Disposition: form-data; name="model"\r\n\r\n`),
        Buffer.from(`whisper-large-v3-turbo\r\n`),
        Buffer.from(`--${boundary}\r\n`),
        Buffer.from(`Content-Disposition: form-data; name="language"\r\n\r\n`),
        Buffer.from(`es\r\n`),
        Buffer.from(`--${boundary}--\r\n`),
      ]);

      const response = await fetch(
        "https://api.groq.com/openai/v1/audio/transcriptions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": `multipart/form-data; boundary=${boundary}`,
          },
          body: body,
        }
      );

      const data = await response.json();

      // ✅ devolver directo (Flutter ya espera "text")
      res.json(data);

    } catch (e) {
      console.error("🔥 ERROR TRANSCRIBE:", e);
      res.status(500).send("Error en transcripción");
    }
  }
);


// 🤖 ================== CHAT ==================
export const chat = onRequest(
  { secrets: [GROQ_API_KEY] },
  async (req, res) => {
    try {
      const apiKey = GROQ_API_KEY.value();
      const { userText, systemPrompt } = req.body;

      if (!userText) {
        return res.status(400).send("Falta userText");
      }

      const response = await fetch(
        "https://api.groq.com/openai/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: "llama-3.1-8b-instant",
            messages: [
              { role: "system", content: systemPrompt || "" },
              { role: "user", content: userText },
            ],
            temperature: 0.7,
            max_tokens: 300,
          }),
        }
      );

      const data = await response.json();

      // 🔥 EXTRAER TEXTO CORRECTAMENTE
      const text = data?.choices?.[0]?.message?.content;

      if (!text) {
        console.error("Respuesta inválida IA:", data);
        return res.status(500).send("Respuesta inválida de IA");
      }

      // ✅ FORMATO QUE FLUTTER ESPERA
      res.json({
        response: text,
      });

    } catch (e) {
      console.error("🔥 ERROR CHAT:", e);
      res.status(500).send("Error en chat");
    }
  }
);