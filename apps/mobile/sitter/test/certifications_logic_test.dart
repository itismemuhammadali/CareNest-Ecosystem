import 'package:flutter_test/flutter_test.dart';

/// Tests the material_paths extraction logic used in _CourseCard.
List<String> extractMaterialPaths(dynamic rawPaths) {
  return rawPaths is List ? rawPaths.whereType<String>().toList() : <String>[];
}

void main() {
  group('extractMaterialPaths', () {
    test('returns empty list when material_paths is null', () {
      expect(extractMaterialPaths(null), isEmpty);
    });

    test('returns empty list when material_paths is empty list', () {
      expect(extractMaterialPaths([]), isEmpty);
    });

    test('returns paths when material_paths has strings', () {
      final paths = extractMaterialPaths(['courses/cpr-guide.pdf', 'courses/safety.pdf']);
      expect(paths, hasLength(2));
      expect(paths.first, 'courses/cpr-guide.pdf');
    });

    test('filters out non-string values', () {
      final paths = extractMaterialPaths(['valid.pdf', 42, null, 'other.pdf']);
      expect(paths, hasLength(2));
      expect(paths, containsAll(['valid.pdf', 'other.pdf']));
    });

    test('returns empty when raw is not a list', () {
      expect(extractMaterialPaths('not a list'), isEmpty);
      expect(extractMaterialPaths(42), isEmpty);
      expect(extractMaterialPaths({}), isEmpty);
    });

    test('shows View Materials button only when paths is non-empty', () {
      final noMaterials = extractMaterialPaths(null);
      expect(noMaterials.isEmpty, isTrue); // button hidden

      final withMaterials = extractMaterialPaths(['cpr.pdf']);
      expect(withMaterials.isNotEmpty, isTrue); // button shown
    });
  });
}
