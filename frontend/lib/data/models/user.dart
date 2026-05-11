class AuthData {
  final String username;
  final String token;

  AuthData({required this.username, required this.token});

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      username: json['username'] ?? '',
      token: json['token'] ?? '',
    );
  }
}

class UserInfo {
  final String username;

  UserInfo({required this.username});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(username: json['username'] ?? '');
  }
}
