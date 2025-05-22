import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/settings.dart';

class EditGroupScreen extends StatefulWidget {
  final int? userId;
  final int groupId;
  final String name;
  final String? description;
  final String? imagePath;

  const EditGroupScreen({
    super.key,
    required this.userId,
    required this.groupId,
    required this.name,
    this.description,
    this.imagePath,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
 final String apiUrl = Settings.apiBaseUrl;

  File? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _descriptionController = TextEditingController(
      text: widget.description ?? '',
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedImage = File(result.files.single.path!);
      });
    }
  }

  Future<void> _updateGroup() async {
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final userId = widget.userId.toString();

      final uri = Uri.parse(
        '$apiUrl/api/groups/${widget.groupId}',
      );
      final request = http.MultipartRequest('PUT', uri);

      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['userId'] = userId;

      if (_pickedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _pickedImage!.path),
        );
      }

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated successfully')),
        );
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body);
        _showErrorSnackbar(data['error'] ?? 'Failed to update group');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (widget.imagePath != null
                                  ? NetworkImage(
                                    '$apiUrl${widget.imagePath!}',
                                  )
                                  : null)
                              as ImageProvider<Object>?,
                  child:
                      widget.imagePath == null && _pickedImage == null
                          ? const Icon(
                            Icons.group,
                            size: 40,
                            color: Colors.grey,
                          )
                          : null,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _pickImage,
                  color: const Color(0xFF008FA0),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF008FA0),
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildTextField(_nameController, 'Group Name', Icons.group),
            const SizedBox(height: 20),
            _buildTextField(
              _descriptionController,
              'Description',
              Icons.description,
              maxLines: 4,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008FA0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSaving
                        ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                        : const Text(
                          "SAVE CHANGES",
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        'Edit Group',
        style: TextStyle(color: Color(0xFF008FA0)),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF008FA0)),
      backgroundColor: Colors.white,
      elevation: 1,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF008FA0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF008FA0), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
