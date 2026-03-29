// lib/screens/settings_screen.dart

import 'package:aprende_lexico/screens/privacy_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:aprende_lexico/onboarding/onboarding_controller.dart';
import 'package:aprende_lexico/auth/auth_service.dart';
import '../settings/settings_controller.dart';
import '../widget/language_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final controller = context.watch<OnboardingController>();
    final settings = context.watch<SettingsController>();
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // 📱 INFORMACIÓN DEL USUARIO
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    user?.email?[0].toUpperCase() ?? "U",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  controller.userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? "",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ⚙️ PREFERENCIAS
          _buildSection(
            title: loc.preferences,
            children: [
              _buildOption(
                icon: Icons.volume_up,
                title: loc.voiceVolume,
                subtitle: loc.adjustVoiceVolume,
                onTap: () {
                  final settings = context.read<SettingsController>();

                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      double tempVolume = settings.voiceVolume;

                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.voiceVolume,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Slider(
                                  value: tempVolume,
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 10,
                                  label: "${(tempVolume * 100).round()}%",
                                  onChanged: (value) {
                                    setState(() => tempVolume = value);
                                    settings.setVoiceVolume(value);
                                  },
                                ),
                                Text(
                                  "${(tempVolume * 100).round()}%",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),

              _buildOption(
                icon: Icons.speed,
                title: loc.voiceSpeed,
                subtitle: loc.voiceSpeedLevels,
                onTap: () {
                  final settings = context.read<SettingsController>();

                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      double tempSpeed = settings.voiceSpeed;

                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: StatefulBuilder(
                          builder: (context, setState) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  loc.voiceSpeed,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Slider(
                                  value: tempSpeed,
                                  min: 0.3,
                                  max: 1.0,
                                  divisions: 7,
                                  label: _speedLabel(context, tempSpeed),
                                  onChanged: (value) {
                                    setState(() => tempSpeed = value);
                                    settings.setVoiceSpeed(value);
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _speedLabel(context, tempSpeed),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),

              _buildOption(
                icon: Icons.language,
                title: loc.language,
                subtitle: settings.languageCode == "es"
                    ? "Español"
                    : settings.languageCode == "en"
                    ? "English"
                    : "Português",
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loc.selectLanguage,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            const LanguageSelector(),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          // 🔐 PRIVACIDAD
          _buildSection(
            title: loc.privacy,
            children: [
              _buildOption(
                icon: Icons.lock,
                title: loc.changePassword,
                onTap: () async {
                  final email = FirebaseAuth.instance.currentUser?.email;

                  if (email != null) {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(loc.passwordResetSent)),
                      );
                    }
                  }
                },
              ),
              _buildOption(
                icon: Icons.security,
                title: loc.privacySecurity,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // 🆘 SOPORTE
          _buildSection(
            title: loc.support,
            children: [
              _buildOption(
                icon: Icons.help,
                title: loc.help,
                onTap: () {},
              ),
              _buildOption(
                icon: Icons.info,
                title: loc.aboutApp,
                subtitle: "Version 1.0.0",
                onTap: () {},
              ),
            ],
          ),

          // 🚪 CERRAR SESIÓN
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(loc.logout),
                    content: Text(loc.confirmLogout),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(loc.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: Text(loc.logout),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await AuthService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/auth');
                  }
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text(
                loc.logout,
                style: const TextStyle(color: Colors.red),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade100),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  String _speedLabel(BuildContext context, double value) {
    final loc = AppLocalizations.of(context)!;

    if (value <= 0.4) return loc.slow;
    if (value <= 0.6) return loc.normal;
    if (value <= 0.8) return loc.fast;
    return loc.veryFast;
  }

  Widget _buildLanguageOption(
      BuildContext context, String label, String code) {
    final settings = context.watch<SettingsController>();
    final isSelected = settings.languageCode == code;

    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.indigo)
          : null,
      onTap: () {
        settings.setLanguage(code);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}