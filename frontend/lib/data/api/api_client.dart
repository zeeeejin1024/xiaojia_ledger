import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio dio;
  static const _storage = FlutterSecureStorage();

  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _storage.delete(key: AppConstants.tokenKey);
          _storage.delete(key: AppConstants.usernameKey);
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data, Options? options}) {
    return dio.post(path, data: data, options: options);
  }

  Future<Response> put(String path, {dynamic data}) {
    return dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return dio.delete(path);
  }

  Future<Response> postMultipart(String path, Map<String, dynamic> formData) {
    final fd = FormData();
    formData.forEach((k, v) => fd.files.add(MapEntry(k, v)));
    return dio.post(path, data: fd, options: Options(contentType: 'multipart/form-data'));
  }
}
