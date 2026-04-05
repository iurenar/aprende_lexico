// lib/services/audio_recorder_service.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isDisposed = false;

  Future<bool> requestPermissions() async {
    try {
      if (_isDisposed) return false;
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint("❌ Error en requestPermissions: $e");
      return false;
    }
  }

  Future<String?> startRecording() async {
    try {
      if (_isDisposed) return null;

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/presentation_$timestamp.m4a';

      debugPrint("🎙️ Iniciando grabación en: $path");

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      return path;
    } catch (e) {
      debugPrint("❌ Error iniciando grabación: $e");
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (_isDisposed) return null;

      if (!await _recorder.isRecording()) {
        debugPrint("⚠️ No hay grabación activa");
        return null;
      }

      final path = await _recorder.stop();
      debugPrint("✅ Grabación detenida: $path");

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          debugPrint("📁 Archivo final: ${await file.length()} bytes");
        }
      }

      return path;
    } catch (e) {
      debugPrint("❌ Error deteniendo grabación: $e");
      return null;
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (e) {
      debugPrint("❌ Error en dispose: $e");
    }
  }
}