import 'package:flutter_test/flutter_test.dart';
import 'package:star_sitters_core/star_sitters_core.dart';

void main() {
  group('parseWalletAvailableBalance', () {
    test('handles null, num, int, string', () {
      expect(parseWalletAvailableBalance(null), 0);
      expect(parseWalletAvailableBalance(100), 100);
      expect(parseWalletAvailableBalance(100.25), 100.25);
      expect(parseWalletAvailableBalance('42.5'), 42.5);
      expect(parseWalletAvailableBalance('x'), 0);
    });
  });

  group('validateWithdrawalRequest', () {
    test('allows amount when total with fee fits', () {
      expect(
        validateWithdrawalRequest(amount: 100, available: 102),
        isNull,
      );
    });

    test('rejects when amount + fee exceeds available', () {
      expect(
        validateWithdrawalRequest(amount: 100, available: 101.99),
        isNotNull,
      );
      expect(
        validateWithdrawalRequest(amount: 100, available: 100),
        isNotNull,
      );
    });

    test('minimum 10', () {
      expect(validateWithdrawalRequest(amount: 9.99, available: 1000), isNotNull);
      expect(validateWithdrawalRequest(amount: 10, available: 10.2), isNull);
    });

    test('rejects non-positive and non-finite', () {
      expect(validateWithdrawalRequest(amount: 0, available: 100), isNotNull);
      expect(validateWithdrawalRequest(amount: -1, available: 100), isNotNull);
      expect(validateWithdrawalRequest(amount: double.nan, available: 100), isNotNull);
      expect(validateWithdrawalRequest(amount: double.infinity, available: 1e9), isNotNull);
    });
  });

  group('withdrawalFee / withdrawalTotalDebit', () {
    test('2% fee and total', () {
      expect(withdrawalFee(100), 2);
      expect(withdrawalTotalDebit(100), 102);
    });
  });
}
