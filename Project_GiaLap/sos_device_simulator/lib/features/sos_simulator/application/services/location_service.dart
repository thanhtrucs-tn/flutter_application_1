import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_constants.dart';

/// Abstraction over the geolocator package so the rest of the app does
/// not depend directly on a third-party plugin.
class LocationService {
  /// Returns the last cached GPS fix without waiting for a new one.
  ///
  /// Wraps [Geolocator.getLastKnownPosition] which is non-blocking — it
  /// reads whatever the OS already has. Returns default coords if the
  /// OS has no cached fix yet (cold start) or geolocator is unavailable
  /// (e.g. desktop). Total runtime < 50 ms in the common case.
  Future<({double latitude, double longitude})> getLastKnown() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return (latitude: position.latitude, longitude: position.longitude);
      }
    } catch (_) {
      // Fall through to default.
    }
    return _defaultLocation();
  }

  /// Pre-warms the GPS subsystem in the background.
  ///
  /// Safe to call on any platform — on unsupported platforms (desktop)
  /// the geolocator call resolves quickly and the result is discarded.
  /// Errors are logged but never thrown.
  void warmUp() {
    // Fire-and-forget: intentionally not awaited.
    // ignore: discarded_futures
    _warmUpImpl();
  }

  Future<void> _warmUpImpl() async {
    try {
      // Quick low-accuracy fix to seed the OS cache. Timeout after 2s so
      // we never block the caller if GPS is unavailable.
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('LocationService.warmUp skipped: $e');
      }
    }
  }

  /// Requests permission and returns a fresh GPS fix.
  ///
  /// Returns [AppConstants.defaultLatitude] / [AppConstants.defaultLongitude]
  /// when permission is denied or the service is unavailable.
  Future<({double latitude, double longitude})> getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return _defaultLocation();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _defaultLocation();
    }

    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return _defaultLocation();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return _defaultLocation();
    }
  }

  ({double latitude, double longitude}) _defaultLocation() {
    return (
      latitude: AppConstants.defaultLatitude,
      longitude: AppConstants.defaultLongitude,
    );
  }
}
