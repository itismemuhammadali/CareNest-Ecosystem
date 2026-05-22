import 'package:flutter/material.dart';
import '../../utils/custom_page_route.dart';
import '../../screens/my_applications_screen.dart';

class BrowseHeader extends StatelessWidget {
  final int appliedCount;
  final int jobCount;

  const BrowseHeader({super.key, this.appliedCount = 0, this.jobCount = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Browse Jobs',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$jobCount Available Opportunities',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            CustomPageRoute(
              builder: (_) => const MyApplicationsScreen(),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFA8D8EA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Applied Job $appliedCount',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
