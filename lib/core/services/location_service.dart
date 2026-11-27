import 'package:geolocator/geolocator.dart';

class CustomerLocation {
  const CustomerLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationService {
  Future<CustomerLocation> current() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled)
      throw const LocationException('فعّل خدمة الموقع من إعدادات الهاتف');
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'اسمح للتطبيق باستخدام الموقع لتحديد أقرب فني',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return CustomerLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;
}
