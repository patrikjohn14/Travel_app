import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:maps_tracker/screen/favorite_screen/favorite.dart';
import 'package:maps_tracker/screen/home/home_screen.dart';
import 'package:maps_tracker/screen/map_tracking_screen.dart';
import 'package:maps_tracker/screen/messenger/chat.dart';
import 'package:maps_tracker/screen/profile/profile.dart';

class Home extends StatefulWidget {
  final int? currentUserId;
  final String? firstName;
  final String? lastName;

  const Home({super.key, this.currentUserId, this.firstName, this.lastName});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late PageController _pageController;
  int _page = 0;
  final Color primaryColor = const Color(0xFF008FA0);
  final Color inactiveColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    if (page == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  Profile(currentUserId: widget.currentUserId, userId: null),
        ),
      );
    } else {
      _pageController.jumpToPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: <Widget>[
          HomeScreen(
            currentUserId: widget.currentUserId,
            firstName: widget.firstName,
            lastName: widget.lastName,
          ),
          EnhancedRouteMapScreen(endPointString: ''),
          Chat(userId: widget.currentUserId),
          FavoriteScreen(currentUserId: widget.currentUserId),
          Profile(currentUserId: widget.currentUserId, userId: null),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(FontAwesomeIcons.house, 0),
            _buildNavItem(FontAwesomeIcons.locationDot, 1),
            _buildNavItem(FontAwesomeIcons.facebookMessenger, 2),
            _buildNavItem(FontAwesomeIcons.solidHeart, 3),
            _buildNavItem(FontAwesomeIcons.solidUser, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int pageIndex) {
    final bool isActive = _page == pageIndex;

    return GestureDetector(
      onTap: () => navigationTapped(pageIndex),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isActive
                      ? primaryColor.withOpacity(0.15)
                      : Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 18,
              color: isActive ? primaryColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
