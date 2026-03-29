import 'package:aprende_lexico/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aprende_lexico/onboarding/onboarding_controller.dart';
import 'package:aprende_lexico/onboarding/onboarding_flow.dart';
import 'package:aprende_lexico/main_scaffold.dart';
import 'package:aprende_lexico/screens/auth_screen.dart';
import 'package:aprende_lexico/screens/intro_screen.dart';
import 'enums/profession.dart';
import "package:flutter_localizations/flutter_localizations.dart";
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => OnboardingController(),
        ),

        ChangeNotifierProvider(
          create: (_) {
            final controller = SettingsController();
            controller.loadSettings();
            return controller;
          },
        ),
      ],
      child: const LexiaApp(),
    ),
  );
}

class LexiaApp extends StatelessWidget {
  const LexiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'LEXIGA',
          debugShowCheckedModeBanner: false,

          // 🌎 idioma dinámico
          locale: settings.locale,

          supportedLocales: const [
            Locale('es'),
            Locale('en'),
          ],

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          theme: ThemeData(
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: Colors.white,
          ),

          routes: {
            '/intro': (context) => const IntroScreen(),
            '/auth': (context) => const AuthScreen(),
            '/onboarding': (context) => const OnboardingFlow(),
            '/main': (context) => const MainScaffold(),
          },

          home: const AppStartup(),
        );
      },
    );
  }
}

////////////////////////////////////////////////////////////
/// 1️⃣ CONTROLADOR DE INICIO (INTRO)
////////////////////////////////////////////////////////////

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool? _seenIntro;

  @override
  void initState() {
    super.initState();
    _checkIntro();
  }

  Future<void> _checkIntro() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_intro') ?? false;
    setState(() => _seenIntro = seen);
  }

  @override
  Widget build(BuildContext context) {
    if (_seenIntro == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_seenIntro!) {
      return const IntroScreen();
    }
    return const AuthGate();
  }
}

////////////////////////////////////////////////////////////
/// 2️⃣ CONTROLADOR DE AUTENTICACIÓN
////////////////////////////////////////////////////////////

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const AuthScreen();
        }

        final user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              final hasProfession = userData?['profession'] != null;

              if (hasProfession) {
                // 👇 ACTUALIZAR ONBOARDING CONTROLLER (clave del original)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final controller = context.read<OnboardingController>();

                  // Cargar profesión guardada
                  for (var p in Profession.values) {
                    if (p.name == userData?['profession']) {
                      controller.setProfessionFromSaved(p);
                      break;
                    }
                  }

                  // Cargar nombre si existe
                  if (userData?['name'] != null) {
                    controller.onAuthenticated(
                      email: user.email ?? '',
                      name: userData?['name'],
                      isGoogle: userData?['isGoogleUser'] ?? false,
                    );
                  }
                });

                return const MainScaffold();
              }
            }

            // Actualizar controller para nuevos usuarios
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final controller = context.read<OnboardingController>();
              controller.onAuthenticated(
                email: user.email ?? '',
                name: user.displayName,
                isGoogle: user.providerData.any((info) => info.providerId == 'google.com'),
              );
            });

            return const OnboardingFlow();
          },
        );
      },
    );
  }
}

