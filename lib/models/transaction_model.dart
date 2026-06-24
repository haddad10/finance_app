class TransactionModel {
  final String id;      
  final String docKey;  
  final String userId;
  final String type;   
  final double amount;
  final String category;
  final String note;
  final String createdAt;

  const TransactionModel({
    required this.id,
    required this.docKey,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Ambil amount — bisa int atau double dari server
    final raw = json['amount'];
    double amount = 0;
    if (raw is num) amount = raw.toDouble();

    // ID bisa berupa int (numerik) atau String (legacy)
    final rawId = json['id'];
    final String id = rawId != null ? rawId.toString() : '';

    // doc_key untuk operasi edit/hapus
    final String docKey = json['doc_key'] as String? ?? id;

    return TransactionModel(
      id: id,
      docKey: docKey,
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? 'expense',
      amount: amount,
      category: json['category'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  bool get isIncome => type == 'income';

  /// Untuk tampilan ID yang rapih: #1, #2, #3
  String get displayId => '#$id';

  Map<String, dynamic> toJson() => {
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
      };
}
