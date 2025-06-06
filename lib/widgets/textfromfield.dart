import 'package:flutter/material.dart';
import '../theme/colors.dart';

class Textfromfield extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final Color textColor;
  final Color fillColor;
  final double borderRadius;
  final Color iconColor;
  final bool obscureText;
  final bool isEmail;
  final bool isPassword;
  final IconData? prefixIcon;

  const Textfromfield({
    super.key,
    this.controller,
    required this.labelText,
    required this.textColor,
    required this.obscureText,
    required this.fillColor,
    required this.borderRadius,
    required this.iconColor,
    this.isEmail = false,
    this.isPassword = false,
    this.prefixIcon,
  });

  @override
  _TextfromfieldState createState() => _TextfromfieldState();
}

class _TextfromfieldState extends State<Textfromfield> {
  bool _isValid = true;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: widget.controller,
        obscureText:
            widget.isPassword ? !_isPasswordVisible : widget.obscureText,
        onChanged: (value) {
          _validateInput(value);
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: _isValid ? widget.fillColor : Colors.red[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: _isValid ? Color(0xFF008FA0) : TColor.red,
              width: 2,
            ),
          ),
          prefixIcon:
              widget.prefixIcon != null
                  ? Padding(
                    padding: const EdgeInsets.only(right: 8, left: 8),
                    child: Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _isValid ? widget.iconColor : TColor.red,
                    ),
                  )
                  : null,
          labelText: widget.labelText,
          labelStyle: TextStyle(
            color: _isValid ? widget.textColor : TColor.red,
          ),
          suffixIcon:
              widget.isPassword
                  ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: _isValid ? widget.iconColor : TColor.red,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                  : null,
        ),
      ),
    );
  }

  void _validateInput(String value) {
    if (widget.isEmail) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      setState(() {
        _isValid = emailRegex.hasMatch(value);
      });
    } else if (widget.isPassword) {
      setState(() {
        _isValid = value.length >= 8;
      });
    } else {
      setState(() {
        _isValid = true;
      });
    }
  }
}
