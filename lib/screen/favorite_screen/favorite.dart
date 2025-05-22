import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/screen/search/search.dart';
import '../../settings.dart';

class FavoriteScreen extends StatefulWidget {
  final int? currentUserId;

  const FavoriteScreen({super.key, required this.currentUserId});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<dynamic> favoritePlaces = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (widget.currentUserId == null) {
      _showLoginRequiredMessage();
      return;
    }

    try {
      final url = '${Settings.apiBaseUrl}/api/favorites/user/${widget.currentUserId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            favoritePlaces = data['data'] ?? [];
            isLoading = false;
          });
        } else {
          _handleError();
        }
      } else {
        _handleError();
      }
    } catch (error) {
      print('Error loading favorites: $error');
      _handleError();
    }
  }

  Future<void> _removeFromFavorites(int placeId) async {
    try {
      final url = '${Settings.apiBaseUrl}/api/favorites/${widget.currentUserId}/$placeId';
      final response = await http.delete(
        Uri.parse(url),
        body: json.encode({'user_id': widget.currentUserId, 'place_id': placeId}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _loadFavorites(); // Refresh the list
      }
    } catch (error) {
      print('Error removing favorite: $error');
    }
  }

  void _handleError() {
    setState(() {
      hasError = true;
      isLoading = false;
    });
  }

  void _showLoginRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You need to log in to access your favorites'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: buildAppbar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isLoading) return _buildLoader();
          if (hasError) return _buildError();
          if (favoritePlaces.isEmpty) return _buildEmpty();
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: favoritePlaces.length,
            itemBuilder: (context, index) {
              return _buildPlaceItem(favoritePlaces[index], constraints.maxWidth);
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaceItem(dynamic place, double maxWidth) {
    final placeId = place['place_id'] ?? place['id'];
    final imageSize = maxWidth < 400 ? 70.0 : 90.0;

    return InkWell(
      onTap: () {
        // Navigator.push(...)
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: place['image_picture'] is String && place['image_picture'].isNotEmpty
                  ? Image.memory(
                      base64Decode(place['image_picture'].split(',').last),
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: imageSize,
                      height: imageSize,
                      color: Colors.grey[300],
                      child: const Icon(Icons.photo, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['name'] ?? 'Tourist Place',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Color(0xFF008FA0)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${place['province'] ?? ''}${place['province'] != null && place['country'] != null ? ', ' : ''}${place['country'] ?? ''}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (place['rate'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          place['rate'].toString(),
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => _removeFromFavorites(placeId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(child: CircularProgressIndicator(color: Color(0xFF008FA0)));
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text('An error occurred while loading favorites'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008FA0)),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No favorite places found',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  AppBar buildAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 52,
      title: Row(
        children: [
          const Icon(FontAwesomeIcons.locationDot, size: 18, color: Color(0xFF008FA0)),
          const SizedBox(width: 6),
          const Text(
            "Map Tracker",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF008FA0),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(FontAwesomeIcons.search, size: 20, color: Color(0xFF008FA0)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Search(currentUserId: widget.currentUserId)),
            );
          },
        ),
      ],
    );
  }
}
