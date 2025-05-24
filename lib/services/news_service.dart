import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news.dart';

class NewsService {
  static const String _apiKey = '5e8db1fab2fe4457abcc093f8f08b710'; // Replace with your NewsAPI key
  static const String _baseUrl = 'https://newsapi.org/v2/everything';

  Future<List<NewsArticle>> getHealthAndFitnessNews() async {
    try {      final response = await http.get(
        Uri.parse(
          '$_baseUrl?q=(fitness+workout+exercise+health+nutrition+diet+wellness)+AND+(tips+guide+benefits+research+study)&language=en&sortBy=publishedAt&pageSize=10',
        ),
        headers: {'X-Api-Key': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        return articles.map((article) => NewsArticle.fromJson(article)).toList();
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}