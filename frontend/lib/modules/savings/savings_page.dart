import 'package:flutter/material.dart';
import 'package:xiaojia_ledger/data/api/savings_api.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<dynamic> _goals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _goals = await SavingsApi.getGoals();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createGoal() async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('创建存钱目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '目标名称')),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: '目标金额'), keyboardType: TextInputType.number),
            TextField(controller: deadlineCtrl, decoration: const InputDecoration(labelText: '截止日期（可选，如 2026-12-31）')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('创建')),
        ],
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final amount = double.tryParse(amountCtrl.text);
      if (name.isNotEmpty && amount != null && amount > 0) {
        await SavingsApi.createGoal(
          name, amount,
          deadline: deadlineCtrl.text.isNotEmpty ? deadlineCtrl.text : null,
        );
        _load();
      }
    }
  }

  Future<void> _deposit(dynamic goal) async {
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('存入 ${goal['name']}'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '金额'), keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('存入')),
        ],
      ),
    );

    if (result == true) {
      final amount = double.tryParse(ctrl.text);
      if (amount != null && amount > 0) {
        await SavingsApi.deposit(goal['id'], amount);
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('存钱')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGoal,
        backgroundColor: const Color(0xFFD4794A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💰', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('还没有存钱目标', style: TextStyle(color: Color(0xFFAAA098))),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _createGoal, child: const Text('创建第一个目标')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _goals.map((g) => _GoalCard(
                  goal: g,
                  onDeposit: () => _deposit(g),
                  onDelete: () async {
                    await SavingsApi.deleteGoal(g['id']);
                    _load();
                  },
                )).toList(),
              ),
            ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final dynamic goal;
  final VoidCallback onDeposit, onDelete;

  const _GoalCard({required this.goal, required this.onDeposit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name = goal['name'] ?? '';
    final target = (goal['target_amount'] as num?)?.toDouble() ?? 0;
    final current = (goal['current_amount'] as num?)?.toDouble() ?? 0;
    final progress = target > 0 ? current / target : 0.0;
    final emoji = goal['emoji'] ?? '💰';
    final completed = goal['is_completed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF3D362F).withAlpha(13), blurRadius: 16, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$emoji ', style: const TextStyle(fontSize: 28)),
              Expanded(
                child: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              if (completed)
                const Icon(Icons.check_circle, color: Color(0xFF5C8F7A)),
            ],
          ),
          const SizedBox(height: 12),
          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFEBE5DE),
              valueColor: AlwaysStoppedAnimation<Color>(
                  completed ? const Color(0xFF5C8F7A) : const Color(0xFFD4794A)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('¥${current.toStringAsFixed(0)} / ¥${target.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 14, color: completed ? const Color(0xFF5C8F7A) : const Color(0xFFAAA098))),
            ],
          ),
          if (goal['deadline'] != null) ...[
            const SizedBox(height: 4),
            Text('截止: ${goal['deadline']}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFAAA098))),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: completed ? null : onDeposit,
                  child: const Text('存入一笔'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('删除目标'),
                      content: Text('确定删除「$name」吗？'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirmed == true) onDelete();
                },
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFAAA098)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
