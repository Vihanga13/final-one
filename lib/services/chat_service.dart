import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  static String get apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static const endpoint = 'https://api.openai.com/v1/chat/completions';

  static Future<String> getChatResponse(String prompt) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a medical assistant helping non-infected patients with nutrition. Respond clearly and professionally."
          },
          {"role": "user", "content": prompt}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception("API error: ${response.body}");
    }
  }
}