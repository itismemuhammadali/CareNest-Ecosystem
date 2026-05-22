import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DocumentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String uploadDate;
  final bool isVerified;
  /// When set, the download row opens the signed document URL.
  final VoidCallback? onDownload;

  const DocumentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.uploadDate,
    this.isVerified = false,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33A8D8EA), width: 1.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doc icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0x1AA8D8EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/document-icon.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFA8D8EA),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0x99A8D8EA),
                      ),
                    ),
                  ],
                ),
              ),

              // Status icon
              if (isVerified)
                SvgPicture.asset(
                  'assets/tick-icon.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFB5FFD9),
                    BlendMode.srcIn,
                  ),
                )
              else
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 22,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Upload date + Download
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uploaded: $uploadDate',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              if (onDownload != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDownload,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/download_icon.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFA8D8EA),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Download',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFA8D8EA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 10),

          // Verified badge
          if (isVerified)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x33B5FFD9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Verified',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFA8D8EA),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
