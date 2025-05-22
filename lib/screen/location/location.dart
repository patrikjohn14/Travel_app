import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Location extends StatefulWidget {
  const Location({super.key});

  @override
  State<Location> createState() => _LocationState();
}

class _LocationState extends State<Location> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppbar(context),
    );
  }

  AppBar buildAppbar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 52,
      backgroundColor: Colors.grey.shade100,
      elevation: 0,
      title: Row(
        children: [
          Icon(
            FontAwesomeIcons.locationDot,
            color: const Color(0xFF008FA0),
            size: 18,
          ),
          SizedBox(width: 6),
          Text(
            "Location",
            style: TextStyle(fontSize: 16, color: const Color(0xFF008FA0)),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              "/notification",
              // arguments: widget.currentUserId,
            ).then((_) {
              // fetchUnreadCount();
            });
          },
          icon: Stack(
            children: [
              Icon(
                FontAwesomeIcons.bell,
                color: const Color(0xFF008FA0),
                size: 22,
              ),
              //   if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                  child: Text(
                    "",
                    /*  unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center, */
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      iconTheme: IconThemeData(color: Colors.black, size: 24),
    );
  }
}
