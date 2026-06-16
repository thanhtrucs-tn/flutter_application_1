import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/care_alert.dart';
import '../../domain/entities/care_device.dart';
import '../../domain/repositories/sos_care_repository.dart';
import '../models/care_alert_model.dart';
import '../models/care_device_model.dart';

/// Concrete repository that fetches caregiver data via REST.
class SosCareRemoteRepository implements SosCareRepository {
  final Dio _dio;

  const SosCareRemoteRepository(this._dio);

  @override
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  }) async {
    return _post(
      ApiConfig.loginEndpoint,
      {'email': email, 'password': password},
      (data) => data['token'] as String,
    );
  }

  @override
  Future<Either<Failure, List<CareAlert>>> loadHistory({
    String? deviceId,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    return _get(
      ApiConfig.historyEndpoint,
      {
        'deviceId': deviceId,
        'type': type,
        'page': page,
        'limit': limit,
      },
      (data) => (data as List)
          .map((json) => CareAlertModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList(),
    );
  }

  @override
  Future<Either<Failure, CareDevice>> loadDevice(String id) async {
    return _get(
      '${ApiConfig.deviceEndpoint}/$id',
      {},
      (data) => CareDeviceModel.fromJson(data as Map<String, dynamic>).toEntity(),
    );
  }

  Future<Either<Failure, T>> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(dynamic data) mapper,
  ) async {
    try {
      final response = await _dio.post(path, data: body);
      final envelope = response.data as Map<String, dynamic>;
      if (envelope['success'] == true) {
        return Right(mapper(envelope['data']));
      }
      return Left(ServerFailure(
        statusCode: response.statusCode,
        message: envelope['message']?.toString() ?? 'Server reported failure',
      ));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(DataFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, T>> _get<T>(
    String path,
    Map<String, dynamic> query,
    T Function(dynamic data) mapper,
  ) async {
    try {
      final response = await _dio.get(path, queryParameters: query);
      final envelope = response.data as Map<String, dynamic>;
      if (envelope['success'] == true) {
        return Right(mapper(envelope['data']));
      }
      return Left(ServerFailure(
        statusCode: response.statusCode,
        message: envelope['message']?.toString() ?? 'Server reported failure',
      ));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(DataFailure(message: e.toString()));
    }
  }

  Failure _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkFailure(message: error.message ?? 'Kết nối mạng bị lỗi');
    }
    if (error.response?.statusCode == 401) {
      return const AuthFailure();
    }
    return ServerFailure(
      statusCode: error.response?.statusCode,
      message: error.message ?? 'Lỗi server',
    );
  }
}
