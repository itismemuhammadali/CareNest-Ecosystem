import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/primary_button.dart';
import '../utils/navigation_transitions.dart';
import 'create_account_step3_screen.dart';

class CreateAccountStep2Screen extends StatefulWidget {
  final String? userId;
  
  const CreateAccountStep2Screen({super.key, this.userId});

  @override
  State<CreateAccountStep2Screen> createState() => _CreateAccountStep2ScreenState();
}

class _CreateAccountStep2ScreenState extends State<CreateAccountStep2Screen> {
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _guardianEmailController = TextEditingController();
  Country _selectedCountry = kCountries.first;
  bool _consentChecked = false;
  bool _saving = false;

  @override
  void dispose() {
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _guardianEmailController.dispose();
    super.dispose();
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
                // ── Pinned header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Create Account',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      const Text('Step 2 of 6',
                          style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 2 / 6,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC8F0FF)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        // Info box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                              top: BorderSide(
                                color: Color(0x4DD4B5FF), // 30% opacity
                                width: 1.09,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Guardian consent is required for minors (under 18). Your parent/guardian will be contacted for verification.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFD4B5FF),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel('Parent/Guardian Full Name'),
                        const SizedBox(height: 8),
                        _buildTextField(
                            controller: _guardianNameController, hint: 'Enter Name'),
                        const SizedBox(height: 16),
                        _buildLabel('Guardian Contact Number'),
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
                              child: _buildTextField(
                                controller: _guardianPhoneController,
                                hint: '555 123 4567',
                                keyboardType: TextInputType.phone,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Guardian Email'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _guardianEmailController,
                          hint: 'parent@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        // Consent checkbox
                        GestureDetector(
                          onTap: () =>
                              setState(() => _consentChecked = !_consentChecked),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _consentChecked,
                                onChanged: (val) => setState(
                                    () => _consentChecked = val!),
                                activeColor: const Color(0xFFC8F0FF),
                                checkColor: const Color(0xFF0F172A),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'I confirm that my parent/guardian consents to my registration and use of this platform.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xB3A8D8EA),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: PrimaryButton(
                    label: _saving ? 'Saving…' : 'Continue',
                    onPressed: _saving
                        ? () {}
                        : () async {
                            if (!_consentChecked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please confirm guardian consent.')),
                              );
                              return;
                            }
                            final name = _guardianNameController.text.trim();
                            final email = _guardianEmailController.text.trim();
                            if (name.isEmpty || email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enter guardian name and email.')),
                              );
                              return;
                            }
                            setState(() => _saving = true);
                            try {
                              final rawPhone = _guardianPhoneController.text.trim();
                              
                              // Use passed userId if available, otherwise fall back to currentUser
                              final uid = widget.userId ?? Supabase.instance.client.auth.currentUser?.id;
                              if (uid == null) {
                                throw StateError('Not signed in');
                              }
                              
                              // Call RPC to create guardian consent (bypasses RLS for unconfirmed users)
                              final result = await Supabase.instance.client.rpc(
                                'sitter_create_guardian_consent',
                                params: {
                                  'p_sitter_id': uid,
                                  'p_guardian_name': name.trim(),
                                  'p_guardian_email': email.trim(),
                                  if (rawPhone.isNotEmpty)
                                    'p_guardian_phone': '${_selectedCountry.dialCode}$rawPhone',
                                },
                              );
                              
                              if (result is Map && result['error'] != null) {
                                throw Exception(result['error']);
                              }
                              
                              if (!mounted) return;
                              Navigator.of(context).push(
                                NavigationTransitions.fadeTransition(
                                  CreateAccountStep3Screen(userId: widget.userId),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not save: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) =>
      Text(text, style: const TextStyle(fontSize: 14, color: Colors.white));

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
      ),
    );
  }
}
