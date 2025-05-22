import 'package:flutter/material.dart';

import '../../theme/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white,
     appBar: buildAppBar(context),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 52,
      backgroundColor: TColor.white,
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
        "Settings",
        style: TextStyle(color: Color(0xFF008FA0), fontSize: 20),
      ),
      actions: [],
      iconTheme: IconThemeData(color: TColor.black, size: 20),
    );
  }
}
