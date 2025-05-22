import 'package:flutter/material.dart';

Future<String?> showLocationInputDialog(BuildContext context) {
  TextEditingController locationController = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Enter Location'),
        content: TextField(
          controller: locationController,
          decoration: const InputDecoration(hintText: 'Enter city, country, etc.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(locationController.text),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
