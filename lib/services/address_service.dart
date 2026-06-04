import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/address_model.dart';

/// Service gọi Nominatim (OpenStreetMap) Reverse Geocoding với cache trong bộ nhớ
/// + SharedPreferences để giảm số lần gọi API.
///
/// Lưu ý:
/// - Nominatim yêu cầu User-Agent hợp lệ (đặt trong header Accept-Language)
/// - Giới hạn 1 request/giây: cache trước khi gọi API
/// - Cache key làm tròn 5 chữ số thập phân (~1.1m) cho cùng tọa độ
class AddressService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/reverse';
  static const String _cachePrefix = 'address_cache_';
  static const Duration _timeout = Duration(seconds: 8);

  // Cache in-memory: tránh gọi trùng trong cùng session
  final Map<String, Address> _memoryCache = <String, Address>{};

  // Cache theo dõi các request đang chạy để tránh duplicate
  final Map<String, Future<Address?>> _inflight = <String, Future<Address?>>{};

  /// Lấy địa chỉ từ tọa độ lat/lng. Có cache 2 lớp: memory + SharedPreferences.
  Future<Address?> getAddress(double lat, double lng) async {
    final key = _keyOf(lat, lng);

    // 1) Cache memory
    final cached = _memoryCache[key];
    if (cached != null) return cached;

    // 2) Cache SharedPreferences
    final fromDisk = await _readFromDisk(key);
    if (fromDisk != null) {
      _memoryCache[key] = fromDisk;
      return fromDisk;
    }

    // 3) Tránh duplicate request cùng key
    final inflight = _inflight[key];
    if (inflight != null) return inflight;

    final future = _fetchAndCache(lat, lng, key);
    _inflight[key] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<Address?> _fetchAndCache(double lat, double lng, String key) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'format': 'json',
        'lat': lat.toString(),
        'lon': lng.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'vi',
      });

      final response = await http
          .get(uri, headers: {
            'User-Agent': 'flutter_application_1/1.0 (elderly-care-app)',
            'Accept': 'application/json',
          })
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return null;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['error'] != null) {
        return null;
      }

      final address = Address.fromNominatim(
        body,
        lat: lat,
        lng: lng,
      );

      // Lưu cả 2 cache
      _memoryCache[key] = address;
      await _writeToDisk(key, address);
      return address;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  String _keyOf(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
  }

  Future<Address?> _readFromDisk(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_cachePrefix$key');
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Address.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeToDisk(String key, Address address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_cachePrefix$key',
        jsonEncode(address.toJson()),
      );
    } catch (_) {
      // ignore disk write failure - memory cache đã có
    }
  }

  /// Xóa toàn bộ cache (dùng cho debug hoặc khi đổi ngôn ngữ)
  Future<void> clearCache() async {
    _memoryCache.clear();
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
