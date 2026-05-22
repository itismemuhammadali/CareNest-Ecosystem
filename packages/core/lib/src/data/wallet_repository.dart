import 'package:supabase_flutter/supabase_flutter.dart';

import '../validation/withdrawal_validation.dart';

/// Sitter wallet + ledger (BACKEND.md §5 Migration 9).
class WalletRepository {
  WalletRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>?> myWallet() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await _client
        .from('wallets')
        .select()
        .eq('sitter_id', uid)
        .maybeSingle();
    return res == null ? null : Map<String, dynamic>.from(res as Map);
  }

  Stream<List<Map<String, dynamic>>> ledgerStream() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return _client
        .from('ledger_entries')
        .stream(primaryKey: ['id'])
        .eq('sitter_id', uid);
  }

  Future<String> requestWithdrawal({
    required double amount,
    required String method,
    Map<String, dynamic>? accountInfo,
    double? availableBalance,
  }) async {
    if (availableBalance != null) {
      final err = validateWithdrawalRequest(
        amount: amount,
        available: availableBalance,
      );
      if (err != null) throw ArgumentError(err);
    }
    final res = await _client.rpc(
      'request_withdrawal',
      params: {
        'p_amount': amount,
        'p_method': method,
        'p_account_info': accountInfo ?? <String, dynamic>{},
      },
    );
    return res.toString();
  }
}
