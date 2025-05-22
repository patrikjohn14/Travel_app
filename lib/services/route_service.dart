import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class RouteService {
  static Future<Map<String, dynamic>> getRouteDetails(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};'
      '${end.longitude},${end.latitude}?geometries=geojson&overview=full&steps=true&annotations=true',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final route = data['routes'][0];
      
      final coordinates = route['geometry']['coordinates'] as List;
      final points = coordinates
          .map((point) => LatLng(point[1] as double, point[0] as double))
          .toList();
      
      final distance = (route['distance'] as num).toDouble() / 1000; // كم
      final duration = (route['duration'] as num).toDouble() / 60; // دقائق
      
      return {
        'points': points,
        'distance': distance,
        'duration': duration.round(),
      };
    } else {
      throw Exception('Failed to load route: ${response.statusCode}');
    }
  }

  static Future<LatLng> geocodeLocation(String location) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$location&format=json&addressdetails=1&limit=1'
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'YourAppName/1.0 (your@email.com)',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return LatLng(
          double.parse(data[0]['lat']),
          double.parse(data[0]['lon']),
        );
      }
      throw Exception('Location not found');
    }
    throw Exception('Geocoding failed: ${response.statusCode}');
  }
}