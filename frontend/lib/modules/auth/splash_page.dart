import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/constants.dart';
import 'package:xiaojia_ledger/core/router.dart';
import 'package:xiaojia_ledger/core/theme.dart';
import 'package:xiaojia_ledger/core/notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 1500), () async {
      // 请求通知权限
      await _requestNotificationPermission();

      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.tokenKey);
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        final lastAuth = p.getString('last_auth_check');
        final now = DateTime.now();
        bool needConfirm = true;
        if (lastAuth != null) {
          final last = DateTime.tryParse(lastAuth);
          if (last != null && now.difference(last).inDays < 7) needConfirm = false;
        }
        if (needConfirm) {
          final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: Text('确认登录'),
            content: Text('为了你的账号安全，请确认继续使用当前账号。'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('退出登录')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('确认', style: TextStyle(color: AppColors.highlight))),
            ],
          ));
          if (ok == true && mounted) {
            await p.setString('last_auth_check', now.toIso8601String());
            if (mounted) Navigator.pushReplacementNamed(context, AppRouter.home);
          } else if (mounted) {
            await storage.delete(key: AppConstants.tokenKey);
            await storage.delete(key: AppConstants.usernameKey);
            if (mounted) Navigator.pushReplacementNamed(context, AppRouter.login);
          }
        } else {
          if (mounted) Navigator.pushReplacementNamed(context, AppRouter.home);
        }
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, AppRouter.login);
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _requestNotificationPermission() async {
    try {
      final p = await SharedPreferences.getInstance();
      final hasRequested = p.getBool('notification_permission_requested') ?? false;

      if (!hasRequested) {
        await Permission.notification.request();
        await p.setBool('notification_permission_requested', true);
      }

      // 初始化通知服务
      await NotificationService.init();

      // 调度周报和月报
      await NotificationService.scheduleWeeklyReport();
      await NotificationService.scheduleMonthlyReport();

      // 调度记账提醒
      final reminderEnabled = p.getBool('reminder_enabled') ?? false;
      if (reminderEnabled) {
        final time = p.getString('reminder_time') ?? '21:00';
        final parts = time.split(':');
        await NotificationService.scheduleReminder(int.parse(parts[0]), int.parse(parts[1]));
      }
    } catch (_) {
      // 静默处理通知初始化错误
    }
  }

  static const _title = '小满记账';
  static const _subtitle = '记录每一笔，攒出小确幸';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value; // 0 → 1

            // Logo: scale 0→1 + rotation 15deg→0 (first 60% of timeline)
            final logoProgress = (t / 0.6).clamp(0.0, 1.0);
            final logoScale = Curves.easeOutBack.transform(logoProgress);
            final logoRotate = (1 - logoProgress) * 0.26;

            // Title stagger: each character 60ms apart
            final titleStart = 0.3;
            final titleEnd = 0.7;

            // Subtitle: fade in during last 30%
            final subtitleStart = 0.65;
            final subtitleProgress = ((t - subtitleStart) / 0.35).clamp(0.0, 1.0);

            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Logo
                Transform.rotate(
                  angle: logoRotate,
                  child: Transform.scale(
                    scale: logoScale,
                    child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.highlight, Color.lerp(AppColors.highlight, Colors.black, 0.2)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.highlight.withAlpha(60), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Icon(Icons.savings_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                ),
                SizedBox(height: 28),
                // Title — staggered chars
                _StaggeredTitle(title: _title, controller: _ctrl, start: titleStart, end: titleEnd),
                SizedBox(height: 10),
                // Subtitle — fade + float up
                Opacity(
                  opacity: subtitleProgress,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - subtitleProgress)),
                    child: Text(_subtitle, style: TextStyle(fontSize: 14, color: AppColors.gray)),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _StaggeredTitle extends StatelessWidget {
  final String title;
  final AnimationController controller;
  final double start, end;

  const _StaggeredTitle({required this.title, required this.controller, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final chars = title.characters.toList();
        return Row(mainAxisSize: MainAxisSize.min, children: List.generate(chars.length, (i) {
          final charStart = start + (i * 0.06);
          final charProgress = ((controller.value - charStart) / (end - start)).clamp(0.0, 1.0);
          final y = (1 - charProgress) * 20;
          final opacity = charProgress;
          return Transform.translate(
            offset: Offset(0, y),
            child: Opacity(
              opacity: opacity,
              child: Text(chars[i], style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.5)),
            ),
          );
        }));
      },
    );
  }
}
