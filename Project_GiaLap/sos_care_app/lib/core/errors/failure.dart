/// Base class for all application-level failures.
sealed class Failure {
  final String message;

  const Failure({this.message = 'Đã xảy ra lỗi không xác định'});
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({this.statusCode, super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Kết nối mạng bị lỗi'});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Xác thực thất bại'});
}

class DataFailure extends Failure {
  const DataFailure({super.message = 'Dữ liệu không hợp lệ'});
}
