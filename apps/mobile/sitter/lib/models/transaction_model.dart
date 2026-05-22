enum TxType { earning, withdrawal, purchase }

class Transaction {
  final TxType type;
  final String title;
  final String date;
  final String amount;
  final String status;
  final String txnId;

  // Earning fields
  final String? jobDate;
  final String? hoursWorked;
  final String? hourlyRate;
  final String? location;
  final String? children;

  // Withdrawal fields
  final String? method;
  final String? account;

  // Purchase fields
  final String? course;

  /// Extra `ledger_entries` columns when built from [fromLedgerRow].
  final Map<String, dynamic>? ledgerMeta;

  const Transaction({
    required this.type,
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.txnId,
    this.jobDate,
    this.hoursWorked,
    this.hourlyRate,
    this.location,
    this.children,
    this.method,
    this.account,
    this.course,
    this.ledgerMeta,
  });

  /// Maps a `ledger_entries` row from Supabase to the UI model.
  factory Transaction.fromLedgerRow(Map<String, dynamic> r) {
    final rawType = (r['type'] ?? '').toString();
    final TxType type = rawType == 'withdrawal'
        ? TxType.withdrawal
        : (rawType == 'refund' || rawType == 'adjustment')
            ? TxType.purchase
            : TxType.earning;
    final amt = r['amount'];
    final signed = rawType == 'withdrawal' ? '-\$$amt' : '+\$$amt';
    final created = r['created_at']?.toString() ?? '';
    final ref = (r['reference_type'] ?? 'ledger').toString();
    final id = (r['id'] ?? '').toString();
    final rid = r['reference_id']?.toString();
    final bal = r['balance_after']?.toString();
    return Transaction(
      type: type,
      title: ref,
      date: created.length >= 10 ? created.substring(0, 10) : created,
      amount: signed,
      status: 'posted',
      txnId: id.isEmpty ? '—' : id,
      jobDate: created.length >= 10 ? created.substring(0, 10) : null,
      ledgerMeta: {
        'raw_type': rawType,
        'reference_type': ref,
        'reference_id': rid,
        'balance_after': bal,
        'created_at': created,
      },
    );
  }
}
