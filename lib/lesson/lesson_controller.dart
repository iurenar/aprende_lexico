import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lesson_state.dart';
import 'basic_conversation_lesson.dart';

class LessonController {
  LessonState state = LessonState.idle;

  final BasicConversationLesson lesson;
  final String apiKey;

  LessonController({
    required this.lesson,
    required this.apiKey,
  });

  Future<String> processUserInput(String userText) async {
    state = LessonState.analyzing;

    final response = await http.post(
      Uri.parse("https://api.deepseek.com/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "deepseek-chat",
        "messages": [
          {"role": "system", "content": lesson.systemPrompt},
          {"role": "user", "content": userText},
        ],
        "temperature": 0.7,
        "max_tokens": 300,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("DeepSeek error: ${response.body}");
    }

    final data = jsonDecode(response.body);
    final aiText = data["choices"][0]["message"]["content"];

    state = LessonState.responding;
    return aiText;
  }
}
