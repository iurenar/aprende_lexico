import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aprende_lexico/onboarding/onboarding_controller.dart';
import 'package:aprende_lexico/widget/home_header.dart';
import 'package:aprende_lexico/widget/practice_card.dart';
import 'package:aprende_lexico/home/practice_mode.dart';
import 'package:aprende_lexico/presentation/last_practice_service.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';
import 'package:aprende_lexico/home/practice_mode_mapper.dart';
import 'package:aprende_lexico/learn/learn_screen.dart';
import 'package:aprende_lexico/screens/professional_screen.dart';
import '../screens/practice_screen.dart';


class HomeScreen extends StatefulWidget {
  final VoidCallback onLearnTap; // 👈 NUEVO

  const HomeScreen({
    super.key,
    required this.onLearnTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PracticeMode? _lastPractice;

  @override
  void initState() {
    super.initState();
    _loadLastPractice();
  }

  Future<void> _loadLastPractice() async {
    final last = await LastPracticeService.load();
    if (!mounted) return;
    setState(() {
      _lastPractice = last;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔹 CONTINUAR PRÁCTICA
          if (_lastPractice != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VoiceChatScreen(
                      mode: mapPracticeToTraining(_lastPractice!),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // ✅ menos padding
                margin: const EdgeInsets.only(bottom: 16), // ✅ menos margen
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(14), // ✅ radio más suave
                ),
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 18), // ✅ ícono más pequeño
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Continuar: ${_lastPractice!.title}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15, // ✅ texto más pequeño
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          /// 🔹 HEADER
          Consumer<OnboardingController>(
            builder: (context, controller, _) {
              return HomeHeader(
                userName: controller.userName,
                profession: controller.professionLabel,
                level: controller.level,
              );
            },
          ),
          const SizedBox(height: 16), // ✅ reducido de 20 a 16

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PracticeScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // ✅ menos padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14), // ✅ radio más suave
                border: Border.all(color: Colors.indigo.withOpacity(0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.grid_view, color: Colors.indigo, size: 18), // ✅ ícono más pequeño
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Ver todas las prácticas",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15, // ✅ texto más pequeño
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18), // ✅ ícono más pequeño
                ],
              ),
            ),
          ),
          const SizedBox(height: 16), // ✅ reducido de 20 a 16

          /// 🔹 TARJETA PRINCIPAL
          const PracticeCard(),

          /// 🔹 APRENDER
          Column(
            children: [
              GestureDetector(
                onTap: widget.onLearnTap, // ✅ CLAVE
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEAFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.school, color: Colors.indigo),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Aprender conceptos clave",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfessionalScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEAFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.work, color: Colors.indigo),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Habla como un profesional",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}


