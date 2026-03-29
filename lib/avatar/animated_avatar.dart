import 'package:flutter/material.dart';
import '../avatar/avatars_catalog.dart';
import '../avatar/avatar_service.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';

class AnimatedAvatar extends StatelessWidget {
  final MicState micState;
  final bool guidedMode;
  final LexicalDeficitType? deficit;

  const AnimatedAvatar({
    super.key,
    required this.micState,
    required this.guidedMode,
    required this.deficit,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = avatarsCatalog.firstWhere(
          (a) => a.id == AvatarService.selectedAvatarId,
    );

    double scale = 1.0;

    if (micState == MicState.ariaSpeaking) {
      scale = 1.1;
    } else if (micState == MicState.listening) {
      scale = 1.05;
    }

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 250),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: guidedMode
              ? [
            BoxShadow(
              color: _deficitColor(deficit).withOpacity(0.6),
              blurRadius: 25,
              spreadRadius: 6,
            )
          ]
              : [],
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundImage: AssetImage(avatar.previewImage),
        ),
      ),
    );
  }

  // 🎨 Color según déficit REAL
  Color _deficitColor(LexicalDeficitType? d) {
    switch (d) {
      case LexicalDeficitType.vagueVerbs:
        return Colors.indigo;

      case LexicalDeficitType.genericNouns:
        return Colors.orange;

      case LexicalDeficitType.weakStructure:
        return Colors.redAccent;

      case LexicalDeficitType.lackOfConnectors:
        return Colors.teal;

      default:
        return Colors.indigo;
    }
  }
}

