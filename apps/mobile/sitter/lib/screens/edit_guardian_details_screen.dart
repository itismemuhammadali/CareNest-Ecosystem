import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/profile/profile_text_field.dart';

class EditGuardianDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const EditGuardianDetailsScreen({super.key, this.existing});

  @override
  State<EditGuardianDetailsScreen> createState() => _EditGuardianDetailsScreenState();
}

class _EditGuardianDetailsScreenState extends State<EditGuardianDetailsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String _relationship = 'Parent';
  bool _saving = false;

  final List<String> _relationships = [
    'Parent', 'Mother', 'Father', 'Guardian', 'Uncle', 'Aunt', 'Grandparent', 'Other',
  ];

  Country _selectedCountry = kCountries.first;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?['guardian_name']?.toString() ?? '');
    _emailController = TextEditingController(text: e?['guardian_email']?.toString() ?? '');
    final rel = e?['relationship']?.toString();
    if (rel != null && _relationships.contains(rel)) _relationship = rel;

    // Pre-select country from existing phone
    final phone = e?['guardian_phone']?.toString() ?? '';
    Country? matched;
    if (phone.isNotEmpty) {
      for (final c in kCountries) {
        if (phone.startsWith(c.dialCode)) { matched = c; break; }
      }
    }
    _selectedCountry = matched ?? kCountries.first;
    final dialCode = _selectedCountry.dialCode;
    final digits = phone.startsWith(dialCode) ? phone.substring(dialCode.length) : phone;
    _phoneController = TextEditingController(text: digits);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final rawPhone = _phoneController.text.trim();
      await Supabase.instance.client.from('guardian_consents').update({
        'guardian_name': _nameController.text.trim(),
        'guardian_email': _emailController.text.trim(),
        'guardian_phone': rawPhone.isEmpty ? null : '${_selectedCountry.dialCode}$rawPhone',
        'relationship': _relationship,
        'status': 'pending',
      }).eq('sitter_id', uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved — re-verification email will be sent.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showCountryPicker() {
    List<Country> filtered = List.from(kCountries);
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
                    final selected = country.code == _selectedCountry.code;
                    return ListTile(
                      leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(country.name, style: const TextStyle(color: Colors.white)),
                      trailing: Text(country.dialCode, style: TextStyle(color: selected ? const Color(0xFFC8F0FF) : Colors.white54)),
                      selected: selected,
                      selectedTileColor: Colors.white12,
                      onTap: () {
                        setState(() => _selectedCountry = country);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB30F172A), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Back', style: TextStyle(fontSize: 15, color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Guardian Details',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Edit guardian information',
                          style: TextStyle(fontSize: 13, color: Color(0xB2A8D8EA)),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x1AD4B5FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x4DD4B5FF), width: 1.09),
                          ),
                          child: const Text(
                            'Guardian consent is required for all babysitters under 18. Any changes to guardian information will need to be re-verified.',
                            style: TextStyle(fontSize: 13, color: Color(0xFFD4B5FF), height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ProfileTextField(label: 'Guardian Name', controller: _nameController),
                        const SizedBox(height: 16),
                        ProfileTextField(label: 'Guardian Email', controller: _emailController, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        Text('Guardian Phone',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _showCountryPicker,
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_selectedCountry.flag, style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 6),
                                    Text(_selectedCountry.dialCode, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: '555 123 4567',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: Colors.transparent,
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
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Relationship',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _relationship,
                            dropdownColor: const Color(0xFF1E293B),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0x99FFFFFF)),
                            style: const TextStyle(fontSize: 14, color: Color(0x99FFFFFF)),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            items: [
                              for (final r in _relationships)
                                DropdownMenuItem(value: r, child: Text(r)),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _relationship = val);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF0F172B), Color(0xFF03060F), Color(0xFF0F172B)],
                    ),
                    border: Border(top: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _saving ? null : () => Navigator.pop(context),
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _saving ? null : _save,
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8F0FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E293B)),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/save-icon.svg',
                                        width: 16, height: 16,
                                        colorFilter: const ColorFilter.mode(Color(0xFF1E293B), BlendMode.srcIn),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Save Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
