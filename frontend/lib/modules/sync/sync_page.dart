import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xiaojia_ledger/core/theme.dart';
import 'package:xiaojia_ledger/data/api/api_client.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});
  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  List<dynamic> _items = [];
  bool _loading = false;

  Future<void> _pasteAndParse(String source) async {
    final ctrl = TextEditingController();
    final label = source == 'wechat' ? '微信' : '支付宝';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('粘贴${label}账单 CSV'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: TextField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: '从$label导出的 CSV 内容粘贴到此处...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: Text('解析')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _loading = true);
      try {
        final res = await ApiClient().post('/sync/parse', data: {'content': result, 'source': source});
        if (res.data['code'] == 0) {
          setState(() => _items = res.data['data']['items'] ?? []);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? '解析失败')));
        }
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('同步失败，请重试')));
      }
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: _items.isEmpty ? _buildEmpty() : _buildList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.file_upload_rounded, color: Colors.white, size: 36),
        ),
        SizedBox(height: 20),
        Text('导入账单，自动匹配分类', style: TextStyle(fontSize: 14, color: AppColors.gray)),
        SizedBox(height: 4),
        Text('从微信/支付宝导出 CSV 文件后粘贴到此处', style: TextStyle(fontSize: 12, color: AppColors.gray.withAlpha(150))),
        SizedBox(height: 24),
        SizedBox(height: 48, child: ElevatedButton.icon(onPressed: () { HapticFeedback.lightImpact(); _pasteAndParse('wechat'); }, icon: Icon(Icons.chat_bubble_outline_rounded, size: 20), label: Text('导入微信账单'))),
        SizedBox(height: 10),
        SizedBox(height: 48, child: ElevatedButton.icon(onPressed: () { HapticFeedback.lightImpact(); _pasteAndParse('alipay'); }, icon: Icon(Icons.account_balance_rounded, size: 20), label: Text('导入支付宝账单'))),
      ]),
    );
  }

  Widget _buildList() {
    return Column(children: [
      if (_loading) const LinearProgressIndicator(),
      Padding(
        padding: EdgeInsets.all(12),
        child: Row(children: [
          Text('共 ${_items.length} 条待导入', style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton(onPressed: () => setState(() => _items = []), child: Text('清除')),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 12),
          itemCount: _items.length,
          separatorBuilder: (_, __) => Divider(),
          itemBuilder: (_, i) {
            final item = _items[i];
            return ListTile(
              dense: true,
              title: Text(item['merchant'] ?? item['note'] ?? '未知', style: TextStyle(fontSize: 14)),
              subtitle: Text('${item['date']}  ${item['type']}  ¥${item['amount']}', style: TextStyle(fontSize: 12, color: AppColors.gray)),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8)),
                child: Text(item['child_category'] ?? item['matched_category'] ?? '—', style: TextStyle(fontSize: 12)),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
