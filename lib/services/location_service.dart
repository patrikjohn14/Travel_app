import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static Future<void> requestLocationPermission() async {
    if (await Permission.location.request().isGranted) {
      return;
    } else {
      throw Exception('Location permission denied');
    }
  }

  static Future<LatLng> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Error getting current location: $e');
    }
  }
}
