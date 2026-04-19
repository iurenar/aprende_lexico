// lib/services/whisper_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WhisperService {
  static const String _url =
      "https://transcribe-czedra5txa-uc.a.run.app";

  static Future<String?> transcribeAudioBytes(Uint8List bytes) async {
    try {
      debugPrint("🚀 Enviando audio al backend...");

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          "Content-Type": "application/octet-stream",
        },
        body: bytes,
      ).timeout(const Duration(seconds: 60));

      debugPrint("📡 STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["text"] != null) {
          return data["text"];
        } else {
          throw Exception("Respuesta inválida del backend");
        }
      } else {
        throw Exception("Error backend: ${response.body}");
      }
    } catch (e) {
      debugPrint("🔥 ERROR WHISPER BACKEND: $e");
      return null;
    }
  }
}