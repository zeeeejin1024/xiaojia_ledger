import 'package:flutter/material.dart';
import 'package:xiaojia_ledger/modules/record/add_record_sheet.dart';
import 'package:xiaojia_ledger/modules/record/records_list_page.dart';
import 'package:xiaojia_ledger/modules/stats/stats_page.dart';
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
  bool _loading = true;

  final List<Widget> _pages = const [
    _HomeTab(),
    StatsPage(),
    RecordsListPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final month =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final result = await RecordApi.getRecords(month: month);
    if (result.isSuccess && result.data != null) {
      final records = result.data!;
      double income = 0, expense = 0, savings = 0;
      for (final r in records) {
        if (r.isIncome) income += r.amount;
        if (r.isExpense) expense += r.amount;
        if (r.isSavings) savings += r.amount;
      }
      if (mounted) {
        setState(() {
          _records = records;
          _income = income;
          _expense = expense;
          _savings = savings;
          _balance = income - expense - savings;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecordSheet(onSaved: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('小佳记账')),
      body: _currentIndex == 0
          ? _HomeTab(
              records: _records,
              income: _income,
              expense: _expense,
              balance: _balance,
              loading: _loading,
              onRefresh: _loadData,
              onOpenAdd: _openAddSheet,
            )
          : _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFFD4794A),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: '流水'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: const Color(0xFFD4794A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final List<Record> records;
  final double income, expense, balance;
  final bool loading;
  final VoidCallback onRefresh, onOpenAdd;

  const _HomeTab({
    required this.records,
    required this.income,
    required this.expense,
    required this.balance,
    required this.loading,
    required this.onRefresh,
    required this.onOpenAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BalanceCard(balance: balance, income: income, expense: expense),
          const SizedBox(height: 16),
          RecentRecords(records: records.take(5).toList()),
        ],
      ),
    );
  }
}
