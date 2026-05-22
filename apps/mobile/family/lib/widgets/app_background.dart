import 'package:flutter/material.dart';

/// Reusable background widget with image and gradient overlay
class AppBackground extends StatelessWidget {
  final Widget child;
  final String backgroundImage;

  const AppBackground({
    super.key,
    required this.child,
    this.backgroundImage = 'assets/screen-bg.jpg',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundImage),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Dark gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xB30F172A),
                Color(0xFF0F172A),
              ],
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}
