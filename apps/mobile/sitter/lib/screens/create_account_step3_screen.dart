import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/primary_button.dart';
import '../utils/navigation_transitions.dart';
import 'create_account_step4_screen.dart';

class CreateAccountStep3Screen extends StatefulWidget {
  final String? userId;
  
  const CreateAccountStep3Screen({super.key, this.userId});

  @override
  State<CreateAccountStep3Screen> createState() =>
      _CreateAccountStep3ScreenState();
}

class _CreateAccountStep3ScreenState extends State<CreateAccountStep3Screen> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
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
                      const Text('Step 3 of 6',
                          style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 3 / 6,
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
                        _buildLabel('Home Address'),
                        const SizedBox(height: 8),
                        _buildTextField(
                            controller: _addressController, hint: '123 Main Street'),
                        const SizedBox(height: 10),
                        _buildLabel('City'),
                        const SizedBox(height: 8),
                        _buildTextField(
                            controller: _cityController, hint: 'Los Angeles'),
                        const SizedBox(height: 10),
                        _buildLabel('Zip Code'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _zipController,
                          hint: '90210',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: PrimaryButton(
                    label: 'Continue',
                    onPressed: () async {
                      final address = _addressController.text.trim();
                      final city = _cityController.text.trim();
                      final zip = _zipController.text.trim();
                      if (address.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Home address is required.')),
                        );
                        return;
                      }
                      if (city.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('City is required.')),
                        );
                        return;
                      }
                      try {
                        await ProfileRepository(Supabase.instance.client)
                            .updateSitterAddress({
                          'street': address,
                          'city': city,
                          'zip': zip,
                        });
                      } catch (e) {
                        debugPrint('Address save failed: $e');
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        NavigationTransitions.fadeTransition(
                          CreateAccountStep4Screen(userId: widget.userId),
                        ),
                      );
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
