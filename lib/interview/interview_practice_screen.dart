import 'package:flutter/material.dart';
import 'interview_steps.dart';
import 'package:aprende_lexico/enums/training_mode.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';

class InterviewPracticeScreen extends StatefulWidget {
  const InterviewPracticeScreen({super.key});

  @override
  State<InterviewPracticeScreen> createState() =>
      _InterviewPracticeScreenState();
}

class _InterviewPracticeScreenState extends State<InterviewPracticeScreen> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _startInterview();
  }

  void _startInterview() async {
    await _ariaSpeak(
      "Vamos a simular una entrevista laboral profesional. "
          "Responde con claridad y estructura. Empezamos.",
    );
    await _ariaSpeak(interviewSteps[_currentStep].question);
  }

  Future<void> _ariaSpeak(String text) async {
    // 🔊 AQUÍ conectas tu TTS real
    debugPrint("ARIA: $text");
  }

  void _nextStep() async {
    if (_currentStep < interviewSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      await _ariaSpeak(interviewSteps[_currentStep].question);
    } else {
      await _ariaSpeak(
        "Has finalizado la entrevista. A continuación recibirás una evaluación global.",
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VoiceChatScreen(
            mode: TrainingMode.interview,
            learnContext: "Evaluación final de entrevista laboral",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = interviewSteps[_currentStep];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Entrevista laboral"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // FASE
            Text(
              step.phase,
              style: TextStyle(
                color: Colors.indigo.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // PROGRESO
            Text(
              "Pregunta ${_currentStep + 1} de ${interviewSteps.length}",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            // PREGUNTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                step.question,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(),

            // BOTÓN MIC (placeholder)
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text("Responder"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceChatScreen(
                      mode: TrainingMode.interview,
                      learnContext: step.question, // 👈 CONTEXTO
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // SIGUIENTE
            TextButton(
              onPressed: _nextStep,
              child: const Text("Siguiente pregunta"),
            ),
          ],
        ),
      ),
    );
  }
}
