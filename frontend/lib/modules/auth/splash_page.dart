import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/constants.dart';
import 'package:xiaojia_ledger/core/router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _navigate();
    });
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.splashSkippedKey, true);

    final token = prefs.getString(AppConstants.tokenKey);
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      (token != null && token.isNotEmpty) ? AppRouter.home : AppRouter.login,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '小佳记账',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w600,
                letterSpacing: 18,
                color: Color(0xFF3D362F),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '每一笔，都算数',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFAAA098),
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _navigate,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFAAA098)),
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: const Color(0xFF3D362F),
              ),
              child: const Text('开 始 使 用',
                  style: TextStyle(letterSpacing: 8, fontSize: 15)),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _navigate,
              child: const Text(
                '跳过',
                style: TextStyle(fontSize: 12, color: Color(0xFFAAA098)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
