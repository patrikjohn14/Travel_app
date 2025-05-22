import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/settings.dart'; // تأكد من أن هذا الملف يحتوي على عنوان الـ API

class ProfileService {
  // دالة لجلب بيانات المستخدم
  static Future<Map<String, dynamic>> fetchUserData(int userId) async {
    final response = await http.get(Uri.parse('${Settings.apiBaseUrl}/users/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body); 
    } else {
      throw Exception('Failed to load user data');
    }
  }
}
