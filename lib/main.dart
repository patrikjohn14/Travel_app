import 'package:flutter/material.dart';
import 'package:maps_tracker/screen/auth_screen/login.dart';
import 'package:maps_tracker/screen/auth_screen/register.dart';
import 'package:maps_tracker/screen/categorie/CategoryDetailsPage.dart';
import 'package:maps_tracker/screen/home/home.dart';
import 'package:maps_tracker/screen/home/home_screen.dart';
import 'package:maps_tracker/screen/notifications/notification.dart';
import 'package:maps_tracker/screen/search/search.dart';
import 'package:maps_tracker/screen/settings/Settings_screen.dart';
import 'package:maps_tracker/screen/splash_screen/splash.dart';
import 'package:maps_tracker/screen/welcome_screen/welcome.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Travel Tracker",
      theme: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(primary: Colors.blue),
        scaffoldBackgroundColor: Colors.white, 
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Roboto', color: Colors.black),
          bodyLarge: TextStyle(fontFamily: 'Roboto', color: Colors.black),
        ),
      ),
      themeMode: ThemeMode.light, 
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/welcome':
            return MaterialPageRoute(builder: (context) => const Welcome());
          case '/login':
            return MaterialPageRoute(builder: (context) => const Login());
          case '/register':
            return MaterialPageRoute(builder: (context) => const Register());
          case '/home':
            return MaterialPageRoute(builder: (context) => const Home());
          case '/home_screen':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/notification':
            return MaterialPageRoute(builder: (context) => const Notifications());
          case '/settingsScreen':
            return MaterialPageRoute(builder: (context) => const SettingsScreen());
          case '/search':
            return MaterialPageRoute(
              builder: (context) => const Search(currentUserId: null),
            );
          case '/categori_details':
            return MaterialPageRoute(
              builder: (context) => const Categorydetailspage(
                categories: [],
                initialCategory: null,
                currentUserId: null,
              ),
            );
          default:
            return MaterialPageRoute(builder: (context) => const SplashScreen());
        }
      },
    );
  }
}
