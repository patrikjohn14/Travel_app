import 'package:flutter/material.dart';

class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                });
              },
              child: SizedBox(
                height: 36, // ارتفاع ثابت لحقل البحث
                child: TextField(
                  cursorColor: const Color(0xFF008FA0),
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    isDense: true, // لتقليل الحشو الداخلي
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ), // تعديل الحشو الداخلي
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8, left: 8),
                      child: Icon(
                        Icons.search,
                        size: 22,
                        color:
                            _isFocused ? const Color(0xFF008FA0) : Colors.grey,
                      ),
                    ),
                    hintText: _isFocused ? '' : 'Search ...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color:
                            _isFocused ? const Color(0xFF008FA0) : Colors.grey,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: Color(0xFF008FA0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Settings icon
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF008FA0),
              borderRadius: BorderRadius.circular(12),
            ),
            height: 36,
            width: 36,
            child: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
