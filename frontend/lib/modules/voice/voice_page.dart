import 'package:flutter/material.dart';
import 'package:xiaojia_ledger/core/theme.dart';
import 'package:xiaojia_ledger/data/api/api_client.dart';
import 'package:xiaojia_ledger/data/api/record_api.dart';
import 'package:xiaojia_ledger/data/api/category_api.dart';

class VoicePage extends StatefulWidget {
  const VoicePage({super.key});
  @override
  State<VoicePage> createState() => _VoicePageState();
}

class _VoicePageState extends State<VoicePage> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  bool _saving = false;
  Map<String, dynamic>? _parsed;

  Future<void> _parse() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await ApiClient().post('/ai/parse', data: {'text': text});
      if (res.data['code'] == 0) {
        setState(() => _parsed = res.data['data']);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.data['message'] ?? '解析失败')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('网络错误，请重试')));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_parsed == null) return;
    final p = _parsed!;
    final type = p['type'] ?? 'expense';
    final amount = double.tryParse((p['amount'] ?? '0').toString()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('金额无效')));
      return;
    }
    setState(() => _saving = true);
    try {
      int catId = p['category_id'] ?? 1;
      // 如果没有 category_id，尝试按名称匹配
      if (catId <= 1) {
        try {
          final cats = await CategoryApi.getCategories();
          if (cats.isSuccess && cats.data != null) {
            final allLeaf = cats.data!.where((c) => c.type == type).expand((c) => c.leafCategories).toList();
            final catName = p['category']?.toString() ?? '';
            final found = allLeaf.where((c) => c.name == catName || c.name.contains(catName) || catName.contains(c.name));
            if (found.isNotEmpty) {
              catId = found.first.id;
            } else if (allLeaf.isNotEmpty) {
              catId = allLeaf.first.id; // fallback 到第一个匹配类型的分类
            }
          }
        } catch (_) {}
      }
      final r = await RecordApi.addRecord(type: type, amount: amount, categoryId: catId, date: DateTime.now().toIso8601String().split('T')[0], note: _ctrl.text.trim());
      if (mounted) {
        if (r.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
          _parsed = null;
          _ctrl.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
        }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text('语音记账'), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(child: Padding(padding: EdgeInsets.all(24), child: Column(children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.goldLight, AppColors.goldDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.gold.withAlpha(50), blurRadius: 20)]), child: Icon(Icons.mic_rounded, color: Colors.white, size: 36)),
        SizedBox(height: 20),
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(hintText: '输入消费文字，如：午餐花了22元', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: _ctrl.text.isNotEmpty && !_loading ? _parse : null,
            child: Text(_loading ? '解析中...' : 'AI 解析'),
          ),
        ),
        if (_parsed != null) ...[
          SizedBox(height: 16),
          AppCard(child: Column(children: [
            Text('类型: ${_parsed!['type'] == 'income' ? '收入' : '支出'}', style: TextStyle(color: AppColors.ink)),
            Text('金额: ¥${_parsed!['amount']}', style: TextStyle(color: AppColors.ink)),
            Text('分类: ${_parsed!['category'] ?? '未知'}', style: TextStyle(color: AppColors.ink)),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 44,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.sage),
                child: Text(_saving ? '保存中...' : '保存记录'),
              ),
            ),
          ])),
        ],
      ]))),
    );
  }
}
