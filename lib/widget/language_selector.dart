import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/settings_controller.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _languageTile(
          context,
          flag: "🇪🇸",
          label: "Español",
          code: "es",
          isSelected: settings.languageCode == "es",
        ),
        _languageTile(
          context,
          flag: "🇺🇸",
          label: "English",
          code: "en",
          isSelected: settings.languageCode == "en",
        ),
        _languageTile(
          context,
          flag: "🇧🇷",
          label: "Português",
          code: "pt",
          isSelected: settings.languageCode == "pt",
        ),
      ],
    );
  }

  Widget _languageTile(
      BuildContext context, {
        required String flag,
        required String label,
        required String code,
        required bool isSelected,
      }) {
    final settings = context.read<SettingsController>();

    return ListTile(
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(label),
      trailing:
      isSelected ? const Icon(Icons.check, color: Colors.indigo) : null,
      onTap: () {
        settings.setLanguage(code);
        Navigator.pop(context);
      },
    );
  }
}