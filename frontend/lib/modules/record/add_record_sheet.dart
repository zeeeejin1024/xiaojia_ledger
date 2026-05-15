import 'package:flutter/material.dart';
import 'package:xiaojia_ledger/data/api/category_api.dart';
import 'package:xiaojia_ledger/data/api/record_api.dart';
import 'package:xiaojia_ledger/data/models/category.dart';

class AddRecordSheet extends StatefulWidget {
  final VoidCallback? onSaved;

  const AddRecordSheet({super.key, this.onSaved});

  @override
  State<AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<AddRecordSheet> {
  String _type = 'expense';
  Category? _selectedCategory;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  final _searchCtrl = TextEditingController();
  List<Category> _leafCats = [];
  List<Category> _allCats = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await CategoryApi.getCategories();
    if (result.isSuccess && result.data != null) {
      _allCats = result.data!;
      _filter();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    var cats = _allCats.where((c) => c.type == _type).expand((c) => c.leafCategories).toList();
    if (q.isNotEmpty) cats = cats.where((c) => c.name.toLowerCase().contains(q)).toList();
    setState(() => _leafCats = cats);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _toast('请输入有效金额'); return;
    }
    if (_selectedCategory == null) {
      _toast('请选择分类'); return;
    }
    setState(() => _saving = true);
    final result = await RecordApi.addRecord(
      type: _type, amount: amount, categoryId: _selectedCategory!.id,
      date: _date.toIso8601String().split('T')[0],
      note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
    );
    if (mounted) {
      setState(() => _saving = false);
      if (result.isSuccess) {
        widget.onSaved?.call();
        Navigator.pop(context);
      } else {
        _toast(result.message);
      }
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  void dispose() {
    _amountCtrl.dispose(); _noteCtrl.dispose(); _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE0D8CE), borderRadius: BorderRadius.circular(2))),
          // Type switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              _typeBtn('expense', '支出'),
              _typeBtn('income', '收入'),
              _typeBtn('savings', '存钱'),
            ]),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _filter(),
              decoration: InputDecoration(
                hintText: '搜索分类...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: const Color(0xFFF0EBE4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Categories grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _leafCats.isEmpty
                    ? const Center(child: Text('无匹配分类', style: TextStyle(color: Color(0xFFAAA098))))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, childAspectRatio: 3.0, crossAxisSpacing: 8, mainAxisSpacing: 8,
                        ),
                        itemCount: _leafCats.length,
                        itemBuilder: (_, i) {
                          final cat = _leafCats[i];
                          final sel = _selectedCategory?.id == cat.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: Container(
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFFF8F3EC) : const Color(0xFFF5F1EB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: sel ? const Color(0xFFD4794A) : Colors.transparent, width: 1.5),
                              ),
                              child: Center(
                                child: Text('${cat.emoji ?? ''} ${cat.name}',
                                    style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Bottom inputs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(children: [
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
                decoration: const InputDecoration(hintText: '0.00', border: InputBorder.none),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F1EB), borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFFAAA098)),
                        const SizedBox(width: 6),
                        Text('${_date.month}/${_date.day}',
                            style: const TextStyle(fontSize: 14)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      hintText: '备注',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true, fillColor: const Color(0xFFF5F1EB),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4794A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('保 存', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(String type, String label) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() { _type = type; _selectedCategory = null; }); _filter(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? Colors.white : const Color(0xFFF0EBE4),
            borderRadius: BorderRadius.circular(14),
            boxShadow: active ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 1))] : null,
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontWeight: active ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
        ),
      ),
    );
  }
}
