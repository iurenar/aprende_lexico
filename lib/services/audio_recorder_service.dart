// lib/services/audio_recorder_service.dart
import 'dart:io';
import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentFilePath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<bool> requestPermissions() async {
    try {
      // Solicitar permisos de micrófono
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        return false;
      }
      return true;
    } catch (e) {
      print("❌ Error al solicitar permisos: $e");
      return false;
    }
  }

  Future<String?> startRecording() async {
    try {
      // Crear archivo único
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentFilePath = '${dir.path}/presentation_$timestamp.m4a';

      print("🎙️ Iniciando grabación en: $_currentFilePath");

      // Configurar y empezar grabación
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc, // Formato AAC (buena calidad)
          bitRate: 128000, // 128 kbps
          sampleRate: 44100, // 44.1 kHz
        ),
        path: _currentFilePath!,
      );

      _isRecording = true;
      return _currentFilePath;
    } catch (e) {
      print("❌ Error al iniciar grabación: $e");
      return null;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;

      if (path != null && await File(path).exists()) {
        final fileSize = await File(path).length();
        print("✅ Grabación detenida: $path (${fileSize ~/ 1024} KB)");
        return path;
      }

      return null;
    } catch (e) {
      print("❌ Error al detener grabación: $e");
      _isRecording = false;
      return null;
    }
  }

  Future<void> dispose() async {
    if (_isRecording) {
      await _recorder.stop();
    }
    await _recorder.dispose();
  }
}