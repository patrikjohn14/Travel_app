import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:maps_tracker/screen/categorie/CategoryDetailsPage.dart';
import 'package:maps_tracker/screen/places/place_deatails.dart';
import 'package:maps_tracker/screen/search/search.dart';

import '../../settings.dart';
import '../../theme/color.dart';
import '../categorie/category.dart';

class HomeScreen extends StatefulWidget {
  final int? currentUserId;
  final String? firstName;
  final String? lastName;
  const HomeScreen({
    super.key,
    this.currentUserId,
    this.firstName,
    this.lastName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  List<dynamic> places = [];
  List<Map<String, dynamic>> populars = [];

  bool hasError = false;
  Set<int> favoritePlaces = {};
  Future<List<Category>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${Settings.apiBaseUrl}/api/categories'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'].isNotEmpty) {
          return (data['data'] as List)
              .map((json) => Category.fromJson(json))
              .toList();
        } else {
          throw Exception('No categories found');
        }
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPopularPlaces() async {
    try {
      final url = Uri.parse('${Settings.apiBaseUrl}/api/places');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('data')) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception(
          "Failed to load popular places: ${response.statusCode}",
        );
      }
    } catch (error) {
      throw Exception("Error fetching popular places: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchCategories();
      fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBgColor,
      appBar: buildAppbar(context),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => buildBody(),
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  buildBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle("Categories"),
          getCategories(),
          const SizedBox(height: 12),
          buildSectionTitle("Most Popular"),
          getPopularPlaces(),
          const SizedBox(height: 12),
          buildSectionTitle("New Places"),
          getNewPlaces(),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Padding buildCategoryText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Categories",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 17.0,
            ),
          ),
        ],
      ),
    );
  }

  Padding buildTopTripsText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Most Popular",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
        ],
      ),
    );
  }

  Padding buildNewTripsText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "New Places",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget getCategories() {
    return FutureBuilder<List<Category>>(
      future: fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF008FA0)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No categories found",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          );
        }

        final categories = snapshot.data!;

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CarouselSlider.builder(
                  options: CarouselOptions(
                    enlargeCenterPage: true,
                    disableCenter: true,
                    viewportFraction: 0.4,
                    scrollPhysics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index, realIdx) {
                    final category = categories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => Categorydetailspage(
                                  currentUserId: widget.currentUserId,
                                  categories: categories,
                                  initialCategory: category,
                                ),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  category.iconBytes != null
                                      ? MemoryImage(category.iconBytes!)
                                      : null,
                              child:
                                  category.iconBytes == null
                                      ? Icon(
                                        Icons.category,
                                        size: 30,
                                        color: Colors.grey.shade600,
                                      )
                                      : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget getPopularPlaces() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchPopularPlaces(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF008FA0)),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Error: Failed to load places',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text(
                "No places available",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          );
        }

        final popularPlaces = snapshot.data!;

        return SizedBox(
          height:
              MediaQuery.of(context).size.height * 0.27, // 27% من ارتفاع الشاشة
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CarouselSlider.builder(
              options: CarouselOptions(
                enlargeCenterPage: true,
                disableCenter: true,
                viewportFraction: 0.7,
                scrollPhysics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
              ),
              itemCount: popularPlaces.length,
              itemBuilder: (context, index, realIndex) {
                final place = popularPlaces[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PlaceDetails(
                              placeId: place["id"] ?? 0,
                              placeCategoryId: place["category_id"] ?? 0,
                              placeName: place["name"] ?? "Unknown",
                              placeDescription:
                                  place["description"] ?? "No description",
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
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child:
                                place["image_picture"] != null
                                    ? Image.memory(
                                      base64Decode(place["image_picture"]),
                                      fit: BoxFit.cover,
                                    )
                                    : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.photo, size: 50),
                                    ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    place["name"] ?? "Place Name",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          place["province"] ?? "Location",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget getNewPlaces() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchPopularPlaces(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF008FA0)),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Error: Failed to load places',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: Text(
                "No places available",
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          );
        }

        final popularPlaces = snapshot.data!;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: popularPlaces.length,
          itemBuilder: (context, index) {
            final place = popularPlaces[index];
            double rate =
                double.tryParse(place["rate"]?.toString() ?? "0") ?? 0;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PlaceDetails(
                          placeId: place["id"] ?? 0,
                          placeCategoryId: place["category_id"] ?? 0,
                          placeName: place["name"] ?? "Unknown",
                          placeDescription:
                              place["description"] ?? "No description",
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
                height: 120, // ✅ صغرت الطول هنا
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child:
                          place["image_picture"] != null
                              ? Image.memory(
                                base64Decode(place["image_picture"]),
                                width: 110,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                width: 110,
                                height: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(Icons.photo, size: 50),
                              ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place["name"] ?? "Place Name",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    place["province"] ?? "Location",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < rate ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
            "Hikely",
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
                builder:
                    (context) => Search(currentUserId: widget.currentUserId),
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

}
