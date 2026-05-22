import 'package:flutter/material.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/custom_text_field.dart';
import 'package:star_sitter_family/widgets/header2.dart';

class _ContactEntry {
  final name = TextEditingController();
  final relationship = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  Country selectedCountry;

  _ContactEntry({Country? country})
      : selectedCountry = country ?? kCountries.first;

  void fillFrom(Map<String, dynamic> m) {
    name.text = '${m['contact_name'] ?? m['name'] ?? ''}'.trim();
    relationship.text = '${m['relationship'] ?? ''}'.trim();
    phone.text = '${m['phone'] ?? m['phone_number'] ?? ''}'.trim();
    email.text = '${m['email'] ?? m['email_address'] ?? ''}'.trim();
    final code = m['country_code']?.toString();
    if (code != null) {
      final match = kCountries.where((c) => c.code == code);
      if (match.isNotEmpty) selectedCountry = match.first;
    }
  }

  Map<String, dynamic> toMap() => {
        'contact_name': name.text.trim(),
        'relationship': relationship.text.trim(),
        'phone': phone.text.trim(),
        'country_code': selectedCountry.code,
        'dial_code': selectedCountry.dialCode,
        'email': email.text.trim(),
      };

  bool get isEmpty =>
      name.text.trim().isEmpty &&
      phone.text.trim().isEmpty &&
      email.text.trim().isEmpty;

  void dispose() {
    name.dispose();
    relationship.dispose();
    phone.dispose();
    email.dispose();
  }
}

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final List<_ContactEntry> _contacts = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row =
          await ProfileRepository(Supabase.instance.client).familyProfile();
      if (!mounted) return;
      final raw = row?['emergency_contact'];
      final loaded = _parseContacts(raw);
      setState(() {
        _contacts.clear();
        if (loaded.isEmpty) {
          _contacts.add(_ContactEntry());
        } else {
          _contacts.addAll(loaded);
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_ContactEntry> _parseContacts(dynamic raw) {
    if (raw == null) return [];
    // New format: {'contacts': [...]}
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      if (m.containsKey('contacts') && m['contacts'] is List) {
        return _mapListToEntries(m['contacts'] as List);
      }
      // Old single-object format backward compat
      if (m.containsKey('contact_name') || m.containsKey('name')) {
        final e = _ContactEntry()..fillFrom(m);
        return [e];
      }
    }
    if (raw is List) {
      return _mapListToEntries(raw);
    }
    return [];
  }

  List<_ContactEntry> _mapListToEntries(List list) {
    return list
        .whereType<Map>()
        .map((m) {
          final e = _ContactEntry()
            ..fillFrom(Map<String, dynamic>.from(m));
          return e;
        })
        .toList();
  }

  @override
  void dispose() {
    for (final c in _contacts) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final validContacts = _contacts.where((c) => !c.isEmpty).toList();
    for (int i = 0; i < validContacts.length; i++) {
      final c = validContacts[i];
      if (c.name.text.trim().isEmpty ||
          c.relationship.text.trim().isEmpty ||
          c.phone.text.trim().isEmpty ||
          c.email.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please fill all fields for contact ${i + 1}.'),
        ));
        return;
      }
    }
    if (validContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one emergency contact.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ProfileRepository(Supabase.instance.client).updateFamily(
        emergencyContact: {
          'contacts': validContacts.map((c) => c.toMap()).toList(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency contacts saved.')),
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

  void _addContact() {
    setState(() => _contacts.add(_ContactEntry()));
  }

  void _removeContact(int index) {
    if (_contacts.length <= 1) return;
    setState(() {
      _contacts[index].dispose();
      _contacts.removeAt(index);
    });
  }

  void _showCountryPicker(int contactIndex) {
    final searchController = TextEditingController();
    List<Country> filtered = List.from(kCountries);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (_, scrollController) => Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Country',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search country...',
                        hintStyle: const TextStyle(color: Color(0x61FFFFFF)),
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0x61FFFFFF)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (q) {
                        setModal(() {
                          filtered = kCountries
                              .where((c) =>
                                  c.name
                                      .toLowerCase()
                                      .contains(q.toLowerCase()) ||
                                  c.dialCode.contains(q))
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final country = filtered[i];
                        final selected =
                            country.code == _contacts[contactIndex].selectedCountry.code;
                        return ListTile(
                          leading: Text(country.flag,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(country.name,
                              style: const TextStyle(color: Colors.white)),
                          trailing: Text(
                            country.dialCode,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFFC8F0FF)
                                  : const Color(0x99FFFFFF),
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: selected,
                          selectedTileColor:
                              Colors.white.withValues(alpha: 0.05),
                          onTap: () {
                            setState(() =>
                                _contacts[contactIndex].selectedCountry =
                                    country);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Header2(
              title: 'Emergency Contacts',
              subtitle: 'Backup contacts for emergency situations',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20, left: 24, right: 24),
                child: Column(
                  children: [
                    ...List.generate(_contacts.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _contactCard(i),
                    )),
                    // Add contact button
                    GestureDetector(
                      onTap: _saving ? null : _addContact,
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
                              'Add Contact',
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
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                    color:
                                        Colors.white.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
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
                                backgroundColor: const Color(0xFFC8F0FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.zero,
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(int index) {
    final c = _contacts[index];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (_contacts.length > 1)
                GestureDetector(
                  onTap: _saving ? null : () => _removeContact(index),
                  child: const Icon(Icons.close,
                      color: Color(0x99FFFFFF), size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: c.name,
            label: 'Contact Name',
            hintText: 'Full name',
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: c.relationship,
            label: 'Relationship',
            hintText: 'Spouse, parent, etc.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Phone Number',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showCountryPicker(index),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.selectedCountry.flag,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(
                        c.selectedCountry.dialCode,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down,
                          color: Color(0x99FFFFFF), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: c.phone,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    hintStyle:
                        const TextStyle(color: Color(0x61FFFFFF)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: c.email,
            label: 'Email Address',
            hintText: 'email@example.com',
          ),
        ],
      ),
    );
  }
}
