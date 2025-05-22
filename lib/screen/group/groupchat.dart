import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/screen/group/aboutgroup.dart';
import 'package:maps_tracker/settings.dart';

class Groupchat extends StatefulWidget {
  final int? userId;
  final int groupId;
  final String name;
  final String? description;
  final String? image;

  const Groupchat({
    super.key,
    required this.userId,
    required this.groupId,
    required this.name,
    this.description,
    this.image,
  });

  @override
  State<Groupchat> createState() => _GroupchatState();
}

class _GroupchatState extends State<Groupchat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  final String apiUrl = Settings.apiBaseUrl;

  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/groups/${widget.groupId}/messages'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = data['data'] ?? [];
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.minScrollExtent,
            );
          }
        });
      } else {
        throw Exception('Failed to load messages (${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() => isLoading = false);
      showError('Error fetching messages: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (isSending || text.trim().isEmpty) return;
    setState(() => isSending = true);

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/groups/${widget.groupId}/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId, 'content': text}),
      );

      if (response.statusCode == 200) {
        _messageController.clear();
        await fetchMessages();
      } else {
        throw Exception('Failed to send message: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error sending message: $e');
      showError('Error sending message: $e');
    } finally {
      setState(() => isSending = false);
    }
  }

  void showError(String error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
  }

  Widget buildMessageBubble(dynamic msg) {
    final isMine = msg['sender_id'] == widget.userId;
    final messageContent = msg['message'] ?? '';
    final createdAt = _formatTime(msg['sent_at']);
    final profileImage = msg['profile_picture'];
    final senderName =
        "${msg['first_name'] ?? ''} ${msg['last_name'] ?? ''}".trim();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                        profileImage != null
                            ? NetworkImage('$apiUrl$profileImage')
                            : null,
                    child:
                        profileImage == null
                            ? const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    senderName.isEmpty ? "Unknown" : senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color:
                    isMine ? const Color(0xFF008FA0) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    messageContent,
                    style: TextStyle(
                      color: isMine ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    createdAt,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(dateTime);
      if (dt == null) return '';
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }

  Widget buildAppBarTitle() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AboutGroupScreen(
                  groupId: widget.groupId,
                  name: widget.name,
                  description: widget.description,
                  image: widget.image,
                  userId: widget.userId,
                ),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                widget.image != null
                    ? NetworkImage('$apiUrl${widget.image!}')
                    : null,
            child:
                widget.image == null
                    ? const Icon(Icons.group, size: 22, color: Colors.grey)
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (widget.description != null)
                  Text(
                    widget.description!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          Text(
            "Start the conversation!",
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey[600]),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: const Color(0xFFF0F2F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                minLines: 1,
                maxLines: 5,
                onChanged: (text) {
                  setState(() {}); // لتحديث الزر
                },
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.mic, color: Colors.grey[600]),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  _messageController.text.trim().isNotEmpty
                      ? const Color(0xFF008FA0)
                      : Colors.grey[300],
              child: IconButton(
                icon: Icon(
                  isSending ? Icons.hourglass_top : Icons.send,
                  color:
                      _messageController.text.trim().isNotEmpty
                          ? Colors.white
                          : Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  final text = _messageController.text.trim();
                  if (text.isNotEmpty) {
                    sendMessage(text);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 52,
        elevation: 1,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        centerTitle: false,
        title: buildAppBarTitle(),
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                    ? buildEmptyState()
                    : GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          if (msg == null || msg['message'] == null) {
                            return const SizedBox.shrink();
                          }
                          return buildMessageBubble(msg);
                        },
                      ),
                    ),
          ),
          buildMessageInput(),
        ],
      ),
    );
  }
}
