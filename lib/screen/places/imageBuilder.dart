import 'dart:convert';
import 'package:flutter/material.dart';

class ImageBuilder extends StatelessWidget {
  final String? base64Image;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ImageBuilder({
    super.key,
    required this.base64Image,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (base64Image == null || base64Image!.isEmpty) {
      return _buildErrorWidget();
    }

    try {
      final cleanBase64 = _cleanBase64String(base64Image!);
      final bytes = base64Decode(cleanBase64);
      
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: frame != null ? child : _buildPlaceholder(),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } catch (e) {
      debugPrint('Image Builder Error: $e');
      return _buildErrorWidget();
    }
  }

  String _cleanBase64String(String base64) {
    return base64
        .replaceAll(RegExp(r'^data:image/[^;]+;base64,'), '')
        .replaceAll(RegExp(r'\s+'), '');
  }

  Widget _buildPlaceholder() {
    return placeholder ?? Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.photo, color: Colors.grey),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return errorWidget ?? Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.red),
            SizedBox(height: 8),
            Text('تعذر تحميل الصورة', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}