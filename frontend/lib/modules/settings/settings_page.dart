import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/constants.dart';
import 'package:xiaojia_ledger/core/router.dart';
import 'package:xiaojia_ledger/data/api/auth_api.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: FutureBuilder<String?>(
            future: SharedPreferences.getInstance()
                .then((p) => p.getString(AppConstants.usernameKey)),
            builder: (_, snap) {
              return Text('当前用户：${snap.data ?? "—"}',
                  style: const TextStyle(fontSize: 14));
            },
          ),
        ),
        const SizedBox(height: 12),

        // Export CSV
        _settingItem(
          Icons.download,
          '导出 CSV',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('导出功能将在 W4 完成')),
            );
          },
        ),
        const SizedBox(height: 8),

        // Switch account
        _settingItem(
          Icons.swap_horiz,
          '切换账号',
          () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(AppConstants.tokenKey);
            await prefs.remove(AppConstants.usernameKey);
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, AppRouter.login);
            }
          },
        ),
        const SizedBox(height: 8),

        // Clear data
        _settingItem(
          Icons.delete_outline,
          '清空我的所有数据',
          () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('确认清空'),
                content: const Text('此操作不可恢复！'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('确定', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirmed == true) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('清空功能将在 W2.8 完成')),
                );
              }
            }
          },
          isDanger: true,
        ),
        const SizedBox(height: 16),

        // Version
        Center(
          child: Text('小佳记账 v${AppConstants.appVersion}',
              style: const TextStyle(color: Color(0xFFAAA098), fontSize: 12)),
        ),
      ],
    );
  }

  Widget _settingItem(IconData icon, String title, VoidCallback onTap,
      {bool isDanger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDanger ? Colors.red : const Color(0xFFD4794A)),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(
                    color: isDanger ? Colors.red : const Color(0xFF3D362F),
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
