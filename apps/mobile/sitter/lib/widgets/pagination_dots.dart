import 'package:flutter/material.dart';

class PaginationDots extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Color activeDotColor;
  final Color inactiveDotColor;

  const PaginationDots({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.activeDotColor = const Color(0xFFC8F0FF),
    this.inactiveDotColor = const Color(0xFF757575),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == currentPage ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == currentPage ? activeDotColor : inactiveDotColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
