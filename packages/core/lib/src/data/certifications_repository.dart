import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Sitter certification rows + `cert-docs` storage (BACKEND.md §5 Migration 5 + §9).
class CertificationsRepository {
  CertificationsRepository(this._client);
  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> myCertificationsStream() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const Stream<List<Map<String, dynamic>>>.empty();
    }
    return _client
        .from('certifications')
        .stream(primaryKey: ['id'])
        .eq('sitter_id', uid);
  }

  static String _mimeFromExtension(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Uploads bytes to `cert-docs/<userId>/...` then inserts a `certifications` row for admin review.
  Future<void> uploadCertificationDocument({
    required Uint8List bytes,
    required String filename,
    required String certType,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    final safe = filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$safe';
    final mime = _mimeFromExtension(filename);
    await _client.storage.from('cert-docs').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: mime),
        );
    await _client.rpc(
      'register_certification_document',
      params: {
        'p_cert_type': certType.trim(),
        'p_document_path': path,
      },
    );
  }

  /// Signed URL for the sitter's own file under `cert-docs` (short-lived).
  /// Appends ?download=true so the browser serves it as an attachment (B6: no inline execution).
  Future<String> signedCertDocumentUrl(
    String documentPath, {
    int expiresInSeconds = 3600,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not signed in');
    if (!documentPath.startsWith('$uid/')) {
      throw ArgumentError('Invalid document path');
    }
    final url = await _client.storage
        .from('cert-docs')
        .createSignedUrl(documentPath, expiresInSeconds);
    return url.contains('?') ? '$url&download=true' : '$url?download=true';
  }
}
