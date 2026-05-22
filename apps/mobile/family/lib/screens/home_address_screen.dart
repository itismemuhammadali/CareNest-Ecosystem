import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/custom_text_field.dart';
import 'package:star_sitter_family/widgets/header2.dart';

class HomeAddressScreen extends StatefulWidget {
  const HomeAddressScreen({super.key});

  @override
  State<HomeAddressScreen> createState() => _HomeAddressScreenState();
}

class _HomeAddressScreenState extends State<HomeAddressScreen> {
  final _streetAddressController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ProfileRepository(Supabase.instance.client);
    final fp = await repo.familyProfile();
    if (!mounted) return;
    if (fp != null) {
      final addr = fp['home_address'];
      if (addr is Map) {
        final m = Map<String, dynamic>.from(addr as Map);
        _streetAddressController.text = (m['line1'] ?? '').toString();
        _apartmentController.text = (m['line2'] ?? '').toString();
        _cityController.text = (m['city'] ?? '').toString();
        _stateController.text = (m['state'] ?? '').toString();
        _zipCodeController.text = (m['postal_code'] ?? '').toString();
      }
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _streetAddressController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final street = _streetAddressController.text.trim();
    final city = _cityController.text.trim();
    final zip = _zipCodeController.text.trim();
    if (street.isEmpty || city.isEmpty || zip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Street, city, and zip are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ProfileRepository(Supabase.instance.client).updateFamily(
        homeAddress: {
          'line1': street,
          'line2': _apartmentController.text.trim(),
          'city': city,
          'state': _stateController.text.trim(),
          'postal_code': zip,
        },
      );
      if (!mounted) return;
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
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Header2(
              title: 'Home Address',
              subtitle: 'Update your street address, city, state, and zip code',
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.only(top: 20, left: 24, right: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0x991E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _streetAddressController,
                              label: 'Street Address',
                              hintText: '123 Main Street',
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              controller: _apartmentController,
                              label: 'Apartment, Suite, etc. (Optional)',
                              hintText: 'Apt 4B',
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _cityController,
                                    label: 'City',
                                    hintText: 'San Francisco',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _stateController,
                                    label: 'State',
                                    hintText: 'CA',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              controller: _zipCodeController,
                              label: 'Zip Code',
                              hintText: '94102',
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: OutlinedButton(
                                      onPressed: _saving
                                          ? null
                                          : () => Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
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
