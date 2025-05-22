import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:maps_tracker/settings.dart';

class SentRequestsScreen extends StatefulWidget {
  final int? userId;
  const SentRequestsScreen({super.key, required this.userId});

  @override
  State<SentRequestsScreen> createState() => _SentRequestsScreenState();
}

class _SentRequestsScreenState extends State<SentRequestsScreen> {
  List<dynamic> sentRequests = [];
  bool isLoading = true;
 final String apiUrl = Settings.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _fetchSentRequests();
  }

  Future<void> _fetchSentRequests() async {
    if (widget.userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/sent-requests/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          sentRequests = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load sent requests');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _cancelRequest(int requestId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/api/cancel-request/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId}),
      );

      if (response.statusCode == 200) {
        _fetchSentRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request cancelled successfully')),
        );
      } else {
        throw Exception('Failed to cancel request');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _showCancelDialog(int requestId, String friendName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Cancel Request',
              style: TextStyle(color: Colors.black),
            ),
            content: Text(
              'Are you sure you want to cancel the request for $friendName?',
              style: TextStyle(color: Colors.black),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelRequest(requestId);
                },
                child: const Text('Yes', style: TextStyle(color: Colors.red)),
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
              : sentRequests.isEmpty
              ? Center(
                child: Text(
                  'No sent requests',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: sentRequests.length,
                itemBuilder: (context, index) {
                  final request = sentRequests[index];
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
                            request['profile_picture'] != null
                                ? NetworkImage('$apiUrl${request['profile_picture']}')
                                : null,
                        child:
                            request['profile_picture'] == null
                                ? Icon(Icons.person, size: 28)
                                : null,
                      ),
                      title: Text(
                        '${request['first_name']} ${request['last_name']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.cancel, color: Colors.green),
                        onPressed:
                            () => _showCancelDialog(
                              request['id'],
                              '${request['first_name']} ${request['last_name']}',
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
        "Sent Requests",
        style: TextStyle(color: Color(0xFF008FA0), fontSize: 22),
      ),
      iconTheme: IconThemeData(color: Colors.black, size: 24),
    );
  }
}
