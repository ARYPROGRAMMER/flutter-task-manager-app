import 'dart:convert';
import 'package:http/http.dart' as http;

class MotivationalQuote {
  final String content;
  final String author;

  const MotivationalQuote({required this.content, required this.author});
}

class QuoteService {
  static const MotivationalQuote fallbackQuote = MotivationalQuote(
    content: 'Small steps every day turn plans into progress.',
    author: 'TaskFlow',
  );

  Future<MotivationalQuote> fetchQuote() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.quotable.io/random'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['content'];
        final author = data['author'];

        if (content is String && author is String) {
          return MotivationalQuote(content: content, author: author);
        }
      }

      return fallbackQuote;
    } catch (_) {
      return fallbackQuote;
    }
  }
}
