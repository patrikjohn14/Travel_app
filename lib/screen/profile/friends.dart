import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:maps_tracker/settings.dart';
class Friends extends StatefulWidget {
  final int? currentUserId;
  const Friends({super.key, required this.currentUserId});

  @override
  State<Friends> createState() => _FriendsState();
}

class _FriendsState extends State<Friends> {
  List<dynamic> friendsList = [];
  bool isLoading = true;
  final String apiUrl = Settings.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    if (widget.currentUserId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/friends/${widget.currentUserId}'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            friendsList =
                responseData['data'] is List
                    ? responseData['data']
                    : []; // Ensure we're getting a List
            isLoading = false;
          });
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load friends');
        }
      } else {
        throw Exception('Failed to load friends: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      debugPrint('Error details: $e');
    }
  }

  Future<void> deleteFriend(int friendId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '$apiUrl/api/friends/${widget.currentUserId}/$friendId',
        ),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Friend deleted successfully',
            ),
          ),
        );
        setState(() {
          friendsList =
              friendsList.where((friend) => friend['id'] != friendId).toList();
        });
      } else {
        throw Exception(responseData['error'] ?? 'Failed to delete friend');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
      debugPrint('Error details: $e');
    }
  }

  void _showDeleteConfirmation(int friendId, String friendName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Friend', style: TextStyle(color: Colors.black)),
            content: Text(
              'Are you sure you want to remove $friendName from your friends?',
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  deleteFriend(friendId);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(context),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(color: Color(0xFF008FA0)),
              )
              : friendsList.isEmpty
              ? Center(
                child: Text(
                  'No friends found',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: friendsList.length,
                itemBuilder: (context, index) {
                  final friend = friendsList[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            friend['profile_picture'] != null
                                ? NetworkImage('$apiUrl${friend['profile_picture']}')
                                : null,
                        child:
                            friend['profile_picture'] == null
                                ? Icon(Icons.person, size: 28)
                                : null,
                      ),
                      title: Text(
                        '${friend['first_name']} ${friend['last_name']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '@${friend['username'] ?? '${friend['first_name']}${friend['last_name']}'}',
                        style: TextStyle(color: Colors.grey),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            () => _showDeleteConfirmation(
                              friend['id'],
                              '${friend['first_name']} ${friend['last_name']}',
                            ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      backgroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF008FA0),
          size: 24,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        "Friends",
        style: TextStyle(color: Color(0xFF008FA0), fontSize: 22),
      ),
      iconTheme: IconThemeData(color: Colors.black, size: 24),
    );
  }
}
