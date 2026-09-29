import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../map/map_tiles.dart';
import '../models/address_model.dart';

/// Service gọi Nominatim (OpenStreetMap) Reverse Geocoding với cache trong bộ nhớ
/// + SharedPreferences để giảm số lần gọi API.
///
/// Lưu ý:
/// - Nominatim yêu cầu User-Agent hợp lệ (đặt trong header Accept-Language)
/// - Giới hạn 1 request/giây: cache trước khi gọi API
/// - Cache key làm tròn 5 chữ số thập phân (~1.1m) cho cùng tọa độ
class AddressService {
  AddressService._();
  static final AddressService instance = AddressService._();

  static const String _baseUrl = 'https://nominatim.openstreetmap.org/reverse';
  static const String _searchUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _photonUrl = 'https://photon.komoot.io';
  /// Khung Việt Nam (minLon,minLat,maxLon,maxLat) để Photon không trả kết quả nước khác.
  static const String _vnBbox = '102.1,8.2,109.5,23.4';
  static const Map<String, String> _headers = {
    'User-Agent': 'flutter_application_1/1.0 (elderly-care-app)',
    'Accept': 'application/json',
  };
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
    // Nominatim trước; lỗi hoặc bị từ chối (giới hạn 1 request/giây) thì hỏi Photon.
    final address = await _reverseNominatim(lat, lng) ?? await _reversePhoton(lat, lng);
    if (address == null) return null;
    _memoryCache[key] = address;
    await _writeToDisk(key, address);
    return address;
  }

  Future<Address?> _reversePhoton(double lat, double lng) async {
    try {
      final uri = Uri.parse('$_photonUrl/reverse').replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'limit': '1',
      });
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint('[AddressService] photon reverse ${response.statusCode}');
        return null;
      }
      final features = (json.decode(response.body) as Map<String, dynamic>)['features'] as List?;
      if (features == null || features.isEmpty) return null;
      final a = Address.fromPhoton(features.first as Map<String, dynamic>);
      // Giữ tọa độ gốc làm khóa cache.
      return Address(
        houseNumber: a.houseNumber,
        street: a.street,
        suburb: a.suburb,
        cityDistrict: a.cityDistrict,
        province: a.province,
        country: a.country,
        displayName: a.displayName,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      debugPrint('[AddressService] photon reverse error: $e');
      return null;
    }
  }

  Future<Address?> _reverseNominatim(double lat, double lng) async {
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
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('[AddressService] reverse ${response.statusCode}: ${response.body}');
        return null;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['error'] != null) {
        return null;
      }

      return Address.fromNominatim(body, lat: lat, lng: lng);
    } on TimeoutException {
      debugPrint('[AddressService] reverse timeout');
      return null;
    } catch (e) {
      debugPrint('[AddressService] reverse error: $e');
      return null;
    }
  }

  /// Tìm địa chỉ theo chữ (số nhà, tên đường, phường…) trong Việt Nam.
  ///
  /// Hỏi lần lượt MapTiler (nếu có key) → Photon → Nominatim, lấy nguồn đầu
  /// tiên có kết quả. Photon chịu được gõ thiếu dấu ("an phu dong") và gõ dở
  /// chữ cuối nên được ưu tiên. [nearLat]/[nearLng] ưu tiên kết quả gần đó.
  ///
  /// Trả về `null` khi không gọi được dịch vụ nào (mất mạng…), `[]` khi gọi
  /// được nhưng không có kết quả.
  Future<List<Address>?> search(String query, {double? nearLat, double? nearLng}) async {
    final q = query.trim();
    if (q.length < 3) return const [];
    var reachedAny = false;
    final sources = <Future<List<Address>?> Function()>[
      if (MapTiles.hasMapTilerKey) () => _searchMapTiler(q, nearLat, nearLng),
      () => _searchPhoton(q, nearLat, nearLng),
      () => _searchNominatim(q, nearLat, nearLng),
    ];
    for (final source in sources) {
      final results = await source();
      if (results == null) continue;
      reachedAny = true;
      if (results.isNotEmpty) return results;
    }
    return reachedAny ? const [] : null;
  }

  Future<List<Address>?> _searchPhoton(String q, double? lat, double? lng) async {
    try {
      final uri = Uri.parse('$_photonUrl/api').replace(queryParameters: {
        'q': q,
        'limit': '6',
        'bbox': _vnBbox,
        if (lat != null && lng != null) 'lat': lat.toString(),
        if (lat != null && lng != null) 'lon': lng.toString(),
      });
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint('[AddressService] photon search ${response.statusCode}');
        return null;
      }
      final features = (json.decode(response.body) as Map<String, dynamic>)['features'] as List? ?? const [];
      return features
          .whereType<Map<String, dynamic>>()
          .map(Address.fromPhoton)
          .where((a) => a.lat != 0 || a.lng != 0)
          .toList();
    } catch (e) {
      debugPrint('[AddressService] photon search error: $e');
      return null;
    }
  }

  Future<List<Address>?> _searchNominatim(String q, double? lat, double? lng) async {
    try {
      final uri = Uri.parse(_searchUrl).replace(queryParameters: {
        'q': q,
        'format': 'json',
        'addressdetails': '1',
        'countrycodes': 'vn',
        'limit': '6',
        'accept-language': 'vi',
        // Ưu tiên (không giới hạn) vùng quanh vị trí đang xem trên bản đồ.
        if (lat != null && lng != null)
          'viewbox': '${lng - 0.3},${lat + 0.3},${lng + 0.3},${lat - 0.3}',
      });
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint('[AddressService] nominatim search ${response.statusCode}');
        return null;
      }
      final list = json.decode(response.body) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().map((item) {
        final la = double.tryParse('${item['lat']}') ?? 0;
        final lo = double.tryParse('${item['lon']}') ?? 0;
        return Address.fromNominatim(item, lat: la, lng: lo);
      }).where((a) => a.lat != 0 || a.lng != 0).toList();
    } catch (e) {
      debugPrint('[AddressService] nominatim search error: $e');
      return null;
    }
  }

  Future<List<Address>?> _searchMapTiler(String q, double? lat, double? lng) async {
    try {
      final uri = Uri.parse(
        'https://api.maptiler.com/geocoding/${Uri.encodeComponent(q)}.json',
      ).replace(queryParameters: {
        'key': MapTiles.mapTilerKey,
        'country': 'vn',
        'language': 'vi',
        'limit': '6',
        'autocomplete': 'true',
        if (lat != null && lng != null) 'proximity': '$lng,$lat',
      });
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        debugPrint('[AddressService] maptiler search ${response.statusCode}');
        return null;
      }
      final features = (json.decode(response.body) as Map<String, dynamic>)['features'] as List? ?? const [];
      return features
          .whereType<Map<String, dynamic>>()
          .map(Address.fromMapTiler)
          .where((a) => a.lat != 0 || a.lng != 0)
          .toList();
    } catch (e) {
      debugPrint('[AddressService] maptiler search error: $e');
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
