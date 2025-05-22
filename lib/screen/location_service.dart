import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'dart:io';

class LocationService {
  static Future<LatLng> getCurrentLocation() async {
    try {
      // إذا كان الجهاز أندرويد
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
        Position position = await Geolocator.getCurrentPosition();
        return LatLng(position.latitude, position.longitude);
      }
      
      // إذا كان نظام لينكس
      return await _getNetworkLocation();
    } catch (e) {
      throw Exception('لا يمكن الحصول على الموقع: ${e.toString()}');
    }
  }

  static Future<void> _requestAndroidPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('الرجاء تفعيل خدمة الموقع في إعدادات الجهاز');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض صلاحيات الموقع');
      }
    }
  }

  static Future<LatLng> _getNetworkLocation() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json/?fields=status,message,lat,lon,city,region'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          final lat = data['lat'];
          final lon = data['lon'];
          final city = data['city'];
          final region = data['region'];
          
          return LatLng(lat, lon);
        }
      }
      throw Exception('لا يمكن تحديد الموقع عبر الشبكة');
    } catch (e) {
      throw Exception('خطأ في خدمة الموقع: ${e.toString()}');
    }
  }
}