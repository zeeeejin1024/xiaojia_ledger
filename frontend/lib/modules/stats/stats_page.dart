import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:xiaojia_ledger/data/api/stats_api.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentMonth = DateTime.now();
  int _currentYear = DateTime.now().year;
  Map<String, dynamic>? _monthlyData;
  Map<String, dynamic>? _yearlyData;
  bool _loading = true;

  static const _colors = [
    Color(0xFFD4794A), Color(0xFF5C8F7A), Color(0xFF7B9E8F),
    Color(0xFFE8A87C), Color(0xFF8FBBA6), Color(0xFFC4A882),
    Color(0xFF6B8E7B), Color(0xFFD4C5B9), Color(0xFFA0C4A8),
    Color(0xFFB8956A), Color(0xFF4A7C6B), Color(0xFFE0C8A0),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  String get _monthStr =>
      '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      StatsApi.getMonthly(_monthStr),
      StatsApi.getYearly(_currentYear.toString()),
    ]);
    if (mounted) {
      setState(() {
        _monthlyData = results[0];
        _yearlyData = results[1];
        _loading = false;
      });
    }
  }

  void _shiftMonth(int delta) {
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta));
    _loadAll();
  }

  void _shiftYear(int delta) {
    setState(() => _currentYear += delta);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFAAA098),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: const Color(0xFFD4794A),
            borderRadius: BorderRadius.circular(24),
          ),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: '月度'),
            Tab(text: '年度'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [_buildMonthly(), _buildYearly()],
                ),
        ),
      ],
    );
  }

  // ========== Monthly ==========
  Widget _buildMonthly() {
    final d = _monthlyData;
    if (d == null) return const SizedBox();
    final income = (d['income'] as num?)?.toDouble() ?? 0;
    final expense = (d['expense'] as num?)?.toDouble() ?? 0;
    final savings = (d['savings'] as num?)?.toDouble() ?? 0;
    final balance = (d['balance'] as num?)?.toDouble() ?? 0;
    final incomeCats = (d['income_cats'] as Map<String, dynamic>?) ?? {};
    final expenseCats = (d['expense_cats'] as Map<String, dynamic>?) ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month nav
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left)),
            Text(DateFormat('yyyy年M月').format(_currentMonth),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 12),
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('收入', income, const Color(0xFF5C8F7A)),
              _summaryItem('支出', expense, const Color(0xFF3D362F)),
              _summaryItem('结余', balance, const Color(0xFFD4794A)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bar chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Column(
            children: [
              _buildBar('收入', income, max(income, max(expense, savings)), const Color(0xFF5C8F7A)),
              const SizedBox(height: 10),
              _buildBar('支出', expense, max(income, max(expense, savings)), const Color(0xFFAAA098)),
              const SizedBox(height: 10),
              _buildBar('存钱', savings, max(income, max(expense, savings)), const Color(0xFFD4794A)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Pie charts
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPie('收入分布', incomeCats, income)),
            const SizedBox(width: 12),
            Expanded(child: _buildPie('支出分布', expenseCats, expense)),
          ],
        ),
      ],
    );
  }

  Widget _buildBar(String label, double value, double maxVal, Color color) {
    final ratio = maxVal > 0 ? value / maxVal : 0.0;
    return Row(
      children: [
        SizedBox(width: 36, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFAAA098)))),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1EB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text('¥${value.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildPie(String title, Map<String, dynamic> data, double total) {
    final entries = data.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value));
    if (entries.isEmpty || total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDeco(),
        child: Column(children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          const Icon(Icons.pie_chart_outline, size: 80, color: Color(0xFFE0D8CE)),
          const Text('暂无数据', style: TextStyle(color: Color(0xFFAAA098), fontSize: 12)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 2)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            width: 90,
            child: PieChart(
              PieChartData(
                sectionsSpace: 1,
                centerSpaceRadius: 25,
                sections: entries.map((e) {
                  final i = entries.indexOf(e);
                  final pct = total > 0 ? ((e.value as num).toDouble() / total * 100) : 0.0;
                  return PieChartSectionData(
                    value: pct,
                    color: _colors[i % _colors.length],
                    showTitle: false,
                    radius: 40,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...entries.take(4).map((e) {
            final i = entries.indexOf(e);
            final pct = total > 0 ? ((e.value as num).toDouble() / total * 100) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _colors[i % _colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12))),
                  Text('¥${((e.value as num).toDouble()).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFAAA098))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ========== Yearly ==========
  Widget _buildYearly() {
    final d = _yearlyData;
    if (d == null) return const SizedBox();
    final months = (d['months'] as List<dynamic>?) ?? [];
    final totalIncome = (d['total_income'] as num?)?.toDouble() ?? 0;
    final totalExpense = (d['total_expense'] as num?)?.toDouble() ?? 0;
    final totalBalance = (d['total_balance'] as num?)?.toDouble() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: () => _shiftYear(-1), icon: const Icon(Icons.chevron_left)),
            Text('$_currentYear年', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            IconButton(onPressed: () => _shiftYear(1), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('年收入', totalIncome, const Color(0xFF5C8F7A)),
              _summaryItem('年支出', totalExpense, const Color(0xFF3D362F)),
              _summaryItem('年结余', totalBalance, const Color(0xFFD4794A)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (months.isEmpty)
          const Center(child: Text('暂无年度数据', style: TextStyle(color: Color(0xFFAAA098)))),
        if (months.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDeco(),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: months.fold(0.0, (max, m) {
                    final income = (m['income'] as num?)?.toDouble() ?? 0;
                    final expense = (m['expense'] as num?)?.toDouble() ?? 0;
                    return max > (income + expense) ? max : (income + expense);
                  }) * 1.2,
                  barGroups: months.map((m) {
                    final idx = months.indexOf(m);
                    final income = (m['income'] as num?)?.toDouble() ?? 0;
                    final expense = (m['expense'] as num?)?.toDouble() ?? 0;
                    final label = (m['month'] as String).substring(5);
                    return BarChartGroupData(x: idx, barRods: [
                      BarChartRodData(toY: income, color: const Color(0xFF5C8F7A), width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                      BarChartRodData(toY: expense, color: const Color(0xFFAAA098), width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    ]);
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i >= 0 && i < months.length) {
                            final label = (months[i]['month'] as String).substring(5);
                            return Text(label, style: const TextStyle(fontSize: 11));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        // Legend
        if (months.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF5C8F7A), '收入'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFAAA098), '支出'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFAAA098))),
      ],
    );
  }

  Widget _summaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFFAAA098))),
        const SizedBox(height: 4),
        Text('¥${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: const Color(0xFF3D362F).withAlpha(10), blurRadius: 16, offset: const Offset(0, 2))],
    );
  }
}
