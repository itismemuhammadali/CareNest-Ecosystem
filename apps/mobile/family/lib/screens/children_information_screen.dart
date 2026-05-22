import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/custom_text_field.dart';
import 'package:star_sitter_family/widgets/header2.dart';

class _ChildEntry {
  final name = TextEditingController();
  final age = TextEditingController();
  final gender = TextEditingController();
  final allergies = TextEditingController();
  final special = TextEditingController();

  void fillFrom(Map<String, dynamic> row, String? notes) {
    name.text = (row['name'] ?? '').toString();
    age.text = (row['age'] ?? '').toString();
    _applyNotes(notes);
  }

  void _applyNotes(String? notes) {
    gender.text = '';
    allergies.text = '';
    special.text = '';
    if (notes == null || notes.isEmpty) return;
    for (final line in notes.split('\n')) {
      final t = line.trim();
      if (t.toLowerCase().startsWith('gender:')) {
        gender.text = t.substring(7).trim();
      } else if (t.toLowerCase().startsWith('allergies:')) {
        allergies.text = t.substring(10).trim();
      } else if (t.toLowerCase().startsWith('special:')) {
        special.text = t.substring(8).trim();
      }
    }
  }

  String get encodedNotes =>
      'Gender: ${gender.text.trim()}\nAllergies: ${allergies.text.trim()}\nSpecial: ${special.text.trim()}';

  void dispose() {
    name.dispose();
    age.dispose();
    gender.dispose();
    allergies.dispose();
    special.dispose();
  }
}

class ChildrenInformationScreen extends StatefulWidget {
  const ChildrenInformationScreen({super.key});

  @override
  State<ChildrenInformationScreen> createState() =>
      _ChildrenInformationScreenState();
}

class _ChildrenInformationScreenState extends State<ChildrenInformationScreen> {
  final List<_ChildEntry> _children = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list =
        await ProfileRepository(Supabase.instance.client).listFamilyChildren();
    if (!mounted) return;
    setState(() {
      _children.clear();
      if (list.isEmpty) {
        _children.add(_ChildEntry());
      } else {
        for (final row in list) {
          final entry = _ChildEntry();
          entry.fillFrom(
            Map<String, dynamic>.from(row as Map),
            row['notes']?.toString(),
          );
          _children.add(entry);
        }
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in _children) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final rows = <Map<String, Object>>[];
    String? validationError;

    for (int i = 0; i < _children.length; i++) {
      final e = _children[i];
      final nm = e.name.text.trim();
      if (nm.isEmpty) continue;
      final age = int.tryParse(e.age.text.trim());
      if (age == null || age < 0 || age > 18) {
        validationError = 'Age must be 0–18 for child ${i + 1} ("$nm").';
        break;
      }
      rows.add({'name': nm, 'age': age, 'notes': e.encodedNotes});
    }

    if (validationError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter at least one child name and age.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ProfileRepository(Supabase.instance.client)
          .replaceFamilyChildren(rows);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Children information saved.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addChild() {
    setState(() => _children.add(_ChildEntry()));
  }

  void _removeChild(int index) {
    if (_children.length <= 1) return;
    setState(() {
      _children[index].dispose();
      _children.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Header2(
              title: 'Children Information',
              subtitle: 'Manage details about your children',
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 24,
                        right: 24,
                        bottom: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...List.generate(_children.length, (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _childBlock(i),
                          )),
                          // Add child button
                          GestureDetector(
                            onTap: _saving ? null : _addChild,
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFC8F0FF)
                                        .withValues(alpha: 0.5)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      color: Color(0xFFC8F0FF), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add Child',
                                    style: TextStyle(
                                        color: Color(0xFFC8F0FF),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: OutlinedButton(
                                    onPressed: _saving
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: Colors.white
                                            .withValues(alpha: 0.3),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFC8F0FF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      _saving ? 'Saving…' : 'Save Changes',
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _childBlock(int index) {
    final e = _children[index];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Child ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_children.length > 1)
                GestureDetector(
                  onTap: _saving ? null : () => _removeChild(index),
                  child: const Icon(Icons.close,
                      color: Color(0x99FFFFFF), size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: e.name,
            label: "Child's Name",
            hintText: 'Name',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: e.age,
                  label: 'Age',
                  hintText: '5',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: e.gender,
                  label: 'Gender',
                  hintText: 'Optional',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: e.allergies,
            label: 'Allergies / Dietary Restrictions',
            hintText: 'Optional',
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: e.special,
            label: 'Special needs or medical notes',
            hintText: 'Optional',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
