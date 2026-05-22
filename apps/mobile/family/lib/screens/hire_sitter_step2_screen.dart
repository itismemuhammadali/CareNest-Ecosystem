import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/hire_header.dart';
import 'hire_sitter_step3_screen.dart';

class HireSitterStep2Screen extends StatefulWidget {
  final String sitterName;
  final String hourlyRate;
  final String rating;
  final String jobCount;
  final DateTime? selectedDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final int numberOfChildren;
  final String? sitterId;
  final String? sitterAvatarUrl;

  const HireSitterStep2Screen({
    super.key,
    required this.sitterName,
    required this.hourlyRate,
    this.rating = '—',
    this.jobCount = '—',
    this.selectedDate,
    this.startTime,
    this.endTime,
    this.numberOfChildren = 1,
    this.sitterId,
    this.sitterAvatarUrl,
  });

  @override
  State<HireSitterStep2Screen> createState() => _HireSitterStep2ScreenState();
}

class _HireSitterStep2ScreenState extends State<HireSitterStep2Screen> {
  final _specialRequirementsController = TextEditingController();

  @override
  void dispose() {
    _specialRequirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                HireHeader(title: 'Hire ${widget.sitterName}', currentStep: 2, totalSteps: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _SitterMiniCard(
                          name: widget.sitterName,
                          rating: widget.rating,
                          jobCount: widget.jobCount,
                          hourlyRate: widget.hourlyRate,
                          avatarUrl: widget.sitterAvatarUrl,
                        ),
                        const SizedBox(height: 28),
                        const Text('Any special requirements?',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(
                          'Let ${widget.sitterName} know what to expect',
                          style: const TextStyle(fontSize: 13, color: Colors.white60),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                                child: Text(
                                  'Special Instructions',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ),
                              TextField(
                                controller: _specialRequirementsController,
                                maxLines: 5,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Example: Allergies, bedtime routines, favorite\nactivities, dietary restrictions, etc...',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13, height: 1.5),
                                  filled: false,
                                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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
                              Row(
                                children: [
                                  Icon(Icons.person_outline, color: Colors.white.withValues(alpha: 0.7), size: 18),
                                  const SizedBox(width: 8),
                                  Text('What ${widget.sitterName} can help with:',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildInfoItem('Diaper changing'),
                              _buildInfoItem('Meal preparation'),
                              _buildInfoItem('Homework help'),
                              _buildInfoItem('Arts & crafts'),
                              _buildInfoItem('Bedtime routines'),
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HireSitterStep3Screen(
                      sitterName: widget.sitterName,
                      hourlyRate: widget.hourlyRate,
                      rating: widget.rating,
                      jobCount: widget.jobCount,
                      selectedDate: widget.selectedDate,
                      startTime: widget.startTime,
                      endTime: widget.endTime,
                      numberOfChildren: widget.numberOfChildren,
                      specialInstructions: _specialRequirementsController.text.trim(),
                      sitterId: widget.sitterId,
                      sitterAvatarUrl: widget.sitterAvatarUrl,
                    )),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8F0FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildInfoItem(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SvgPicture.asset('assets/tick-icon.svg', width: 20, height: 20),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.white70)),
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
