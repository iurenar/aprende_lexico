import express from "express";
import multer from "multer";
import fetch from "node-fetch";
import dotenv from "dotenv";
import cors from "cors";
import fs from "fs";

dotenv.config();

const app = express();
const upload = multer({ dest: "uploads/" });

app.use(cors());

app.post("/transcribe", upload.single("file"), async (req, res) => {
  try {
    const filePath = req.file.path;

    const formData = new FormData();
    formData.append("file", fs.createReadStream(filePath));
    formData.append("model", "whisper-large-v3-turbo");
    formData.append("language", "es");

    const response = await fetch(
      "https://api.groq.com/openai/v1/audio/transcriptions",
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
        },
        body: formData,
      }
    );

    const data = await response.json();

    fs.unlinkSync(filePath); // borrar archivo temporal

    res.json({ text: data.text });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Error transcribiendo" });
  }
});

app.listen(3000, () => {
  console.log("🔥 Server corriendo en http://localhost:3000");
});