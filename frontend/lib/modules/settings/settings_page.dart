import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/theme.dart';
import 'package:xiaojia_ledger/core/constants.dart';
import 'package:xiaojia_ledger/core/router.dart';
import 'package:xiaojia_ledger/core/notifications.dart';
import 'package:xiaojia_ledger/core/calendar_service.dart';
import 'package:xiaojia_ledger/widgets/app_icon.dart';
import 'package:xiaojia_ledger/modules/home/home_page.dart';
import 'package:xiaojia_ledger/data/api/api_client.dart';
import 'package:xiaojia_ledger/data/api/record_api.dart';
import 'package:xiaojia_ledger/data/api/auth_api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _idx = 0;
  bool _reminderEnabled = false;
  bool _calendarSyncEnabled = false;
  String _reminderTime = '21:00';

  @override
  void initState() {
    super.initState();
    _idx = AppColors.schemeIndex;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final syncEnabled = await CalendarService.isSyncEnabled();
    setState(() {
      _reminderEnabled = prefs.getBool('reminder_enabled') ?? false;
      _reminderTime = prefs.getString('reminder_time') ?? '21:00';
      _calendarSyncEnabled = syncEnabled;
    });
  }

  Future<void> _scheduleReminder() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('reminder_time', _reminderTime);
    final parts = _reminderTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    await NotificationService.scheduleReminder(hour, minute);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('记账提醒已开启，每天 $_reminderTime 提醒')));
  }

  Future<void> _pickReminderTime() async {
    final parts = _reminderTime.split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (time != null) {
      final newTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() => _reminderTime = newTime);
      final p = await SharedPreferences.getInstance();
      await p.setString('reminder_time', newTime);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提醒时间已设为 $newTime')));
    }
  }

  void _pickScheme(int i) async {
    final s = AppColorScheme.all[i];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color_scheme', i);
    AppColors.apply(s);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: s.brightness == Brightness.dark ? Brightness.light : Brightness.dark, systemNavigationBarColor: s.navBg, systemNavigationBarIconBrightness: s.brightness == Brightness.dark ? Brightness.light : Brightness.dark));
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomePage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('设置', style: TextStyle(color: AppColors.ink)), backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(padding: EdgeInsets.all(20), children: [
        // 配色方案 — 6 色圆点
        PremiumCard(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('配色方案', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: AppColorScheme.all.asMap().entries.map((e) {
            final i = e.key; final s = e.value; final sel = i == _idx;
            return GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); setState(() => _idx = i); _pickScheme(i); },
              child: Column(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: s.brightness == Brightness.dark ? [s.card, s.cardAlt] : [s.premium, s.premiumDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: s.brightness == Brightness.dark ? s.premium.withAlpha(180) : (sel ? s.accent : Colors.transparent),
                      width: s.brightness == Brightness.dark ? 2 : (sel ? 3 : 0),
                    ),
                    boxShadow: sel ? [BoxShadow(color: s.accent.withAlpha(60), blurRadius: 10)] : null,
                  ),
                  child: sel ? Icon(Icons.check, color: s.brightness == Brightness.dark ? s.premiumLight : Colors.white, size: 20) : null,
                ),
                SizedBox(height: 6),
                Text(s.name, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.normal, color: sel ? AppColors.ink : AppColors.gray)),
              ]),
            );
          }).toList()),
        ])),
        SizedBox(height: 20),
        // 账号安全
        PremiumCard(padding: EdgeInsets.zero, child: Column(children: [
          _row(Icons.phone_android_rounded, '修改手机号', onTap: _changePhone),
          Divider(indent: 52),
          _row(Icons.lock_rounded, '修改密码', onTap: _changePassword),
          Divider(indent: 52),
          _row(Icons.help_rounded, '修改密保', onTap: _changeSecurity),
        ])),
        SizedBox(height: 20),
        // 账号
        PremiumCard(padding: EdgeInsets.zero, child: Column(children: [
          _row(Icons.person_outline_rounded, '当前账号', trailing: FutureBuilder<String?>(future: SharedPreferences.getInstance().then((p) => p.getString(AppConstants.usernameKey)), builder: (_, s) => Text(s.data ?? '—', style: TextStyle(fontSize: 14, color: AppColors.gray)))),
          Divider(indent: 52),
          _row(Icons.swap_horiz_rounded, '切换账号', onTap: () async {
            HapticFeedback.lightImpact();
            final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('切换账号'), content: Text('确定要切换账号吗？'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')), TextButton(onPressed: () => Navigator.pop(context, true), child: Text('确定', style: TextStyle(color: AppColors.danger)))]));
            if (ok == true && mounted) { const storage = FlutterSecureStorage(); await storage.delete(key: AppConstants.tokenKey); await storage.delete(key: AppConstants.usernameKey); if (mounted) Navigator.pushReplacementNamed(context, AppRouter.login); }
          }),
        ])),
        SizedBox(height: 20),
        // 记账提醒
        PremiumCard(padding: EdgeInsets.zero, child: Column(children: [
          _row(Icons.notifications_rounded, '记账提醒', trailing: Switch(value: _reminderEnabled, onChanged: (v) async {
            HapticFeedback.lightImpact();
            setState(() => _reminderEnabled = v);
            final p = await SharedPreferences.getInstance();
            await p.setBool('reminder_enabled', v);
            if (v) _scheduleReminder();
          })),
          if (_reminderEnabled) ...[
            Divider(indent: 52),
            _row(Icons.access_time_rounded, '提醒时间', trailing: Text(_reminderTime, style: TextStyle(fontSize: 14, color: AppColors.gray)), onTap: _pickReminderTime),
            Divider(indent: 52),
            _row(Icons.send_rounded, '测试通知', onTap: () async {
              HapticFeedback.lightImpact();
              await NotificationService.testNotification();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('测试通知已发送')));
            }),
          ],
          Divider(indent: 52),
          _row(Icons.calendar_today_rounded, '日历同步', trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('同步周报/月报', style: TextStyle(fontSize: 11, color: AppColors.gray)),
            SizedBox(width: 8),
            Switch(value: _calendarSyncEnabled, onChanged: (v) async {
              HapticFeedback.lightImpact();
              if (v) {
                final granted = await CalendarService.requestPermission();
                if (!granted) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('需要日历权限才能同步')));
                  return;
                }
              }
              setState(() => _calendarSyncEnabled = v);
              await CalendarService.setSyncEnabled(v);
            }),
          ])),
        ])),
        SizedBox(height: 20),
        PremiumCard(padding: EdgeInsets.zero, child: Column(children: [
          _row(Icons.download_rounded, '导出 CSV', onTap: () async { HapticFeedback.lightImpact(); try { final r = await ApiClient().get('/export/csv'); final dir = await getTemporaryDirectory(); final f = File('${dir.path}/records_${DateTime.now().toIso8601String().split('T')[0]}.csv'); await f.writeAsString(r.data.toString()); await Share.shareXFiles([XFile(f.path)], text: '小满记账 - 账单导出'); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败'))); } }),
          Divider(indent: 52),
          _row(Icons.code_rounded, '导出 JSON', onTap: () async { HapticFeedback.lightImpact(); try { final r = await ApiClient().get('/export/json'); final dir = await getTemporaryDirectory(); final f = File('${dir.path}/backup_${DateTime.now().toIso8601String().split('T')[0]}.json'); await f.writeAsString(r.data.toString()); await Share.shareXFiles([XFile(f.path)], text: '小满记账 - 备份导出'); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败'))); } }),
        ])),
        SizedBox(height: 20),
        PremiumCard(padding: EdgeInsets.zero, child: _row(Icons.delete_outline_rounded, '清空所有数据', onTap: () async {
          HapticFeedback.lightImpact();
          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('确认清空'), content: Text('此操作不可恢复！'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')), TextButton(onPressed: () => Navigator.pop(context, true), child: Text('确定', style: TextStyle(color: AppColors.danger)))]));
          if (ok == true) {
            try { final r = await RecordApi.getRecords(); if (r.data != null) for (final e in r.data!) { await RecordApi.deleteRecord(e.id); } } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('清空失败，请重试'))); }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已清空')));
              // 跳回首页触发重新加载
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => HomePage()), (_) => false);
            }
          }
        }, isDanger: true)),
        SizedBox(height: 20),
        PremiumCard(padding: EdgeInsets.zero, child: Column(children: [
          _row(Icons.help_rounded, '关于与帮助', onTap: () {
            HapticFeedback.lightImpact();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('关于 ${AppConstants.appName}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _aboutRow('版本号', 'v${AppConstants.appVersion}'),
                      _aboutRow('开发者', '小满团队'),
                      _aboutRow('联系邮箱', 'support@xiaoman.app'),
                      _aboutRow('隐私政策', 'https://xiaoman.app/privacy'),
                      _aboutRow('用户协议', 'https://xiaoman.app/terms'),
                      SizedBox(height: 16),
                      Text('版权所有 © 2026 小满记账团队', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                      SizedBox(height: 12),
                      Center(child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('当前已是最新版本')));
                        },
                        child: Text('检查更新'),
                      )),
                    ],
                  ),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('关闭'))],
              ),
            );
          }),
          Divider(indent: 52),
          _row(Icons.star_rounded, '给个好评', onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('感谢您的支持！')));
          }),
          Divider(indent: 52),
          _row(Icons.info_rounded, '开源许可', onTap: () {
            HapticFeedback.lightImpact();
            showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: 'v${AppConstants.appVersion}',
            );
          }),
        ])),
        SizedBox(height: 40),
        Center(child: Text('${AppConstants.appName} v${AppConstants.appVersion}', style: TextStyle(fontSize: 12, color: AppColors.gray))),
      ]),
    );
  }

  Future<void> _changePhone() async {
    HapticFeedback.lightImpact();
    final pwCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('修改手机号'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: pwCtrl, obscureText: true, decoration: InputDecoration(labelText: '输入密码确认身份')),
        SizedBox(height: 12),
        TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: '新手机号')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('确定'))],
    ));
    if (ok == true && mounted) {
      try {
        final r = await AuthApi.updatePhone(pwCtrl.text, phoneCtrl.text.trim());
        if (r.isSuccess) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('手机号已更新')));
        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
      } catch (_) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('网络错误'))); }
    }
  }

  Future<void> _changePassword() async {
    HapticFeedback.lightImpact();
    final oldPw = TextEditingController(), newPw = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('修改密码'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: oldPw, obscureText: true, decoration: InputDecoration(labelText: '原密码')),
        SizedBox(height: 12),
        TextField(controller: newPw, obscureText: true, decoration: InputDecoration(labelText: '新密码（至少6位）')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('确定'))],
    ));
    if (ok == true && mounted) {
      try {
        final r = await AuthApi.updatePassword(oldPw.text, newPw.text);
        if (r.isSuccess) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('密码已更新')));
        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
      } catch (_) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('网络错误'))); }
    }
  }

  Future<void> _changeSecurity() async {
    HapticFeedback.lightImpact();
    final pwCtrl = TextEditingController(), ansCtrl = TextEditingController();
    String q = '你的母亲的名字是？';
    const questions = AppConstants.securityQuestions;

    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) {
      return AlertDialog(
        title: Text('修改密保'), content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: pwCtrl, obscureText: true, decoration: InputDecoration(labelText: '输入密码确认身份')),
          SizedBox(height: 12),
          DropdownButtonFormField(value: q, items: questions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setSt(() => q = v ?? q)),
          SizedBox(height: 12),
          TextField(controller: ansCtrl, decoration: InputDecoration(labelText: '答案')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('确定'))],
      );
    }));
    if (ok == true && mounted) {
      try {
        final r = await AuthApi.updateSecurity(pwCtrl.text, q, ansCtrl.text.trim());
        if (r.isSuccess) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('密保已更新')));
        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
      } catch (_) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('网络错误'))); }
    }
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: AppColors.gray)),
          Text(value, style: TextStyle(fontSize: 14, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String title, {VoidCallback? onTap, Widget? trailing, bool isDanger = false}) {
    return ListTile(
      leading: Icon(icon, color: isDanger ? AppColors.danger : AppColors.ink, size: 22),
      title: Text(title, style: TextStyle(fontSize: 16, color: isDanger ? AppColors.danger : AppColors.ink)),
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right, color: AppColors.gray, size: 20) : null),
      onTap: onTap != null ? () { HapticFeedback.lightImpact(); onTap(); } : null, contentPadding: EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
