import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/screen/categorie/category.dart';

import '../../settings.dart';


class ApiService {
  static Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${Settings.apiBaseUrl}/api/categories'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }
}