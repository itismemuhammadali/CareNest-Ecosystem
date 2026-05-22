/// Client-side withdrawal rules (BACKEND RPC remains authoritative).

const double kDefaultWithdrawalMinAmount = 10;
const double kDefaultWithdrawalFeeRate = 0.02;

double parseWalletAvailableBalance(dynamic raw) {
  if (raw == null) return 0;
  if (raw is num) return raw.toDouble();
  return double.tryParse('$raw') ?? 0;
}

/// Returns `null` if the request is valid; otherwise a short user-visible message.
String? validateWithdrawalRequest({
  required double amount,
  required double available,
  double minAmount = kDefaultWithdrawalMinAmount,
  double feeRate = kDefaultWithdrawalFeeRate,
}) {
  if (amount.isNaN || amount.isInfinite) {
    return 'Enter a valid withdrawal amount.';
  }
  if (amount <= 0) {
    return 'Enter a valid withdrawal amount.';
  }
  if (amount < minAmount) {
    return 'Minimum withdrawal is \$10.';
  }
  final total = amount + amount * feeRate;
  if (total > available + 1e-6) {
    return 'Amount plus fee exceeds available balance.';
  }
  return null;
}

double withdrawalFee(double amount, {double feeRate = kDefaultWithdrawalFeeRate}) =>
    amount * feeRate;

double withdrawalTotalDebit(double amount, {double feeRate = kDefaultWithdrawalFeeRate}) =>
    amount + withdrawalFee(amount, feeRate: feeRate);
