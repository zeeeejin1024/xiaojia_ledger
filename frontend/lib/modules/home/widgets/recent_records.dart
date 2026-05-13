import 'package:flutter/material.dart';
import 'package:xiaojia_ledger/data/models/record.dart';

class RecentRecords extends StatelessWidget {
  final List<Record> records;

  const RecentRecords({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('暂无记录\n点击 + 开始记账',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFAAA098), fontSize: 14)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('最近流水',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 2)),
          ),
          ...records.map((r) => _RecordRow(record: r)),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final Record record;
  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final sign = record.isIncome ? '+' : (record.isSavings ? '◎' : '-');
    final color = record.isIncome
        ? const Color(0xFF5C8F7A)
        : (record.isSavings ? const Color(0xFFD4794A) : const Color(0xFF3D362F));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(record.categoryEmoji ?? '●', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${record.date} ${record.note ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFAAA098))),
              ],
            ),
          ),
          Text('$sign¥${record.amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
