import 'package:flutter/material.dart';

class NextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? nextPage;
  final double height;
  final double borderwidth;
  final Color boxColor;
  final Color borderColor;
  final String text;
  final Color textColor;
  const NextButton({
    super.key,
    this.onPressed,
    this.nextPage,
    required this.height,
    required this.borderwidth,
    required this.boxColor,
    required this.borderColor,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width,
        height: height,
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(width: borderwidth, color: borderColor),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
