import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/care_alert.dart';
import '../entities/care_device.dart';

/// Repository contract for fetching historical data from the backend.
abstract class SosCareRepository {
  /// Authenticates a caregiver and returns a JWT token.
  Future<Either<Failure, String>> login({
    required String email,
    required String password,
  });

  /// Loads paginated history (alerts, events, locations).
  Future<Either<Failure, List<CareAlert>>> loadHistory({
    String? deviceId,
    String? type,
    int page,
    int limit,
  });

  /// Loads details of a single device.
  Future<Either<Failure, CareDevice>> loadDevice(String id);
}
