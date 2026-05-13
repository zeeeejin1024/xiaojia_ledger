import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:xiaojia_ledger/modules/record/add_record_sheet.dart';
import 'package:xiaojia_ledger/modules/record/records_list_page.dart';
import 'package:xiaojia_ledger/modules/stats/stats_page.dart';
import 'package:xiaojia_ledger/modules/savings/savings_page.dart';
import 'package:xiaojia_ledger/modules/settings/settings_page.dart';
import 'package:xiaojia_ledger/modules/home/widgets/balance_card.dart';
import 'package:xiaojia_ledger/modules/home/widgets/recent_records.dart';
import 'package:xiaojia_ledger/data/api/record_api.dart';
import 'package:xiaojia_ledger/data/models/record.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<Record> _records = [];
  double _income = 0, _expense = 0, _savings = 0, _balance = 0;
  Map<String, double> _incomeCats = {};
  Map<String, double> _expenseCats = {};
  bool _loading = true;

  static const _pieColors = [
    Color(0xFFD4794A), Color(0xFF5C8F7A), Color(0xFF7B9E8F),
    Color(0xFFE8A87C), Color(0xFF8FBBA6), Color(0xFFC4A882),
    Color(0xFF6B8E7B), Color(0xFFD4C5B9), Color(0xFFA0C4A8),
    Color(0xFFB8956A),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final result = await RecordApi.getRecords(month: month);
    if (result.isSuccess && result.data != null) {
      final records = result.data!;
      double income = 0, expense = 0, savings = 0;
      final incCats = <String, double>{};
      final expCats = <String, double>{};

      for (final r in records) {
        if (r.isIncome) {
          income += r.amount;
          incCats[r.categoryName] = (incCats[r.categoryName] ?? 0) + r.amount;
        } else if (r.isExpense) {
          expense += r.amount;
          expCats[r.categoryName] = (expCats[r.categoryName] ?? 0) + r.amount;
        } else {
          savings += r.amount;
        }
      }
      if (mounted) {
        setState(() {
          _records = records;
          _income = income;
          _expense = expense;
          _savings = savings;
          _balance = income - expense - savings;
          _incomeCats = incCats;
          _expenseCats = expCats;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetail(String title, Map<String, double> data, double total) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDFBF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailSheet(title: title, data: data, total: total),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomeTab(),
      const StatsPage(),
      const SavingsPage(),
      const RecordsListPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(title: const Text('小佳记账'))
          : null,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFFD4794A),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: '统计'),
          BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), activeIcon: Icon(Icons.savings), label: '存钱'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '流水'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddRecordSheet(onSaved: _loadData),
        ),
        backgroundColor: const Color(0xFFD4794A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BalanceCard(balance: _balance, income: _income, expense: _expense),
          const SizedBox(height: 12),
          // Quick cards
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  emoji: '📈',
                  label: '收入',
                  amount: _income,
                  color: const Color(0xFF5C8F7A),
                  onTap: () => _showDetail('收入分布', _incomeCats, _income),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  emoji: '📉',
                  label: '支出',
                  amount: _expense,
                  color: const Color(0xFF3D362F),
                  onTap: () => _showDetail('支出分布', _expenseCats, _expense),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RecentRecords(records: _records.take(5).toList()),
        ],
      ),
    );
  }
}

// ===== Quick Card =====
class _QuickCard extends StatelessWidget {
  final String emoji, label;
  final double amount;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.emoji,
    required this.label,
    required this.amount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF3D362F).withAlpha(13), blurRadius: 16, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFFAAA098), fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('¥${amount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

// ===== Detail Sheet =====
class _DetailSheet extends StatelessWidget {
  final String title;
  final Map<String, double> data;
  final double total;

  const _DetailSheet({required this.title, required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        child: const Center(child: Text('暂无数据', style: TextStyle(color: Color(0xFFAAA098)))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(
              color: const Color(0xFFE0D8CE), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 3)),
          const SizedBox(height: 16),
          SizedBox(
            height: 130, width: 130,
            child: PieChart(PieChartData(
              sectionsSpace: 1,
              centerSpaceRadius: 35,
              sections: entries.map((e) {
                final i = entries.indexOf(e);
                final pct = total > 0 ? e.value / total * 100 : 0.0;
                return PieChartSectionData(
                  value: pct, color: _HomePageState._pieColors[i % 10],
                  showTitle: false, radius: 50,
                );
              }).toList(),
            )),
          ),
          const SizedBox(height: 16),
          ...entries.take(6).map((e) {
            final i = entries.indexOf(e);
            final pct = total > 0 ? e.value / total * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(
                    color: _HomePageState._pieColors[i % 10], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(e.key, style: const TextStyle(fontSize: 14))),
                Text('¥${e.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Text('${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFAAA098))),
              ]),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
