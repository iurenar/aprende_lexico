import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF6FF), // celeste muy claro
              Color(0xFFDDE6FF), // azul-lila suave
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🐱 LOGO
                Image.asset(
                  'assets/lexiga/logo 2.png',
                  width: 140,
                ),

                const SizedBox(height: 32),

                // 🧠 TÍTULO
                const Text(
                  "Soy Lexiga",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3A59),
                  ),
                ),

                const SizedBox(height: 12),

                // ✨ SUBTÍTULO
                const Text(
                  "Te ayudo a mejorar tu léxico profesional\nhablando contigo.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4A5A7A),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 48),

                // ▶ BOTÓN
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F6BD8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('seen_intro', true);

                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/auth');
                      }
                    },
                    child: const Text(
                      "Comenzar",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
