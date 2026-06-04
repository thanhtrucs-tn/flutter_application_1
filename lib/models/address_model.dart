/// Model lưu trữ địa chỉ phân cấp từ kết quả Reverse Geocoding.
///
/// Cấu trúc địa chỉ Việt Nam:
/// - houseNumber: Số nhà (ví dụ: "12", "12A")
/// - street: Tên đường (ví dụ: "Nguyễn Huệ")
/// - suburb: Phường/Xã (ví dụ: "Phường Bến Nghé")
/// - cityDistrict: Quận/Huyện (ví dụ: "Quận 1")
/// - province: Tỉnh/Thành phố (ví dụ: "TP. Hồ Chí Minh")
/// - country: Quốc gia (ví dụ: "Việt Nam")
/// - displayName: Tên hiển thị đầy đủ từ Nominatim
/// - lat, lng: Tọa độ gốc
class Address {
  final String houseNumber;
  final String street;
  final String suburb;
  final String cityDistrict;
  final String province;
  final String country;
  final String displayName;
  final double lat;
  final double lng;

  const Address({
    required this.houseNumber,
    required this.street,
    required this.suburb,
    required this.cityDistrict,
    required this.province,
    required this.country,
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  /// Địa chỉ ngắn gọn dùng cho badge (ưu tiên số nhà + đường, fallback suburb)
  String get shortAddress {
    if (street.isNotEmpty) {
      return houseNumber.isNotEmpty
          ? '$houseNumber $street'
          : street;
    }
    return suburb.isNotEmpty ? suburb : displayName;
  }

  /// Địa chỉ chi tiết nhiều dòng dùng cho modal
  List<AddressLine> get detailedLines {
    final lines = <AddressLine>[];
    final line1Parts = <String>[];
    if (houseNumber.isNotEmpty) line1Parts.add(houseNumber);
    if (street.isNotEmpty) line1Parts.add(street);
    if (line1Parts.isNotEmpty) {
      lines.add(AddressLine(label: 'Địa chỉ', value: line1Parts.join(' ')));
    }
    if (suburb.isNotEmpty) {
      lines.add(AddressLine(label: 'Phường/Xã', value: suburb));
    }
    if (cityDistrict.isNotEmpty) {
      lines.add(AddressLine(label: 'Quận/Huyện', value: cityDistrict));
    }
    if (province.isNotEmpty) {
      lines.add(AddressLine(label: 'Tỉnh/TP', value: province));
    }
    if (country.isNotEmpty && country != 'Việt Nam') {
      lines.add(AddressLine(label: 'Quốc gia', value: country));
    }
    return lines;
  }

  /// Khóa cache duy nhất cho tọa độ (làm tròn 5 chữ số thập phân ~1m)
  String get cacheKey => '${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';

  factory Address.fromNominatim(
    Map<String, dynamic> json, {
    required double lat,
    required double lng,
  }) {
    final address = json['address'] as Map<String, dynamic>? ?? const {};
    return Address(
      houseNumber: (address['house_number'] as String?) ??
          (address['building'] as String?) ??
          '',
      street: (address['road'] as String?) ??
          (address['pedestrian'] as String?) ??
          (address['footway'] as String?) ??
          (address['path'] as String?) ??
          (address['neighbourhood'] as String?) ??
          '',
      suburb: (address['suburb'] as String?) ??
          (address['quarter'] as String?) ??
          (address['neighbourhood'] as String?) ??
          (address['village'] as String?) ??
          (address['hamlet'] as String?) ??
          '',
      cityDistrict: (address['city_district'] as String?) ??
          (address['county'] as String?) ??
          (address['district'] as String?) ??
          (address['state_district'] as String?) ??
          '',
      province: (address['city'] as String?) ??
          (address['state'] as String?) ??
          (address['province'] as String?) ??
          (address['region'] as String?) ??
          '',
      country: (address['country'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      lat: lat,
      lng: lng,
    );
  }

  Map<String, dynamic> toJson() => {
        'houseNumber': houseNumber,
        'street': street,
        'suburb': suburb,
        'cityDistrict': cityDistrict,
        'province': province,
        'country': country,
        'displayName': displayName,
        'lat': lat,
        'lng': lng,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        houseNumber: json['houseNumber'] as String? ?? '',
        street: json['street'] as String? ?? '',
        suburb: json['suburb'] as String? ?? '',
        cityDistrict: json['cityDistrict'] as String? ?? '',
        province: json['province'] as String? ?? '',
        country: json['country'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
      );

  /// Địa chỉ rỗng (khi chưa load được)
  static const Address empty = Address(
    houseNumber: '',
    street: '',
    suburb: '',
    cityDistrict: '',
    province: '',
    country: '',
    displayName: '',
    lat: 0,
    lng: 0,
  );
}

/// Một dòng trong địa chỉ chi tiết
class AddressLine {
  final String label;
  final String value;
  const AddressLine({required this.label, required this.value});
}
