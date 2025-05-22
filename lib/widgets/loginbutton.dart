import 'package:flutter/material.dart';

class Loginbutton extends StatelessWidget {
  final VoidCallback? onPressed; 
  final double height;
  final Color boxColor1;
  final Color boxColor2;
  final double borderraduis;
  final String text;
  final Color textColor;

  const Loginbutton({
    super.key,
    this.onPressed, 
    required this.height,
    required this.boxColor1,
    required this.boxColor2,
    required this.borderraduis,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onPressed, 
        child: Container(
          
          alignment: Alignment.center,
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(
              width: 3,
              color: Color(0xFF008FA0)
            ),
            gradient: LinearGradient(
              colors: [
                boxColor1,
                boxColor2,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderraduis),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}