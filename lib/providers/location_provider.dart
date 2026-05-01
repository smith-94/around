import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_mode.dart';
import '../services/location_service.dart';
import '../services/mock_data.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider({LocationService? service})
      : _service = service ?? LocationService();

  final LocationService _service;

  LatLng? current;
  bool denied = false;

  Future<void> bootstrap(String userId) async {
    if (AppModeConfig.isPreview) {
      current = MockData.myLocation;
      notifyListeners();
      return;
    }
    final ok = await _service.ensurePermission();
    if (!ok) {
      denied = true;
      notifyListeners();
      return;
    }
    final pos = await _service.getCurrent();
    if (pos != null) {
      current = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    }
    _service.startSharing(userId);
  }

  void onPosition(Position p) {
    current = LatLng(p.latitude, p.longitude);
    notifyListeners();
  }

  Future<void> stop() async {
    if (AppModeConfig.isPreview) return;
    await _service.stopSharing();
  }
}
