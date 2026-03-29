import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.privacySecurity),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "Aquí puedes explicar cómo se manejan los datos del usuario.",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}