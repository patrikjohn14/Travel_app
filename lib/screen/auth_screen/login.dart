import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../settings.dart';
import '../../theme/colors.dart';
import '../../widgets/textfromfield.dart';
import '../../widgets/loginbutton.dart';
import '../home/home.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _visible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields.");
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

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Settings.apiBaseUrl}/api/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['user'] != null) {
        final userId = responseData['user']['id'];
        final firstName = responseData['user']['first_name'] ?? "User";
        final lastName = responseData['user']['last_name'] ?? "";
        final sessionId = responseData['session_id'];
        final expiresIn = responseData['expires_in'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_id', sessionId);
        await prefs.setInt('user_id', userId);
        await prefs.setString('user_email', email);
        await prefs.setInt(
          'session_expiry',
          DateTime.now()
              .add(Duration(seconds: expiresIn))
              .millisecondsSinceEpoch,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => Home(
                  currentUserId: userId,
                  firstName: firstName,
                  lastName: lastName,
                ),
          ),
        );
      } else if (response.statusCode == 404) {
        _showError("Email not found. Please check your email or sign up.");
      } else if (response.statusCode == 401) {
        _showError("Incorrect email or password. Please try again.");
      } else {
        _showError(
          responseData['message'] ?? "An error occurred. Please try again.",
        );
      }
    } catch (e) {
      print("❌ Error during login: $e");
      _showError(
        "An error occurred. Please check your internet connection and try again.",
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: TColor.white, fontSize: 16),
        ),
        backgroundColor: TColor.red,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/back.png', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: Stack(
              children: [
                // عنوان التطبيق في الأعلى
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _visible ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 130),
                      child: Transform.translate(
                        offset: _visible ? Offset.zero : Offset(0, 20),
                        child: Text(
                          "Hikely",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // نموذج تسجيل الدخول في الأسفل
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    child: Container(
                      margin: EdgeInsets.only(bottom: 20),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAnimatedField(
                            _emailController,
                            "Email",
                            FontAwesomeIcons.solidEnvelope,
                            isEmail: true,
                          ),
                          _buildAnimatedField(
                            _passwordController,
                            "Password",
                            FontAwesomeIcons.lock,
                            isPassword: true,
                          ),
                          SizedBox(height: 24),
                          _buildAnimatedButton(),
                          SizedBox(height: 30),
                          _buildSignupText(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isEmail = false,
    bool isPassword = false,
  }) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 130),
      child: Transform.translate(
        offset: _visible ? Offset.zero : Offset(0, 20),
        child: Textfromfield(
          controller: controller,
          labelText: label,
          textColor: Color(0xFF008FA0),
          obscureText: isPassword,
          fillColor: Color(0xFFD2F8FD),
          borderRadius: 25,
          iconColor: Color(0xFF008FA0),
          isEmail: isEmail,
          isPassword: isPassword,
          prefixIcon: icon,
        ),
      ),
    );
  }

  Widget _buildAnimatedButton() {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 130),
      child: Transform.translate(
        offset: _visible ? Offset.zero : Offset(0, 20),
        child: Loginbutton(
          onPressed: _isLoading ? null : _login,
          height: 46,
          boxColor1: Color(0xFF008FA0),
          boxColor2: Color(0xFF008FA0),
          borderraduis: 25,
          text: _isLoading ? "Loading..." : "Sign In",
          textColor: TColor.white,
        ),
      ),
    );
  }

  Widget _buildSignupText() {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 130),
      child: Transform.translate(
        offset: _visible ? Offset.zero : Offset(0, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            InkWell(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Text(
                "Sign up here!",
                style: TextStyle(
                  color: Color(0xFF008FA0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
