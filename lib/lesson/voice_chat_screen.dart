import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' as typed;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:aprende_lexico/chat_messages/chat_message.dart';

import 'package:aprende_lexico/learn/learn_progress_services.dart';
import 'package:aprende_lexico/enums/training_mode.dart';
import 'package:aprende_lexico/enums/interview_flow.dart';
import 'package:aprende_lexico/interview/interview_script.dart';
import 'package:aprende_lexico/interview/lexical_result.dart';
import 'package:aprende_lexico/avatar/animated_avatar.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../enums/profession.dart';
import '../onboarding/onboarding_controller.dart';
import '../prompts/profession_prompts.dart';
import '../services/audio_recorder_service.dart';
import '../services/whisper_service.dart';


enum DifficultyLevel { basic, intermediate, advanced }
enum LexicalDeficitType { vagueVerbs, genericNouns, weakStructure, lackOfConnectors }
enum LiveCorrectionType { none, soft, important }
enum MicState {
  idle, // mic apagado
  listening, // usuario hablando
  ariaSpeaking, // Aria hablando (mic forzado OFF)
}

const String baseAriaPrompt = """
Eres Aria, una entrenadora de comunicación profesional en español.

Tu objetivo es elevar el léxico profesional del usuario.
Hablas de forma natural, cercana y segura.
No eres académica ni rígida.
""";

const String professionalLexiconPrompt = """
Eres Aria, una entrenadora de español profesional.

Tu objetivo es ayudar al usuario a mejorar su léxico profesional y su forma de expresarse en contextos laborales.

Flujo que debes seguir SIEMPRE:
1. Propón un contexto profesional (reuniones, presentaciones, correos, liderazgo, proyectos, etc.).
2. Escucha la respuesta del usuario.
3. Analiza su lenguaje y:
   - Detecta palabras vagas o informales.
   - Sugiere sustituciones más profesionales.
   - Reformula la frase usando un léxico más preciso.
4. Explica brevemente por qué la nueva versión es mejor.
5. Continúa la conversación con una nueva pregunta relacionada.

Reglas:
- Responde solo en español.
- Mantén un tono natural, cercano y profesional.
- No uses listas largas ni lenguaje académico.
- Habla como un mentor, no como un profesor.
- No muestres el texto original del usuario, solo la versión mejorada.

Tu misión no es corregir errores básicos, sino elevar el nivel del discurso.
Si detectas una palabra vaga:
- Corrige solo UNA por turno
- Hazlo de forma natural
- No interrumpas el flujo
""";

String _sanitizeForTTS(String text) {
  return text
      .replaceAll(RegExp(r'[*_`#>-]'), '')
      .replaceAll(RegExp(r'\n\s*-\s*'), '. ')
      .replaceAll(RegExp(r'\n+'), '. ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}

class VoiceChatScreen extends StatefulWidget {
  final TrainingMode mode;
  final String? documentContext;
  final String? learnContext;

  const VoiceChatScreen({
    super.key,
    required this.mode,
    this.documentContext,
    this.learnContext,
  });

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  // === STT / TTS ===
  late final stt.SpeechToText _speechToText;
  final FlutterTts _tts = FlutterTts();
  final Set<String> _usedProfessionalWords = {};
  final Set<String> _recentCorrections = {};
  DateTime _lastLiveCorrection = DateTime.fromMillisecondsSinceEpoch(0);
  final ScrollController _scrollController = ScrollController();
  DifficultyLevel _difficulty = DifficultyLevel.basic;
  int _turnCount = 0;
  String? _activeLiveError;
  LexicalDeficitType? _activeDeficit;
  Timer? _presentationTimer;
  final List<String> _presentationSegments = [];
  String _fullPresentationText = "";
  final Map<String, int> _errorFrequency = {};
  final Set<String> _masteredWords = {};

  // === LIVE SPEECH COACHING ===
  String _liveSpeechBuffer = "";
  DateTime _lastFeedbackTime = DateTime.now();
  late final Profession _profession;

  // === ESTADO ===
  bool _speechReady = false;
  bool _sessionCompleted = false;
  MicState _micState = MicState.idle;
  bool _wasListeningBeforeAria = false;
  bool _guidedModeActive = false;
  bool isListening = false;
  bool isLongFormMode = false;
  String accumulatedText = "";
  bool _finalSpeechHandled = false;
  int _presentationSecondsRemaining = 120; // 2 minutos en segundos

  final List<ChatMessage> _messages = [];
  late final TrainingMode _mode;

  final AudioRecorderService _audioRecorder = AudioRecorderService();
  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isTranscribing = false;

  // interview
  InterviewPhase _currentPhase = InterviewPhase.analysis;
  int _questionIndex = 0;
  int _lexicalLowCount = 0;
  int _structureErrorCount = 0;
  int _vagueResponseCount = 0;
  int _vagueVerbCount = 0;
  int _genericNounCount = 0;
  int _connectorCount = 0;
  int _vagueWordCount = 0;
  int _preciseWordCount = 0;
  double _lexicalScore = 0.0; // 0 a 10
  double _structureScore = 1.0;
  bool _waitingForValidAnswer = false;

  String _currentQuestion() {
    final questions = InterviewScript.questions[_currentPhase] ?? [];
    return _questionIndex < questions.length ? questions[_questionIndex] : "";
  }

  String _difficultyLabel() {
    switch (_difficulty) {
      case DifficultyLevel.basic:
        return "Nivel Básico";
      case DifficultyLevel.intermediate:
        return "Nivel Intermedio";
      case DifficultyLevel.advanced:
        return "Nivel Avanzado";
    }
  }

  Color _difficultyColor() {
    switch (_difficulty) {
      case DifficultyLevel.basic:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.advanced:
        return Colors.redAccent;
    }
  }

  String _buildModePrompt() {
    final hasDocument = widget.documentContext != null;

    switch (_mode) {
      case TrainingMode.guidedPractice:
        return """
Estás guiando al usuario paso a paso.
Haz preguntas abiertas.
Corrige suavemente.
Sugiere mejoras sin presionar.
""";

      case TrainingMode.presentation:
        return hasDocument
            ? """
El usuario está presentando oralmente un documento.

Evalúa al usuario COMO EXPOSITOR comparando:
- lo que dice
- con lo que realmente contiene el documento

NO evalúes la calidad del documento.
Evalúa la concordancia entre discurso y contenido.

Da feedback breve en máximo 3 puntos sobre:
- fidelidad al documento (ideas clave, coherencia)
- vocabulario profesional usado para explicarlo
- claridad y forma de hablar

Usa frases cortas y sugerencias prácticas.
No te extiendas.

Responde siempre en este formato:
1. Fortalezas
2. A mejorar
3. Consejo rápido
"""       : """
El usuario está presentando una idea profesional.

Evalúa su desempeño oral en máximo 3 observaciones:
- claridad del mensaje
- vocabulario profesional
- forma de hablar

Sé conciso y práctico.
No te extiendas.

Responde siempre en este formato:
1. Fortalezas
2. A mejorar
3. Consejo rápido
""";

      case TrainingMode.defense:
        return hasDocument
            ? """
Estás evaluando una defensa basada en una tesis real.
Contrasta lo que dice el usuario con el documento.
Detecta inconsistencias, vacíos y debilidades argumentales.
Haz repreguntas exigentes pero respetuosas.
"""
            : """
Actúa como un evaluador exigente.
Cuestiona ideas con respeto.
Exige precisión léxica y argumentos claros.
""";

      case TrainingMode.professional:
        return """
Eres Aria, una coach experta en comunicación profesional.

El objetivo es entrenar al usuario en el uso de léxico profesional
relacionado con su profesión.

Instrucciones:
- Propón situaciones laborales reales
- Pide al usuario que responda usando vocabulario técnico
- Corrige si usa palabras vagas o poco profesionales
- Sugiere mejores términos cuando sea posible
- Refuerza el uso correcto del léxico

Sé clara, exigente y pedagógica.
""";

      case TrainingMode.interview:
        return """
Eres Aria, una entrevistadora profesional senior.

Haz una sola pregunta clara.
Escucha atentamente la respuesta del candidato.
Evalúa:
- Claridad
- Estructura
- Uso de léxico profesional
- Relevancia para el puesto

Pregunta actual:
"${widget.learnContext}"

No respondas aún. Espera la respuesta del candidato.
""";
    }
  }

  String get systemPrompt {
    final documentContext = widget.documentContext != null
        ? "\n\nDocumento de referencia:\n${widget.documentContext}"
        : "";

    return '''
${professionBasePrompt(_profession)}

${_guidedModeActive ? guidedPracticePrompt : _buildModePrompt()}

$documentContext
''';
  }

  bool _shouldEndSession() {
    if (_turnCount >= 6 && !_sessionCompleted) {
      _sessionCompleted = true;
      return true;
    }
    return false;
  }

  bool _shouldInterruptNow(LiveCorrectionType type, String text) {
    if (_micState != MicState.listening) return false;
    if (_mode == TrainingMode.presentation) return false; // 🛑 No interrumpir en presentación

    final hasPause = text.endsWith(".") || text.endsWith(",") || text.endsWith(" y");
    if (!hasPause) return false;

    switch (_difficulty) {
      case DifficultyLevel.basic:
        return true;
      case DifficultyLevel.intermediate:
        return type == LiveCorrectionType.important;
      case DifficultyLevel.advanced:
        return type == LiveCorrectionType.important && _lexicalScore < 6.5;
    }
  }

  void _updateDifficulty() {
    if (_difficulty == DifficultyLevel.basic && _lexicalScore >= 4.5) {
      setState(() {
        _difficulty = DifficultyLevel.intermediate;
      });
      _ariaSpeak("Muy bien. Pasamos a un nivel intermedio.");
    }

    if (_difficulty == DifficultyLevel.intermediate && _lexicalScore >= 7.5) {
      setState(() {
        _difficulty = DifficultyLevel.advanced;
      });
      _ariaSpeak("Excelente. Entramos en nivel avanzado.");
    }
  }

  @override
  void initState() {
    super.initState();
    final profession = context.read<OnboardingController>().state.profession;
    _speechToText = stt.SpeechToText();
    _mode = widget.mode;
    _profession = context.read<OnboardingController>().state.profession;

    _tts.setStartHandler(() {
      debugPrint("🗣️ Aria empezó a hablar");
      setState(() {
        _micState = MicState.ariaSpeaking;
      });
    });

    if (_mode == TrainingMode.presentation) {
      _guidedModeActive = false;
      _activeDeficit = null;
    }

    _tts.setCompletionHandler(() async {
      debugPrint("✅ Aria terminó de hablar");

      if (!mounted) return;

      setState(() {
        _micState = MicState.idle;
      });

      if (_wasListeningBeforeAria && !_sessionCompleted) {
        await Future.delayed(const Duration(milliseconds: 400));
        await _startListening();
      }
    });

    _addInitialMessage();
    _initializeServices();
  }

  // SOLO TE MUESTRO LAS PARTES MODIFICADAS (TODO LO DEMÁS QUEDA IGUAL)

  Future<void> _initializeServices() async {


    final speechReady = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) => debugPrint("❌ STT error: $error"),
      debugLogging: true, // ✅ importante para iOS
    );

    setState(() {
      _speechReady = speechReady;
    });

    // ✅ CONFIGURACIÓN iOS TTS

    await _tts.setSharedInstance(true); // 🔥 CLAVE iOS
    await _tts.awaitSpeakCompletion(true); // 🔥 CLAVE iOS
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playAndRecord,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
      ],
    );

    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.5);
  }

  void _onSpeechStatus(String status) {
    debugPrint("📊 Speech status: $status, Mode: $_mode");

    // 🔥 MANEJO ESPECIAL PARA MODO PRESENTACIÓN
    if (_mode == TrainingMode.presentation) {
      if (status == "done" && _micState == MicState.listening) {
        debugPrint("⚠️ STT reportó 'done' en presentación");

        // Guardar texto acumulado antes de reiniciar
        if (accumulatedText.trim().isNotEmpty) {
          debugPrint("💾 Guardando texto acumulado: '$accumulatedText'");

          setState(() {
            _messages.add(ChatMessage(
                text: accumulatedText,
                isUser: true
            ));
          });
          _scrollToBottom();
        }

        // Reiniciar escucha inmediatamente
        _restartListeningWithAccumulation();
      }
      return;
    }

    // 🔄 COMPORTAMIENTO NORMAL PARA OTROS MODOS
    if (_micState == MicState.listening &&
        status == "done" &&
        !_speechToText.isListening) {

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _micState == MicState.listening) {
          _speechToText.listen(
            onResult: _onSpeechResult,
            listenMode: ListenMode.dictation,
            partialResults: true,
            cancelOnError: false,
            localeId: "es-ES",
          );
        }
        if (status == "notListening" && _micState == MicState.listening) {
          debugPrint("⚠️ iOS cortó el mic - reiniciando");

          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _micState == MicState.listening) {
              _startListening();
            }
          });
        }
      });
    }
  }

  void _addInitialMessage() {
    String baseText = switch (_mode) {
      TrainingMode.guidedPractice => "Empecemos con una práctica guiada.",
      TrainingMode.presentation => "Imagina que estás frente a un equipo. Tienes 2 minutos para exponer.",
      TrainingMode.defense => "Voy a cuestionar tus ideas como en una defensa profesional.",
      TrainingMode.professional => "Evaluaré tu léxico profesional.",
      TrainingMode.interview => "Prepárate con preguntas reales de reclutadores.",
    };

    if (widget.learnContext != null) {
      baseText += "\n\nHoy quiero que pongas atención especial a este concepto:\n"
          "${widget.learnContext}\n"
          "Intenta usarlo conscientemente cuando hables.";
    }

    _messages.add(ChatMessage(text: baseText, isUser: false));

    if (_mode == TrainingMode.interview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ariaSpeak(_currentQuestion());
      });
    }

    if (_mode == TrainingMode.presentation) {
      _showPresentationInstructions();
    }
  }

  void _showPresentationInstructions() {
    _messages.add(
      ChatMessage(
        text: "🎤 **MODO PRESENTACIÓN ACTIVADO**\n\n"
            "Tienes 2 minutos completos para hablar sin interrupciones.\n"
            "Presiona el botón 'Comenzar Presentación' para iniciar.\n"
            "El sistema NO se detendrá automáticamente por silencios.\n"
            "Presiona 'Finalizar Presentación' cuando termines o espera los 2 minutos.\n\n"
            "¡Buena suerte!",
        isUser: false,
      ),
    );
    _scrollToBottom();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (result.recognizedWords.isEmpty) return;

    // Actualizar texto acumulado
    setState(() {
      accumulatedText = result.recognizedWords;
    });

    debugPrint("🎤 Parcial: '$accumulatedText' (final: ${result.finalResult})");

    // PARA PRESENTACIÓN
    if (_mode == TrainingMode.presentation) {
      if (result.finalResult) {
        debugPrint("🎤 Presentación - Resultado FINAL recibido");

        // Guardar el texto final
        if (accumulatedText.trim().isNotEmpty) {
          setState(() {
            _messages.add(ChatMessage(
                text: "[${_formatTime(120 - _presentationSecondsRemaining)}] $accumulatedText",
                isUser: true
            ));
          });
          _scrollToBottom();
        }

        // Si esto ocurre, el STT se detuvo - reiniciar
        if (_micState == MicState.listening) {
          _restartListeningWithAccumulation();
        }
      }
      // No procesar nada más, solo acumular
      return;
    }

    // Para otros modos - comportamiento normal
    if (result.finalResult) {
      setState(() {
        _micState = MicState.idle;
      });
      _onFinalSpeech(result.recognizedWords);
    } else {
      if (_mode == TrainingMode.guidedPractice || _mode == TrainingMode.professional) {
        _onPartialSpeech(result.recognizedWords);
      }
    }
  }

  Future<void> _startListening() async {
    _finalSpeechHandled = false;

    if (_mode == TrainingMode.presentation) {
      // 🎤 MODO PRESENTACIÓN - USAR GRABACIÓN

      // Verificar permisos
      final hasPermission = await _audioRecorder.requestPermissions();
      if (!hasPermission) {
        _showErrorDialog("Se necesitan permisos de micrófono para grabar");
        return;
      }

      // Iniciar grabación
      final path = await _audioRecorder.startRecording();
      if (path != null) {
        setState(() {
          _isRecording = true;
          _currentRecordingPath = path;
          _micState = MicState.listening;
          _presentationSegments.clear();
          _fullPresentationText = "";
        });

        debugPrint("🎙️ Grabación iniciada: $path");

        // Iniciar timer de presentación
        _startPresentationTimer();

        // Mensaje de inicio
        _messages.add(ChatMessage(
          text: "🎤 Grabando presentación... Habla libremente por 2 minutos.",
          isUser: false,
        ));
        _scrollToBottom();
      } else {
        _showErrorDialog("No se pudo iniciar la grabación");
      }
      return;
    }

    // 🎤 OTROS MODOS - USAR STT NORMAL
    if (_micState != MicState.idle || !_speechReady) return;

    accumulatedText = "";

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        localeId: "es-ES",
      );
    } catch (e) {
      debugPrint("❌ Error al iniciar escucha: $e");
      return;
    }

    setState(() {
      _micState = MicState.listening;
    });
  }

  void _startPresentationTimer() {
    _presentationTimer?.cancel();
    _presentationSecondsRemaining = 120;

    _presentationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _presentationSecondsRemaining--;
      });

      if (_presentationSecondsRemaining <= 0) {
        timer.cancel();
        if (_micState == MicState.listening) {
          _finishPresentationByTimer();
        }
      }
    });
  }

  Future<void> _finishPresentationByTimer() async {
    debugPrint("⏰ 2 minutos completados - Finalizando presentación automáticamente");

    try {
      await _stopListening();
    } catch (e) {
      debugPrint("❌ Error al detener escucha: $e");
    }

    if (accumulatedText.trim().isNotEmpty && !_finalSpeechHandled) {
      await _onFinalSpeech(accumulatedText);
    }

    _ariaSpeak("Tiempo completado. Vamos a evaluar tu presentación.");

    // Mostrar mensaje
    setState(() {
      _messages.add(
        ChatMessage(
          text: "⏰ Tiempo de presentación finalizado (2 minutos)",
          isUser: false,
        ),
      );
    });
    _scrollToBottom();
  }
  Future<void> _finishPresentationManually() async {
    debugPrint("🎤 FINALIZANDO PRESENTACIÓN - Procesando audio...");

    if (_isTranscribing) {
      debugPrint("⚠️ Ya está transcribiendo, ignorando");
      return;
    }

    setState(() {
      _micState = MicState.idle;
      _isTranscribing = true;
    });

    _presentationTimer?.cancel();

    String? audioPath;
    if (_isRecording) {
      audioPath = await _audioRecorder.stopRecording();
      debugPrint("📁 Audio path devuelto: $audioPath");

      setState(() {
        _isRecording = false;
        _currentRecordingPath = null;
      });
    }

    if (audioPath == null) {
      _handleTranscriptionError("No se generó archivo de audio");
      return;
    }

    // Verificar archivo original
    final sourceFile = File(audioPath);
    if (!await sourceFile.exists()) {
      _handleTranscriptionError("Archivo original no encontrado");
      return;
    }

    final sourceSize = await sourceFile.length();
    debugPrint("📁 Archivo original: $sourceSize bytes");

    // 👇 COPIAR ARCHIVO A DOCUMENTS (más estable que cache)
    final documentsDir = await getApplicationDocumentsDirectory();
    final newAudioPath = '${documentsDir.path}/presentation_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      final destFile = File(newAudioPath);

      // Copiar el archivo
      await sourceFile.copy(newAudioPath);
      debugPrint("✅ Archivo copiado a: $newAudioPath");

      // Verificar que la copia existe
      if (!await destFile.exists()) {
        _handleTranscriptionError("Error al copiar el archivo de audio");
        return;
      }

      final copySize = await destFile.length();
      debugPrint("📁 Archivo copiado: $copySize bytes");


      // Procesar la copia
      await _processAudioFileSafe(newAudioPath);


    } catch (e) {
      debugPrint("❌ Error copiando archivo: $e");
      _handleTranscriptionError("Error al preparar el audio");
    }
  }

  void _handleTranscriptionError(String message) {
    debugPrint("❌ Error de transcripción: $message");
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: "❌ $message", isUser: false));
        _isTranscribing = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _processAudioFileSafe(String path) async {
    try {


      if (!mounted) return;

      setState(() {
        _messages.add(ChatMessage(
          text: "⏳ Procesando tu presentación...",
          isUser: false,
        ));
      });

      // 🔥 VALIDACIÓN EXTRA (debug real)
      final file = File(path);

      final exists = await file.exists();
      final size = exists ? await file.length() : 0;

      debugPrint("📁 Exists: $exists");
      debugPrint("📁 Size: $size bytes");

      if (!exists || size < 5000) {
        _handleTranscriptionError("Audio inválido o muy corto");
        return;
      }

      // 🔥 LLAMADA CORRECTA
      final bytes = await File(path).readAsBytes();

      final transcript =
      await WhisperService.transcribeAudioBytes(bytes);

      if (transcript != null && transcript.isNotEmpty) {
        await _onFinalSpeech(transcript);
      } else {
        _handleTranscriptionError("No se pudo transcribir el audio.");
      }

      // 🔥 LIMPIAR ARCHIVO (opcional pero recomendado)
      if (await file.exists()) {
        await file.delete();
        debugPrint("🗑️ Archivo eliminado");
      }

    } catch (e) {
      debugPrint("❌ Error procesando audio: $e");
      _handleTranscriptionError("Error al procesar el audio");
    }
  }

  Future<void> _restartListeningIfNeeded() async {
    if (!mounted) return;
    if (_mode != TrainingMode.presentation) return;
    if (_micState != MicState.listening) return;
    if (_speechToText.isListening) return;

    debugPrint("🔄 Reiniciando escucha automáticamente (se detuvo sola)");

    // Pequeña pausa antes de reiniciar
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted && _micState == MicState.listening) {
      await _startListening();
    }
  }
  Future<void> _restartListeningWithAccumulation() async {
    if (!mounted) return;
    if (_mode != TrainingMode.presentation) return;

    debugPrint("🔄 Reiniciando escucha - texto acumulado: '$accumulatedText'");

    // Guardar el texto acumulado en una variable temporal
    final String textBeforePause = accumulatedText;

    // Limpiar el acumulado actual pero mantenerlo para referencia
    setState(() {
      // No limpiar accumulatedText todavía - lo necesitamos para concatenar
    });

    // Pequeña pausa antes de reiniciar
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // Reiniciar escucha
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }

      // Iniciar nueva escucha
      final bool started = await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(minutes: 3),
        pauseFor: const Duration(seconds: 30),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        localeId: Platform.isIOS ? "es_ES" : "es-ES",

      );

      if (started) {
        debugPrint("✅ Escucha reiniciada exitosamente");

        // Mostrar indicador visual de continuación
        setState(() {
          _messages.add(ChatMessage(
              text: "⏸️ Pausa detectada - continúa tu presentación...",
              isUser: false
          ));
        });
        _scrollToBottom();
      }

    } catch (e) {
      debugPrint("❌ Error al reiniciar escucha: $e");
    }
  }



  Future<void> _finishListening() async {
    // ⚠️ NUNCA llamar a este método en modo presentación
    if (_mode == TrainingMode.presentation) {
      debugPrint("❌ ERROR: _finishListening llamado en modo presentación");
      return;
    }

    try {
      await _speechToText.stop();

      setState(() {
        _micState = MicState.idle;
      });

      if (accumulatedText.trim().isNotEmpty) {
        await _onFinalSpeech(accumulatedText);
      }

    } catch (e) {
      debugPrint("❌ Error al finalizar escucha: $e");
      setState(() {
        _micState = MicState.idle;
      });
    }
  }

  Future<void> _stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (e) {
      debugPrint("❌ Error al detener STT: $e");
    } finally {
      if (mounted) {
        setState(() {
          _micState = MicState.idle;
        });
      }
    }
  }

  void _onPartialSpeech(String text) {
    _liveSpeechBuffer = text;

    if (_mode == TrainingMode.presentation) return; // ✅ ESTO ESTÁ BIEN

    // ... resto del código que NO debería ejecutarse en presentación
  }

  LiveCorrectionType _evaluateLiveSpeech(String text) {
    final lower = text.toLowerCase();

    final vagueWords = ["cosa", "hacer"];
    final softWords = ["creo que", "como que", "un poco"];

    for (final entry in _errorFrequency.entries) {
      if (lower.contains(entry.key)) {
        if (entry.value >= 3) {
          return LiveCorrectionType.important;
        } else {
          return LiveCorrectionType.soft;
        }
      }
    }

    for (final w in softWords) {
      if (lower.contains(w)) {
        if (_activeLiveError == w) {
          return LiveCorrectionType.soft;
        }
        _activeLiveError = w;
        return LiveCorrectionType.none;
      }
    }

    _activeLiveError = null;
    return LiveCorrectionType.none;
  }

  Future<void> _onFinalSpeech(String text) async {
    debugPrint("🎯 _onFinalSpeech() LLAMADO - Modo: $_mode");
    debugPrint("📞 STACK TRACE: ${StackTrace.current}");

    if (_finalSpeechHandled) {
      debugPrint("⏭️ _finalSpeechHandled = true, ignorando");
      return;
    }

    _finalSpeechHandled = true;

    debugPrint("🧠 PROCESANDO TEXTO FINAL (longitud: ${text.length}): ${text.substring(0, min(100, text.length))}...");
    _onUserText(text);
  }

  void _analyzeUserLexicon(String text) {
    final lower = text.toLowerCase();

    final vagueWords = [
      "cosa",
      "hacer",
      "algo",
      "un poco",
      "más o menos",
      "como que",
    ];

    final preciseWords = [
      "implementar",
      "optimizar",
      "estructurar",
      "alinear",
      "gestionar",
      "priorizar",
      "definir",
    ];

    bool foundVague = false;
    bool foundPrecise = false;

    for (final w in vagueWords) {
      if (lower.contains(w)) {
        _vagueWordCount++;
        foundVague = true;
        break;
      }
    }

    for (final w in preciseWords) {
      if (lower.contains(w)) {
        _preciseWordCount++;
        foundPrecise = true;
        break;
      }
    }

    _recalculateLexicalScore(
      foundVague: foundVague,
      foundPrecise: foundPrecise,
    );
  }

  void _detectDeficits(String text) {
    final lower = text.toLowerCase();

    final vagueVerbs = ["hacer", "poner", "llevar"];
    if (vagueVerbs.any(lower.contains)) {
      _vagueVerbCount++;
    }

    final genericNouns = ["cosa", "tema", "algo"];
    if (genericNouns.any(lower.contains)) {
      _genericNounCount++;
    }

    final connectors = ["por lo tanto", "además", "sin embargo"];
    if (connectors.any(lower.contains)) {
      _connectorCount++;
    }

    _structureScore = text.split(".").length > 1 ? 0.7 : 0.3;
  }

  LexicalDeficitType _detectMainDeficit() {
    if (_vagueVerbCount >= 2) {
      return LexicalDeficitType.vagueVerbs;
    }
    if (_genericNounCount >= 2) {
      return LexicalDeficitType.genericNouns;
    }
    if (_structureScore < 0.4) {
      return LexicalDeficitType.weakStructure;
    }
    return LexicalDeficitType.lackOfConnectors;
  }

  void _recalculateLexicalScore({
    required bool foundVague,
    required bool foundPrecise,
  }) {
    double score = _lexicalScore;

    if (foundPrecise) score += 0.6;
    if (foundVague) score -= 0.8;

    score = score.clamp(0.0, 10.0);

    setState(() {
      _lexicalScore = score;
    });

    debugPrint("🧠 Lexical Score: $_lexicalScore");
  }

  void _evaluateNeedForGuidedPractice({
    required LexicalLevel lexicalLevel,
    required double structureScore,
    required int wordCount,
    required bool repeatedError,
  }) {
    if (_mode == TrainingMode.presentation ||
        _mode == TrainingMode.defense ||
        _mode == TrainingMode.interview) {
      return;
    }

    if (lexicalLevel == LexicalLevel.low) {
      _lexicalLowCount++;
    } else {
      _lexicalLowCount = 0;
    }

    if (structureScore < 0.4) {
      _structureErrorCount++;
    } else {
      _structureErrorCount = 0;
    }

    if (wordCount < 12) {
      _vagueResponseCount++;
    } else {
      _vagueResponseCount = 0;
    }

    if ((_lexicalLowCount >= 2) ||
        (_structureErrorCount >= 2) ||
        (_vagueResponseCount >= 2) ||
        repeatedError) {
      if (!_guidedModeActive) {
        debugPrint("🧠 ACTIVANDO PRÁCTICA GUIADA");
        _guidedModeActive = true;

        _messages.add(
          ChatMessage(
            text: "Pausa un momento 😊\n"
                "Vamos a trabajarlo paso a paso.\n\n"
                "Te voy a mostrar una forma clara de estructurar la respuesta "
                "y luego la reformulamos juntos.",
            isUser: false,
          ),
        );
      }
    }

    if (_guidedModeActive && _lexicalScore >= 6.5) {
      debugPrint("✅ Saliendo de práctica guiada");
      _guidedModeActive = false;

      _messages.add(
        ChatMessage(
          text: "Perfecto 👌\n"
              "Ahora sigamos con la dinámica normal.",
          isUser: false,
        ),
      );
    }
  }

  void _saveCorrectionMemory(String text) {
    final trackedWords = [
      "hacer",
      "cosa",
      "creo que",
      "como que",
      "un poco",
      "más o menos",
    ];

    for (final w in trackedWords) {
      if (text.toLowerCase().contains(w)) {
        if (_masteredWords.contains(w)) return;

        _errorFrequency[w] = (_errorFrequency[w] ?? 0) + 1;
        _recentCorrections.add(w);

        debugPrint("🧠 Error '$w' → ${_errorFrequency[w]} veces");
        break;
      }
    }
  }

  Future<void> _giveLiveCorrection(String text, LiveCorrectionType type) async {
    if (_recentCorrections.any((w) => text.toLowerCase().contains(w))) {
      return;
    }

    final prompt = switch (_difficulty) {
      DifficultyLevel.basic => """
Eres Aria.
Interrumpe con una sugerencia clara y amable.
Máximo 8 palabras.
""",
      DifficultyLevel.intermediate => """
Eres Aria.
Da una pista rápida sin cortar la idea.
Máximo 6 palabras.
""",
      DifficultyLevel.advanced => """
Eres Aria.
Corrige solo una palabra.
Máximo 4 palabras.
""",
    };

    final correction = await _askAIWithPrompt(
      systemPrompt: prompt,
      userText: text,
      maxTokens: 40,
    );

    await _ariaSpeak(correction);
    _saveCorrectionMemory(text);
    await Future.delayed(const Duration(seconds: 6));
  }

  Future<void> _ariaSpeak(String text) async {
    final cleanText = _sanitizeForTTS(text);

    debugPrint("🤖 Aria dice: $cleanText");

    if (_micState == MicState.listening) {
      _wasListeningBeforeAria = true;
      await _stopListening();
    } else {
      _wasListeningBeforeAria = false;
    }

    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    await _tts.speak(cleanText);
  }

  Future<void> _onUserText(String text) async {
    debugPrint("🎤 USUARIO DIJO: $text");

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();

    _analyzeUserLexicon(text);
    _detectImprovement(text);
    _detectDeficits(text);
    _activeDeficit = _detectMainDeficit();

    _evaluateNeedForGuidedPractice(
      lexicalLevel: _lexicalScore < 4
          ? LexicalLevel.low
          : _lexicalScore < 7
          ? LexicalLevel.medium
          : LexicalLevel.high,
      structureScore: _lexicalScore / 10,
      wordCount: text.split(' ').length,
      repeatedError: _recentCorrections.isNotEmpty,
    );

    if (widget.mode == TrainingMode.interview && !_sessionCompleted) {
      final result = await _evaluateResponse(text);
      _handleEvaluation(result);
      return;
    }

    try {
      final aiResponse = _guidedModeActive
          ? await _askGuidedAI(text)
          : await _askAI(text);
      _extractProfessionalWords(aiResponse);
      _turnCount++;
      _updateDifficulty();

      if (_guidedModeActive && _lexicalScore >= 6.5) {
        debugPrint("✅ Saliendo de práctica guiada");
        _guidedModeActive = false;
      }

      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
      });
      _scrollToBottom();

      await _ariaSpeak(aiResponse);

      if (_shouldEndSession()) {
        await _handleFinalEvaluation(text);
      }
    } catch (e) {
      debugPrint("❌ Error IA: $e");
    }
  }

  Future<String> _askGuidedAI(String text) async {
    final prompt = switch (_activeDeficit) {
      LexicalDeficitType.vagueVerbs =>
      "Guía al usuario a usar un verbo profesional concreto.",
      LexicalDeficitType.genericNouns =>
      "Pide al usuario que especifique el sustantivo.",
      LexicalDeficitType.weakStructure =>
      "Guía usando la estructura Contexto → Acción → Resultado.",
      LexicalDeficitType.lackOfConnectors =>
      "Ayuda a unir ideas con conectores profesionales.",
      null => throw UnimplementedError(),
    };

    return _askAIWithPrompt(
      systemPrompt: prompt,
      userText: text,
      maxTokens: 120,
    );
  }

  String _buildReprompt(LexicalResult result) {
    return switch (result.level) {
      LexicalLevel.low =>
      "Intenta responder usando vocabulario más profesional. ${result.followUpQuestion}",
      LexicalLevel.medium =>
      "Vas bien, pero puedes ser más preciso. ${result.followUpQuestion}",
      LexicalLevel.high => "Buen nivel léxico. Sigamos.",
    };
  }

  Future<LexicalResult> _evaluateResponse(String text) async {
    final prompt = """
Analiza la respuesta del candidato a una entrevista laboral.

Devuelve:
1. Nivel de léxico profesional: BAJO / MEDIO / ALTO
2. Diagnóstico breve
3. Decisión: ADVANCE / PROBE / CORRECT
4. Repregunta si aplica
""";

    final aiResponse = await _askAIWithPrompt(
      systemPrompt: prompt,
      userText: text,
    );

    return LexicalResult.fromAI(aiResponse);
  }

  void _handleEvaluation(LexicalResult result) {
    if (result.decision == Decision.advance) {
      _ariaSpeak("Bien. Continuemos.");
      _advanceQuestion();
    } else {
      _ariaSpeak(result.followUpQuestion);
    }
  }

  void _advanceQuestion() {
    final questions = InterviewScript.questions[_currentPhase] ?? [];

    _questionIndex++;

    if (_questionIndex < questions.length) {
      _ariaSpeak(_currentQuestion());
    } else {
      _moveToNextPhase();
    }
  }

  void _moveToNextPhase() {
    if (_currentPhase == InterviewPhase.analysis) {
      _currentPhase = InterviewPhase.star;
    } else if (_currentPhase == InterviewPhase.star) {
      _currentPhase = InterviewPhase.difficult;
    }

    _questionIndex = 0;
    _ariaSpeak(_currentQuestion());
  }

  void _detectImprovement(String text) {
    final improvements = {
      "hacer": ["implementar", "ejecutar", "desarrollar"],
      "cosa": ["elemento", "aspecto", "factor"],
    };

    for (final entry in improvements.entries) {
      for (final goodWord in entry.value) {
        if (text.toLowerCase().contains(goodWord)) {
          _masteredWords.add(entry.key);
          _errorFrequency.remove(entry.key);
          debugPrint("✅ Dominado: ${entry.key}");
        }
      }
    }
  }

  Future<String> _askAI(String userText) async {
    debugPrint("🤖 ENVIANDO A IA: $userText");

    try {
      final response = await http
          .post(
        Uri.parse("https://us-central1-lexiga-2b637.cloudfunctions.net/chat"), // 🔥 CAMBIAR
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userText": userText,
          "systemPrompt": systemPrompt,
        }),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint("📡 STATUS CODE: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);

        final aiText = data["response"];

        debugPrint("🧠 RESPUESTA IA: $aiText");

        return aiText;
      } else {
        throw Exception("Error backend: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Error en _askAI: $e");
      rethrow;
    }
  }

  Future<String> _askForFinalEvaluation(String userSpeech) async {
    final systemPrompt = """
Eres Aria, evaluadora experta en comunicación profesional.

Evalúa la actuación del usuario según:
- Claridad (0–10)
- Estructura (0–10)
- Léxico profesional (0–10)
${widget.documentContext != null ? "- Dominio del contenido (0–10)" : ""}

${widget.learnContext != null ? """
Además, evalúa si el usuario aplicó correctamente este concepto aprendido:
"${widget.learnContext}"

Si lo usó bien, reconócelo explícitamente.
Si no lo usó, explica cómo podría haberlo integrado mejor.
""" : ""}

Da:
1. Puntuación por criterio
2. Comentario breve por criterio
3. Una recomendación principal

Sé clara, directa y profesional.
""";

    final response = await _askAIWithPrompt(
      systemPrompt: systemPrompt,
      userText: userSpeech,
      maxTokens: 350,
    );

    return response;
  }

  Future<void> _handleFinalEvaluation(String userSpeech) async {
    final evaluation = await _askForFinalEvaluation(userSpeech);

    setState(() {
      _messages.add(ChatMessage(text: evaluation, isUser: false));
    });

    _scrollToBottom();
    await _ariaSpeak("Aquí tienes tu evaluación final.");
    await _ariaSpeak(evaluation);

    if (widget.learnContext != null && _evaluationConfirmsMastery(evaluation)) {
      await LearnProgressService.markMastered(widget.learnContext!);
    }
  }

  bool _evaluationConfirmsMastery(String evaluation) {
    final text = evaluation.toLowerCase();

    return text.contains("aplicó correctamente") ||
        text.contains("uso adecuado del concepto") ||
        text.contains("utilizó el concepto") ||
        text.contains("se evidencia el uso");
  }

  Future<String> _askAIWithPrompt({
    required String systemPrompt,
    required String userText,
    int maxTokens = 100,
  }) async {
    debugPrint("⚡ LIVE COACHING IA");

    try {
      final response = await http.post(
        Uri.parse("https://us-central1-lexiga-2b637.cloudfunctions.net/chat"), // 🔥 CAMBIAR ESTO
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "systemPrompt": systemPrompt,
          "userText": userText,
          "maxTokens": maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["response"];
      } else {
        throw Exception("Error backend: ${response.body}");
      }

    } catch (e) {
      debugPrint("❌ ERROR IA: $e");
      throw Exception("Error al conectar con la IA");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ELIMINA COMPLETAMENTE el método _toggleListening actual y REEMPLÁZALO con esto:
  void _toggleListening() {
    // Para modo presentación, usar método específico
    if (_mode == TrainingMode.presentation) {
      if (_micState == MicState.listening) {
        _finishPresentationManually();
      } else {
        _startListening();
      }
    } else {
      // Para otros modos, comportamiento normal
      if (_micState == MicState.listening) {
        _finishListening();
      } else {
        _startListening();
      }
    }
  }

  void _extractProfessionalWords(String aiText) {
    final candidates = [
      "optimizar",
      "alinear",
      "implementar",
      "gestionar",
      "estructurar",
      "priorizar",
    ];

    for (final word in candidates) {
      if (aiText.toLowerCase().contains(word)) {
        _usedProfessionalWords.add(word);
        debugPrint("📚 PALABRAS GUARDADAS: $_usedProfessionalWords");
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _speechToText.stop();
    _tts.stop();
    _presentationTimer?.cancel();

    // 🔥 Limpiar recursos de audio
    if (_isRecording) {
      _audioRecorder.stopRecording();
    }
    _audioRecorder.dispose();

    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6FF),
      appBar: AppBar(
        title: const Text("Aria"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E3A59),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildDifficultyBadge(),
          const SizedBox(height: 12),
          AnimatedAvatar(
            micState: _micState,
            guidedMode: _guidedModeActive,
            deficit: _activeDeficit,
          ),
          if (_mode == TrainingMode.presentation && _micState == MicState.listening)
            _buildPresentationTimer(),
          Divider(
            color: const Color(0xFF4A5A7A).withOpacity(0.3),
            height: 24,
          ),
          Expanded(child: _buildMessages()),
        ],
      ),
      floatingActionButton: _micState == MicState.ariaSpeaking
          ? null
          : _buildFloatingButton(),
    );
  }

  Widget _buildPresentationTimer() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            "Tiempo restante: ${_formatTime(_presentationSecondsRemaining)}",
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    if (_micState == MicState.ariaSpeaking) return const SizedBox();

    if (_mode == TrainingMode.presentation) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_micState == MicState.listening)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fiber_manual_record,
                        color: Colors.red, size: 8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "GRABANDO ${_formatTime(_presentationSecondsRemaining)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          if (_isTranscribing)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Procesando audio...",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: 220,
            height: 56,
            child: ElevatedButton.icon(
              // ✅ CORRECCIÓN AQUÍ: No usar _speechReady en modo presentación
              onPressed: !_isTranscribing
                  ? (_micState == MicState.listening
                  ? _finishPresentationManually
                  : _startListening)
                  : null,
              icon: Icon(
                _micState == MicState.listening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
              label: Text(
                _micState == MicState.listening
                    ? "Finalizar Presentación"
                    : "Comenzar Presentación",
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _micState == MicState.listening
                    ? Colors.redAccent
                    : const Color(0xFF4F6BD8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    // Para otros modos - usar _toggleListening con _speechReady
    return SizedBox(
      width: 180,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _speechReady ? _toggleListening : null,
        icon: Icon(
          _micState == MicState.listening ? Icons.stop : Icons.mic,
          color: Colors.white,
        ),
        label: Text(
          _micState == MicState.listening ? "Finalizar" : "Hablar",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _micState == MicState.listening
              ? Colors.redAccent
              : const Color(0xFF4F6BD8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _difficultyColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _difficultyColor()),
      ),
      child: Text(
        _difficultyLabel(),
        style: TextStyle(
          color: _difficultyColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: msg.isUser
                  ? Colors.indigo
                  : _guidedModeActive
                  ? Colors.indigo.shade100
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }
}