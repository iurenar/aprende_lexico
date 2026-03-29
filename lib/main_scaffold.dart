// lib/main_scaffold.dart

import 'package:flutter/material.dart';
import 'package:aprende_lexico/home/home_screen.dart';
import 'package:aprende_lexico/screens/practice_screen.dart';
import 'package:aprende_lexico/learn/learn_screen.dart';
import 'package:aprende_lexico/screens/profile_screen.dart';
import 'package:aprende_lexico/screens/settings_screen.dart'; // 👈 IMPORTA

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  void goToLearn() {
    setState(() {
      _currentIndex = 2;
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeScreen(onLearnTap: goToLearn),
      const PracticeScreen(),
      const LearnScreen(),
      const ProfileScreen(), // 👈 PERFIL (abajo)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),

      // 🔹 APP BAR GLOBAL - CON AJUSTES ⚙️
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/lexiga/icono.png',
              width: 28,
            ),
            SizedBox(width: 10),
            Text(
              "LEXIGA",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              // 🔥 NAVEGAR A PANTALLA DE AJUSTES
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      // 🔹 CONTENIDO
      body: _pages[_currentIndex],

      // 🔹 BOTTOM NAVIGATION BAR - CON PERFIL 👤
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none),
            activeIcon: Icon(Icons.mic),
            label: "Práctica",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: "Aprender",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Perfil", // 👤 PERFIL
          ),
        ],
      ),
    );
  }
}


