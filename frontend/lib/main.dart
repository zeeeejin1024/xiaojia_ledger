import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/router.dart';
import 'package:xiaojia_ledger/core/theme.dart';
import 'package:xiaojia_ledger/core/constants.dart';
import 'package:xiaojia_ledger/core/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final schemeIdx = prefs.getInt('color_scheme') ?? 0;
  AppColors.apply(AppColorScheme.all[schemeIdx.clamp(0, AppColorScheme.all.length - 1)]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: AppColors.isDark ? Brightness.light : Brightness.dark));

  runApp(const XiaojiaApp());
}

class XiaojiaApp extends StatelessWidget {
  const XiaojiaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: appTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
