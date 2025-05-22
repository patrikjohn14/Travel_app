import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:maps_tracker/screen/auth_screen/login.dart';
import '../../widgets/loginbutton.dart';
import '../../theme/colors.dart';
import '../../widgets/textfromfield.dart';
import 'package:http/http.dart' as http;
import '../../settings.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool _visible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final firstName = _firstnameController.text.trim();
    final lastName = _lastnameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty) {
      _showError("Please fill in all fields.");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match.");
      return;
    }

    final nameRegex = RegExp(r'^[a-zA-Z]{4,}$');
    if (!nameRegex.hasMatch(firstName)) {
      _showError("First name must contain only letters (min 4 characters).");
      return;
    }

    if (!nameRegex.hasMatch(lastName)) {
      _showError("Last name must contain only letters (min 4 characters).");
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError("Please enter a valid email address.");
      return;
    }

    if (password.length < 8) {
      _showError("Password must be at least 8 characters long.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Settings.apiBaseUrl}/api/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _showSuccess("Registration successful! Login now.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      } else {
        _showError(responseData['message'] ?? "Registration failed.");
      }
    } catch (e) {
      _showError("Connection error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: TColor.white, fontSize: 16)),
        backgroundColor: TColor.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: TColor.white, fontSize: 16)),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        backgroundColor: TColor.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFF008FA0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          "Registration",
          style: TextStyle(
            color: Color(0xFF008FA0),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 130),
              child: Transform.translate(
                offset: _visible ? Offset.zero : Offset(0, 20),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "Let's Start Your Journey together!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: TColor.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            _buildField(_firstnameController, "First Name", FontAwesomeIcons.solidUser),
            _buildField(_lastnameController, "Last Name", FontAwesomeIcons.solidUser),
            _buildField(_emailController, "Email", FontAwesomeIcons.solidEnvelope, isEmail: true),
            _buildField(_passwordController, "Password", FontAwesomeIcons.lock, isPassword: true),
            _buildField(_confirmPasswordController, "Confirm Password", FontAwesomeIcons.lock, isPassword: true),
            SizedBox(height: 30),
            AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 130),
              child: Transform.translate(
                offset: _visible ? Offset.zero : Offset(0, 20),
                child: Loginbutton(
                  onPressed: _isLoading ? null : _register,
                  height: 46,
                  boxColor1: Colors.white,
                  boxColor2: Colors.white,
                  borderraduis: 25,
                  text: _isLoading ? "Loading..." : "Create Account",
                  textColor: Color(0xFF008FA0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      {bool isEmail = false, bool isPassword = false}) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 130),
      child: Transform.translate(
        offset: _visible ? Offset.zero : Offset(0, 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Textfromfield(
            controller: controller,
            labelText: label,
            textColor: Color(0xFF008FA0),
            obscureText: isPassword,
            fillColor: Color(0xFFD2F8FD),
            borderRadius: 6,
            iconColor: Color(0xFF008FA0),
            isEmail: isEmail,
            isPassword: isPassword,
            prefixIcon: icon,
          ),
        ),
      ),
    );
  }
}
