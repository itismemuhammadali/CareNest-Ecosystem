import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/hire_header.dart';
import 'hire_sitter_step4_screen.dart';

class HireSitterStep3Screen extends StatelessWidget {
  final String sitterName;
  final String hourlyRate;
  final String rating;
  final String jobCount;
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int numberOfChildren;
  final String specialInstructions;
  final String? sitterId;
  final String? sitterAvatarUrl;

  const HireSitterStep3Screen({
    super.key,
    required this.sitterName,
    required this.hourlyRate,
    this.rating = '—',
    this.jobCount = '—',
    this.selectedDate,
    this.startTime,
    this.endTime,
    this.numberOfChildren = 1,
    this.specialInstructions = '',
    this.sitterId,
    this.sitterAvatarUrl,
  });

  double? _estimatedHours() {
    if (startTime == null || endTime == null) return null;
    final startMins = startTime!.hour * 60 + startTime!.minute;
    final endMins = endTime!.hour * 60 + endTime!.minute;
    final diff = endMins - startMins;
    if (diff <= 0) return null;
    return diff / 60.0;
  }

  String? _estimatedTotal() {
    final rateStr = hourlyRate.replaceAll(RegExp(r'[^\d.]'), '');
    final rate = double.tryParse(rateStr);
    final hours = _estimatedHours();
    if (rate == null || hours == null) return null;
    return '\$${(rate * hours).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final hours = _estimatedHours();
    final total = _estimatedTotal();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/screen-bg.jpg'), fit: BoxFit.cover),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC0F172A), Color(0xFF0F172A)],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                HireHeader(title: 'Hire $sitterName', currentStep: 3, totalSteps: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _SitterMiniCard(name: sitterName, rating: rating, jobCount: jobCount, hourlyRate: hourlyRate, avatarUrl: sitterAvatarUrl),
                        const SizedBox(height: 28),
                        const Text('Confirm hourly rate',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        const Text('Review the pricing for this job',
                            style: TextStyle(fontSize: 13, color: Colors.white60)),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            children: [
                              _rateRow('Hourly Rate', hourlyRate),
                              const SizedBox(height: 16),
                              _rateRow(
                                'Estimated Duration',
                                hours != null ? '~${hours.toStringAsFixed(1)} hours' : 'Not set',
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Estimated Total',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text(
                                    total ?? '—',
                                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("This is $sitterName's standard rate.",
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Final payment is based on actual hours worked and calculated automatically.',
                                      style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("What's Included:",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 14),
                              _includedItem('Automatic time tracking', 'Precise start and end time recording'),
                              _includedItem('Real-time updates', 'Get notified when babysitter arrives/leaves'),
                              _includedItem('Secure payment processing', 'Your payment info is encrypted and protected'),
                              _includedItem('24/7 safety support', 'Access to emergency support anytime', isLast: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 53,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 53,
                child: ElevatedButton(
                  onPressed: _estimatedHours() == null
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('End time must be after start time.')),
                          );
                        }
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => HireSitterStep4Screen(
                              sitterName: sitterName,
                              hourlyRate: hourlyRate,
                              rating: rating,
                              jobCount: jobCount,
                              selectedDate: selectedDate,
                              startTime: startTime,
                              endTime: endTime,
                              numberOfChildren: numberOfChildren,
                              estimatedTotal: total,
                              sitterId: sitterId,
                              sitterAvatarUrl: sitterAvatarUrl,
                            )),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8F0FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Continue', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.white60)),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
    ],
  );

  Widget _includedItem(String title, String subtitle, {bool isLast = false}) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SvgPicture.asset('assets/tick-icon.svg', width: 20, height: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.3)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SitterMiniCard extends StatelessWidget {
  final String name, rating, jobCount, hourlyRate;
  final String? avatarUrl;
  const _SitterMiniCard({required this.name, required this.rating, required this.jobCount, required this.hourlyRate, this.avatarUrl});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0x991E293B), borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: const Color(0xFF1E293B),
          backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
              ? NetworkImage(avatarUrl!) as ImageProvider
              : null,
          child: (avatarUrl == null || avatarUrl!.isEmpty)
              ? const Icon(Icons.person, color: Colors.white38, size: 28)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                const SizedBox(width: 4),
                Text('$rating • $jobCount jobs', style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.attach_money, color: Color(0xFFC8F0FF), size: 14),
                Text(hourlyRate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC8F0FF))),
              ]),
            ],
          ),
        ),
      ],
    ),
  );
}
