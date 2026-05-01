import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'supabase_service.dart';

class LocationService {
  StreamSubscription<Position>? _sub;

  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrent() async {
    if (!await ensurePermission()) return null;
    return Geolocator.getCurrentPosition();
  }

  void startSharing(String userId) {
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((pos) async {
      try {
        await SupabaseService.client.from('locations').upsert({
          'user_id': userId,
          'lat': pos.latitude,
          'lng': pos.longitude,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    });
  }

  Future<void> stopSharing() async {
    await _sub?.cancel();
    _sub = null;
  }
}
