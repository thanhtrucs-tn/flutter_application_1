import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/repositories/sos_simulator_repository.dart';
import '../models/api_response_model.dart';
import '../models/battery_payload_model.dart';
import '../models/event_payload_model.dart';
import '../models/location_payload_model.dart';
import '../models/sos_payload_model.dart';

/// Concrete backend implementation that performs real HTTP calls via Dio.
class SosSimulatorRemoteDataSource implements SosSimulatorRepository {
  final Dio _dio;

  const SosSimulatorRemoteDataSource(this._dio);

  @override
  Future<Either<Failure, Unit>> sendSosAlert({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) async {
    return _post(
      ApiConfig.sosEndpoint,
      SosPayloadModel(
        deviceId: deviceId,
        elderlyId: elderlyId,
        timestamp: _formatTimestamp(timestamp),
        latitude: latitude,
        longitude: longitude,
      ).toJson(),
    );
  }

  @override
  Future<Either<Failure, Unit>> sendEvent({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    required String type,
  }) async {
    return _post(
      ApiConfig.eventsEndpoint,
      EventPayloadModel(
        deviceId: deviceId,
        elderlyId: elderlyId,
        timestamp: _formatTimestamp(timestamp),
        latitude: latitude,
        longitude: longitude,
        type: type,
      ).toJson(),
    );
  }

  @override
  Future<Either<Failure, Unit>> sendLocation({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
  }) async {
    return _post(
      ApiConfig.locationEndpoint,
      LocationPayloadModel(
        deviceId: deviceId,
        elderlyId: elderlyId,
        timestamp: _formatTimestamp(timestamp),
        latitude: latitude,
        longitude: longitude,
      ).toJson(),
    );
  }

  @override
  Future<Either<Failure, Unit>> updateBattery({
    required String deviceId,
    required String elderlyId,
    required DateTime timestamp,
    required int batteryPercent,
  }) async {
    return _post(
      ApiConfig.batteryEndpoint,
      BatteryPayloadModel(
        deviceId: deviceId,
        elderlyId: elderlyId,
        timestamp: _formatTimestamp(timestamp),
        batteryPercent: batteryPercent,
      ).toJson(),
    );
  }

  String _formatTimestamp(DateTime value) {
    return value.toUtc().toIso8601String();
  }

  Future<Either<Failure, Unit>> _post(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(path, data: data);
      final body = ApiResponseModel.fromJson(response.data as Map<String, dynamic>);
      if (body.success) {
        return const Right(unit);
      }
      return Left(
        ServerFailure(
          statusCode: response.statusCode,
          message: body.message ?? 'Server reported failure',
        ),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        final message = switch (e.type) {
          DioExceptionType.connectionTimeout =>
            'Kết nối đến server quá chậm, vui lòng thử lại',
          DioExceptionType.receiveTimeout =>
            'Server phản hồi quá chậm, vui lòng thử lại',
          DioExceptionType.sendTimeout =>
            'Gửi dữ liệu đến server quá chậm, vui lòng thử lại',
          _ => e.message ?? 'Kết nối mạng bị lỗi',
        };
        return Left(NetworkFailure(message: message));
      }
      return Left(
        ServerFailure(
          statusCode: e.response?.statusCode,
          message: e.message ?? 'Lỗi server',
        ),
      );
    } catch (e) {
      return Left(DataFailure(message: e.toString()));
    }
  }
}
