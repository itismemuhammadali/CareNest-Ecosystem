import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/job_post_session.dart';
import '../widgets/primary_button.dart';
import '../widgets/hire_header.dart';
import 'post_new_job_step3_screen.dart';

class PostNewJobStep2Screen extends StatefulWidget {
  const PostNewJobStep2Screen({super.key});

  @override
  State<PostNewJobStep2Screen> createState() => _PostNewJobStep2ScreenState();
}

class _PostNewJobStep2ScreenState extends State<PostNewJobStep2Screen> {
  final _addressController = TextEditingController();
  final _focusNode = FocusNode();
  late double _geofenceRadius;

  bool _loadingHome = false;
  bool _searching = false;
  bool _pinned = false;

  List<_Place> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _geofenceRadius = JobPostSession.geofenceRadiusM.toDouble();

    if (JobPostSession.cachedLat != null) {
      _addressController.text = JobPostSession.address;
      _pinned = true;
    } else {
      // Auto-load home address if available — silent, no snackbar on failure
      Future.microtask(_autoLoadHome);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Home address ─────────────────────────────────────────────────────────

  Future<void> _autoLoadHome() async {
    setState(() => _loadingHome = true);
    try {
      final profile = await ProfileRepository(Supabase.instance.client).familyProfile();
      if (!mounted) return;
      var lat = (profile?['home_lat'] as num?)?.toDouble();
      var lng = (profile?['home_lng'] as num?)?.toDouble();
      // If coords missing, geocode the saved text address
      if ((lat == null || lng == null || (lat == 0.0 && lng == 0.0))) {
        final addr = _formatHomeAddress(profile?['home_address']);
        if (addr != 'Home address') {
          final coords = await JobPostSession.geocodeAddress(addr);
          lat = coords.$1;
          lng = coords.$2;
        }
      }
      if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) return;
      _applyPin(_formatHomeAddress(profile?['home_address']), lat, lng);
    } catch (_) {
      // Silently skip — user can still search
    } finally {
      if (mounted) setState(() => _loadingHome = false);
    }
  }

  Future<void> _useHomeAddress() async {
    setState(() => _loadingHome = true);
    try {
      final profile = await ProfileRepository(Supabase.instance.client).familyProfile();
      if (!mounted) return;
      var lat = (profile?['home_lat'] as num?)?.toDouble();
      var lng = (profile?['home_lng'] as num?)?.toDouble();
      final addrText = _formatHomeAddress(profile?['home_address']);

      // If no coords stored, try geocoding the saved text address
      if (lat == null || lng == null || (lat == 0.0 && lng == 0.0)) {
        if (addrText == 'Home address') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No home address saved in your profile yet.')),
          );
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Locating your home address…')),
          );
        }
        final coords = await JobPostSession.geocodeAddress(addrText);
        lat = coords.$1;
        lng = coords.$2;
        if (lat == 0.0 && lng == 0.0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not locate that address. Try searching manually.')),
            );
          }
          return;
        }
        // Save coords back to profile so next time is instant
        try {
          await ProfileRepository(Supabase.instance.client)
              .updateFamily(homeLat: lat, homeLng: lng);
        } catch (_) {}
      }
      if (!mounted) return;
      _applyPin(addrText, lat, lng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load home address: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingHome = false);
    }
  }

  String _formatHomeAddress(dynamic addr) {
    if (addr is Map) {
      final parts = ['line1', 'city', 'state', 'postal_code']
          .map((k) => addr[k]?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return 'Home address';
  }

  // ── Address search autocomplete ───────────────────────────────────────────

  void _onSearchChanged(String text) {
    _clearPin();
    _debounce?.cancel();
    if (text.trim().length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _fetchSuggestions(text.trim()));
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _searching = true);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '5',
        'addressdetails': '0',
      });
      final response = await http
          .get(uri, headers: {'User-Agent': 'StarSittersFamilyApp/1.0'})
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _suggestions = results.map((r) {
            return _Place(
              displayName: r['display_name'] as String,
              lat: double.parse(r['lat'].toString()),
              lng: double.parse(r['lon'].toString()),
            );
          }).toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onSuggestionTap(_Place place) {
    _debounce?.cancel();
    _applyPin(place.displayName, place.lat, place.lng);
    FocusScope.of(context).unfocus();
  }

  void _applyPin(String label, double lat, double lng) {
    _addressController.text = label;
    JobPostSession.cachedLat = lat;
    JobPostSession.cachedLng = lng;
    setState(() {
      _pinned = true;
      _suggestions = [];
    });
  }

  void _clearPin() {
    JobPostSession.cachedLat = null;
    JobPostSession.cachedLng = null;
    setState(() => _pinned = false);
  }

  // ── Continue ──────────────────────────────────────────────────────────────

  void _onContinue() {
    final text = _addressController.text.trim();
    if (!_pinned && text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please search for and select a location.')),
      );
      return;
    }
    // If user typed but didn't pick from autocomplete, geocoding happens at publish.
    JobPostSession.address = text.isNotEmpty ? text : 'Home address';
    JobPostSession.geofenceRadiusM = _geofenceRadius.round();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostNewJobStep3Screen()),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

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
              const HireHeader(title: 'Post New Job', currentStep: 2, totalSteps: 4),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text(
                        'Where is the job?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Search any address — or use your saved home address.',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),
                      ),
                      const SizedBox(height: 16),

                      // ── Search field ──────────────────────────────────────
                      TextField(
                        controller: _addressController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search address…',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: _loadingHome || _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC8F0FF)),
                                  ),
                                )
                              : Icon(
                                  _pinned ? Icons.location_on : Icons.search,
                                  color: _pinned ? const Color(0xFFC8F0FF) : Colors.white38,
                                ),
                          suffixIcon: _addressController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                                  onPressed: () {
                                    _addressController.clear();
                                    _clearPin();
                                    setState(() => _suggestions = []);
                                    _focusNode.requestFocus();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0x221E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _pinned
                                  ? const Color(0x88C8F0FF)
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                          ),
                        ),
                      ),

                      // ── Autocomplete suggestions ──────────────────────────
                      if (_suggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: _suggestions.asMap().entries.map((entry) {
                                final i = entry.key;
                                final place = entry.value;
                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () => _onSuggestionTap(place),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFC8F0FF)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                place.displayName,
                                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (i < _suggestions.length - 1)
                                      Divider(height: 1, color: Colors.white.withValues(alpha: 0.07)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                      // ── Pinned confirmation ───────────────────────────────
                      if (_pinned && _suggestions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 15, color: Color(0xFFC8F0FF)),
                              const SizedBox(width: 6),
                              const Text(
                                'Location pinned — coordinates ready',
                                style: TextStyle(fontSize: 12, color: Color(0xFFC8F0FF)),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ── Quick-pick: Home Address ──────────────────────────
                      OutlinedButton.icon(
                        onPressed: _loadingHome ? null : _useHomeAddress,
                        icon: const Icon(Icons.home_outlined, size: 16, color: Color(0xFFC8F0FF)),
                        label: const Text(
                          'Use My Home Address',
                          style: TextStyle(fontSize: 13, color: Color(0xFFC8F0FF)),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          side: const BorderSide(color: Color(0x55C8F0FF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Geofence slider ───────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0x991E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Clock-in Geofence Radius',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                Text(
                                  '${_geofenceRadius.round()} m',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFC8F0FF)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sitter must be within this distance to clock in.',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: const Color(0xFFC8F0FF),
                                inactiveTrackColor: Colors.white12,
                                thumbColor: const Color(0xFFC8F0FF),
                                overlayColor: const Color(0x1AC8F0FF),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _geofenceRadius,
                                min: 100,
                                max: 500,
                                divisions: 8,
                                onChanged: (v) => setState(() => _geofenceRadius = v),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('100 m',
                                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
                                Text('500 m',
                                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      PrimaryButton(label: 'Continue', onPressed: _onContinue),
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

class _Place {
  final String displayName;
  final double lat;
  final double lng;
  const _Place({required this.displayName, required this.lat, required this.lng});
}
