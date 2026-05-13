import 'package:flutter/material.dart';
import 'package:xiaojia_ledger/data/api/record_api.dart';
import 'package:xiaojia_ledger/data/models/record.dart';

class RecordsListPage extends StatefulWidget {
  const RecordsListPage({super.key});

  @override
  State<RecordsListPage> createState() => _RecordsListPageState();
}

class _RecordsListPageState extends State<RecordsListPage> {
  List<Record> _records = [];
  List<Record> _filtered = [];
  bool _loading = true;
  String _filterType = '';
  String _filterCategory = '';
  String _filterDateFrom = '';
  String _filterDateTo = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final result = await RecordApi.getRecords(month: month);
    if (result.isSuccess && result.data != null) {
      _records = result.data!;
      _applyFilter();
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    _filtered = _records.where((r) {
      if (_filterType.isNotEmpty && r.type != _filterType) return false;
      if (_filterCategory.isNotEmpty && r.categoryName != _filterCategory) return false;
      if (_filterDateFrom.isNotEmpty && r.date.compareTo(_filterDateFrom) < 0) return false;
      if (_filterDateTo.isNotEmpty && r.date.compareTo(_filterDateTo) > 0) return false;
      return true;
    }).toList();
    setState(() {});
  }

  Future<void> _deleteRecord(Record r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除 ${r.categoryName} ¥${r.amount}？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await RecordApi.deleteRecord(r.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group records by date
    final groups = <String, List<Record>>{};
    for (final r in _filtered) {
      groups.putIfAbsent(r.date, () => []).add(r);
    }
    final dates = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildDropdown(
                '类型',
                _filterType,
                ['', 'expense', 'income', 'savings'],
                ['全部', '支出', '收入', '存钱'],
                (v) {
                  _filterType = v;
                  _applyFilter();
                },
              ),
              const SizedBox(width: 8),
              _buildDropdown(
                '分类',
                _filterCategory,
                ['', ..._records.map((r) => r.categoryName).toSet()],
                ['全部', ..._records.map((r) => r.categoryName).toSet()],
                (v) {
                  _filterCategory = v;
                  _applyFilter();
                },
              ),
            ],
          ),
        ),
        // Records list
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text('暂无记录', style: TextStyle(color: Color(0xFFAAA098))))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dates.length,
                    itemBuilder: (_, i) {
                      final date = dates[i];
                      final items = groups[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 4),
                            child: Text(date,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFAAA098))),
                          ),
                          ...items.map((r) => _buildRow(r)),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> values, List<String> labels,
      ValueChanged<String> onChanged) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? '' : value,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        isExpanded: true,
        items: List.generate(values.length, (i) {
          return DropdownMenuItem(value: values[i], child: Text(labels[i], style: const TextStyle(fontSize: 13)));
        }),
        onChanged: (v) => onChanged(v ?? ''),
      ),
    );
  }

  Widget _buildRow(Record r) {
    final sign = r.isIncome ? '+' : (r.isSavings ? '◎' : '-');
    final color = r.isIncome
        ? const Color(0xFF5C8F7A)
        : (r.isSavings ? const Color(0xFFD4794A) : const Color(0xFF3D362F));

    return GestureDetector(
      onLongPress: () => _deleteRecord(r),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEBE5DE), width: 0.5)),
        ),
        child: Row(
          children: [
            Text(r.categoryEmoji ?? '●', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.categoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (r.note != null && r.note!.isNotEmpty)
                    Text(r.note!, style: const TextStyle(fontSize: 12, color: Color(0xFFAAA098))),
                ],
              ),
            ),
            Text('$sign¥${r.amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
