/// Pure Dart: family onboarding wizard → `children` row payloads (no Flutter / Supabase).

List<Map<String, Object>> parseFamilyOnboardingChildrenRecords({
  required String countStr,
  required String agesStr,
}) {
  final count = int.tryParse(countStr.trim()) ?? 0;
  if (count <= 0) return [];
  final ages = agesStr
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .where((a) => a >= 0 && a <= 18)
      .toList();
  final out = <Map<String, Object>>[];
  for (var i = 0; i < count; i++) {
    final age = i < ages.length ? ages[i] : (ages.isNotEmpty ? ages.last : 8);
    out.add({'name': 'Child ${i + 1}', 'age': age});
  }
  return out;
}
