import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'hire_sitter_step2_screen.dart';
import '../widgets/hire_header.dart';

class HireSitterStep1Screen extends StatefulWidget {
  final String sitterName;
  final String hourlyRate;
  final String rating;
  final String jobCount;
  final String? sitterId;
  final String? sitterAvatarUrl;

  const HireSitterStep1Screen({
    super.key,
    required this.sitterName,
    required this.hourlyRate,
    this.rating = '—',
    this.jobCount = '—',
    this.sitterId,
    this.sitterAvatarUrl,
  });

  @override
  State<HireSitterStep1Screen> createState() => _HireSitterStep1ScreenState();
}

class _HireSitterStep1ScreenState extends State<HireSitterStep1Screen> {
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final TextEditingController _childrenController =
      TextEditingController(text: '1');

  @override
  void dispose() {
    _childrenController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';

  String _formatTime(TimeOfDay time, BuildContext context) =>
      time.format(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
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
          Column(
            children: [
              HireHeader(
                title: 'Hire ${widget.sitterName}',
                currentStep: 1,
                totalSteps: 4,
              ),
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
                      const SizedBox(height: 24),
                      const Text(
                        'When do you need babysitting?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select the date and time for your babysitting job',
                        style: TextStyle(fontSize: 13, color: Colors.white60),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0x991E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Date'),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) setState(() => selectedDate = date);
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.07),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedDate != null ? _formatDate(selectedDate!) : 'mm/dd/yyyy',
                                        style: TextStyle(fontSize: 14, color: selectedDate != null ? Colors.white : Colors.white38),
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Start Time'),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                          if (time != null) setState(() => startTime = time);
                                        },
                                        child: _timeBox(startTime != null ? _formatTime(startTime!, context) : '--:-- --', startTime != null),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('End Time'),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                          if (time != null) setState(() => endTime = time);
                                        },
                                        child: _timeBox(endTime != null ? _formatTime(endTime!, context) : '--:-- --', endTime != null),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFieldLabel('Number of Children'),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: TextField(
                                controller: _childrenController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgPicture.asset('assets/callender.svg', width: 20, height: 20,
                                colorFilter: const ColorFilter.mode(Color(0xFFA8D8EA), BlendMode.srcIn)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Quick Tip', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.sitterName} typically responds within 1 hour to booking requests',
                                    style: const TextStyle(fontSize: 12, color: Colors.white60, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
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
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HireSitterStep2Screen(
                      sitterName: widget.sitterName,
                      hourlyRate: widget.hourlyRate,
                      rating: widget.rating,
                      jobCount: widget.jobCount,
                      selectedDate: selectedDate,
                      startTime: startTime,
                      endTime: endTime,
                      numberOfChildren: int.tryParse(_childrenController.text.trim()) ?? 1,
                      sitterId: widget.sitterId,
                      sitterAvatarUrl: widget.sitterAvatarUrl,
                    )),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8F0FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Continue', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBox(String label, bool hasValue) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: hasValue ? Colors.white : Colors.white38))),
        const Icon(Icons.access_time, color: Colors.white38, size: 18),
      ],
    ),
  );

  Widget _buildFieldLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70),
  );
}

class _SitterMiniCard extends StatelessWidget {
  final String name, rating, jobCount, hourlyRate;
  final String? avatarUrl;
  const _SitterMiniCard({required this.name, required this.rating, required this.jobCount, required this.hourlyRate, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}
