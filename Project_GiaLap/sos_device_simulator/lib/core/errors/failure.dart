/// Base class for all application-level failures.
///
/// Every repository call returns either a success value or a [Failure]
/// so the UI can show meaningful feedback to the user.
sealed class Failure {
  final String message;

  const Failure({this.message = 'Đã xảy ra lỗi không xác định'});
}

/// Failure caused by the backend returning an error status or body.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({this.statusCode, super.message});
}

/// Failure caused by a network-level problem (no connectivity, timeout).
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Kết nối mạng bị lỗi'});
}

/// Failure caused by the location service being disabled or denied.
class LocationFailure extends Failure {
  const LocationFailure({super.message = 'Không thể lấy vị trí hiện tại'});
}

/// Failure caused by invalid data or unexpected parsing.
class DataFailure extends Failure {
  const DataFailure({super.message = 'Dữ liệu không hợp lệ'});
}
