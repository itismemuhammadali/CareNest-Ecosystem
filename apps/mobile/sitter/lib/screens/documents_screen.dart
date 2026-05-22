import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/documents/document_card.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _uploadBusy = false;

  static String _statusSubtitle(String? status) {
    switch (status) {
      case 'approved':
        return 'Approved by admin';
      case 'pending':
        return 'Pending admin review';
      case 'rejected':
        return 'Rejected — upload a replacement if needed';
      case 'not_submitted':
        return 'Not submitted';
      default:
        return 'Status: ${status ?? 'unknown'}';
    }
  }

  Future<void> _openSignedDownload(String documentPath) async {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await CertificationsRepository(Supabase.instance.client)
          .signedCertDocumentUrl(documentPath);
      if (!context.mounted) return;
      final uri = Uri.tryParse(url);
      if (uri == null) throw FormatException('Bad URL');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open download')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Future<void> _pickAndUpload() async {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final pick = await FilePicker.platform.pickFiles(withData: true);
    if (!context.mounted) return;
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.first;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not read file bytes (try a smaller file).')),
      );
      return;
    }

    final typeController = TextEditingController(text: 'CPR / First aid');

    if (!context.mounted) return;
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Certification type', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: typeController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. CPR, First aid, background check',
            hintStyle: TextStyle(color: Color(0x88A8D8EA)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0x44A8D8EA)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFA8D8EA)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Upload')),
        ],
      ),
    );

    if (submit != true || !context.mounted) return;
    final certType = typeController.text.trim();
    if (certType.length < 2) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Certification type must be at least 2 characters.')),
      );
      return;
    }

    setState(() => _uploadBusy = true);
    try {
      await CertificationsRepository(Supabase.instance.client).uploadCertificationDocument(
        bytes: bytes,
        filename: f.name,
        certType: certType,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Document uploaded — pending review.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (context.mounted) setState(() => _uploadBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();

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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                      const Text(
                        "Document's",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Manage your verification documents*',
                        style: TextStyle(fontSize: 13, color: Color(0xB2A8D8EA)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: CertificationsRepository(Supabase.instance.client)
                                  .myCertificationsStream(),
                              builder: (context, snap) {
                                if (snap.connectionState == ConnectionState.waiting &&
                                    !snap.hasData) {
                                  return const Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Center(
                                      child: CircularProgressIndicator(color: Color(0xFFA8D8EA)),
                                    ),
                                  );
                                }
                                if (snap.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'Could not load documents: ${snap.error}',
                                      style: const TextStyle(color: Color(0xFFFF9494)),
                                    ),
                                  );
                                }
                                final raw = snap.data ?? <Map<String, dynamic>>[];
                                final rows = List<Map<String, dynamic>>.from(raw);
                                rows.sort((a, b) {
                                  final da = DateTime.tryParse(
                                        a['submitted_at']?.toString() ?? '',
                                      ) ??
                                      DateTime.fromMillisecondsSinceEpoch(0);
                                  final db = DateTime.tryParse(
                                        b['submitted_at']?.toString() ?? '',
                                      ) ??
                                      DateTime.fromMillisecondsSinceEpoch(0);
                                  return db.compareTo(da);
                                });

                                if (rows.isEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Text(
                                      'No certifications on file yet. Upload a document below.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.65),
                                        height: 1.4,
                                      ),
                                    ),
                                  );
                                }

                                return Column(
                                  children: rows.map((row) {
                                    final type = (row['cert_type'] ?? 'Certification').toString();
                                    final status = row['status']?.toString();
                                    final path = row['document_path']?.toString();
                                    final submitted = DateTime.tryParse(
                                          row['submitted_at']?.toString() ?? '',
                                        ) ??
                                        DateTime.now();
                                    final uploadLabel = dateFmt.format(submitted.toLocal());
                                    final verified = status == 'approved';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: DocumentCard(
                                        title: type,
                                        subtitle: _statusSubtitle(status),
                                        uploadDate: uploadLabel,
                                        isVerified: verified,
                                        onDownload: (path != null && path.isNotEmpty)
                                            ? () => _openSignedDownload(path)
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 24,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x991E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0x33A8D8EA),
                                  width: 1.09,
                                ),
                              ),
                              child: Column(
                                children: [
                                  SvgPicture.asset(
                                    'assets/upload-icon.svg',
                                    width: 36,
                                    height: 36,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFFA8D8EA),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Upload Additional Documents',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Add certifications or other relevant documents',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0x99A8D8EA),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Material(
                                    color: const Color(0xFFA8D8EA),
                                    borderRadius: BorderRadius.circular(20),
                                    child: InkWell(
                                      onTap: _uploadBusy ? null : _pickAndUpload,
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          _uploadBusy ? 'Uploading…' : 'Choose File',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: _uploadBusy
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF1E293B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1AD4B5FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0x4DD4B5FF),
                                  width: 1.09,
                                ),
                              ),
                              child: const Text(
                                'All documents are securely stored and encrypted. Only verified admins can access your documents for safety purposes.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD4B5FF),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      if (_uploadBusy)
                        Container(
                          color: Colors.black38,
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFFA8D8EA)),
                          ),
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
}
