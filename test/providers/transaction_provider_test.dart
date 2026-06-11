import 'package:flutter_test/flutter_test.dart';
import 'package:accounting_app/providers/transaction_provider.dart';

void main() {
  group('TransactionProvider — 鍵盤輸入邏輯', () {
    late TransactionProvider provider;

    setUp(() {
      provider = TransactionProvider.test();
    });

    test('appendDigit 正常附加數字', () {
      provider.appendDigit('1');
      provider.appendDigit('2');
      provider.appendDigit('3');
      expect(provider.displayAmount, '123');
    });

    test('appendDigit 忽略開頭 0', () {
      provider.appendDigit('0');
      expect(provider.displayAmount, '0');
      provider.appendDigit('0');
      expect(provider.displayAmount, '0');
    });

    test('appendDigit 上限 7 位數', () {
      for (var i = 0; i < 10; i++) {
        provider.appendDigit('9');
      }
      expect(provider.displayAmount.length, 7);
    });

    test('deleteDigit 退格正常', () {
      provider.appendDigit('5');
      provider.appendDigit('0');
      provider.deleteDigit();
      expect(provider.displayAmount, '5');
    });

    test('deleteDigit 空字串時不拋出例外', () {
      expect(() => provider.deleteDigit(), returnsNormally);
      expect(provider.displayAmount, '0');
    });
  });

  group('TransactionProvider — 驗證邏輯', () {
    late TransactionProvider provider;

    setUp(() {
      provider = TransactionProvider.test();
    });

    test('金額為空時回傳錯誤訊息', () async {
      final err = await provider.saveTransaction();
      expect(err, isNotNull);
      expect(err, contains('金額'));
    });

    test('未選類別時回傳錯誤訊息', () async {
      provider.appendDigit('1');
      provider.appendDigit('0');
      final err = await provider.saveTransaction();
      expect(err, isNotNull);
      expect(err, contains('類別'));
    });
  });
}
