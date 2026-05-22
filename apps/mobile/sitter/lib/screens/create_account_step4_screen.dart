import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/primary_button.dart';
import '../utils/navigation_transitions.dart';
import 'create_account_step5_screen.dart';

class CreateAccountStep4Screen extends StatefulWidget {
  final String? userId;
  
  const CreateAccountStep4Screen({super.key, this.userId});

  @override
  State<CreateAccountStep4Screen> createState() =>
      _CreateAccountStep4ScreenState();
}

class _CreateAccountStep4ScreenState extends State<CreateAccountStep4Screen> {
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _bioController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            child: Column(
              children: [
                // ── Pinned header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Create Account',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text('Step 4 of 6',
                          style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 4 / 6,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC8F0FF)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildLabel('Short Bio'),
                        const SizedBox(height: 8),
                        _buildMultilineField(
                          controller: _bioController,
                          hint: 'Tell families about yourself',
                        ),
                        const SizedBox(height: 10),
                        _buildLabel('Skills'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _skillsController,
                          hint: 'CPR Certified, First aid, homework help....',
                        ),
                        const SizedBox(height: 10),
                        _buildLabel('Experience ( Optional )'),
                        const SizedBox(height: 8),
                        _buildMultilineField(
                          controller: _experienceController,
                          hint: 'Previous babysitting experience...',
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: PrimaryButton(
                    label: _saving ? 'Saving…' : 'Continue',
                    onPressed: _saving
                        ? () {}
                        : () async {
                            final bio = _bioController.text.trim();
                            final skills = _skillsController.text.trim();
                            final exp = _experienceController.text.trim();
                            if (bio.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a short bio.')),
                              );
                              return;
                            }
                            final composed = [
                              bio,
                              if (skills.isNotEmpty) '\n\nSkills: $skills',
                              if (exp.isNotEmpty) '\n\nExperience: $exp',
                            ].join();
                            setState(() => _saving = true);
                            try {
                              final uid = widget.userId ?? Supabase.instance.client.auth.currentUser?.id;
                              if (uid == null) {
                                throw StateError('Not signed in');
                              }
                              
                              final result = await Supabase.instance.client.rpc(
                                'sitter_update_bio',
                                params: {
                                  'p_sitter_id': uid,
                                  'p_bio': composed,
                                },
                              );
                              
                              if (result is Map && result['error'] != null) {
                                throw Exception(result['error']);
                              }
                              
                              if (!mounted) return;
                              Navigator.of(context).push(
                                NavigationTransitions.fadeTransition(
                                  CreateAccountStep5Screen(userId: widget.userId),
                                ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) =>
      Text(text, style: const TextStyle(fontSize: 14, color: Colors.white));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
      ),
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: 4,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
      ),
    );
  }
}
