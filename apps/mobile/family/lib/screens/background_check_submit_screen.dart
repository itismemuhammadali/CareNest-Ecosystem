import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads files to `bg-check-docs/<uid>/…` then calls `family_submit_background_check` (BACKEND.md Day 5).
class BackgroundCheckSubmitScreen extends StatefulWidget {
  const BackgroundCheckSubmitScreen({super.key});

  @override
  State<BackgroundCheckSubmitScreen> createState() => _BackgroundCheckSubmitScreenState();
}

class _BackgroundCheckSubmitScreenState extends State<BackgroundCheckSubmitScreen> {
  bool _busy = false;

  Future<void> _pickAndSubmit() async {
    final pick = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (pick == null || pick.files.isEmpty) return;

    setState(() => _busy = true);
    try {
      final repo = ProfileRepository(Supabase.instance.client);
      final docs = <Map<String, dynamic>>[];
      for (final f in pick.files) {
        final bytes = f.bytes;
        if (bytes == null || bytes.isEmpty) continue;
        final name = f.name;
        final path = await repo.uploadFamilyBgCheckBytes(bytes, name);
        docs.add({'storage_path': path, 'name': name});
      }
      if (docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No readable files selected.')),
        );
        return;
      }
      await repo.submitBackgroundCheck(docs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background check submitted. Status is now pending review.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background check documents'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select PDF or images (ID, proof of address). Files upload to your private folder in Supabase Storage, then your profile is marked pending for admin review.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _pickAndSubmit,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_busy ? 'Uploading…' : 'Choose files & submit'),
            ),
          ],
        ),
      ),
    );
  }
}
