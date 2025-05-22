import 'dart:convert';
import 'package:flutter/foundation.dart';
class Category {
  final int id;
  final String name;
  final String description;
  final Uint8List? iconBytes;
  final Uint8List? imageBytes;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.iconBytes,
    this.imageBytes,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? 'No description available',
      iconBytes: _parseBase64(json['icon']),
      imageBytes: _parseBase64(json['image']),
    );
  }

  static Uint8List? _parseBase64(dynamic data) {
    if (data == null || data == 'null') return null;
    try {
      String base64Str = data.toString();
      if (base64Str.contains(',')) {
        base64Str = base64Str.split(',').last;
      }
      return base64Decode(base64Str.trim());
    } catch (e) {
      debugPrint('Base64 decode error: $e');
      return null;
    }
  }
}