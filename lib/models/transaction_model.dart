class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'income' | 'expense'
  final double amount;
  final String category;
  final String note;
  final String createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final raw = json['amount'];
    double amount = 0;
    if (raw is num) amount = raw.toDouble();

    return TransactionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? 'expense',
      amount: amount,
      category: json['category'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  bool get isIncome => type == 'income';

  Map<String, dynamic> toJson() => {
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
      };
}
