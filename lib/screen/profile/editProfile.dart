import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:maps_tracker/settings.dart';
class EditProfileScreen extends StatefulWidget {
  final int? UserId;
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
    required this.UserId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers for text fields
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _bioController;
 final String apiUrl = Settings.apiBaseUrl;

  // Image handling variables
  String? _profileImageBase64;
  final bool _isImageLoading = false;

  // General loading state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    _firstNameController = TextEditingController(
      text: widget.userData['user']['first_name'],
    );
    _lastNameController = TextEditingController(
      text: widget.userData['user']['last_name'],
    );
    _bioController = TextEditingController(
      text: widget.userData['user']['bio'],
    );
    // فقط إذا كانت صورة محفوظة كـ Base64
    final profilePic = widget.userData['user']['profile_picture'];
    if (profilePic != null && profilePic.toString().startsWith('/assets/')) {
      _profileImageBase64 = null;
    } else {
      _profileImageBase64 = profilePic;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();

        try {
          final image = await decodeImageFromList(bytes);
          print('Image dimensions: ${image.width}x${image.height}');

          setState(() {
            _profileImageBase64 = base64Encode(bytes);
          });
        } catch (e) {
          print('Error decoding image: $e');
          _showErrorSnackbar('Invalid image file selected.');
        }
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Failed to pick image: ${e.toString()}');
      _showErrorSnackbar('Failed to pick image.');
    }
  }

  Future<void> _saveProfile() async {
    final isConnected = await _checkInternetConnection();
    if (!isConnected) {
      _showErrorSnackbar('No internet connection. Please try again.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse('$apiUrl/api/users/${widget.UserId}');
      final request = http.MultipartRequest('PUT', uri);

      // الحقول النصية
      request.fields['first_name'] = _firstNameController.text.trim();
      request.fields['last_name'] = _lastNameController.text.trim();
      request.fields['bio'] = _bioController.text.trim();

      // إذا تم اختيار صورة
      if (_profileImageBase64 != null) {
        final bytes = base64Decode(_profileImageBase64!);
        final multipartFile = http.MultipartFile.fromBytes(
          'profile_picture',
          bytes,
          filename: 'profile_${widget.UserId}.jpg',
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          _showSuccessSnackbar('Profile updated successfully!');
          if (mounted) Navigator.pop(context, true);
        } else {
          _showErrorSnackbar(
            responseData['message'] ?? 'Failed to update profile',
          );
        }
      } else {
        _showErrorSnackbar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Unexpected error: $e');
      _showErrorSnackbar('An error occurred while updating profile.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final response = await http.get(Uri.parse('https://www.google.com'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileImage(),
            const SizedBox(height: 32),
            _buildFormFields(),
            const SizedBox(height: 40),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 52,
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.grey.withOpacity(0.1),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: const Color(0xFF008FA0),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Edit Profile",
        style: TextStyle(
          color: Color(0xFF008FA0),
          fontSize: 20,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF008FA0).withOpacity(0.2),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child:
                _isImageLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF008FA0)),
                      ),
                    )
                    : _profileImageBase64 != null
                    ? ClipOval(
                      child: Material(
                        color: Colors.transparent,
                        child: Ink.image(
                          image: MemoryImage(
                            base64Decode(_profileImageBase64!),
                          ),
                          fit: BoxFit.cover,
                          width: 130,
                          height: 130,
                        ),
                      ),
                    )
                    : CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[100],
                      child: Icon(
                        Icons.person,
                        size: 70,
                        color: Colors.grey[400],
                      ),
                    ),
          ),
          if (!_isImageLoading)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008FA0),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: "First Name",
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _lastNameController,
          label: "Last Name",
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _bioController,
          label: "Bio",
          icon: Icons.info_outline,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF008FA0), size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF008FA0), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile, // إرسال البيانات عند الضغط
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008FA0), // لون الخلفية
          padding: const EdgeInsets.symmetric(vertical: 16), // الحشو الداخلي
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // زوايا دائرية
          ),
        ),
        child:
            _isSaving
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, // سماكة المؤشر
                    color: Colors.white, // لون المؤشر
                  ),
                )
                : const Text(
                  "SAVE CHANGES",
                  style: TextStyle(
                    color: Colors.white, // لون النص
                    fontSize: 16, // حجم النص
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
      ),
    );
  }
}
