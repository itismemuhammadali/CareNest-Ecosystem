import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_sitters_core/star_sitters_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/primary_button.dart';
import '../widgets/auth_gate.dart';

class CreateAccountStep6Screen extends StatefulWidget {
  final String? userId;
  
  const CreateAccountStep6Screen({super.key, this.userId});

  @override
  State<CreateAccountStep6Screen> createState() =>
      _CreateAccountStep6ScreenState();
}

class _CreateAccountStep6ScreenState extends State<CreateAccountStep6Screen> {
  bool _confirmed = false;
  bool _submitting = false;

  void _goBackToStep(int stepsBack) {
    int count = 0;
    Navigator.of(context).popUntil((_) => count++ >= stepsBack);
  }

  // Real data loaded from Supabase
  String _fullName = '—';
  String _email = '—';
  String _phone = '—';
  String _bio = '';
  String _guardianName = '—';
  String _guardianPhone = '—';
  String _guardianEmail = '—';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final profileRepo = ProfileRepository(client);

    // Load user row (full_name, email, phone)
    final userRow = await profileRepo.currentUserRow();
    // Load guardian consent row
    final guardianRow = await client
        .from('guardian_consents')
        .select()
        .eq('sitter_id', user.id)
        .maybeSingle();
    // Load sitter profile (bio)
    final sitterRow = await profileRepo.sitterProfile();

    if (!mounted) return;
    setState(() {
      _fullName = userRow?['full_name']?.toString() ?? user.email?.split('@').first ?? '—';
      _email = userRow?['email']?.toString() ?? user.email ?? '—';
      _phone = userRow?['phone']?.toString() ?? '—';
      _bio = sitterRow?['bio']?.toString() ?? '';
      _avatarUrl = userRow?['avatar_url']?.toString();
      if (guardianRow != null) {
        final g = guardianRow;
        _guardianName = g['guardian_name']?.toString() ?? '—';
        _guardianPhone = g['guardian_phone']?.toString() ?? '—';
        _guardianEmail = g['guardian_email']?.toString() ?? '—';
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await Supabase.instance.client.rpc('sitter_submit_for_review');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
        setState(() => _submitting = false);
      }
    }
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
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1E293B),
                              title: const Text('Go back?',
                                  style: TextStyle(color: Colors.white)),
                              content: const Text(
                                'Going back will lose your progress on this review step. Continue?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Stay',
                                      style: TextStyle(color: Color(0xFFA8D8EA))),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Go back',
                                      style: TextStyle(color: Color(0xFFFF6467))),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
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
                      const Text('Step 6 of 6',
                          style: TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          value: 1.0,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC8F0FF)),
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
                        const SizedBox(height: 20),

                        // Review info box
                        _buildInfoBox(
                          'Review Your Information',
                          'Please review all your details carefully. Your profile will be submitted for admin review and you\'ll be notified once approved.',
                        ),
                        const SizedBox(height: 16),

                        // Profile card
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xFF1E293B),
                                    backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                        ? NetworkImage(_avatarUrl!) as ImageProvider
                                        : null,
                                    child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                                        ? const Icon(Icons.person, color: Colors.white38, size: 28)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_fullName,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(height: 4),
                                        Text(_email,
                                            style: const TextStyle(fontSize: 12, color: Colors.white54)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _bio.isNotEmpty ? _bio : 'No bio added yet.',
                                style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Personal Information
                        _buildSection('Personal Information', [
                          _buildFieldRow('Full Name', _fullName,
                              onEdit: () => _goBackToStep(5)),
                          _buildFieldRow('Email Address', _email,
                              onEdit: () => _goBackToStep(5)),
                          _buildFieldRow('Phone Number', _phone.isNotEmpty && _phone != '—' ? _phone : 'Not provided',
                              isLast: true, onEdit: () => _goBackToStep(5)),
                        ]),
                        const SizedBox(height: 16),

                        // Guardian Information
                        _buildSection('Guardian Information', [
                          _buildFieldRow('Guardian Name', _guardianName,
                              onEdit: () => _goBackToStep(4)),
                          _buildFieldRow('Guardian Phone', _guardianPhone.isNotEmpty && _guardianPhone != '—' ? _guardianPhone : 'Not provided',
                              onEdit: () => _goBackToStep(4)),
                          _buildFieldRow('Guardian Email', _guardianEmail,
                              isLast: true, onEdit: () => _goBackToStep(4)),
                        ], footer: _buildConsentBox()),
                        const SizedBox(height: 16),

                        // Profile Details
                        _buildSection('Profile Details', [
                          _buildBioRow('Bio', _bio.isNotEmpty ? _bio : 'No bio added yet.',
                              onEdit: () => _goBackToStep(2)),
                          _buildFieldRow('Experience', 'To be reviewed by admin',
                              isLast: true, onEdit: () => _goBackToStep(2)),
                        ]),
                        const SizedBox(height: 16),

                        // Documents
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Documents',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 12),
                              _buildDocumentRow(Icons.insert_drive_file_outlined, 'Government/School ID', 'Required for verification'),
                              const SizedBox(height: 10),
                              _buildDocumentRow(null, 'Profile Photo', 'Helps families recognize you', svgAsset: 'assets/image-icon.svg'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // What happens next
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x1AB5FFD9),
                            borderRadius: BorderRadius.circular(16),
                            border: const Border(
                              top: BorderSide(color: Color(0x4DB5FFD9), width: 1.09),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.info_outline, color: Color(0xFFB5FFD9), size: 18),
                                  SizedBox(width: 8),
                                  Text('What happens next?',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFB5FFD9))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildNumberedStep(1, 'Your profile will be reviewed by our admin team'),
                              _buildNumberedStep(2, 'We\'ll verify your identity and contact your guardian'),
                              _buildNumberedStep(3, 'You\'ll receive an email notification once approved'),
                              _buildNumberedStep(4, 'Complete certification training to start applying for jobs'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Confirm checkbox
                        GestureDetector(
                          onTap: () => setState(() => _confirmed = !_confirmed),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0x991E293B),
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                              border: Border(
                                top: BorderSide(color: Color(0x33A8D8EA), width: 1.09),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _confirmed,
                                    onChanged: (val) => setState(() => _confirmed = val!),
                                    activeColor: const Color(0xFFA8D8EA),
                                    checkColor: const Color(0xFF0F172A),
                                    side: const BorderSide(color: Color(0xFFA8D8EA), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'I confirm that all the information provided is accurate.',
                                    style: TextStyle(fontSize: 13, color: Color(0xFFA8D8EA), height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: PrimaryButton(
                    label: _submitting ? 'Submitting…' : 'Submit for Review',
                    onPressed: (_confirmed && !_submitting) ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(12),
        border: const Border(top: BorderSide(color: Color(0x33A8D8EA), width: 1.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFA8D8EA))),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 13, color: Color(0xFFA8D8EA), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          top: BorderSide(color: Color(0x33A8D8EA), width: 1.09),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSection(String title, List<Widget> rows, {Widget? footer}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title container — #A8D8EA with 10% opacity
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: const Color(0x1AA8D8EA),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: const Border(
              top: BorderSide(color: Color(0x33A8D8EA), width: 1.09),
            ),
          ),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        // Fields container — #1E293B with 60% opacity
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0x991E293B),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: const Border(
              top: BorderSide(color: Color(0x33A8D8EA), width: 1.09),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...rows,
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: footer,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ', style: const TextStyle(fontSize: 13, color: Color(0xFFB5FFD9))),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Color(0xFFB5FFD9), height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildBioRow(String label, String value, {VoidCallback? onEdit}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(),
                  GestureDetector(
                    onTap: onEdit,
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/edit-icon.svg',
                          width: 13,
                          height: 13,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFA8D8EA),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Edit',
                            style: TextStyle(fontSize: 13, color: Color(0xFFA8D8EA))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFFA8D8EA))),
                    const SizedBox(height: 6),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }

  Widget _buildConsentBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/tick-icon.svg',
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFF4ADE80),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          const Text('Guardian consent confirmed',
              style: TextStyle(fontSize: 13, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value,
      {String? subValue, bool isLast = false, VoidCallback? onEdit}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFFA8D8EA))),
                  GestureDetector(
                    onTap: onEdit,
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/edit-icon.svg',
                          width: 13,
                          height: 13,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFA8D8EA),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Edit',
                            style: TextStyle(fontSize: 13, color: Color(0xFFA8D8EA))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              if (subValue != null) ...[
                const SizedBox(height: 4),
                Text(subValue,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF4ADE80))),
              ],
            ],
          ),
        ),
        if (!isLast) const Divider(color: Color(0x33A8D8EA), height: 1),
      ],
    );
  }

  Widget _buildDocumentRow(IconData? icon, String title, String subtitle,
      {String? svgAsset}) {
    return Row(
      children: [
        // Icon box
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0x1AA8D8EA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: svgAsset != null
                ? SvgPicture.asset(
                    svgAsset,
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFA8D8EA),
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(icon, color: const Color(0xFFA8D8EA), size: 22),
          ),
        ),
        const SizedBox(width: 12),
        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0x99A8D8EA))),
            ],
          ),
        ),
        // Upload text
        const Text(
          'Upload',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFFA8D8EA),
          ),
        ),
      ],
    );
  }
}

