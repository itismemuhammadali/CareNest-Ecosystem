import 'package:flutter_test/flutter_test.dart';
import 'package:star_sitters_core/star_sitters_core.dart';

void main() {
  group('parseFamilyOnboardingChildrenRecords', () {
    test('empty and non-positive counts', () {
      expect(parseFamilyOnboardingChildrenRecords(countStr: '', agesStr: ''), isEmpty);
      expect(parseFamilyOnboardingChildrenRecords(countStr: '0', agesStr: '5'), isEmpty);
      expect(parseFamilyOnboardingChildrenRecords(countStr: '-2', agesStr: '3'), isEmpty);
    });

    test('trims count and parses ages', () {
      final rows = parseFamilyOnboardingChildrenRecords(
        countStr: '  3  ',
        agesStr: '4, 6, 9',
      );
      expect(rows.length, 3);
      expect(rows[0], {'name': 'Child 1', 'age': 4});
      expect(rows[1], {'name': 'Child 2', 'age': 6});
      expect(rows[2], {'name': 'Child 3', 'age': 9});
    });

    test('pads with last valid age', () {
      final rows = parseFamilyOnboardingChildrenRecords(
        countStr: '3',
        agesStr: '10',
      );
      expect(rows.map((m) => m['age']), [10, 10, 10]);
    });

    test('filters invalid ages and defaults to 8 when none valid', () {
      final rows = parseFamilyOnboardingChildrenRecords(
        countStr: '2',
        agesStr: '99, -1, abc',
      );
      expect(rows.length, 2);
      expect(rows[0]['age'], 8);
      expect(rows[1]['age'], 8);
    });

    test('keeps boundary ages 0 and 18', () {
      final rows = parseFamilyOnboardingChildrenRecords(
        countStr: '2',
        agesStr: '0, 18',
      );
      expect(rows[0]['age'], 0);
      expect(rows[1]['age'], 18);
    });
  });

  group('ProfileRepository delegation', () {
    test('matches pure parser', () {
      const c = '2';
      const a = '3, 5';
      expect(
        ProfileRepository.parseOnboardingChildrenRecords(countStr: c, agesStr: a),
        parseFamilyOnboardingChildrenRecords(countStr: c, agesStr: a),
      );
    });
  });
}
