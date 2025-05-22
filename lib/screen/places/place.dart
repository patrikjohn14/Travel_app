import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/settings.dart' show Settings;

import 'place_deatails.dart';
class TouristPlacesScreen extends StatefulWidget {
  final int? currentUserId;
  final int categoryId;
  final String categoryName;
  final String categoryDescription;

  const TouristPlacesScreen({
    super.key,
    required this.currentUserId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryDescription,
  });

  @override
  State<TouristPlacesScreen> createState() => _TouristPlacesScreenState();
}

class _TouristPlacesScreenState extends State<TouristPlacesScreen> {
  List<dynamic> places = [];
  bool isLoading = true;
  bool hasError = false;
  Set<int> favoritePlaces = {};
  final String apiUrl = Settings.apiBaseUrl;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
    if (widget.currentUserId != null) {
      _loadFavorites();
    }
  }

  Future<void> _fetchPlaces() async {
    final url =
        '$apiUrl/api/categories/${widget.categoryId}/places';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> fetchedPlaces = json.decode(response.body)['data'];
        setState(() {
          places = fetchedPlaces;
          isLoading = false;
        });
      } else {
        _handleError();
      }
    } catch (error) {
      _handleError();
    }
  }

  void _handleError() {
    setState(() {
      hasError = true;
      isLoading = false;
    });
  }

  Future<void> _addToFavorite(int placeId) async {
    try {
      final userId = widget.currentUserId;
      if (userId == null) {
        _showLoginRequiredMessage();
        return;
      }

      final url = '$apiUrl/api/favorites/';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId, 'place_id': placeId}),
      );

      if (response.statusCode == 201) {
        setState(() {
          favoritePlaces.add(placeId);
        });
        _showSuccessMessage('Added to favorites');
      } else {
        _showErrorMessage('Failed to add to favorites');
      }
    } catch (error) {
      print('Error adding to favorites: $error');
      _showErrorMessage('Connection error');
    }
  }

  Future<void> _removeFromFavorite(int placeId) async {
    try {
      final userId = widget.currentUserId;
      if (userId == null) {
        _showLoginRequiredMessage();
        return;
      }

      final url = '$apiUrl/api/favorites/$userId/$placeId';
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          favoritePlaces.remove(placeId);
        });
        _showSuccessMessage('Removed from favorites');
      } else {
        _showErrorMessage('Failed to remove from favorites');
      }
    } catch (error) {
      print('Error removing from favorites: $error');
      _showErrorMessage('Connection error');
    }
  }

  void _toggleFavorite(int placeId) {
    if (favoritePlaces.contains(placeId)) {
      _removeFromFavorite(placeId);
    } else {
      _addToFavorite(placeId);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final userId = widget.currentUserId;
      if (userId == null) return;

      final url = '$apiUrl/api/favorites/user/$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> fetchedFavorites =
            json.decode(response.body)['data'];
        final Set<int> favorites =
            fetchedFavorites.map((f) => f['place_id'] as int).toSet();

        setState(() {
          favoritePlaces = favorites;
        });
      }
    } catch (error) {
      print('Error loading favorites: $error');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showLoginRequiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login required to add favorites'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 52,
      centerTitle: true,
      title: Text(
        widget.categoryName,
        style: const TextStyle(fontSize: 18, color: Color(0xFF008FA0)),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
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
    );
  }

  Widget _buildBody() {
    if (isLoading) return _buildLoader();
    if (hasError) return _buildError();
    if (places.isEmpty) return _buildEmpty();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            itemCount: places.length,
            itemBuilder: (context, index) => _buildPlaceItem(places[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceItem(dynamic place) {
    final isFavorite = favoritePlaces.contains(place['id']);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetails(
              placeId: place["id"] ?? 0,
              placeCategoryId: place["category_id"] ?? 0,
              placeName: place["name"] ?? "Unknown",
              placeDescription: place["description"] ?? "No description",
              province: place["province"] ?? "Unknown",
              municipality: place["municipality"] ?? "Unknown",
              neighborhood: place["neighborhood"] ?? "Unknown",
              latitude: place["latitude"]?.toString(),
              longitude: place["longitude"]?.toString(),
              map_link: place["map_link"],
              placeImage: place["image_picture"],
              rate: place["rate"]?.toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlaceImage(place['image_picture']),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['name'] ?? 'Tourist Place',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (place['city'] != null || place['country'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 20,
                              color: Color(0xFF008FA0),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${place['province'] ?? ''} ${place['province'] != null ? ', ${place['country']}' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (place['rate'] != null || place['price'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            if (place['rate'] != null) ...[
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                place['rate'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (place['price'] != null)
                              Text(
                                '${place['price']} \$',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Favorite Button
            Padding(
              padding: const EdgeInsets.all(4),
              child: IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: () => _toggleFavorite(place['id']),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceImage(String? imageBase64) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      child: Container(
        width: 120,
        height: 120,
        color: Colors.grey[200],
        child: imageBase64 != null
            ? Image.memory(base64Decode(imageBase64), fit: BoxFit.cover)
            : const Center(
                child: Icon(Icons.photo_camera, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading tourist places...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Failed to load data'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchPlaces,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No places available'),
        ],
      ),
    );
  }
}