import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:maps_tracker/screen/profile/profile.dart';
import 'package:maps_tracker/settings.dart';

import '../../theme/colors.dart';



class Search extends StatefulWidget {
  final int? currentUserId;

  const Search({super.key, required this.currentUserId});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer<String> _debouncer = Debouncer(
    const Duration(milliseconds: 500),
    initialValue: '',
  );
  late final http.Client _httpClient;
  List<Map<String, dynamic>> users = [];
  bool isLoading = false;
  bool hasError = false;
  final String apiUrl = Settings.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
    _setupDebouncer();
  }

  void _setupDebouncer() {
    _debouncer.values.listen((query) {
      if (query.trim().isEmpty) {
        setState(() {
          users = [];
        });
      } else {
        _fetchUsers(query); 
      }
    });
  }

  Future<void> _fetchUsers(String query) async {
    if (!mounted || query.trim().isEmpty) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final uri = Uri.parse(
        '$apiUrl/api/users/search/${widget.currentUserId}',
      ).replace(queryParameters: {'query': query});

      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map &&
            data['data'] is Map &&
            data['data']['users'] is List) {
          final List<dynamic> nestedUsers = data['data']['users'][0] ?? [];
          setState(() {
            users = List<Map<String, dynamic>>.from(nestedUsers);
          });
        } else {
          throw Exception('Unexpected data format: $data');
        }
      } else {
        setState(() {
          hasError = true;
          users = [];
        });
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          users = [];
        });
        print('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _httpClient.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body: Column(
        children: [_buildSearchField(), Expanded(child: _buildResults())],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onChanged: (value) => _debouncer.value = value,
      ),
    );
  }

  Widget _buildResults() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Text(
          'Failed to load users',
          style: TextStyle(color: Colors.red.shade600),
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Start typing to search users'
              : 'No users found',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => Profile(
                      currentUserId: widget.currentUserId,
                      userId: user['id'],
                    ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(child: Text(user['first_name']?[0] ?? '?')),
              title: Text('${user['first_name']} ${user['last_name']}'),
              subtitle: Text(user['bio'] ?? ''),
            ),
          ),
        );
      },
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
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF008FA0),
          size: 20,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        "Search",
        style: TextStyle(color: Color(0xFF008FA0), fontSize: 20),
      ),
      actions: [],
      iconTheme: IconThemeData(color: TColor.black, size: 20),
    );
  }
}

class UserDetailPage extends StatelessWidget {
  final int userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Center(child: Text('Details for user with ID: $userId')),
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
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF008FA0),
          size: 20,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        "User Details",
        style: TextStyle(color: Color(0xFF008FA0), fontSize: 20),
      ),
      actions: [],
      iconTheme: IconThemeData(color: TColor.black, size: 20),
    );
  }
}
