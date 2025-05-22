import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:maps_tracker/screen/places/place.dart';
import 'category.dart';

class Categorydetailspage extends StatefulWidget {
  final int? currentUserId;
  final List<Category> categories;
  final Category? initialCategory;

  const Categorydetailspage({
    super.key,
    required this.currentUserId,
    required this.categories,
    this.initialCategory,
  });

  @override
  State<Categorydetailspage> createState() => _CategorydetailspageState();
}

class _CategorydetailspageState extends State<Categorydetailspage> {
  final Map<String, String> _categoryImages = {
    'Tourism': 'assets/images/venice.jpg',
    'Adventure': 'assets/images/santorini.jpg',
    'Business': 'assets/images/newyork.jpg',
    'Beach': 'assets/images/paris.jpg',
    'Cultural': 'assets/images/stmarksbasilica.jpg',
    'Hotels': 'assets/images/hotel1.jpg',
    'Transport': 'assets/images/gondola.jpg',
  };

  final Map<String, String> _categoryIcons = {
    'Tourism': 'assets/icons/marker.svg',
    'Adventure': 'assets/icons/navigation.svg',
    'Business': 'assets/icons/home.svg',
    'Beach': 'assets/icons/star.svg',
    'Cultural': 'assets/icons/heart.svg',
    'Hotels': 'assets/icons/hotel.svg',
    'Transport': 'assets/icons/angle-left.svg',
  };

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Categories',
          style: TextStyle(
            color: Color(0xFF008FA0),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF008FA0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: widget.categories.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              slivers: [
                if (widget.initialCategory != null)
                  SliverToBoxAdapter(child: _buildFeaturedCategory(widget.initialCategory!)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCategoryCard(widget.categories[index]),
                      childCount: widget.categories.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 3 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeaturedCategory(Category category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCategoryBackground(category),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildCardContent(category, isFeatured: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TouristPlacesScreen(
            currentUserId: widget.currentUserId,
            categoryId: category.id,
            categoryName: category.name,
            categoryDescription: category.description,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCategoryBackground(category),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _buildCardContent(category, isFeatured: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(Category category, {required bool isFeatured}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildCategoryIcon(category, size: isFeatured ? 26 : 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isFeatured ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                ),
              ),
            ),
          ],
        ),
        if (isFeatured) ...[
          const SizedBox(height: 8),
          Text(
            category.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryBackground(Category category) {
    return category.imageBytes != null
        ? Image.memory(
            category.imageBytes!,
            fit: BoxFit.cover,
          )
        : Image.asset(
            _categoryImages[category.name] ?? 'assets/images/travel_logo.jpg',
            fit: BoxFit.cover,
          );
  }

  Widget _buildCategoryIcon(Category category, {required double size}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SvgPicture.asset(
        _categoryIcons[category.name] ?? 'assets/icons/marker.svg',
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/marker.svg',
              height: 60,
              colorFilter: const ColorFilter.mode(Color(0xFF008FA0), BlendMode.srcIn),
            ),
            const SizedBox(height: 20),
            const Text(
              'No categories available',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF008FA0),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
