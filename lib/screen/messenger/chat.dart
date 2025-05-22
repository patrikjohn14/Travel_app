import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/screen/group/addgroup.dart';
import 'package:maps_tracker/screen/group/groupchat.dart';
import 'package:maps_tracker/screen/search/search.dart';
import 'package:maps_tracker/settings.dart';

class Chat extends StatefulWidget {
  final int? userId;
  const Chat({super.key, required this.userId});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  List<dynamic> chats = [];
  bool isLoading = true;
 final String apiUrl = Settings.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/user-chats/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          chats = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load chats');
      }
    } catch (e) {
      print('Error fetching chats: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppbar(context),
      body: _buildModernChatList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF008FA0),
        child: const Icon(Icons.edit, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Addgroup(userId: widget.userId),
            ),
          );
        },
      ),
    );
  }

  AppBar buildAppbar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 52,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Row(
        children: [
          Icon(
            FontAwesomeIcons.locationDot,
            color: const Color(0xFF008FA0),
            size: 18,
          ),
          SizedBox(width: 6),
          Text(
            "Map Tracker",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF008FA0),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Search(currentUserId: widget.userId),
              ),
            );
          },
          icon: Icon(
            FontAwesomeIcons.search,
            size: 20,
            color: Color(0xFF008FA0),
          ),
        ),
      ],
      iconTheme: IconThemeData(color: Colors.black, size: 24),
    );
  }

  Widget _buildModernChatList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008FA0)),
        ),
      );
    }

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/no_chats.png', width: 150),
            const SizedBox(height: 20),
            const Text(
              "No conversations yet",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            const Text(
              "Start a new conversation",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _buildModernChatItem(chat);
      },
    );
  }

  Widget _buildModernChatItem(dynamic chat) {
    final lastMessage = chat['message'] ?? '';
    final groupName = chat['group_name'] ?? 'New Group';
    final groupImage = chat['group_image'];
    final sentAt = _formatTime(chat['sent_at']);
    final isUnread = chat['is_unread'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildModernAvatar(groupImage),
        title: Text(
          groupName,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sentAt,
              style: TextStyle(
                color: isUnread ? const Color(0xFF008FA0) : Colors.grey,
                fontSize: 12,
              ),
            ),
            if (isUnread)
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF008FA0),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () => _navigateToGroupChat(chat, groupName, groupImage),
      ),
    );
  }

  Widget _buildModernAvatar(String? groupImage) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF008FA0), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child:
            groupImage != null
                ? CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(
                    '$apiUrl$groupImage',
                  ),
                )
                : const Icon(Icons.group, color: Colors.white, size: 28),
      ),
    );
  }

  void _navigateToGroupChat(
    dynamic chat,
    String groupName,
    String? groupImage,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Groupchat(
              userId: widget.userId!,
              groupId: chat['group_id'],
              name: groupName,
              description: null,
              image: groupImage,
            ),
      ),
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateTime);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }
}
