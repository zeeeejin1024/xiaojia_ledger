import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xiaojia_ledger/data/api/api_client.dart';
import 'package:xiaojia_ledger/data/models/category.dart';
import 'package:xiaojia_ledger/data/api/category_api.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  List<dynamic> _items = [];
  List<Category> _categories = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await CategoryApi.getCategories();
    if (result.data != null) {
      _categories = result.data!
          .expand((c) => c.leafCategories)
          .toList();
    }
  }

  Future<void> _parse(String csvContent, String source) async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().post('/sync/parse', data: {
        'content': csvContent,
        'source': source,
      });
      if (res.data['code'] == 0) {
        setState(() => _items = res.data['data']['items'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pasteAndParse(String source) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('粘贴${source == "wechat" ? "微信" : "支付宝"}账单 CSV'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: TextField(
            controller: ctrl,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: '从微信/支付宝导出的 CSV 内容粘贴到此处...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('解析'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      _parse(result, source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账单同步')),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📥', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  const Text('导入账单，自动匹配分类',
                      style: TextStyle(color: Color(0xFFAAA098))),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _pasteAndParse('wechat'),
                    icon: const Text('💬'),
                    label: const Text('导入微信账单'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _pasteAndParse('alipay'),
                    icon: const Text('🔵'),
                    label: const Text('导入支付宝账单'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_loading)
                  const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text('共 ${_items.length} 条待导入',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _items = []),
                        child: const Text('清除'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final matched = item['child_category'] ?? item['matched_category'] ?? '—';
                      return ListTile(
                        dense: true,
                        title: Text(item['merchant'] ?? item['note'] ?? '未知',
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text('${item['date']}  ${item['type']}  ¥${item['amount']}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFAAA098))),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F1EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(matched, style: const TextStyle(fontSize: 11)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
