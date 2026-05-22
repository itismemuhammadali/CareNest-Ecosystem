import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/primary_button.dart';
import '../utils/navigation_transitions.dart';
import 'create_account_step6_screen.dart';

class CreateAccountStep5Screen extends StatefulWidget {
  final String? userId;
  
  const CreateAccountStep5Screen({super.key, this.userId});

  @override
  State<CreateAccountStep5Screen> createState() =>
      _CreateAccountStep5ScreenState();
}

class _CreateAccountStep5ScreenState extends State<CreateAccountStep5Screen> {
  String? _idFileName;
  bool _idUploading = false;
  bool _idUploaded = false;

  String? _photoFileName;
  bool _photoUploading = false;
  bool _photoUploaded = false;

  Future<void> _pickAndUpload({
    required String certType,
    required List<String> allowedExtensions,
    required void Function(String name, bool uploading, bool uploaded) onState,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is too large. Maximum size is 10 MB.')),
        );
      }
      return;
    }

    onState(file.name, true, false);
    try {
      await CertificationsRepository(Supabase.instance.client)
          .uploadCertificationDocument(
        bytes: bytes,
        filename: file.name,
        certType: certType,
      );
      onState(file.name, false, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      onState(file.name, false, false);
    }
  }

  void _pickId() => _pickAndUpload(
        certType: 'identity',
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
        onState: (name, uploading, uploaded) {
          if (!mounted) return;
          setState(() {
            _idFileName = name;
            _idUploading = uploading;
            _idUploaded = uploaded;
          });
        },
      );

  void _pickPhoto() => _pickAndUpload(
        certType: 'profile_photo',
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        onState: (name, uploading, uploaded) {
          if (!mounted) return;
          setState(() {
            _photoFileName = name;
            _photoUploading = uploading;
            _photoUploaded = uploaded;
          });
        },
      );

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
                      const Text('Step 5 of 6',
                          style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 5 / 6,
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
                        // Info box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                              top: BorderSide(
                                color: Color(0x4DB5FFD9),
                                width: 1.09,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Upload your documents for age verification. Accepted: School ID, Government ID, or Birth Certificate.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFB5FFD9),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLabel('Government ID or School ID'),
                        const SizedBox(height: 8),
                        _buildUploadBox(
                          subtitle: 'PNG, JPG, PDF up to 10MB',
                          fileName: _idFileName,
                          uploading: _idUploading,
                          uploaded: _idUploaded,
                          onTap: _idUploading ? null : _pickId,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Profile Photo'),
                        const SizedBox(height: 8),
                        _buildUploadBox(
                          subtitle: 'PNG, JPG, up to 5MB',
                          fileName: _photoFileName,
                          uploading: _photoUploading,
                          uploaded: _photoUploaded,
                          onTap: _photoUploading ? null : _pickPhoto,
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
                    onPressed: () => Navigator.of(context).push(
                      NavigationTransitions.fadeTransition(
                        CreateAccountStep6Screen(userId: widget.userId),
                      ),
                    ),
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

  Widget _buildUploadBox({
    required String subtitle,
    required String? fileName,
    required bool uploading,
    required bool uploaded,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: uploaded
              ? const Color(0xFF0D2B1A)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: uploaded
                ? const Color(0xFF1A5C35)
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: uploading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC8F0FF),
                  ),
                ),
              )
            : uploaded
                ? Column(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 28),
                      const SizedBox(height: 6),
                      Text(
                        fileName ?? 'Uploaded',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4ADE80),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap to replace',
                        style: TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.upload_file_outlined, color: Colors.white54, size: 28),
                      const SizedBox(height: 6),
                      const Text(
                        'Click to upload or drag and drop',
                        style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
      ),
    );
  }
}
