import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/primary_button.dart';
import 'create_account_step3_screen.dart';

Future<void> _navigateWithFade(BuildContext context, Widget destination, {bool removeUntil = false}) async {
  if (removeUntil) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  } else {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class CreateAccountStep2Screen extends StatefulWidget {
  const CreateAccountStep2Screen({super.key});

  @override
  State<CreateAccountStep2Screen> createState() => _CreateAccountStep2ScreenState();
}

class _CreateAccountStep2ScreenState extends State<CreateAccountStep2Screen> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _childrenCountController = TextEditingController();
  final _childrenAgesController = TextEditingController();
  bool _imagesCached = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesCached) {
      precacheImage(const AssetImage('assets/screen-bg.jpg'), context);
      _imagesCached = true;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _childrenCountController.dispose();
    _childrenAgesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark gradient overlay
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
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Back button
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
                  // Title
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
                    'Step 2 of 4',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.50,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC8F0FF)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Section title
                  const Text(
                    'Homes Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Home Address'),
                  const SizedBox(height: 8),
                  _buildTextField(controller: _addressController, hint: '123 Highland Ave.'),
                  const SizedBox(height: 16),
                  _buildLabel('City'),
                  const SizedBox(height: 8),
                  _buildTextField(controller: _cityController, hint: 'San Francisco`'),
                  const SizedBox(height: 16),
                  _buildLabel('Zip Code'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _zipController,
                    hint: '94012',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Number of Childern'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _childrenCountController,
                    hint: '2',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Ages of Children'),
                  const SizedBox(height: 8),
                  _buildTextField(controller: _childrenAgesController, hint: 'e.g 3,5,8'),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: _saving ? 'Saving…' : 'Continue',
                    onPressed: _saving
                        ? () {}
                        : () async {
                            final addr = _addressController.text.trim();
                            final city = _cityController.text.trim();
                            final zip = _zipController.text.trim();
                            if (addr.isEmpty || city.isEmpty || zip.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill address, city, and zip.')),
                              );
                              return;
                            }
                            final rows = ProfileRepository.parseOnboardingChildrenRecords(
                              countStr: _childrenCountController.text,
                              agesStr: _childrenAgesController.text,
                            );
                            if (rows.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Enter number of children (1–10) and ages (e.g. 3,5).')),
                              );
                              return;
                            }
                            setState(() => _saving = true);
                            try {
                              final repo = ProfileRepository(Supabase.instance.client);
                              await repo.updateFamily(
                                homeAddress: {
                                  'line1': addr,
                                  'city': city,
                                  'postal_code': zip,
                                },
                              );
                              await repo.replaceFamilyChildren(rows);
                              if (!mounted) return;
                              final ctx = context;
                              await precacheImage(const AssetImage('assets/screen-bg.jpg'), ctx);
                              if (!mounted) return;
                              _navigateWithFade(ctx, const CreateAccountStep3Screen());
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

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, color: Colors.white));
  }

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
