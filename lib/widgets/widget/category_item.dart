import 'dart:convert';

import 'package:flutter/material.dart';
import '../../theme/color.dart';

class CategoryItem extends StatelessWidget {
  const CategoryItem({
    super.key,
    required this.data,
    this.onTap,
    this.color = primary,
  });
  
  final Map<String, dynamic> data;
  final Color color;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.only(right: 10),
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.1),
              spreadRadius: .5,
              blurRadius: .5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // استخدام صورة الفئة بدلاً من الأيقونة
            if (data["image"] != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: MemoryImage(
                      base64Decode(data["image"].split(',')[1]),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(.2)
                ),
                child: Icon(Icons.category, size: 25, color: color),
              ),
            SizedBox(height: 5),
            Expanded(
              child: Text(
                data["name"] ?? "Category",
                maxLines: 1, 
                overflow: TextOverflow.ellipsis, 
                style: TextStyle(fontSize: 13, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}