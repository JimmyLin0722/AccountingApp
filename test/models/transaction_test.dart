import 'package:flutter_test/flutter_test.dart';
import 'package:accounting_app/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    test('fromMap 正確解析所有欄位', () {
      final map = {
        'transaction_id': 10,
        'amount': 150,
        'category_id': 1,
        'transaction_date': '2026-06-11',
        'created_at': '2026-06-11 08:00:00',
      };
      final t = Transaction.fromMap(map);
      expect(t.id, 10);
      expect(t.amount, 150);
      expect(t.categoryId, 1);
      expect(t.transactionDate, '2026-06-11');
    });

    test('toMap 排除 null id', () {
      final t = Transaction(amount: 200, categoryId: 2, transactionDate: '2026-06-11');
      final map = t.toMap();
      expect(map.containsKey('transaction_id'), isFalse);
      expect(map['amount'], 200);
    });

    test('toMap 包含非 null id', () {
      final t = Transaction(id: 5, amount: 300, categoryId: 3, transactionDate: '2026-06-10');
      final map = t.toMap();
      expect(map['transaction_id'], 5);
    });
  });
}
