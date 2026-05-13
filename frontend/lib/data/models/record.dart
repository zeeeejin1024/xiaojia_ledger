class Record {
  final int id;
  final String type;
  final double amount;
  final int categoryId;
  final String categoryName;
  final String? categoryEmoji;
  final String date;
  final String? note;

  Record({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    this.categoryEmoji,
    required this.date,
    this.note,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? '',
      categoryEmoji: json['category_emoji'],
      date: json['date'],
      note: json['note'],
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isSavings => type == 'savings';
}
