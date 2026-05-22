import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileHeaderCard extends StatefulWidget {
  final String? displayName;
  final String? displayEmail;
  final String? avatarUrl;
  final bool isAdminVerified;
  final bool guardianConsentGiven;

  const ProfileHeaderCard({
    super.key,
    this.displayName,
    this.displayEmail,
    this.avatarUrl,
    this.isAdminVerified = false,
    this.guardianConsentGiven = false,
  });

  @override
  State<ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends State<ProfileHeaderCard> {
  bool _uploading = false;
  String? _localAvatarUrl;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ProfileRepository(Supabase.instance.client)
          .uploadAvatar(file.bytes!, file.name);
      if (mounted) setState(() => _localAvatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = _localAvatarUrl ?? widget.avatarUrl;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _uploading ? null : _pickAndUpload,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF2A2D3E),
                      backgroundImage: effectiveUrl != null && effectiveUrl.isNotEmpty
                          ? NetworkImage(effectiveUrl) as ImageProvider
                          : const AssetImage('assets/profile.png'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA8D8EA),
                          shape: BoxShape.circle,
                        ),
                        child: _uploading
                            ? const Padding(
                                padding: EdgeInsets.all(3),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F172A),
                                ),
                              )
                            : const Icon(Icons.edit, size: 12, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.displayName?.trim().isNotEmpty == true ? widget.displayName! : 'Sitter',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.displayEmail?.trim().isNotEmpty == true ? widget.displayEmail! : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.isAdminVerified || widget.guardianConsentGiven) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (widget.isAdminVerified) ...[
                  _buildSvgBadge('assets/tick-icon.svg', 'Admin Verified',
                      const Color(0xFFB5FFD9), const Color(0x33B5FFD9)),
                  if (widget.guardianConsentGiven) const SizedBox(width: 10),
                ],
                if (widget.guardianConsentGiven)
                  _buildSvgBadge('assets/tick-icon.svg', 'Guardian Consent',
                      const Color(0xFFA8D8EA), const Color(0x1FA8D8EA)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSvgBadge(String svgAsset, String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgAsset,
            width: 13,
            height: 13,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
