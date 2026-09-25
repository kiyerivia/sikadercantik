import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

final currentLocationNameProvider = FutureProvider<String>((ref) async {
  return await LocationService.getCurrentAddress();
});

class LocationService {
  static const String defaultLocation = 'Kel. Purwokerto Lor, Kec. Purwokerto Timur';

  /// Fetch accurate location as string (e.g. 'Kel. Purwokerto Lor, Kec. Purwokerto Timur')
  static Future<String> getCurrentAddress() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return defaultLocation;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return defaultLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return defaultLocation;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        if (!kIsWeb) {
          try {
            position = await Geolocator.getLastKnownPosition();
          } catch (_) {}
        }
      }

      if (position == null) {
        return defaultLocation;
      }

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'SiKaderCantik/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          String? kel = address['village'] ??
              address['suburb'] ??
              address['quarter'] ??
              address['neighbourhood'] ??
              address['hamlet'];
          String? kec = address['municipality'] ??
              address['city_district'] ??
              address['subdistrict'] ??
              address['town'] ??
              address['county'];

          if (kel != null && kec != null) {
            final kelFormatted =
                kel.startsWith('Kel') || kel.startsWith('Desa') ? kel : 'Kel. $kel';
            final kecFormatted = kec.startsWith('Kec') ? kec : 'Kec. $kec';
            return '$kelFormatted, $kecFormatted';
          } else if (kel != null) {
            final kelFormatted =
                kel.startsWith('Kel') || kel.startsWith('Desa') ? kel : 'Kel. $kel';
            final city = address['city'] ?? address['regency'] ?? '';
            return city.isNotEmpty ? '$kelFormatted, $city' : kelFormatted;
          } else if (kec != null) {
            final kecFormatted = kec.startsWith('Kec') ? kec : 'Kec. $kec';
            final city = address['city'] ?? address['regency'] ?? '';
            return city.isNotEmpty ? '$kecFormatted, $city' : kecFormatted;
          }
        }
      }
      return defaultLocation;
    } catch (e) {
      debugPrint('LocationService getCurrentAddress error: $e');
      return defaultLocation;
    }
  }
}
