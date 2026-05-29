import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/primary_button.dart';
import 'create_account_step4_screen.dart';

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

class CreateAccountStep3Screen extends StatefulWidget {
  const CreateAccountStep3Screen({super.key});

  @override
  State<CreateAccountStep3Screen> createState() =>
      _CreateAccountStep3ScreenState();
}

class _CreateAccountStep3ScreenState extends State<CreateAccountStep3Screen> {
  bool _agreedToTerms = false;
  bool _imagesCached = false;
  bool _saving = false;
  bool _uploadingGov = false;
  bool _uploadingSelfie = false;

  String? _govPath;
  String? _govLabel;
  String? _selfiePath;
  String? _selfieLabel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imagesCached) {
      precacheImage(const AssetImage('assets/screen-bg.jpg'), context);
      _imagesCached = true;
    }
  }

  Future<void> _pickGovernmentId() async {
    final pick = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
    );
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.first;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file. Try another format.')),
      );
      return;
    }
    setState(() => _uploadingGov = true);
    try {
      final repo = ProfileRepository(Supabase.instance.client);
      final path = await repo.uploadFamilyBgCheckBytes(bytes, f.name);
      if (!mounted) return;
      setState(() {
        _govPath = path;
        _govLabel = f.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingGov = false);
    }
  }

  Future<void> _pickSelfie() async {
    final pick = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.image,
    );
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.first;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that image.')),
      );
      return;
    }
    setState(() => _uploadingSelfie = true);
    try {
      final repo = ProfileRepository(Supabase.instance.client);
      // Upload to bg-check-docs for verification
      final path = await repo.uploadFamilyBgCheckBytes(bytes, f.name);
      // Also set as profile picture — same image, no separate upload needed
      await repo.uploadAvatar(bytes, f.name);
      if (!mounted) return;
      setState(() {
        _selfiePath = path;
        _selfieLabel = f.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingSelfie = false);
    }
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
                Expanded(
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
                              Text('Back',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Step 3 of 4',
                            style:
                                TextStyle(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 0.75,
                            minHeight: 6,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFC8F0FF)),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Identity Verification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Files upload to your private folder (same secure storage as background checks).',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildUploadCard(
                          icon: const Text('📄',
                              style: TextStyle(fontSize: 48)),
                          label: 'Upload Government ID',
                          buttonLabel: _uploadingGov ? 'Uploading…' : 'Choose File',
                          subtitle: _govLabel != null ? '✓ $_govLabel' : null,
                          onButtonTap: _uploadingGov ? () {} : _pickGovernmentId,
                        ),
                        const SizedBox(height: 16),
                        _buildUploadCard(
                          icon: SvgPicture.asset('assets/image-icon.svg',
                              width: 48, height: 48),
                          label: 'Upload Selfie Verification',
                          buttonLabel: _uploadingSelfie ? 'Uploading…' : 'Choose Photo',
                          subtitle: _selfieLabel != null ? '✓ $_selfieLabel' : null,
                          onButtonTap: _uploadingSelfie ? () {} : _pickSelfie,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _agreedToTerms = !_agreedToTerms),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (val) => setState(
                                      () => _agreedToTerms = val ?? false),
                                  activeColor: const Color(0xFFC8F0FF),
                                  checkColor: const Color(0xFF0F172A),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'I agree to the Terms & Conditions and Child Safety Policy',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: _saving ? 'Saving…' : 'Continue',
                        onPressed: _saving
                            ? () {}
                            : () async {
                                if (!_agreedToTerms) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please accept the Terms & Conditions.')),
                                  );
                                  return;
                                }
                                if (_govPath == null || _selfiePath == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please upload both your government ID and a selfie.'),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _saving = true);
                                try {
                                  final repo = ProfileRepository(Supabase.instance.client);
                                  final now = DateTime.now().toUtc().toIso8601String();
                                  await repo.mergeFamilyBabysitterPrefs({
                                    'onboarding': {
                                      'terms_accepted_at': now,
                                      'identity': {
                                        'government_id': {
                                          'storage_path': _govPath,
                                          'filename': _govLabel,
                                        },
                                        'selfie': {
                                          'storage_path': _selfiePath,
                                          'filename': _selfieLabel,
                                        },
                                        'uploaded_at': now,
                                      },
                                    },
                                  });
                                  if (!mounted) return;
                                  final ctx = context;
                                  await precacheImage(const AssetImage('assets/screen-bg.jpg'), ctx);
                                  if (!mounted) return;
                                  _navigateWithFade(ctx, const CreateAccountStep4Screen());
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required Widget icon,
    required String label,
    required String buttonLabel,
    required VoidCallback onButtonTap,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.white70)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB5FFD9)),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onButtonTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
