import 'package:xiaojia_ledger/data/api/api_client.dart';
import 'package:xiaojia_ledger/data/models/api_response.dart';
import 'package:xiaojia_ledger/data/models/user.dart';

class AuthApi {
  static final ApiClient _client = ApiClient();

  static Future<ApiResponse<AuthData>> register(
      String username, String password) async {
    final response = await _client.post('/auth/register', data: {
      'username': username,
      'password': password,
    });
    return ApiResponse.fromJson(response.data, AuthData.fromJson);
  }

  static Future<ApiResponse<AuthData>> login(
      String username, String password) async {
    final response = await _client.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return ApiResponse.fromJson(response.data, AuthData.fromJson);
  }

  static Future<ApiResponse<UserInfo>> getMe() async {
    final response = await _client.get('/auth/me');
    return ApiResponse.fromJson(response.data, UserInfo.fromJson);
  }
}
