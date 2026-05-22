import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/job_post_session.dart';
import '../widgets/hire_header.dart';

class PostNewJobStep4Screen extends StatefulWidget {
  const PostNewJobStep4Screen({super.key});

  @override
  State<PostNewJobStep4Screen> createState() => _PostNewJobStep4ScreenState();
}

class _PostNewJobStep4ScreenState extends State<PostNewJobStep4Screen> {
  bool _publishing = false;

  Future<void> _publish() async {
    final err = JobPostSession.validateForPublish();
    if (err != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    final day = JobPostSession.parseUsDate(JobPostSession.dateStr)!;
    final start = JobPostSession.combineDateAndTime(day, JobPostSession.startTimeStr)!;
    final end = JobPostSession.combineDateAndTime(day, JobPostSession.endTimeStr)!;

    setState(() => _publishing = true);
    try {
      // Use children selected in step 3; fall back to all if somehow empty
      List<String> childIds = List.from(JobPostSession.selectedChildIds);
      if (childIds.isEmpty) {
        final childRows = await ProfileRepository(Supabase.instance.client).listFamilyChildren();
        childIds = childRows.map((r) => r['id'].toString()).toList();
      }

      // Use pre-resolved coords (home address / GPS) or fall back to Nominatim geocoding.
      final (lat, lng) = await JobPostSession.resolveCoords();
      if (lat == 0.0 && lng == 0.0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location not found. Go back and tap 'Use Home Address' or enter a full address with city."),
            duration: Duration(seconds: 5),
          ),
        );
        setState(() => _publishing = false);
        return;
      }

      final repo = JobsRepository(Supabase.instance.client);
      await repo.createJob(
        title: JobPostSession.buildTitle(),
        description: JobPostSession.combinedDescription.isEmpty
            ? null
            : JobPostSession.combinedDescription,
        date: DateTime(day.year, day.month, day.day),
        startTime: start,
        endTime: end,
        numberOfChildren: JobPostSession.numberOfChildren,
        locationLat: lat,
        locationLng: lng,
        locationAddress: {'formatted': JobPostSession.address},
        childIds: childIds,
        geofenceRadiusM: JobPostSession.geofenceRadiusM,
      );
      JobPostSession.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job published as Open'),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      JobPostSession.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not publish: $e')),
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String get _dateTimeLine {
    final d = JobPostSession.dateStr.trim();
    final s = JobPostSession.startTimeStr.trim();
    final e = JobPostSession.endTimeStr.trim();
    if (d.isEmpty && s.isEmpty && e.isEmpty) return '—';
    return '$d | $s - $e';
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
                colors: [
                  Color(0xB30F172A),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          Column(
            children: [
              const HireHeader(
                title: 'Post New Job',
                currentStep: 4,
                totalSteps: 4,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Review & Publish',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0x991E293B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date & Time',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dateTimeLine,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Divider(color: Colors.white.withValues(alpha: 0.1), height: 32),
                            const Text(
                              'Number of Children',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${JobPostSession.numberOfChildren}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Divider(color: Colors.white.withValues(alpha: 0.1), height: 32),
                            const Text(
                              'Location',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              JobPostSession.address.trim().isEmpty
                                  ? '—'
                                  : JobPostSession.address.trim(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Divider(color: Colors.white.withValues(alpha: 0.1), height: 32),
                            const Text(
                              'Geofence Radius',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${JobPostSession.geofenceRadiusM} m',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _publishing ? null : _publish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC8F0FF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _publishing
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                )
                              : const Text(
                                  'Publish Job',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
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
    );
  }
}
