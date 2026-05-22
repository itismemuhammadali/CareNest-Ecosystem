import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();

  static const List<Map<String, dynamic>> _topics = [
    {
      'title': 'Getting Started',
      'svgAsset': 'assets/book-icon.svg',
      'items': [
        'How to create an account',
        'Complete your certification',
        'Setting up your profile',
        'Understanding guardian consent',
      ],
    },
    {
      'title': 'Finding Jobs',
      'svgAsset': null,
      'icon': Icons.search_outlined,
      'items': [
        'How to browse available jobs',
        'Applying to babysitting positions',
        'Communicating with families',
        'Job application status',
      ],
    },
    {
      'title': 'During a Job',
      'svgAsset': null,
      'icon': Icons.work_outline,
      'items': [
        'Using clock-in/clock-out',
        'Safety guidelines',
        'Emergency procedures',
        'Reporting issues',
      ],
    },
    {
      'title': 'Payments & Earnings',
      'svgAsset': null,
      'icon': Icons.payments_outlined,
      'items': [
        'How payment works',
        'Viewing your earnings',
        'Payment schedule',
        'Tax information',
      ],
    },
  ];

  // Track which accordion items are expanded
  final Map<String, bool> _expanded = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                // ── Pinned transparent header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Back',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Help Center',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Get help and support',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                // ── Scrollable body ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Search bar
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0x1AA8D8EA), width: 1),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              Icon(Icons.search,
                                  color: Colors.white.withValues(alpha: 0.4),
                                  size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search for help...',
                                    hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.3)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Popular Topics
                        const Text(
                          'Popular Topics',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 12),

                        for (final topic in _topics) ...[
                          _TopicCard(
                            title: topic['title'] as String,
                            icon: topic['icon'] as IconData?,
                            svgAsset: topic['svgAsset'] as String?,
                            items: List<String>.from(
                                topic['items'] as List),
                            expanded: _expanded,
                            onToggle: (key) => setState(
                                () => _expanded[key] = !(_expanded[key] ?? false)),
                          ),
                          const SizedBox(height: 12),
                        ],

                        const SizedBox(height: 12),

                        // Contact Support
                        const Text(
                          'Contact Support',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 12),

                        _contactCard(
                          svgAsset: 'assets/roundmsg-icon.svg',
                          iconColor: const Color(0xFFA8D8EA),
                          iconBg: const Color(0x1AA8D8EA),
                          title: 'Live Chat Support',
                          subtitle: 'Chat with our support team',
                        ),
                        const SizedBox(height: 10),
                        _contactCard(
                          svgAsset: 'assets/envelop.svg',
                          iconColor: const Color(0xFFB5FFD9),
                          iconBg: const Color(0x1AB5FFD9),
                          title: 'Email Support',
                          subtitle: 'support@starsitter.app',
                        ),
                        const SizedBox(height: 10),
                        _contactCard(
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFFD4B5FF),
                          iconBg: const Color(0x1AD4B5FF),
                          title: 'Phone Support',
                          subtitle: '1-800-BABYSIT\nAvailable Mon-Fri 9AM-5PM',
                        ),
                        const SizedBox(height: 20),

                        // FAQ card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0x991E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0x1AA8D8EA), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Frequently Asked Questions',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Find quick answers to common questions',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.4)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: const [
                                  Text(
                                    'View all FAQs',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFA8D8EA)),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward,
                                      color: Color(0xFFA8D8EA), size: 14),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard({
    IconData? icon,
    String? svgAsset,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: svgAsset != null
                  ? SvgPicture.asset(svgAsset,
                      width: 20,
                      height: 20,
                      colorFilter:
                          ColorFilter.mode(iconColor, BlendMode.srcIn))
                  : Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                        height: 1.4)),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3), size: 20),
        ],
      ),
    );
  }
}

// ── Topic accordion card ──────────────────────────────────────────────────────

class _TopicCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? svgAsset;
  final List<String> items;
  final Map<String, bool> expanded;
  final void Function(String key) onToggle;

  const _TopicCard({
    required this.title,
    this.icon,
    this.svgAsset,
    required this.items,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1),
      ),
      child: Column(
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                if (svgAsset != null)
                  SvgPicture.asset(
                    svgAsset!,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFA8D8EA),
                      BlendMode.srcIn,
                    ),
                  )
                else
                  Icon(icon, color: const Color(0xFFA8D8EA), size: 18),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          // Divider
          Divider(
              color: Colors.white.withValues(alpha: 0.06),
              height: 1,
              thickness: 1),
          // Items
          for (int i = 0; i < items.length; i++) ...[
            _AccordionItem(
              label: items[i],
              isExpanded: expanded[items[i]] ?? false,
              onToggle: () => onToggle(items[i]),
            ),
            if (i < items.length - 1)
              Divider(
                  color: Colors.white.withValues(alpha: 0.04),
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _AccordionItem extends StatelessWidget {
  final String label;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _AccordionItem({
    required this.label,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white.withValues(alpha: 0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
