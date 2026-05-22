import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Reusable bottom navigation bar widget
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int unreadMessageCount;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.unreadMessageCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-1, -1),
            end: Alignment(1, 1),
            colors: [
              Color(0xFF0F172B),
              Color(0xFF03060F),
              Color(0xFF0F172B),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: 'assets/home-icon.svg',
                label: 'Home',
                index: 0,
                isSelected: selectedIndex == 0,
                onTap: () => onItemTapped(0),
              ),
              _buildNavItem(
                context: context,
                icon: 'assets/hire-icon.svg',
                label: 'Hire',
                index: 1,
                isSelected: selectedIndex == 1,
                onTap: () => onItemTapped(1),
              ),
              _buildNavItem(
                context: context,
                icon: 'assets/message-icon.svg',
                label: 'Messages',
                index: 2,
                isSelected: selectedIndex == 2,
                onTap: () => onItemTapped(2),
              ),
              _buildNavItem(
                context: context,
                icon: 'assets/profile-icon.svg',
                label: 'Profile',
                index: 3,
                isSelected: selectedIndex == 3,
                onTap: () => onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String icon,
    required String label,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Widget iconWidget = SvgPicture.asset(
      icon,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        isSelected ? const Color(0xFFC8F0FF) : Colors.white,
        BlendMode.srcIn,
      ),
    );

    if (index == 2 && unreadMessageCount > 0) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          iconWidget,
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4757),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadMessageCount > 9 ? '9+' : '$unreadMessageCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFFC8F0FF) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
