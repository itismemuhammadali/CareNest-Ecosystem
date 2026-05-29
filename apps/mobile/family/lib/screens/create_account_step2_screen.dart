import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/job_post_session.dart';
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
  List<TextEditingController> _ageControllers = [];
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

  void _onChildrenCountChanged(String value) {
    final count = int.tryParse(value.trim()) ?? 0;
    final clamped = count.clamp(0, 10);
    setState(() {
      // Dispose extras
      for (int i = clamped; i < _ageControllers.length; i++) {
        _ageControllers[i].dispose();
      }
      if (clamped > _ageControllers.length) {
        // Add new controllers
        _ageControllers.addAll(
          List.generate(clamped - _ageControllers.length, (_) => TextEditingController()),
        );
      } else {
        _ageControllers = _ageControllers.sublist(0, clamped);
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _childrenCountController.dispose();
    for (final c in _ageControllers) {
      c.dispose();
    }
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
                    onChanged: _onChildrenCountChanged,
                  ),
                  // Dynamic per-child age fields — two per row
                  if (_ageControllers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildLabel('Ages of Children'),
                    const SizedBox(height: 8),
                    ...List.generate(
                      (_ageControllers.length / 2).ceil(),
                      (rowIndex) {
                        final leftIndex = rowIndex * 2;
                        final rightIndex = leftIndex + 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _ageControllers[leftIndex],
                                  hint: 'Child ${leftIndex + 1} age',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              if (rightIndex < _ageControllers.length) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _ageControllers[rightIndex],
                                    hint: 'Child ${rightIndex + 1} age',
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ] else
                                const Expanded(child: SizedBox()),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
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
                              agesStr: _ageControllers.map((c) => c.text.trim()).join(','),
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
                              // Geocode the address so "Use My Home Address" works in job posting
                              final fullAddr = '$addr, $city, $zip';
                              final coords = await JobPostSession.geocodeAddress(fullAddr);
                              await repo.updateFamily(
                                homeAddress: {
                                  'line1': addr,
                                  'city': city,
                                  'postal_code': zip,
                                },
                                homeLat: coords.$1 != 0.0 ? coords.$1 : null,
                                homeLng: coords.$2 != 0.0 ? coords.$2 : null,
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
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
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
