// lib/services/whisper_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WhisperService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await dotenv.load();
    _isInitialized = true;

    debugPrint("✅ WhisperService inicializado");
  }

  /// 🔥 MÉTODO CORRECTO (usar SIEMPRE este)
  static Future<String?> transcribeAudio(String path) async {
    if (!_isInitialized) {
      throw Exception("Whisper no inicializado");
    }

    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception("API KEY no encontrada");
      }

      final file = File(path);

      // 🔴 VALIDACIONES CRÍTICAS
      if (!await file.exists()) {
        throw Exception("Archivo no existe: $path");
      }

      final fileSize = await file.length();
      debugPrint("📁 Archivo para transcribir: $fileSize bytes");

      if (fileSize < 5000) {
        throw Exception("Audio demasiado pequeño ($fileSize bytes)");
      }

      final uri = Uri.parse(
        "https://api.groq.com/openai/v1/audio/transcriptions",
      );

      final request = http.MultipartRequest("POST", uri);

      request.headers["Authorization"] = "Bearer $apiKey";

      request.fields["model"] = "whisper-large-v3-turbo";
      request.fields["language"] = "es";

      // 🔥 AQUÍ ESTÁ LA CLAVE
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          path,
          filename: "audio.m4a",
        ),
      );

      debugPrint("🚀 Enviando audio a Whisper...");

      final response = await request.send();

      final body = await response.stream.bytesToString();

      debugPrint("📡 STATUS: ${response.statusCode}");
      debugPrint("📡 BODY: $body");

      if (response.statusCode == 200) {
        final data = jsonDecode(body);
        return data["text"];
      } else {
        throw Exception("Whisper error: $body");
      }

    } catch (e) {
      debugPrint("🔥 ERROR REAL WHISPER: $e");
      return null;
    }
  }
}