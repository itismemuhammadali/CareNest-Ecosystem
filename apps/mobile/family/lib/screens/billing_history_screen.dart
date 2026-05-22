import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/header2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BillingHistoryScreen extends StatelessWidget {
  const BillingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            const Header2(title: 'Manage Billing'),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: WalletRepository(Supabase.instance.client).ledgerStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}', style: const TextStyle(color: Colors.white70)));
                  }
                  final entries = snapshot.data ?? [];

                  double totalSpent = 0;
                  for (final e in entries) {
                    final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
                    if (amt < 0) totalSpent += amt.abs();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 24),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(color: Color(0xFFA8D8EA), shape: BoxShape.circle),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/paymentMethod.svg',
                              width: 40,
                              height: 40,
                              colorFilter: const ColorFilter.mode(Color(0xFF0F172A), BlendMode.srcIn),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Billing History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        const Text('View and download past invoices', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text('Total Spent (All Time)', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Text(
                                '\$${totalSpent.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFA8D8EA)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entries.length} transaction${entries.length == 1 ? '' : 's'}',
                                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        if (entries.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('No transactions yet.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          )
                        else
                          ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (ctx, i) => _buildTransactionCard(ctx, entries[i]),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Back to Billing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '📄 Invoices are available for download for up to 12 months',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadInvoice(BuildContext context, Map<String, dynamic> entry) {
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
    final description = entry['description']?.toString() ?? 'Transaction';
    final createdAt = entry['created_at'] != null
        ? DateTime.tryParse(entry['created_at'].toString())
        : null;
    final dateStr = createdAt != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toLocal())
        : '—';
    final entryType = entry['entry_type']?.toString() ?? '';
    final invoiceId = entry['id']?.toString() ?? '—';

    final lines = [
      'STARSITTERS — INVOICE',
      '=' * 40,
      'Invoice ID  : $invoiceId',
      'Date        : $dateStr',
      'Type        : ${entryType.replaceAll("_", " ")}',
      'Description : $description',
      'Amount      : ${amount >= 0 ? "+" : ""}\$${amount.toStringAsFixed(2)}',
      '=' * 40,
      'Thank you for using StarSitters.',
    ];
    final content = lines.join('\n');

    // On mobile, show a snackbar with invoice details
    // On web, download the file (web-only code would go here)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invoice: $description  ${amount >= 0 ? "+" : ""}\$${amount.toStringAsFixed(2)}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> entry) {
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
    final description = entry['description']?.toString() ?? 'Transaction';
    final createdAt = entry['created_at'] != null ? DateTime.tryParse(entry['created_at'].toString()) : null;
    final dateStr = createdAt != null ? DateFormat.yMMMd().format(createdAt.toLocal()) : '—';
    final entryType = entry['entry_type']?.toString() ?? '';
    final isCredit = amount >= 0;
    final statusColor = isCredit ? const Color(0xFF4ADE80) : const Color(0xFF60A5FA);
    final statusLabel = entryType.isNotEmpty ? entryType.replaceAll('_', ' ') : (isCredit ? 'Credit' : 'Charge');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isCredit ? '+' : '-'}\$${amount.abs().toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadInvoice(context, entry),
                  icon: const Icon(Icons.download_outlined, size: 14, color: Color(0xFFC8F0FF)),
                  label: const Text('Download', style: TextStyle(color: Color(0xFFC8F0FF))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
