class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 0;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    return ApiResponse(
      code: json['code'] ?? -1,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : json['data'] as T?,
    );
  }

  factory ApiResponse.fromList(
    Map<String, dynamic> json,
    T Function(List<dynamic>)? fromList,
  ) {
    return ApiResponse(
      code: json['code'] ?? -1,
      message: json['message'] ?? '',
      data: json['data'] != null && fromList != null
          ? fromList(json['data'] as List<dynamic>)
          : json['data'] as T?,
    );
  }
}
