// lib/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aprende_lexico/screens/auth_screen.dart';
import 'package:aprende_lexico/onboarding/onboarding_controller.dart';
import 'package:aprende_lexico/onboarding/onboarding_flow.dart';
import 'package:aprende_lexico/main_scaffold.dart';
import 'package:aprende_lexico/enums/profession.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Estado de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 🔴 USUARIO NO AUTENTICADO → AuthScreen
        if (!snapshot.hasData || snapshot.data == null) {
          print("🔴 Usuario NO autenticado → AuthScreen");
          return const AuthScreen();
        }

        // 🟢 USUARIO AUTENTICADO
        final user = snapshot.data!;
        print("🟢 Usuario autenticado: ${user.email}");

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            // Estado de carga de Firestore
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Verificar si el usuario existe en Firestore y tiene profesión
            final hasCompletedOnboarding = userSnapshot.hasData &&
                userSnapshot.data!.exists &&
                (userSnapshot.data!.data() as Map<String, dynamic>?)?['profession'] != null;

            if (hasCompletedOnboarding) {
              // ✅ USUARIO CON ONBOARDING COMPLETO → HOME (MainScaffold)
              print("✅ Usuario con onboarding completo → MainScaffold");

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;

              // Actualizar controller con datos guardados
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final controller = context.read<OnboardingController>();

                // Autenticar con datos básicos
                controller.onAuthenticated(
                  email: user.email ?? '',
                  name: userData['name'] ?? user.displayName ?? 'Usuario',
                  isGoogle: userData['isGoogleUser'] ??
                      user.providerData.any((info) => info.providerId == 'google.com'),
                );

                // Cargar profesión guardada
                if (userData['profession'] != null) {
                  final professionString = userData['profession'] as String;

                  for (var p in Profession.values) {
                    if (p.name == professionString) {
                      controller.setProfessionFromSaved(p);
                      break;
                    }
                  }
                }
              });

              return const MainScaffold();
            } else {
              // 🔄 USUARIO NUEVO O SIN ONBOARDING COMPLETO
              print("🔄 Usuario sin onboarding completo → Iniciar desde Intro");

              // Configurar controller para empezar desde INTRO
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final controller = context.read<OnboardingController>();

                // Primero autenticar (esto pone el paso en profession por defecto)
                controller.onAuthenticated(
                  email: user.email ?? '',
                  name: user.displayName,
                  isGoogle: user.providerData.any(
                          (info) => info.providerId == 'google.com'
                  ),
                );

                // 🔥 RESETEAR A INTRO PARA QUE VEA LA PANTALLA DE INTRODUCCIÓN
                controller.resetToIntro();
              });

              return const OnboardingFlow();
            }
          },
        );
      },
    );
  }
}