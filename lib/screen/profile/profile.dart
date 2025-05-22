import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/screen/group/groups.dart';
import 'package:maps_tracker/screen/group/membergoup.dart';
import 'package:maps_tracker/screen/profile/editProfile.dart';
import 'package:maps_tracker/screen/profile/friends.dart';
import 'package:maps_tracker/screen/profile/request.dart';
import 'package:maps_tracker/screen/profile/requestSent.dart';
import 'package:maps_tracker/screen/settings/Settings_screen.dart';
import 'package:maps_tracker/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_screen/login.dart';

class Profile extends StatefulWidget {
  final int? currentUserId;
  final int? userId;
  const Profile({super.key, required this.currentUserId, required this.userId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  int? _actualUserId;
  final String apiUrl = Settings.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _actualUserId = widget.userId ?? widget.currentUserId;
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (_actualUserId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user ID available')));
      return;
    }

    final response = await http.get(
      Uri.parse('$apiUrl/api/users/$_actualUserId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
      );
    }
  }

  Future<void> _logoutUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('session_id');

      debugPrint('Session ID: $sessionId');

      if (sessionId == null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active session found')),
        );
        return;
      }

      debugPrint('Sending logout request...');
      final response = await http
          .post(
            Uri.parse('$apiUrl/api/logout'),
            headers: {'session-id': sessionId},
          )
          .timeout(const Duration(seconds: 10));

      Navigator.of(context).pop();

      debugPrint('Server response: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        debugPrint('Logout successful, clearing local data...');
        await prefs.clear();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'] ?? 'Logout failed')),
        );
      }
    } on SocketException {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No connection to server')));
    } on TimeoutException {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request timeout')));
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: ${e.toString()}')),
      );
      debugPrint('Error details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser =
        widget.currentUserId != null && _actualUserId == widget.currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(
        context,
        isCurrentUser,
        widget.userId,
        widget.currentUserId,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008FA0)),
                ),
              )
              : userData == null
              ? const Center(
                child: Text(
                  'No profile data available',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          buildUserImage(isCurrentUser),
                          const SizedBox(height: 16),
                          buildUsernames(),
                          const SizedBox(height: 40),
                          isCurrentUser ? _buildProfileCards() : Container(),
                        ],
                      ),
                    ),
                  ),
                  isCurrentUser
                      ? _buildBottomLogoutButton(context)
                      : Container(),
                ],
              ),
    );
  }

  Widget _buildBottomLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showLogoutConfirmation(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: const Color(0xFF008FA0), size: 24),
                const SizedBox(width: 10),
                Text(
                  'Log Out',
                  style: TextStyle(
                    color: const Color(0xFF008FA0),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
            content: const Text(
              'Are you sure you want to log out?',
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _logoutUser();
                },
                child: const Text(
                  'Confirm',
                  style: TextStyle(color: Color(0xFF008FA0)),
                ),
              ),
            ],
          ),
    );
  }

  Column buildUsernames() {
    return Column(
      children: [
        Text(
          "${userData!['user']['first_name']} ${userData!['user']['last_name']}",
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.black,
            letterSpacing: -0.8,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          '@${userData!['user']['bio']}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Center buildUserImage(bool isCurrentUser) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF008FA0).withOpacity(0.15),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 3,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child:
                userData!['user']['profile_picture'] != null
                    ? ClipOval(
                      child: Material(
                        color: Colors.transparent,
                        child: Ink.image(
                          image: NetworkImage(
                            '$apiUrl${userData!['user']['profile_picture']}',
                          ),
                          fit: BoxFit.cover,
                          width: 130,
                          height: 130,
                        ),
                      ),
                    )
                    : CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[100],
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                    ),
          ),
          if (isCurrentUser)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => EditProfileScreen(
                            userData: userData!,
                            UserId: _actualUserId,
                          ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008FA0),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  AppBar buildAppBar(
    BuildContext context,
    bool isCurrentUser,
    int? userId,
    int? currentId,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 52,
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: Colors.grey.withOpacity(0.1),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF008FA0),
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Profile",
        style: TextStyle(
          color: Color(0xFF008FA0),
          fontSize: 20,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        if (isCurrentUser)
          IconButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
            icon: const Icon(
              Icons.settings,
              size: 22,
              color: Color(0xFF008FA0),
            ),
          ),
        if (userId != null && currentId != null && userId != currentId)
          IconButton(
            onPressed: () => _handleFriendRequest(context, currentId, userId),
            icon: const Icon(
              Icons.person_add_alt_1,
              size: 22,
              color: Color(0xFF008FA0),
            ),
          ),
      ],
    );
  }

  Future<void> _handleFriendRequest(
    BuildContext context,
    int senderId,
    int receiverId,
  ) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final isSent = await sendFriendRequest(
        senderId: senderId,
        receiverId: receiverId,
      );

      if (isSent) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('Friend request sent successfully')),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<bool> sendFriendRequest({
    required int senderId,
    required int receiverId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/request/$senderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'receiverId': receiverId}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception(
          responseData['error'] ?? 'Failed to send friend request',
        );
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection error: ${e.message}');
    } on FormatException catch (_) {
      throw Exception('Data conversion error');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
  }

  Widget _buildProfileCards() {
    final List<Map<String, dynamic>> cards = [
      {
        'icon': Icons.person_add_alt_1,
        'title': 'Friend Requests',
        'color': Colors.blue,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      RequestFriends(currentUserId: widget.currentUserId),
            ),
          );
        },
      },
      {
        'icon': Icons.send,
        'title': 'Sent Requests',
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SentRequestsScreen(userId: widget.currentUserId),
            ),
          );
        },
      },
      {
        'icon': Icons.group,
        'title': 'Your Groups',
        'color': Colors.orange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => UserGroupsPage(userId: widget.currentUserId),
            ),
          );
        },
      },
      {
        'icon': Icons.group_add,
        'title': 'Joined Groups',
        'color': Colors.red,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MemberGroupsPage(userId: widget.currentUserId),
            ),
          );
        },
      },
      {
        'icon': Icons.people,
        'title': 'Friends',
        'color': Colors.purple,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => Friends(currentUserId: widget.currentUserId),
            ),
          );
        },
      },
    ];

    return Column(
      children:
          cards.map((card) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: card['onTap'],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(card['icon'], color: card['color'], size: 28),
                      const SizedBox(width: 16),
                      Text(
                        card['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
