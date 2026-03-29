
import 'package:flutter/material.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';
import 'package:aprende_lexico/enums/training_mode.dart';
import 'avatars_catalog.dart';
import 'avatar_service.dart';

class AvatarCatalogScreen extends StatelessWidget {
  final TrainingMode mode;
  final String? documentContext;

  const AvatarCatalogScreen({
    super.key,
    required this.mode,
    this.documentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elige tu instructor')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: avatarsCatalog.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (_, index) {
          final avatar = avatarsCatalog[index];
          final selected =
              avatar.id == AvatarService.selectedAvatarId;

          return GestureDetector(
            onTap: () {
              AvatarService.selectedAvatarId = avatar.id;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => VoiceChatScreen(
                    mode: mode,
                    documentContext: documentContext,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? Colors.indigo : Colors.grey,
                  width: selected ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Image.asset(
                      avatar.previewImage,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    avatar.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
