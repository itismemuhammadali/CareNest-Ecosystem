import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/job_post_session.dart';
import '../widgets/primary_button.dart';
import '../widgets/hire_header.dart';
import 'post_new_job_step2_screen.dart';

class PostNewJobStep1Screen extends StatefulWidget {
  const PostNewJobStep1Screen({super.key});

  @override
  State<PostNewJobStep1Screen> createState() => _PostNewJobStep1ScreenState();
}

class _PostNewJobStep1ScreenState extends State<PostNewJobStep1Screen> {
  final _descriptionController = TextEditingController();
  final _specialRequirementsController = TextEditingController();

  String _dateDisplay = '';
  String _startTimeDisplay = '';
  String _endTimeDisplay = '';
  int _childrenCount = 2;

  static const _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0x26FFFFFF)),
  );
  static const _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0x66FFFFFF)),
  );

  @override
  void dispose() {
    _descriptionController.dispose();
    _specialRequirementsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFC8F0FF),
            onPrimary: Color(0xFF0F172A),
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateDisplay = DateFormat('MM/dd/yyyy').format(picked));
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFC8F0FF),
            onPrimary: Color(0xFF0F172A),
            surface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '$hour:$minute $period';
      setState(() {
        if (isStart) {
          _startTimeDisplay = formatted;
        } else {
          _endTimeDisplay = formatted;
        }
      });
    }
  }

  Widget _buildTappableField({
    required String label,
    required String value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? hint : value,
                    style: TextStyle(
                      color: value.isEmpty
                          ? const Color(0x61FFFFFF)
                          : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(icon, color: const Color(0x61FFFFFF), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
                colors: [Color(0xB30F172A), Color(0xFF0F172A)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                HireHeader(title: 'Post New Job', currentStep: 1, totalSteps: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Job Detail',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Descriptions',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Details about role etc',
                            hintStyle: TextStyle(color: Color(0x61FFFFFF)),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: _inputBorder,
                            enabledBorder: _inputBorder,
                            focusedBorder: _focusedBorder,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTappableField(
                          label: 'Enter Date',
                          value: _dateDisplay,
                          hint: 'mm/dd/yyyy',
                          icon: Icons.calendar_today,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 16),
                        _buildTappableField(
                          label: 'Start Time',
                          value: _startTimeDisplay,
                          hint: '--:-- --',
                          icon: Icons.access_time,
                          onTap: () => _pickTime(isStart: true),
                        ),
                        const SizedBox(height: 16),
                        _buildTappableField(
                          label: 'Expected End Time',
                          value: _endTimeDisplay,
                          hint: '--:-- --',
                          icon: Icons.access_time,
                          onTap: () => _pickTime(isStart: false),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Number of Children',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Color(0x99FFFFFF),
                                ),
                                onPressed: _childrenCount > 1
                                    ? () =>
                                        setState(() => _childrenCount--)
                                    : null,
                              ),
                              SizedBox(
                                width: 48,
                                child: Text(
                                  '$_childrenCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0x99FFFFFF),
                                ),
                                onPressed: _childrenCount < 10
                                    ? () =>
                                        setState(() => _childrenCount++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Special Requirements',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _specialRequirementsController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText:
                                'Any special needs, allergies, or instructions...',
                            hintStyle: TextStyle(color: Color(0x61FFFFFF)),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: _inputBorder,
                            enabledBorder: _inputBorder,
                            focusedBorder: _focusedBorder,
                          ),
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: 'Continue',
                          onPressed: () {
                            JobPostSession.description =
                                _descriptionController.text;
                            JobPostSession.dateStr = _dateDisplay;
                            JobPostSession.startTimeStr = _startTimeDisplay;
                            JobPostSession.endTimeStr = _endTimeDisplay;
                            JobPostSession.specialRequirements =
                                _specialRequirementsController.text;
                            JobPostSession.numberOfChildren = _childrenCount;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PostNewJobStep2Screen(),
                              ),
                            );
                          },
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
    );
  }
}
