/// Generic API response wrapper used by the SOS Care backend.
class ApiResponseModel {
  final bool success;
  final String? message;
  final dynamic data;

  const ApiResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data,
  };

  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'],
    );
  }
}
