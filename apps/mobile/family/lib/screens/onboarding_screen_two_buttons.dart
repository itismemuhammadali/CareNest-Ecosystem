import 'package:flutter/material.dart';
import '../widgets/pagination_dots.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

class OnboardingScreenTwoButtons extends StatefulWidget {
  final String imagePath;
  final String title;
  final String description;
  final int currentPage;
  final int totalPages;
  final VoidCallback onNextPressed;
  final VoidCallback onBackPressed;
  final Alignment imageAlignment;

  const OnboardingScreenTwoButtons({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.currentPage,
    required this.totalPages,
    required this.onNextPressed,
    required this.onBackPressed,
    this.imageAlignment = Alignment.center,
  });

  @override
  State<OnboardingScreenTwoButtons> createState() => _OnboardingScreenTwoButtonsState();
}

class _OnboardingScreenTwoButtonsState extends State<OnboardingScreenTwoButtons> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.imagePath),
                fit: BoxFit.cover,
                alignment: widget.imageAlignment,
              ),
            ),
          ),
          // Gradient overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.3332, 1.0],
                colors: [
                  Color(0x000F172A),
                  Color(0xFF0F172A),
                ],
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Description
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Pagination dots
                  PaginationDots(
                    currentPage: widget.currentPage,
                    totalPages: widget.totalPages,
                  ),
                  const SizedBox(height: 32),
                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Back',
                          onPressed: widget.onBackPressed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Next',
                          onPressed: widget.onNextPressed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
