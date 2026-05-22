import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ApplicationCard extends StatelessWidget {
  final String familyName;
  final String location;
  final String date;
  final String hours;
  final int childrenCount;
  final String wage;
  final String totalWage;
  final String description;
  final List<String> tags;
  final VoidCallback? onViewJobs;
  final VoidCallback? onMessage;

  const ApplicationCard({
    super.key,
    required this.familyName,
    required this.location,
    required this.date,
    required this.hours,
    required this.childrenCount,
    required this.wage,
    required this.totalWage,
    required this.description,
    required this.tags,
    this.onViewJobs,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AA8D8EA), width: 1.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family name + wage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                familyName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    wage,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB5FFD9),
                    ),
                  ),
                  Text(
                    totalWage,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Color(0x99A8D8EA), size: 14),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                    fontSize: 12, color: Color(0x99A8D8EA)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Date, hours, children
          Row(
            children: [
              SvgPicture.asset(
                'assets/calender-icon.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Color(0x99A8D8EA),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(date,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0x99A8D8EA))),
              const SizedBox(width: 14),
              const Icon(Icons.access_time_outlined,
                  color: Color(0x99A8D8EA), size: 14),
              const SizedBox(width: 4),
              Text(hours,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0x99A8D8EA))),
              const SizedBox(width: 14),
              SvgPicture.asset(
                'assets/hire-icon.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Color(0x99A8D8EA),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$childrenCount ${childrenCount == 1 ? 'child' : 'children'}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0x99A8D8EA)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0x99A8D8EA),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: tags.map((tag) => _buildTag(tag)).toList(),
          ),
          const SizedBox(height: 14),

          // Buttons
          Row(
            children: [
              Expanded(
                child: _OutlineButton(
                  label: 'View Jobs',
                  onTap: onViewJobs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MessageButton(onTap: onMessage),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    final bool isAvailable = label.toLowerCase() == 'available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? const Color(0x1AD4B5FF)
            : const Color(0x1EA8D8EA),
        borderRadius: BorderRadius.circular(20),
        border: isAvailable
            ? null
            : Border.all(color: const Color(0x33A8D8EA), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isAvailable
              ? const Color(0xFFD4B5FF)
              : const Color(0xFFA8D8EA),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OutlineButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFA8D8EA), width: 1),
        ),
        child: const Text(
          'View Jobs',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFFA8D8EA),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _MessageButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFA8D8EA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/message-icon.svg',
              width: 15,
              height: 15,
              colorFilter: const ColorFilter.mode(
                Color(0xFF0F172A),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Message',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
