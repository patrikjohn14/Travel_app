import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/screen/group/addgroup.dart';
import 'package:maps_tracker/screen/group/editgroup.dart';
import 'package:maps_tracker/screen/group/groupchat.dart';
import 'package:maps_tracker/settings.dart';

class UserGroupsPage extends StatefulWidget {
  final int? userId;
  const UserGroupsPage({super.key, required this.userId});

  @override
  State<UserGroupsPage> createState() => _UserGroupsPageState();
}

class _UserGroupsPageState extends State<UserGroupsPage> {
  List<dynamic> groups = [];
  bool isLoading = true;
  final String apiUrl = Settings.apiBaseUrl;


  @override
  void initState() {
    super.initState();
    fetchUserGroups();
  }

  Future<void> fetchUserGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/user-groups/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          groups = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load groups');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching groups: $e");
    }
  }

  Future<void> deleteGroup(int groupId) async {
    try {
      final url = Uri.parse('$apiUrl/api/groups/$groupId');

      final request =
          http.Request("DELETE", url)
            ..headers[HttpHeaders.contentTypeHeader] = "application/json"
            ..body = jsonEncode({'userId': widget.userId});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group deleted successfully")),
        );
        fetchUserGroups(); // تحديث القائمة
      } else {
        print("Server response: ${response.body}");
        throw Exception('Delete failed');
      }
    } catch (e) {
      print("Error deleting group: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete group: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 52,
        backgroundColor: Colors.white,
        title: const Text(
          "My Groups",
          style: TextStyle(color: Color(0xFF008FA0)),
        ),
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF008FA0)),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : groups.isEmpty
              ? const Center(child: Text("No groups found."))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return buildGroupCard(group);
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF008FA0),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Addgroup(userId: widget.userId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildGroupCard(dynamic group) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => Groupchat(
                  userId: widget.userId!,
                  groupId: group['id'],
                  name: group['name'],
                  description: group['description'],
                  image: group['image'],
                ),
          ),
        );
      },

      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // صورة دائرية
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  group['image'] != null
                      ? NetworkImage('$apiUrl${group['image']}')
                      : null,
              child:
                  group['image'] == null
                      ? const Icon(Icons.group, color: Colors.grey, size: 30)
                      : null,
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (group['description'] != null &&
                      group['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        group['description'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // أزرار التحكم
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EditGroupScreen(
                              userId: widget.userId,
                              groupId: group['id'],
                              name: group['name'],
                              description: group['description'],
                              imagePath: group['image'],
                            ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text("Delete Group"),
                            content: const Text(
                              "Are you sure you want to delete this group?",
                            ),
                            actions: [
                              TextButton(
                                child: const Text("Cancel"),
                                onPressed: () => Navigator.pop(context),
                              ),
                              TextButton(
                                child: const Text("Delete"),
                                onPressed: () {
                                  Navigator.pop(context);
                                  deleteGroup(group['id']);
                                },
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
