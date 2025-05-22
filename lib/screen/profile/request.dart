import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/settings.dart';

class RequestFriends extends StatefulWidget {
  final int? currentUserId;
  const RequestFriends({super.key, required this.currentUserId});

  @override
  State<RequestFriends> createState() => _RequestFriendsState();
}

class _RequestFriendsState extends State<RequestFriends> {
  List<dynamic> friendRequests = [];
  bool isLoading = true;
 final String apiUrl = Settings.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    fetchFriendRequests();
  }

  Future<void> fetchFriendRequests() async {
    if (widget.currentUserId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/requests/${widget.currentUserId}'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          if (responseData['data'] is List) {
            setState(() {
              friendRequests = responseData['data'];
              isLoading = false;
            });
          } else {
            throw Exception(
              'Expected list but got ${responseData['data'].runtimeType}',
            );
          }
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load requests');
        }
      } else {
        throw Exception('Failed to load requests: ${response.statusCode}');
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

  Future<void> respondToRequest(int requestId, bool accept) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/api/accept/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.currentUserId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'تم قبول طلب الصداقة'),
          ),
        );
        // إزالة الطلب من القائمة بعد القبول
        setState(() {
          friendRequests.removeWhere((request) => request['id'] == requestId);
        });
      } else {
        throw Exception(
          responseData['error'] ?? 'Failed to respond to request',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      debugPrint('Error details: $e');
    }
  }

  Future<void> rejectRequest(int requestId) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/api/reject/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.currentUserId}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'تم رفض طلب الصداقة'),
          ),
        );
        setState(() {
          friendRequests.removeWhere((request) => request['id'] == requestId);
        });
      } else {
        throw Exception(responseData['error'] ?? 'Failed to reject request');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: ${e.toString()}')));
      debugPrint('Error details: $e');
    }
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
              : friendRequests.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Friend Requests',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When someone sends you a friend request, it will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: friendRequests.length,
                itemBuilder: (context, index) {
                  final request = friendRequests[index];
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color(0xFF008FA0).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage:
                                      request['profile_picture'] is String
                                          ? NetworkImage(
                                            '$apiUrl${request['profile_picture']}',
                                          )
                                          : null,
                                  child:
                                      request['profile_picture'] == null ||
                                              request['profile_picture']
                                                  is! String
                                          ? Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.grey[400],
                                          )
                                          : null,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${request['first_name']} ${request['last_name']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Wants to be your friend',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => rejectRequest(request['id']),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.grey[100],
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Decline',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      () =>
                                          respondToRequest(request['id'], true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF008FA0),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Accept',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
      toolbarHeight: 52,
      backgroundColor: Colors.white,
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
        "Friend Requests",
        style: TextStyle(color: Color(0xFF008FA0), fontSize: 20),
      ),
      actions: [],
      iconTheme: IconThemeData(color: Colors.black, size: 20),
    );
  }
}
