class AppConstants {
  static const String appName = '小佳记账';
  static const String appVersion = '1.0.0';

  // API 地址：开发环境用 localhost，生产环境替换为服务器 IP
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  // Android 模拟器用 10.0.2.2，真机用实际 IP
  // iOS 模拟器用 localhost

  static const String tokenKey = 'auth_token';
  static const String usernameKey = 'auth_username';
  static const String themeKey = 'app_theme';
  static const String splashSkippedKey = 'splash_skipped';
}
