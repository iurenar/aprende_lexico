// lib/services/whisper_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class WhisperService {
  // Usar Groq para Whisper (más rápido y económico)
  static Future<String> transcribeAudio(String audioPath) async {
    try {

      final groqApiKey = dotenv.env['GROQ_API_KEY'];

      if (groqApiKey == null || groqApiKey.isEmpty) {
        throw Exception("❌ GROQ_API_KEY no está configurada en .env");
      }

      print("🔄 Transcribiendo audio con Whisper...");

      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception("Archivo de audio no encontrado");
      }

      // Crear request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );

      // Headers
      request.headers.addAll({
        'Authorization': 'Bearer $groqApiKey',
      });

      // Añadir archivo
      request.files.add(
        await http.MultipartFile.fromPath('file', audioPath),
      );

      // Añadir campos
      request.fields['model'] = 'whisper-large-v3-turbo';
      request.fields['language'] = 'es';
      request.fields['response_format'] = 'json';

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final transcript = data['text'];
        print("✅ Transcripción completada (${transcript.length} caracteres)");
        return transcript;
      } else {
        print("❌ Error Whisper: ${response.statusCode} - ${response.body}");
        throw Exception("Error en transcripción: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error en transcribeAudio: $e");
      rethrow;
    }
  }

  // Versión con OpenAI (alternativa)
  static Future<String> transcribeWithOpenAI(String audioPath) async {
    try {
      final groqApiKey = dotenv.env['GROQ_API_KEY'];

      if (groqApiKey == null || groqApiKey.isEmpty) {
        throw Exception("❌ GROQ_API_KEY no está configurada en .env");
      }

      final file = File(audioPath);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
      );

      request.headers.addAll({
        'Authorization': "Bearer $groqApiKey", // Si tienes
      });

      request.files.add(
        await http.MultipartFile.fromPath('file', audioPath),
      );

      request.fields['model'] = 'whisper-1';
      request.fields['language'] = 'es';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'];
      } else {
        throw Exception("Error OpenAI: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error OpenAI Whisper: $e");
      rethrow;
    }
  }
}