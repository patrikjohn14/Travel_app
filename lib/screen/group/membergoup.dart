import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/screen/group/groupchat.dart';
import 'package:maps_tracker/settings.dart';

class MemberGroupsPage extends StatefulWidget {
  final int? userId;
  const MemberGroupsPage({super.key, required this.userId});

  @override
  State<MemberGroupsPage> createState() => _MemberGroupsPageState();
}

class _MemberGroupsPageState extends State<MemberGroupsPage> {
  List<dynamic> groups = [];
  bool isLoading = true;
final String apiUrl = Settings.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    fetchMemberGroups();
  }

  Future<void> fetchMemberGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/member-groups/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          groups = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load member groups');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching member groups: $e");
    }
  }

  Future<void> leaveGroup(int groupId) async {
    try {
      final url = Uri.parse('$apiUrl/api/groups/$groupId/leave');

      final request = http.Request("POST", url)
        ..headers[HttpHeaders.contentTypeHeader] = "application/json"
        ..body = jsonEncode({'userId': widget.userId});

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You left the group successfully")),
        );
        fetchMemberGroups(); // تحديث القائمة
      } else {
        print("Server response: ${response.body}");
        throw Exception('Failed to leave group');
      }
    } catch (e) {
      print("Error leaving group: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to leave group: $e')));
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
          "Groups I Joined",
          style: TextStyle(color: Color(0xFF008FA0)),
        ),
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF008FA0)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? const Center(child: Text("You haven't joined any groups."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return buildGroupCard(group);
                  },
                ),
    );
  }

  Widget buildGroupCard(dynamic group) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Groupchat(
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
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: group['image'] != null
                  ? NetworkImage('$apiUrl${group['image']}')
                  : null,
              child: group['image'] == null
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
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Leave Group"),
                    content: const Text(
                      "Are you sure you want to leave this group?",
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: const Text("Leave"),
                        onPressed: () {
                          Navigator.pop(context);
                          leaveGroup(group['id']);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
