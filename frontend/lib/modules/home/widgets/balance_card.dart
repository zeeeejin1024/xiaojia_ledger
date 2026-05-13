import 'package:flutter/material.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final total = income + expense;
    final ratio = total > 0 ? income / total : 0.5;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D362F).withAlpha(13),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('本月结余',
              style: TextStyle(fontSize: 13, color: Color(0xFFAAA098), letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(
            '¥ ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Color(0xFFD4794A),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('收入 ¥${income.toStringAsFixed(0)}',
                  style: const TextStyle(color: Color(0xFF5C8F7A), fontSize: 13)),
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE5DE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4794A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              Text('支出 ¥${expense.toStringAsFixed(0)}',
                  style: const TextStyle(color: Color(0xFF3D362F), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
