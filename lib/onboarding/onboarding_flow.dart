// lib/onboarding/onboarding_flow.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aprende_lexico/onboarding/onboarding_controller.dart';
import 'package:aprende_lexico/onboarding/onboarding_state.dart';
import 'package:aprende_lexico/screens/intro_screen.dart';
import 'package:aprende_lexico/screens/profession_screen.dart';
import 'package:aprende_lexico/screens/profile_screen.dart';


class OnboardingFlow extends StatelessWidget {
  const OnboardingFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingController>(
      builder: (context, controller, child) {
        final step = controller.state.step;

        print("🎯 OnboardingFlow - Paso actual: $step");

        switch (step) {
          case OnboardingStep.intro:
            return const IntroScreen(); // 👈 AHORA SÍ FUNCIONA

          case OnboardingStep.auth:
          // Ya autenticado, mostrar loading
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          case OnboardingStep.profession:
            return const ProfessionScreen();

          case OnboardingStep.profile:
            return const ProfileScreen();

          case OnboardingStep.completed:
          // Ir a Home
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/main');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
        }
      },
    );
  }
}
