import 'package:supabase_flutter/supabase_flutter.dart';

class CoursesRepository {
  CoursesRepository(this._client);
  final SupabaseClient _client;

  Stream<List<Map<String, dynamic>>> publishedCoursesStream() {
    return _client
        .from('courses')
        .stream(primaryKey: ['id'])
        .eq('status', 'published')
        .order('name');
  }

  Future<String?> getSignedUrl(String storagePath) async {
    try {
      return await _client.storage
          .from('course-materials')
          .createSignedUrl(storagePath, 3600);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> myCompletedCourseIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('certification_submissions')
        .select('course_id')
        .eq('sitter_id', uid)
        .gte('score', 80);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
