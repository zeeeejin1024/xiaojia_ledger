import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarService {
  static Future<bool> requestPermission() async {
    final status = await Permission.calendar.request();
    return status.isGranted;
  }

  static Future<bool> isPermissionGranted() async {
    final status = await Permission.calendar.status;
    return status.isGranted;
  }

  static Future<void> syncWeeklyReport(String startDate, String endDate, Map<String, dynamic> data) async {
    final p = await SharedPreferences.getInstance();
    final enabled = p.getBool('calendar_sync_enabled') ?? false;
    if (!enabled) return;

    final granted = await isPermissionGranted();
    if (!granted) return;

    // 同步周报到系统日历
    final title = '省钱周报 $startDate - $endDate';
    final expense = data['total_expense'] ?? 0;
    final income = data['total_income'] ?? 0;
    final description = '支出: ¥$expense\n收入: ¥$income\n结余: ¥${income - expense}';

    // TODO: 实现实际的日历同步逻辑
    // 这里需要使用 platform channel 或第三方包来写入系统日历
  }

  static Future<void> syncMonthlyReport(String month, Map<String, dynamic> data) async {
    final p = await SharedPreferences.getInstance();
    final enabled = p.getBool('calendar_sync_enabled') ?? false;
    if (!enabled) return;

    final granted = await isPermissionGranted();
    if (!granted) return;

    // 同步月报到系统日历
    final title = '月度理财报告 $month';
    final expense = data['total_expense'] ?? 0;
    final income = data['total_income'] ?? 0;

    // TODO: 实现实际的日历同步逻辑
  }

  static Future<void> setSyncEnabled(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('calendar_sync_enabled', enabled);
  }

  static Future<bool> isSyncEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('calendar_sync_enabled') ?? false;
  }
}
