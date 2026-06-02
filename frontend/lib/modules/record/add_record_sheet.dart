import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/theme.dart';
import 'package:xiaojia_ledger/data/api/category_api.dart';
import 'package:xiaojia_ledger/data/api/record_api.dart';
import 'package:xiaojia_ledger/data/api/api_client.dart';
import 'package:xiaojia_ledger/data/models/category.dart';

class AddRecordSheet extends StatefulWidget {
  final VoidCallback? onSaved;
  const AddRecordSheet({super.key, this.onSaved});
  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  String _type = 'expense'; Category? _cat;
  final _amt = TextEditingController(), _note = TextEditingController(), _search = TextEditingController();
  DateTime _date = DateTime.now();
  List<Category> _roots = [], _all = [];
  int? _expandedId;
  bool _load = true, _saving = false;
  Timer? _debounce;

  @override
  void initState() { super.initState(); _l(); _search.addListener(() { _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 150), () { if (mounted) setState(() {}); }); }); }

  Future<void> _l() async {
    final r = await CategoryApi.getCategories();
    if (r.isSuccess && r.data != null) { _all = r.data!; _f(); }
    if (mounted) setState(() => _load = false);
  }

  void _f() {
    _search.clear(); _expandedId = null;
    setState(() => _roots = _all.where((c) => c.type == _type).toList());
  }

  Future<void> _save() async {
    final a = double.tryParse(_amt.text);
    if (a == null || a <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额'))); return; }
    if (_cat == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择分类'))); return; }
    setState(() => _saving = true);
    final r = await RecordApi.addRecord(type: _type, amount: a, categoryId: _cat!.id, date: _date.toIso8601String().split('T')[0], note: _note.text.isNotEmpty ? _note.text : null);
    if (mounted) {
      setState(() => _saving = false);
      if (r.isSuccess) {
        HapticFeedback.mediumImpact();
        // 检查钱包预算提醒
        await _checkBudgetAlert(_cat!.id, a);
        widget.onSaved?.call();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message)));
      }
    }
  }

  Future<void> _checkBudgetAlert(int categoryId, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final active = prefs.getStringList('active_wallets') ?? [];
    if (!active.contains(categoryId.toString())) return;

    final budget = prefs.getDouble('wallet_budget_$categoryId') ?? 0;
    if (budget <= 0) return;

    // 获取当前总花费
    final r = await RecordApi.getRecords();
    if (!r.isSuccess || r.data == null) return;
    double totalSpent = 0;
    for (final record in r.data!) {
      if (!record.isIncome && record.categoryId == categoryId) {
        totalSpent += record.amount;
      }
    }

    final pct = totalSpent / budget;
    if (pct >= 1.0) {
      // 已经花超
      _showBudgetAlert(
        '超支提醒',
        '该分类已超支！预算 ¥${budget.toStringAsFixed(2)}，已花费 ¥${totalSpent.toStringAsFixed(2)}',
        true,
      );
    } else if (pct >= 0.8) {
      // 即将花超
      _showBudgetAlert(
        '即将超支',
        '该分类已花费 ${(pct * 100).toStringAsFixed(0)}%，预算 ¥${budget.toStringAsFixed(2)}，剩余 ¥${(budget - totalSpent).toStringAsFixed(2)}',
        false,
      );
    }
  }

  void _showBudgetAlert(String title, String message, bool isOverBudget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(isOverBudget ? Icons.warning_rounded : Icons.info_rounded, color: isOverBudget ? AppColors.danger : AppColors.highlight),
          SizedBox(width: 8),
          Text(title),
        ]),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('忽略', style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('我已知晓'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { _debounce?.cancel(); _amt.dispose(); _note.dispose(); _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final btm = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(bottom: btm),
      decoration: BoxDecoration(color: AppColors.bgSheet, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.gray, borderRadius: BorderRadius.circular(2))),
        SizedBox(height: 16),
        Text('记一笔', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
        SizedBox(height: 16),
        // Tabs
        Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          _tb('expense', '支出'), _tb('income', '收入'), _tb('savings', '存钱'),
        ])),
        SizedBox(height: 12),
        // 搜索
        Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: TextField(
          controller: _search,
          decoration: InputDecoration(hintText: '搜索分类...', prefixIcon: Icon(Icons.search, color: AppColors.gray, size: 18), filled: true, fillColor: AppColors.card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(vertical: 8), isDense: true),
          style: TextStyle(fontSize: 14),
        )),
        SizedBox(height: 12),
        // 分类 — 大类展开子类
        Expanded(child: _load
          ? Center(child: CircularProgressIndicator(color: AppColors.amber))
          : _roots.isEmpty
            ? Center(child: Text('暂无分类', style: TextStyle(color: AppColors.gray)))
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _roots.length + 1,
                itemBuilder: (_, i) {
                  if (i == _roots.length) return _addCustomBtn();
                  return _parentTile(_roots[i]);
                },
              )),
        // 底部
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(children: [
            if (_cat != null) Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.accent.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${_cat!.emoji ?? ''} ${_cat!.name}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.accentDark)),
                  SizedBox(width: 8),
                  GestureDetector(onTap: () => setState(() => _cat = null), child: Icon(Icons.close, size: 14, color: AppColors.gray)),
                ]),
              ),
            ),
            TextField(
              controller: _amt,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.ink),
              decoration: InputDecoration(hintText: '0.00', hintStyle: TextStyle(color: AppColors.gray), border: InputBorder.none),
            ),
            SizedBox(height: 10),
            Row(children: [
              Expanded(child: _datePicker()),
              SizedBox(width: 8),
              Expanded(child: _noteField()),
            ]),
            SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '保存中...' : '保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: () async {
        final p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
        if (p != null) setState(() => _date = p);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.calendar_today, size: 16, color: AppColors.gray),
          SizedBox(width: 6),
          Text('${_date.month}/${_date.day}', style: TextStyle(color: AppColors.ink, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _noteField() {
    return TextField(
      controller: _note,
      decoration: InputDecoration(
        hintText: '备注',
        hintStyle: TextStyle(color: AppColors.gray),
        border: InputBorder.none,
        filled: true,
        fillColor: AppColors.card,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      style: TextStyle(color: AppColors.ink, fontSize: 14),
    );
  }

  Widget _parentTile(Category parent) {
    final children = parent.children.where((c) => c.type == _type).toList();
    if (children.isEmpty) return SizedBox.shrink();
    final isExpanded = _expandedId == parent.id;
    return Column(children: [
      GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); setState(() => _expandedId = isExpanded ? null : parent.id); },
        child: Container(
          margin: EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: isExpanded ? AppColors.accent.withAlpha(15) : AppColors.card, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Text(parent.emoji ?? '', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Expanded(child: Text(parent.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink))),
            Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: AppColors.gray, size: 22),
          ]),
        ),
      ),
      if (isExpanded) Padding(
        padding: EdgeInsets.only(left: 12, bottom: 8),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          ...children.map((c) {
            final sel = _cat?.id == c.id;
            return GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); setState(() => _cat = c); _expandedId = null; },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: sel ? AppColors.accent.withAlpha(40) : AppColors.card, borderRadius: BorderRadius.circular(10), border: sel ? Border.all(color: AppColors.accent, width: 1.2) : null),
                child: Text('${c.emoji ?? ''} ${c.name}', style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? AppColors.accentDark : AppColors.ink)),
              ),
            );
          }),
          GestureDetector(
            onTap: () => _addCustom(parent),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: AppColors.gray.withAlpha(80), style: BorderStyle.solid), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 13, color: AppColors.gray), SizedBox(width: 2), Text('自定义', style: TextStyle(fontSize: 12, color: AppColors.gray))]),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _addCustomBtn() {
    return Padding(
      padding: EdgeInsets.only(top: 12, bottom: 16),
      child: GestureDetector(
        onTap: () => _addCustom(null),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(border: Border.all(color: AppColors.gray.withAlpha(60), style: BorderStyle.solid), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_circle_outline, size: 18, color: AppColors.gray),
            SizedBox(width: 6),
            Text('新建根分类', style: TextStyle(fontSize: 14, color: AppColors.gray)),
          ]),
        ),
      ),
    );
  }

  Future<void> _addCustom(Category? parent) async {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '📌');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('添加自定义分类'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [SizedBox(width: 60, child: Text('图标', style: TextStyle(color: AppColors.gray))), Expanded(child: TextField(controller: emojiCtrl, maxLength: 2, textAlign: TextAlign.center, style: TextStyle(fontSize: 24), decoration: InputDecoration(counterText: '')))]),
        SizedBox(height: 8),
        Row(children: [SizedBox(width: 60, child: Text('名称', style: TextStyle(color: AppColors.gray))), Expanded(child: TextField(controller: nameCtrl, decoration: InputDecoration(hintText: '如：买菜'), autofocus: true))]),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('添加'))],
    ));
    if (ok == true && nameCtrl.text.trim().isNotEmpty && mounted) {
      try {
        final body = <String, dynamic>{'name': nameCtrl.text.trim(), 'type': _type, 'emoji': emojiCtrl.text.isNotEmpty ? emojiCtrl.text : '📌'};
        if (parent != null) body['parent_id'] = parent.id;
        final r = await ApiClient().post('/categories', data: body);
        if (r.data['code'] == 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已添加 ${nameCtrl.text.trim()}')));
          _l(); // 刷新分类列表
        }
      } catch (_) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('添加失败'))); }
    }
  }

  Widget _tb(String type, String label) {
    final a = _type == type;
    return Expanded(child: GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); setState(() { _type = type; _cat = null; }); _f(); },
      child: Container(padding: EdgeInsets.symmetric(vertical: 12), margin: EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: a ? AppColors.amber.withAlpha(30) : AppColors.card, borderRadius: BorderRadius.circular(14), border: a ? Border.all(color: AppColors.amber.withAlpha(100)) : null), alignment: Alignment.center, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: a ? AppColors.ink : AppColors.gray, fontSize: 14))),
    ));
  }
}
