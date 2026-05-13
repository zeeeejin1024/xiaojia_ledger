import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/constants.dart';
import 'package:xiaojia_ledger/core/router.dart';
import 'package:xiaojia_ledger/data/api/api_client.dart';
import 'package:xiaojia_ledger/data/api/record_api.dart';
import 'package:xiaojia_ledger/modules/sync/sync_page.dart';
import 'package:xiaojia_ledger/modules/voice/voice_page.dart';

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
          decoration: _cardDeco(),
          child: FutureBuilder<String?>(
            future: SharedPreferences.getInstance()
                .then((p) => p.getString(AppConstants.usernameKey)),
            builder: (_, snap) {
              return Text('当前用户：${snap.data ?? "—"}', style: const TextStyle(fontSize: 14));
            },
          ),
        ),
        const SizedBox(height: 12),

        // Export CSV
        _settingItem(Icons.download, '导出 CSV', () => _exportCSV(context)),
        const SizedBox(height: 8),

        // Export JSON
        _settingItem(Icons.code, '导出 JSON 备份', () => _exportJSON(context)),
        const SizedBox(height: 8),

        // Bill sync
        _settingItem(Icons.sync, '账单同步（微信/支付宝）', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncPage()));
        }),
        const SizedBox(height: 8),

        // Voice
        _settingItem(Icons.mic, '语音记账', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VoicePage()));
        }),
        const SizedBox(height: 8),

        // Switch account
        _settingItem(Icons.swap_horiz, '切换账号', () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(AppConstants.tokenKey);
          await prefs.remove(AppConstants.usernameKey);
          if (context.mounted) Navigator.pushReplacementNamed(context, AppRouter.login);
        }),
        const SizedBox(height: 8),

        // Clear data
        _settingItem(Icons.delete_outline, '清空我的所有数据', () => _clearData(context), isDanger: true),
        const SizedBox(height: 16),

        Center(
          child: Text('小佳记账 v${AppConstants.appVersion}',
              style: const TextStyle(color: Color(0xFFAAA098), fontSize: 12)),
        ),
      ],
    );
  }

  Future<void> _exportCSV(BuildContext context) async {
    try {
      final response = await ApiClient().get('/export/csv');
      final dir = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      final file = File('${dir.path}\\records_${DateTime.now().toIso8601String().split('T')[0]}.csv');
      await file.writeAsString(response.data.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出到 ${file.path}')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败，请检查网络')),
        );
      }
    }
  }

  Future<void> _exportJSON(BuildContext context) async {
    try {
      final result = await RecordApi.getRecords();
      if (result.data != null) {
        final dir = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
        final file = File('${dir.path}\\backup_${DateTime.now().toIso8601String().split('T')[0]}.json');
        await file.writeAsString(result.data.toString());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导出到 ${file.path}')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败')),
        );
      }
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('此操作不可恢复！将删除你所有的记账记录。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await RecordApi.getRecords();
        if (result.data != null) {
          for (final r in result.data!) {
            await RecordApi.deleteRecord(r.id);
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已清空所有数据')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('操作失败')),
          );
        }
      }
    }
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: const Color(0xFF3D362F).withAlpha(13), blurRadius: 16, offset: const Offset(0, 2)),
      ],
    );
  }

  Widget _settingItem(IconData icon, String title, VoidCallback onTap, {bool isDanger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDanger ? Colors.red : const Color(0xFFD4794A)),
            const SizedBox(width: 12),
            Text(title,
                style: TextStyle(color: isDanger ? Colors.red : const Color(0xFF3D362F), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
