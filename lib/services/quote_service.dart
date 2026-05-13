import 'dart:convert';
import 'package:http/http.dart' as http;

class MotivationalQuote {
  final String content;
  final String author;

  const MotivationalQuote({required this.content, required this.author});
}

class QuoteService {
  static const String _geminiApiKey = 'AIzaSyDZki6ZXxyCO5WEvWcgjIsp8M6jFQO1jDY';
  static const String _geminiModel = 'gemini-2.5-flash';
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';

  static const MotivationalQuote fallbackQuote = MotivationalQuote(
    content: 'Small steps every day turn plans into progress.',
    author: 'TaskFlow',
  );

  Future<MotivationalQuote> fetchQuote() async {
    try {
      final response = await http
          .post(
            Uri.parse(_geminiEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _geminiApiKey,
            },
            body: json.encode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {
                      'text':
                          'Write one original motivational productivity quote for a task manager app. Keep it under 18 words. Return only the quote text with no quotation marks and no attribution.',
                    },
                  ],
                },
              ],
              'generationConfig': {'temperature': 0.9, 'maxOutputTokens': 40},
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final generatedText = data is Map<String, dynamic>
            ? _readGeneratedText(data)
            : '';

        if (generatedText.isNotEmpty) {
          return MotivationalQuote(content: generatedText, author: 'Gemini');
        }
      }

      return fallbackQuote;
    } catch (_) {
      return fallbackQuote;
    }
  }

  String _readGeneratedText(Map<String, dynamic> data) {
    final candidates = data['candidates'];

    if (candidates is! List || candidates.isEmpty) {
      return '';
    }

    final firstCandidate = candidates.first;

    if (firstCandidate is! Map<String, dynamic>) {
      return '';
    }

    final content = firstCandidate['content'];

    if (content is! Map<String, dynamic>) {
      return '';
    }

    final parts = content['parts'];

    if (parts is! List || parts.isEmpty) {
      return '';
    }

    final firstPart = parts.first;

    if (firstPart is! Map<String, dynamic>) {
      return '';
    }

    final text = firstPart['text'];

    if (text is! String) {
      return '';
    }

    return text
        .replaceAll(RegExp(r'^["“”]+|["“”]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
