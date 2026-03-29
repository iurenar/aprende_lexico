import 'package:flutter/material.dart';
import 'package:aprende_lexico/learn/section_title.dart';
import 'package:aprende_lexico/learn/progress_card.dart';
import 'package:aprende_lexico/learn/learn_progress_services.dart';
import 'package:aprende_lexico/enums/learn_status.dart';
import 'package:aprende_lexico/learn/learn_topics_grid.dart';


class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  Map<String, LearnStatus> _progress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final data = await LearnProgressService.loadProgress();
    if (!mounted) return;

    setState(() {
      _progress = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("Aprender"),
          const SizedBox(height: 12),

          LearnTopicsGrid(
            progress: _progress,
          ),

          const SizedBox(height: 24),
          const SectionTitle("Tu progreso"),
          const SizedBox(height: 12),

          ProgressCard(progress: _progress),
        ],
      ),
    );
  }
}
