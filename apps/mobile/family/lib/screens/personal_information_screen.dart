import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:star_sitter_family/widgets/app_background.dart';
import 'package:star_sitter_family/widgets/custom_text_field.dart';
import 'package:star_sitter_family/widgets/header2.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _primaryPhoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  Country _primaryCountry = kCountries.first;
  Country _alternateCountry = kCountries.first;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Country _parseCountry(String phone) {
    for (final c in kCountries) {
      if (phone.startsWith(c.dialCode)) return c;
    }
    return kCountries.first;
  }

  String _stripDialCode(String phone, Country country) {
    final code = country.dialCode;
    return phone.startsWith(code) ? phone.substring(code.length) : phone;
  }

  Future<void> _load() async {
    final row =
        await ProfileRepository(Supabase.instance.client).currentUserRow();
    if (!mounted) return;
    if (row != null) {
      _fullNameController.text = (row['full_name'] ?? '').toString();
      _emailController.text = (row['email'] ?? '').toString();
      final phone = (row['phone'] ?? '').toString();
      if (phone.isNotEmpty) {
        final country = _parseCountry(phone);
        _primaryCountry = country;
        _primaryPhoneController.text = _stripDialCode(phone, country);
      }
    }
    final authEmail = Supabase.instance.client.auth.currentUser?.email;
    if (_emailController.text.isEmpty && authEmail != null) {
      _emailController.text = authEmail;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _primaryPhoneController.dispose();
    _alternatePhoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _fullNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final rawPrimary = _primaryPhoneController.text.trim();
      await ProfileRepository(Supabase.instance.client).updateCurrentUser(
        fullName: name,
        phone: rawPrimary.isEmpty
            ? null
            : '${_primaryCountry.dialCode}$rawPrimary',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showCountryPicker({required ValueChanged<Country> onSelect}) {
    List<Country> filtered = List.from(kCountries);
    final current = onSelect == _setPrimary ? _primaryCountry : _alternateCountry;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Select Country', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search countries…',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true, fillColor: Colors.white12,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onChanged: (q) => setModalState(() {
                    filtered = kCountries.where((c) =>
                      c.name.toLowerCase().contains(q.toLowerCase()) ||
                      c.dialCode.contains(q)).toList();
                  }),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final country = filtered[i];
                    final selected = country.code == current.code;
                    return ListTile(
                      leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(country.name, style: const TextStyle(color: Colors.white)),
                      trailing: Text(country.dialCode, style: TextStyle(color: selected ? const Color(0xFFC8F0FF) : Colors.white54)),
                      selected: selected,
                      selectedTileColor: Colors.white12,
                      onTap: () {
                        setState(() => onSelect(country));
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setPrimary(Country c) => _primaryCountry = c;
  void _setAlternate(Country c) => _alternateCountry = c;

  Widget _phoneRow({
    required TextEditingController controller,
    required Country country,
    required VoidCallback onCountryTap,
    required String hint,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onCountryTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0x991E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(country.dialCode, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              filled: true,
              fillColor: const Color(0x991E293B),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            Header2(
              title: 'Personal Information',
              subtitle: 'Update your name and phone (email is managed by sign-in)',
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.only(top: 20, left: 24, right: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0x991E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _fullNameController,
                              label: 'Full Legal Name',
                              hintText: 'Your name',
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email (read-only)',
                              hintText: 'email@example.com',
                              readOnly: true,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'To change email, use account settings in your auth provider.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('Primary Phone',
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            _phoneRow(
                              controller: _primaryPhoneController,
                              country: _primaryCountry,
                              onCountryTap: () => _showCountryPicker(onSelect: _setPrimary),
                              hint: '555 123 4567',
                            ),
                            const SizedBox(height: 20),
                            Text('Alternate Phone (Optional)',
                                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            _phoneRow(
                              controller: _alternatePhoneController,
                              country: _alternateCountry,
                              onCountryTap: () => _showCountryPicker(onSelect: _setAlternate),
                              hint: '555 123 4567',
                            ),
                            const SizedBox(height: 32),
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
                                          borderRadius: BorderRadius.circular(10),
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
                                        backgroundColor: const Color(0xFFC8F0FF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
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
            ),
          ],
        ),
      ),
    );
  }
}
