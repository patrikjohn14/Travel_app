import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../settings.dart';

class AboutGroupScreen extends StatefulWidget {
  final int groupId;
  final String name;
  final String? description;
  final String? image;
  final int? userId;

  const AboutGroupScreen({
    super.key,
    required this.groupId,
    required this.name,
    this.description,
    this.image,
    required this.userId,
  });

  @override
  State<AboutGroupScreen> createState() => _AboutGroupScreenState();
}

class _AboutGroupScreenState extends State<AboutGroupScreen> {
  bool isLoadingCreator = true;
  bool isLoadingMembers = false;
  bool isLoadingFriends = false;
  int? groupCreatorId;
  bool isAdmin = false;
  List<dynamic> membersList = [];
  List<dynamic> friendsList = [];
  final String apiUrl = Settings.apiBaseUrl;


  @override
  void initState() {
    super.initState();
    fetchCreatorId();
  }

  Future<void> fetchCreatorId() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Settings.apiBaseUrl}/api/groups/${widget.groupId}/creator',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          groupCreatorId = data['creatorId'];
          isAdmin = (widget.userId == groupCreatorId);
          fetchGroupMembers();
        } else {
          throw Exception('Failed to fetch creatorId');
        }
      } else {
        throw Exception('Failed to fetch creatorId: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching creatorId: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoadingCreator = false);
    }
  }

  Future<void> fetchGroupMembers() async {
    setState(() => isLoadingMembers = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${Settings.apiBaseUrl}/api/groups/${widget.groupId}/members',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            membersList = data['data'] as List<dynamic>;
            isLoadingMembers = false;
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load group members');
      }
    } catch (e) {
      setState(() => isLoadingMembers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching members: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchFriends() async {
    setState(() => isLoadingFriends = true);
    try {
      final response = await http.get(
        Uri.parse('${Settings.apiBaseUrl}/api/friends/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            friendsList = data['data'] as List<dynamic>;
            isLoadingFriends = false;
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to load friends');
      }
    } catch (e) {
      setState(() => isLoadingFriends = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching friends: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> addMemberToGroup(int friendUserId) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${Settings.apiBaseUrl}/api/groups/${widget.groupId}/add-member/$friendUserId',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        fetchGroupMembers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add member'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> removeMemberFromGroup(int memberId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${Settings.apiBaseUrl}/api/groups/${widget.groupId}/remove-member/$memberId',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'adminId': widget.userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        fetchGroupMembers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${data['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove member'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showRemoveMemberDialog(int memberId, String memberName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove $memberName from the group?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  removeMemberFromGroup(memberId);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void showFriendsPopup() async {
    await fetchFriends();
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Friends to Group',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Friends List
                  Expanded(
                    child:
                        isLoadingFriends
                            ? const Center(child: CircularProgressIndicator())
                            : friendsList.isEmpty
                            ? const Center(child: Text('No friends available'))
                            : ListView.builder(
                              itemCount: friendsList.length,
                              itemBuilder: (context, index) {
                                final friend = friendsList[index];
                                final fullName =
                                    '${friend['first_name'] ?? ''} ${friend['last_name'] ?? ''}';
                                final isMember = membersList.any(
                                  (member) => member['id'] == friend['id'],
                                );

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 1,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          friend['profile_picture'] != null
                                              ? NetworkImage(
                                                '$apiUrl${friend['profile_picture']}',
                                              )
                                              : null,
                                      backgroundColor: Colors.grey[200],
                                      child:
                                          friend['profile_picture'] == null
                                              ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                    title: Text(
                                      fullName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      '@${friend['bio'] ?? ''}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing:
                                        isMember
                                            ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.green,
                                                ),
                                              ),
                                              child: const Text(
                                                'Member',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            )
                                            : IconButton(
                                              icon: const Icon(Icons.add),
                                              color: Colors.blue,
                                              onPressed:
                                                  () => addMemberToGroup(
                                                    friend['id'],
                                                  ),
                                            ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingCreator) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[50],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child:
                          widget.image != null
                              ? ClipOval(
                                child: Image.network(
                                  '$apiUrl${widget.image}',
                                  fit: BoxFit.cover,
                                ),
                              )
                              : const Icon(
                                Icons.group,
                                size: 40,
                                color: Colors.blue,
                              ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                      ),
                    ),
                    if (widget.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          widget.description!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${membersList.length} members',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          const Text(
                            'Admin',
                            style: TextStyle(color: Colors.amber, fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Members Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Group Members',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.black),
                  ),
                  if (isAdmin)
                    GestureDetector(
                      onTap: showFriendsPopup,
                      child: const Row(
                        children: [
                          Icon(Icons.person_add, size: 20, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(color: Colors.blue, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Members List
            Expanded(
              child:
                  isLoadingMembers
                      ? const Center(child: CircularProgressIndicator())
                      : membersList.isEmpty
                      ? const Center(child: Text('No members yet',
                       style: TextStyle(
                        color: Colors.black
                       ),
                      ))
                      : ListView.builder(
                        itemCount: membersList.length,
                        itemBuilder: (context, index) {
                          final member = membersList[index];
                          final fullName =
                              '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}';
                          final isCurrentUser = member['id'] == widget.userId;
                          final isCreator = member['id'] == groupCreatorId;

                          return Dismissible(
                            key: Key(member['id'].toString()),
                            direction:
                                isAdmin && !isCurrentUser && !isCreator
                                    ? DismissDirection.endToStart
                                    : DismissDirection.none,
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (isAdmin && !isCurrentUser && !isCreator) {
                                showRemoveMemberDialog(member['id'], fullName);
                                return false;
                              }
                              return false;
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      member['profile_picture'] != null
                                          ? NetworkImage(
                                            '$apiUrl${member['profile_picture']}',
                                          )
                                          : null,
                                  backgroundColor: Colors.grey[200],
                                  child:
                                      member['profile_picture'] == null
                                          ? const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          )
                                          : null,
                                ),
                                title: Text(
                                  fullName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  '@${member['bio'] ?? ''}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing:
                                    isCreator
                                        ? Tooltip(
                                          message: 'Group Creator',
                                          child: const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                        )
                                        : isCurrentUser
                                        ? Tooltip(
                                          message: 'You',
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.blue,
                                              ),
                                            ),
                                            child: const Text(
                                              'You',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        )
                                        : null,
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: const Text('Group Info', style: TextStyle(color: Colors.black)),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: fetchGroupMembers,
        ),
      ],
    );
  }
}
