import 'package:flutter/material.dart';
import 'package:xiaojia_ledger/modules/auth/login_page.dart';
import 'package:xiaojia_ledger/modules/auth/splash_page.dart';
import 'package:xiaojia_ledger/modules/home/home_page.dart';
import 'package:xiaojia_ledger/modules/settings/settings_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case splash:
        page = SplashPage();
        break;
      case login:
        page = LoginPage();
        break;
      case home:
        page = HomePage();
        break;
      case AppRouter.settings:
        page = SettingsPage();
        break;
      default:
        page = const Scaffold(body: Center(child: Text('页面不存在')));
    }
    return MaterialPageRoute(builder: (_) => page);
  }
}
