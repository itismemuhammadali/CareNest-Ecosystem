import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Clock in / clock out (BACKEND.md §17 NEW `active_job_screen.dart`).
class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  String? _hireIdClockIn;
  String? _hireIdClockOut;
  bool _busy = false;
  Timer? _timer;
  DateTime? _clockInAt;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final work = WorkRepository(Supabase.instance.client);
    final inId = await work.hireIdAwaitingClockIn();
    final outId = await work.hireIdWithOpenClockIn();
    DateTime? serverClockIn;
    if (outId != null) {
      try {
        final res = await Supabase.instance.client
            .from('time_entries')
            .select('clock_in_at')
            .eq('hire_id', outId)
            .isFilter('clock_out_at', null)
            .order('clock_in_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (res != null && res['clock_in_at'] != null) {
          serverClockIn = DateTime.tryParse(res['clock_in_at'].toString())?.toLocal();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _hireIdClockIn = inId;
      _hireIdClockOut = outId;
      if (serverClockIn != null) _clockInAt = serverClockIn;
    });
    _timer?.cancel();
    if (outId != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  Future<(double, double)?> _gps() async {
    final perm = await Geolocator.checkPermission();
    LocationPermission p = perm;
    if (perm == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.deniedForever || p == LocationPermission.denied) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition();
    return (pos.latitude, pos.longitude);
  }

  String _elapsed() {
    // Without server read of clock_in_at, show local timer placeholder after clock-in success
    if (_clockInAt == null) return '0:00';
    final d = DateTime.now().difference(_clockInAt!);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return '$h:$m';
  }

  Future<void> _doClockIn() async {
    final id = _hireIdClockIn;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final ll = await _gps();
      if (ll == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to clock in.')),
          );
        }
        return;
      }
      await WorkRepository(Supabase.instance.client).clockIn(
        hireId: id,
        lat: ll.$1,
        lng: ll.$2,
      );
      _clockInAt = DateTime.now();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clocked in — job is now live.')),
        );
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doClockOut() async {
    final id = _hireIdClockOut;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      final ll = await _gps();
      if (ll == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to clock out.')),
          );
        }
        return;
      }
      await WorkRepository(Supabase.instance.client).clockOut(
        hireId: id,
        lat: ll.$1,
        lng: ll.$2,
      );
      _clockInAt = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clocked out — check your wallet.')),
        );
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Active job'),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hireIdClockOut != null) ...[
              const Text(
                'You are clocked in',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Elapsed (local): ${_elapsed()}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _doClockOut,
                child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Clock out'),
              ),
            ] else if (_hireIdClockIn != null) ...[
              const Text(
                'Ready to clock in',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You must be within the job geofence (or geofence hard-block disabled in system config for local dev).',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _doClockIn,
                child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Clock in'),
              ),
            ] else
              const Text(
                'No hired job waiting for clock-in, and no open time entry.\nPost → apply → hire from the family account first.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
          ],
        ),
      ),
    );
  }
}
