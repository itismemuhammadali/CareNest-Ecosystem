import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/primary_button.dart';
import 'sign_in_screen.dart';

enum PlanType { free, premium }

class CreateAccountStep4Screen extends StatefulWidget {
  const CreateAccountStep4Screen({super.key});

  @override
  State<CreateAccountStep4Screen> createState() => _CreateAccountStep4ScreenState();
}

class _CreateAccountStep4ScreenState extends State<CreateAccountStep4Screen> {
  PlanType _selectedPlan = PlanType.free;
  bool _saving = false;

  List<Map<String, dynamic>> _documentsFromOnboardingPrefs(dynamic babysitterPrefs) {
    if (babysitterPrefs is! Map) return [];
    final on = babysitterPrefs['onboarding'];
    if (on is! Map) return [];
    final id = on['identity'];
    if (id is! Map) return [];
    final out = <Map<String, dynamic>>[];
    final gov = id['government_id'];
    if (gov is Map) {
      final p = gov['storage_path']?.toString() ?? '';
      if (p.isNotEmpty) {
        out.add({
          'type': 'government_id',
          'storage_path': p,
          'filename': gov['filename']?.toString(),
        });
      }
    }
    final self = id['selfie'];
    if (self is Map) {
      final p = self['storage_path']?.toString() ?? '';
      if (p.isNotEmpty) {
        out.add({
          'type': 'selfie',
          'storage_path': p,
          'filename': self['filename']?.toString(),
        });
      }
    }
    return out;
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Step 4 of 4',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC8F0FF)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPlanCard(
                    plan: PlanType.free,
                    title: 'Free Plan',
                    price: '\$0',
                    priceSubtitle: null,
                    subtitle: null,
                    features: const [
                      'Limited job postings',
                      'Basic candidate access',
                      'Standard support',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPlanCard(
                    plan: PlanType.premium,
                    title: 'Premium',
                    price: '\$29',
                    priceSubtitle: '/month',
                    subtitle: 'Most Popular',
                    features: const [
                      'Unlimited job postings',
                      'Access to top-rated verified babysitters',
                      'Priority application visibility',
                      'Advanced filtering',
                      'Faster support',
                    ],
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: _saving ? 'Submitting…' : 'Submit for Approval',
                    onPressed: _saving
                        ? () {}
                        : () async {
                            setState(() => _saving = true);
                            try {
                              final repo = ProfileRepository(Supabase.instance.client);
                              await repo.mergeFamilyBabysitterPrefs({
                                'plan_choice':
                                    _selectedPlan == PlanType.premium ? 'premium' : 'free',
                                'billing': {
                                  'note':
                                      'In-app plan selection only; Stripe billing deferred (BACKEND.md).',
                                },
                              });
                              final fp = await repo.familyProfile();
                              final docs = _documentsFromOnboardingPrefs(fp?['babysitter_prefs']);
                              if (docs.isEmpty) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Complete step 3 (government ID and selfie) before submitting for approval.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              await repo.submitBackgroundCheck(docs);
                              if (!mounted) return;
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const VerificationInReviewScreen()),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not save: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required PlanType plan,
    required String title,
    required String price,
    required String? priceSubtitle,
    required String? subtitle,
    required List<String> features,
  }) {
    final bool isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0x991E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFC8F0FF) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (priceSubtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          priceSubtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $f',
                  style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerificationInReviewScreen extends StatelessWidget {
  const VerificationInReviewScreen({super.key});

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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 170),
                  const Text(
                    'Verification In Review',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 382,
                    height: 78,
                    child: const Text(
                      'Your profile is under background verification. This typically takes 24-48 hours. You will be notified once approved.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        height: 26 / 16,
                        letterSpacing: 0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Image.asset(
                    'assets/verification_in_review.png',
                    width: 240,
                    height: 149.55,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),
                  // Status container
                  Container(
                    width: 382,
                    height: 120,
                    padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x991E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/Container.png', width: 23.99, height: 23.99),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                'Profile submitted',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  height: 24 / 16,
                                  letterSpacing: 0,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Image.asset('assets/Container1.png', width: 23.99, height: 23.99),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                'Identity verification',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  height: 24 / 16,
                                  letterSpacing: 0,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Image.asset('assets/Container2.png', width: 23.99, height: 23.99),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                'Admin approval',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  height: 24 / 16,
                                  letterSpacing: 0,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
SizedBox(
  width: double.infinity,
  height: 56,
  child: OutlinedButton(
    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    ),
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      side: const BorderSide(
        color: Color(0xFFA8D8EA),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    child: const Text(
      'Go to sign in',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFA8D8EA),
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
    );
  }
}