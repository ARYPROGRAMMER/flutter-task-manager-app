import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteService {
  Future<Map<String, String>> fetchQuote() async {
    try {
      final response = await http.get(Uri.parse('https://api.quotable.io/random'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'content': data['content'] as String,
          'author': data['author'] as String,
        };
      } else {
        throw Exception('Failed to load quote: Invalid status code');
      }
    } catch (error) {
      return {
        'content': 'Stay focused and never give up. You can accomplish anything!',
        'author': 'Anonymous',
      };
    }
  }
}
