import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/custom_text_field.dart';
import 'package:star_sitter_family/widgets/header2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BabysitterPreferencesScreen extends StatefulWidget {
  const BabysitterPreferencesScreen({super.key});

  @override
  State<BabysitterPreferencesScreen> createState() => _BabysitterPreferencesScreenState();
}

class _BabysitterPreferencesScreenState extends State<BabysitterPreferencesScreen> {
  final _preferredGenderController = TextEditingController(text: 'No Preference');
  final _minimumAgeController = TextEditingController(text: '15');
  final _maximumAgeController = TextEditingController(text: '18');
  final _languagePreferenceController = TextEditingController(text: 'English');
  final _smokingPolicyController = TextEditingController(text: 'NO Smoking');
  bool _requireCPR = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fp = await ProfileRepository(Supabase.instance.client).familyProfile();
    if (!mounted || fp == null) return;
    final prefs = fp['babysitter_prefs'];
    if (prefs is! Map) return;
    final p = Map<String, dynamic>.from(prefs as Map);
    setState(() {
      if (p['preferred_gender'] != null) _preferredGenderController.text = p['preferred_gender'].toString();
      if (p['min_age'] != null) _minimumAgeController.text = p['min_age'].toString();
      if (p['max_age'] != null) _maximumAgeController.text = p['max_age'].toString();
      if (p['language'] != null) _languagePreferenceController.text = p['language'].toString();
      if (p['smoking_policy'] != null) _smokingPolicyController.text = p['smoking_policy'].toString();
      if (p['require_cpr'] != null) _requireCPR = p['require_cpr'] == true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ProfileRepository(Supabase.instance.client).mergeFamilyBabysitterPrefs({
        'preferred_gender': _preferredGenderController.text.trim(),
        'min_age': int.tryParse(_minimumAgeController.text.trim()),
        'max_age': int.tryParse(_maximumAgeController.text.trim()),
        'language': _languagePreferenceController.text.trim(),
        'smoking_policy': _smokingPolicyController.text.trim(),
        'require_cpr': _requireCPR,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _preferredGenderController.dispose();
    _minimumAgeController.dispose();
    _maximumAgeController.dispose();
    _languagePreferenceController.dispose();
    _smokingPolicyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Header2(
              title: 'Babysitter Preferences',
              subtitle: 'Gender, age, language, certifications, and smoking policy',
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
                        controller: _preferredGenderController,
                        label: 'Preferred Gender',
                        hintText: 'No Preference',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _minimumAgeController,
                              label: 'Minimum Age',
                              hintText: '15',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _maximumAgeController,
                              label: 'Maximum Age',
                              hintText: '18',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _languagePreferenceController,
                        label: 'Language Preference',
                        hintText: 'English',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _requireCPR,
                              onChanged: (value) => setState(() => _requireCPR = value ?? false),
                              fillColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) return const Color(0xFFC8F0FF);
                                return Colors.transparent;
                              }),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Require CPR Certification',
                              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _smokingPolicyController,
                        label: 'Smoking Policy',
                        hintText: 'NO Smoking',
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  _saving ? 'Saving…' : 'Save Changes',
                                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 12),
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
