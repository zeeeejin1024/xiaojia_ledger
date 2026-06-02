import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings);
      _initialized = true;
      debugPrint('NotificationService: 初始化成功');
    } catch (e) {
      debugPrint('NotificationService: 初始化失败 - $e');
    }
  }

  static Future<void> scheduleWeeklyReport() async {
    await init();
    await _plugin.cancel(1);
    await _plugin.zonedSchedule(
      1, '省钱周报', '本周的省钱报告已生成，点击查看～', _nextMondayMorning(),
      const NotificationDetails(android: AndroidNotificationDetails('weekly_report', '周报推送', channelDescription: '每周省钱报告', importance: Importance.defaultImportance, priority: Priority.defaultPriority)),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> scheduleMonthlyReport() async {
    await init();
    await _plugin.cancel(2);
    await _plugin.zonedSchedule(
      2, '月度报告', '上月的理财报告已生成，来看看你的表现吧～', _nextFirstOfMonthMorning(),
      const NotificationDetails(android: AndroidNotificationDetails('monthly_report', '月报推送', channelDescription: '每月理财报告', importance: Importance.defaultImportance, priority: Priority.defaultPriority)),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  static Future<void> recordWeeklyGenerated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_weekly_gen', DateTime.now().toIso8601String());
  }

  static Future<void> recordMonthlyGenerated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_monthly_gen', DateTime.now().toIso8601String());
  }

  /// 记账提醒
  static Future<void> scheduleReminder(int hour, int minute) async {
    await init();
    await _plugin.cancel(3);
    await _plugin.zonedSchedule(
      3, '记账提醒', '今天还没有记账哦，快记一笔吧～', _nextDaily(hour, minute),
      const NotificationDetails(android: AndroidNotificationDetails('reminder', '记账提醒', channelDescription: '每日记账提醒', importance: Importance.high, priority: Priority.high)),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder() async {
    await init();
    await _plugin.cancel(3);
  }

  static Future<void> testNotification() async {
    await init();
    await _plugin.show(
      99, '测试通知', '小满记账通知功能正常！',
      const NotificationDetails(android: AndroidNotificationDetails('test', '测试通知', channelDescription: '测试通知', importance: Importance.high, priority: Priority.high)),
    );
  }

  static tz.TZDateTime _nextDaily(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  static tz.TZDateTime _nextMondayMorning() {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day + ((DateTime.monday - now.weekday + 7) % 7), 9);
    if (next.isBefore(now)) next = next.add(const Duration(days: 7));
    return next;
  }

  static tz.TZDateTime _nextFirstOfMonthMorning() {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(tz.local, now.year, now.month + 1, 1, 9);
  }
}
