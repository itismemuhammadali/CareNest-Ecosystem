import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/custom_text_field.dart';
import 'package:star_sitter_family/widgets/header2.dart';

class HomeSafetyInformationScreen extends StatefulWidget {
  const HomeSafetyInformationScreen({super.key});

  @override
  State<HomeSafetyInformationScreen> createState() => _HomeSafetyInformationScreenState();
}

class _HomeSafetyInformationScreenState extends State<HomeSafetyInformationScreen> {
  final _homeTypeController = TextEditingController();
  final _petsController = TextEditingController();
  final _parkingController = TextEditingController();
  final _securityCodeController = TextEditingController();
  final _wifiNameController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await ProfileRepository(Supabase.instance.client).familyProfile();
      if (!mounted) return;
      final raw = row?['home_safety_info']?.toString() ?? '';
      if (raw.trim().isEmpty) return;
      try {
        final m = jsonDecode(raw);
        if (m is Map) {
          _homeTypeController.text = '${m['home_type'] ?? ''}'.trim();
          _petsController.text = '${m['pets'] ?? ''}'.trim();
          _parkingController.text = '${m['parking'] ?? ''}'.trim();
          _securityCodeController.text = '${m['security_code'] ?? ''}'.trim();
          _wifiNameController.text = '${m['wifi_name'] ?? ''}'.trim();
          _wifiPasswordController.text = '${m['wifi_password'] ?? ''}'.trim();
        }
      } catch (_) {
        _homeTypeController.text = raw;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _homeTypeController.dispose();
    _petsController.dispose();
    _parkingController.dispose();
    _securityCodeController.dispose();
    _wifiNameController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = jsonEncode({
        'home_type': _homeTypeController.text.trim(),
        'pets': _petsController.text.trim(),
        'parking': _parkingController.text.trim(),
        'security_code': _securityCodeController.text.trim(),
        'wifi_name': _wifiNameController.text.trim(),
        'wifi_password': _wifiPasswordController.text.trim(),
      });
      await ProfileRepository(Supabase.instance.client).updateFamily(
        homeSafetyInfo: payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Home and safety information saved.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Header2(
              title: 'Home & Safety Information',
              subtitle: 'Home type, pets, access codes, and WiFi details',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0x991E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _homeTypeController,
                        label: 'Home Type',
                        hintText: 'House, apartment, etc.',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _petsController,
                        label: 'Pets (if any)',
                        hintText: 'Describe pets',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _parkingController,
                        label: 'Parking / Access Instructions',
                        hintText: 'Where to park, gate codes, etc.',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _securityCodeController,
                        label: 'Building Security Code (if applicable)',
                        hintText: 'Optional',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'WiFi Information (Optional - for babysitter convenience)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _wifiNameController,
                        label: 'WiFi Network Name',
                        hintText: 'SSID',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _wifiPasswordController,
                        label: 'WiFi Password',
                        hintText: 'Optional',
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC8F0FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  _saving ? 'Saving…' : 'Save Changes',
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
