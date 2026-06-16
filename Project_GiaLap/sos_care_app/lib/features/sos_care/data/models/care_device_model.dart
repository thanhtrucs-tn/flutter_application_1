import '../../domain/entities/care_device.dart';
import 'care_device_status_model.dart';
import 'care_location_model.dart';

class CareDeviceModel {
  final String id;
  final String elderlyId;
  final String? elderlyName;
  final String status;
  final DateTime? lastSeenAt;
  final CareDeviceStatusModel? latestStatus;
  final CareLocationModel? latestLocation;

  const CareDeviceModel({
    required this.id,
    required this.elderlyId,
    this.elderlyName,
    required this.status,
    this.lastSeenAt,
    this.latestStatus,
    this.latestLocation,
  });

  factory CareDeviceModel.fromJson(Map<String, dynamic> json) {
    return CareDeviceModel(
      id: json['id'] as String,
      elderlyId: json['elderlyId'] as String,
      elderlyName: json['elderlyName'] as String?,
      status: json['status'] as String? ?? 'active',
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString())
          : null,
      latestStatus: json['latestStatus'] != null
          ? CareDeviceStatusModel.fromJson(json['latestStatus'] as Map<String, dynamic>)
          : null,
      latestLocation: json['latestLocation'] != null
          ? CareLocationModel.fromJson(json['latestLocation'] as Map<String, dynamic>)
          : null,
    );
  }

  CareDevice toEntity() {
    return CareDevice(
      id: id,
      elderlyId: elderlyId,
      elderlyName: elderlyName,
      status: status,
      lastSeenAt: lastSeenAt,
      latestStatus: latestStatus?.toEntity(),
      latestLocation: latestLocation?.toEntity(),
    );
  }
}
