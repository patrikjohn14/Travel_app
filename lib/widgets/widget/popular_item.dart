import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PopularItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final double radius;
  final GestureTapCallback? onTap;

  const PopularItem({
    super.key,
    required this.data,
    this.radius = 16.0,
    this.onTap,
  });

  Widget _buildPlaceImage(String? imageBase64) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child:
            imageBase64 != null
                ? Image.memory(base64Decode(imageBase64), fit: BoxFit.cover)
                : const Center(
                  child: Icon(Icons.photo_camera, color: Colors.grey),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String country = data["country"] ?? "Unknown Country";
    final String province = data["province"] ?? "Unknown Province";
    final String? imageBase64 = data["image_picture"];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image container
            _buildPlaceImage(imageBase64),
            // Gradient overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
            // Text and Icon information
            Positioned(
              bottom: 16,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Text
                  Text(
                    data["name"] ?? "Unknown Name",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location Row
                  Row(
                    children: [
                      SvgPicture.asset(
                        "assets/icons/marker.svg",
                        width: 18,
                        height: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data["location"] ?? "Unknown Location",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Country and Province Text
                  Text(
                    "Country: $country",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Province: $province",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
