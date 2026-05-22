import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JobCard extends StatelessWidget {
  final String title;
  final String family;
  final String date;
  final String time;
  final String? location;
  final String? wage;
  final String? status;
  final bool isAwaitingResponse;

  const JobCard({
    super.key,
    required this.title,
    required this.family,
    required this.date,
    required this.time,
    this.location,
    this.wage,
    this.status,
    this.isAwaitingResponse = false,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (status != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x33A8D8EA),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFA8D8EA)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(family,
              style: const TextStyle(fontSize: 13, color: Color(0xFFA8D8EA))),
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xB3A8D8EA), Color(0xB3A8D8EA)],
            ).createShader(bounds),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/calender-icon.svg',
                  width: 14,
                  height: 14,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(width: 4),
                Text(date,
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time_outlined,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(time,
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
          if (location != null || wage != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (location != null)
                  Row(
                    children: [
                      isAwaitingResponse
                          ? SvgPicture.asset(
                              'assets/hire-icon.svg',
                              width: 14,
                              height: 14,
                              colorFilter: const ColorFilter.mode(
                                Color(0x99A8D8EA),
                                BlendMode.srcIn,
                              ),
                            )
                          : const Icon(
                              Icons.location_on_outlined,
                              color: Color(0x99A8D8EA),
                              size: 14,
                            ),
                      const SizedBox(width: 4),
                      Text(location!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0x99A8D8EA))),
                    ],
                  ),
                if (wage != null)
                  Text(
                    wage!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB5FFD9),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
