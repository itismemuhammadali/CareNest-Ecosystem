import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shown while `sitter_profiles.is_active` is false. [AuthGate] swaps to [HomeScreen] when admin activates.
class ProfileUnderReviewScreen extends StatefulWidget {
  const ProfileUnderReviewScreen({super.key});

  @override
  State<ProfileUnderReviewScreen> createState() => _ProfileUnderReviewScreenState();
}

class _ProfileUnderReviewScreenState extends State<ProfileUnderReviewScreen> {
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
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB30F172A), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Profile Under Review',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Your profile and age verification documents are being reviewed by our admin team. "
                    "You'll receive an email notification once your account is approved. "
                    "You can leave this screen open — the app will continue automatically when you're approved.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x991E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                        top: BorderSide(color: Color(0x33A8D8EA), width: 1.09),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What happens next?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA8D8EA),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Admin reviews guardian consent and certifications.\n'
                          '2. When approved, this screen closes and you can browse jobs.\n'
                          '3. You can sign out from the menu if you need to switch accounts.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFA8D8EA),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: Color(0xFFA8D8EA)),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for approval...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA8D8EA),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => Supabase.instance.client.auth.signOut(),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
