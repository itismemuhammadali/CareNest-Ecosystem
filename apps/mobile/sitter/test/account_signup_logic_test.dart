import 'package:flutter_test/flutter_test.dart';

/// Replicates the logic from create_account_screen.dart for isolated testing.
String? dobIsoFromUs(String raw) {
  final p = raw.trim().split('/');
  if (p.length != 3) return null;
  final m = int.tryParse(p[0]);
  final d = int.tryParse(p[1]);
  final y = int.tryParse(p[2]);
  if (m == null || d == null || y == null) return null;
  return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
}

int calcAge(DateTime dob, DateTime today) {
  int age = today.year - dob.year;
  if (today.month < dob.month ||
      (today.month == dob.month && today.day < dob.day)) {
    age--;
  }
  return age;
}

void main() {
  group('dobIsoFromUs', () {
    test('converts MM/DD/YYYY to ISO YYYY-MM-DD', () {
      expect(dobIsoFromUs('05/15/2010'), '2010-05-15');
      expect(dobIsoFromUs('1/1/2012'), '2012-01-01');
      expect(dobIsoFromUs('12/31/2009'), '2009-12-31');
    });

    test('returns null for missing parts', () {
      expect(dobIsoFromUs(''), isNull);
      expect(dobIsoFromUs('05/15'), isNull);
      expect(dobIsoFromUs('mm/dd/yyyy'), isNull);
    });

    test('returns null for non-numeric parts', () {
      expect(dobIsoFromUs('aa/bb/cccc'), isNull);
    });
  });

  group('calcAge', () {
    test('calculates age correctly on exact birthday', () {
      final today = DateTime(2026, 5, 18);
      final dob = DateTime(2012, 5, 18);
      expect(calcAge(dob, today), 14);
    });

    test('does not count birthday until it arrives', () {
      final today = DateTime(2026, 5, 17);
      final dob = DateTime(2012, 5, 18);
      expect(calcAge(dob, today), 13);
    });

    test('11-year-old is valid sitter age', () {
      final today = DateTime(2026, 5, 18);
      final dob = DateTime(2015, 5, 18);
      final age = calcAge(dob, today);
      expect(age, 11);
      expect(age >= 11 && age <= 17, isTrue);
    });

    test('17-year-old is valid sitter age', () {
      final today = DateTime(2026, 5, 18);
      final dob = DateTime(2009, 5, 18);
      final age = calcAge(dob, today);
      expect(age, 17);
      expect(age >= 11 && age <= 17, isTrue);
    });

    test('10-year-old is too young', () {
      final today = DateTime(2026, 5, 18);
      final dob = DateTime(2016, 5, 18);
      final age = calcAge(dob, today);
      expect(age, 10);
      expect(age >= 11 && age <= 17, isFalse);
    });

    test('18-year-old is too old', () {
      final today = DateTime(2026, 5, 18);
      final dob = DateTime(2008, 5, 18);
      final age = calcAge(dob, today);
      expect(age, 18);
      expect(age >= 11 && age <= 17, isFalse);
    });

    test('DOB of year 2000 (age 26) is rejected', () {
      final today = DateTime(2026, 5, 18);
      final dob = DateTime(2000, 1, 1);
      final age = calcAge(dob, today);
      expect(age > 17, isTrue);
    });
  });

  group('DatePicker range bounds', () {
    test('lastDate is exactly 11 years ago', () {
      final now = DateTime(2026, 5, 18);
      final lastDate = DateTime(now.year - 11, now.month, now.day);
      expect(lastDate, DateTime(2015, 5, 18));
    });

    test('firstDate is exactly 18 years ago', () {
      final now = DateTime(2026, 5, 18);
      final firstDate = DateTime(now.year - 18, now.month, now.day);
      expect(firstDate, DateTime(2008, 5, 18));
    });

    test('initialDate (14 years ago) is within range', () {
      final now = DateTime(2026, 5, 18);
      final firstDate = DateTime(now.year - 18, now.month, now.day);
      final lastDate = DateTime(now.year - 11, now.month, now.day);
      final initialDate = DateTime(now.year - 14, now.month, now.day);
      expect(initialDate.isAfter(firstDate) || initialDate == firstDate, isTrue);
      expect(initialDate.isBefore(lastDate) || initialDate == lastDate, isTrue);
    });
  });
}
