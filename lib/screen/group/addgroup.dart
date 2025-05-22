import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/settings.dart';
import '../../theme/colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class Addgroup extends StatefulWidget {
  final int? userId;
  const Addgroup({super.key, required this.userId});

  @override
  State<Addgroup> createState() => _AddgroupState();
}

class _AddgroupState extends State<Addgroup> {
  final String apiUrl = Settings.apiBaseUrl;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<bool> AddGroup({
    required int creatorId,
    required String name,
    required String description,
    required File? imageFile,
  }) async {
    final uri = Uri.parse(
      '$apiUrl/api/create-group/${widget.userId}',
    );
    final request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['description'] = description;

    if (imageFile != null) {
      final imageStream = http.MultipartFile.fromBytes(
        'image',
        await imageFile.readAsBytes(),
        filename: imageFile.path.split('/').last,
      );
      request.files.add(imageStream);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return true;
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(responseData['error'] ?? 'Erreur Create group ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildFormFields(),
              const SizedBox(height: 30),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child:
                      _imageFile != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                          : const Center(
                            child: Text(
                              "Tap to select group image",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 52,
      backgroundColor: TColor.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF008FA0),
          size: 20,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        "Create Group",
        style: TextStyle(color: Color(0xFF008FA0), fontSize: 20),
      ),
      iconTheme: const IconThemeData(color: Colors.black, size: 20),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: "Group Name",
          icon: Icons.group_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _descriptionController,
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

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF008FA0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      ),
      onPressed: () async {
        final name = _nameController.text.trim();
        final description = _descriptionController.text.trim();

        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group name is required')),
          );
          return;
        }

        try {
          final success = await AddGroup(
            creatorId: widget.userId!,
            name: name,
            description: description,
            imageFile: _imageFile,
          );
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group created successfully')),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      child: const Text(
        "Create",
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
