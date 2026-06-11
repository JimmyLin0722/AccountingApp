class Transaction {
  final int? id;
  final int amount;
  final int categoryId;
  final String type; // 'expense' | 'income'
  final String? note;
  final String transactionDate;
  final String? createdAt;

  const Transaction({
    this.id,
    required this.amount,
    required this.categoryId,
    this.type = 'expense',
    this.note,
    required this.transactionDate,
    this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['transaction_id'] as int?,
        amount: map['amount'] as int,
        categoryId: map['category_id'] as int,
        type: map['type'] as String? ?? 'expense',
        note: map['note'] as String?,
        transactionDate: map['transaction_date'] as String,
        createdAt: map['created_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'transaction_id': id,
        'amount': amount,
        'category_id': categoryId,
        'type': type,
        if (note != null) 'note': note,
        'transaction_date': transactionDate,
      };

  Transaction copyWith({
    int? id,
    int? amount,
    int? categoryId,
    String? type,
    String? note,
    String? transactionDate,
  }) =>
      Transaction(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
        type: type ?? this.type,
        note: note ?? this.note,
        transactionDate: transactionDate ?? this.transactionDate,
        createdAt: createdAt,
      );
}
