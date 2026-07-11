import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' if (dart.library.html) 'package:turf_app/core/utils/platform_utils.dart' as mapbox;

class LocationService {
  static const String _lastLocationKey = 'last_known_location';

  Future<bool> handlePermission() async {
    if (kIsWeb) return false;
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handlePermission();
    if (!hasPermission) return null;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    await _cacheLocation(position);
    return position;
  }

  Stream<Position> getPositionStream() {
    if (kIsWeb) return const Stream.empty();
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map((position) {
      _cacheLocation(position);
      return position;
    });
  }

  Future<void> _cacheLocation(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'lat': position.latitude,
      'lng': position.longitude,
    };
    await prefs.setString(_lastLocationKey, jsonEncode(data));
  }

  Future<mapbox.Position?> getLastKnownLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(_lastLocationKey);
    if (dataStr != null) {
      try {
        final data = jsonDecode(dataStr);
        return mapbox.Position(data['lng'], data['lat']);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
