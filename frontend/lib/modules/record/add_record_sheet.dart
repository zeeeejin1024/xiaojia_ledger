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
  String _date = DateTime.now().toIso8601String().split('T')[0];
  List<Category> _leafCategories = [];
  List<Category> _allCategories = [];
  bool _loadingCats = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await CategoryApi.getCategories();
    if (result.isSuccess && result.data != null) {
      _allCategories = result.data!;
      _updateLeafCategories();
    }
    if (mounted) setState(() => _loadingCats = false);
  }

  void _updateLeafCategories() {
    final cats = _allCategories
        .where((c) => c.type == _type)
        .expand((c) => c.leafCategories)
        .toList();
    setState(() => _leafCategories = cats);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      _showToast('请输入有效金额');
      return;
    }
    if (_selectedCategory == null) {
      _showToast('请选择分类');
      return;
    }

    setState(() => _saving = true);
    final result = await RecordApi.addRecord(
      type: _type,
      amount: amount,
      categoryId: _selectedCategory!.id,
      date: _date,
      note: _noteCtrl.text.isNotEmpty ? _noteCtrl.text : null,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (result.isSuccess) {
        Navigator.pop(context);
        widget.onSaved?.call();
      } else {
        _showToast(result.message);
      }
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE0D8CE), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          const Text('记一笔',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 3)),
          const SizedBox(height: 12),

          // Type switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _typeButton('expense', '支出'),
                _typeButton('income', '收入'),
                _typeButton('savings', '存钱'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Categories grid
          Expanded(
            child: _loadingCats
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.8,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _leafCategories.length,
                    itemBuilder: (_, i) {
                      final cat = _leafCategories[i];
                      final selected = _selectedCategory?.id == cat.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFF8F3EC) : const Color(0xFFF5F1EB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? const Color(0xFFD4794A) : Colors.transparent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${cat.emoji ?? ''} ${cat.name}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Amount, Date, Note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: _date),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(_date),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _date = picked.toIso8601String().split('T')[0]);
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: '日期',
                          prefixIcon: Icon(Icons.calendar_today, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(
                          hintText: '备注（可选）',
                          prefixIcon: Icon(Icons.edit, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('保 存'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeButton(String type, String label) {
    final active = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = type;
            _selectedCategory = null;
          });
          _updateLeafCategories();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? Colors.white : const Color(0xFFF0EBE4),
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14)),
        ),
      ),
    );
  }
}
