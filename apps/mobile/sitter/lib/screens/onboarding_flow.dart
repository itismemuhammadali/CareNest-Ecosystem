import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/pagination_dots.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import 'sign_in_screen.dart';

class OnboardingData {
  final String imagePath;
  final String title;
  final String description;
  final Alignment imageAlignment;

  const OnboardingData({
    required this.imagePath,
    required this.title,
    required this.description,
    this.imageAlignment = Alignment.center,
  });
}

const List<OnboardingData> onboardingPages = [
  OnboardingData(
    imagePath: 'assets/onboarding-1.jpg',
    title: 'Verified & Safe Platform',
    description:
        'All families undergo background checks. Admin oversight ensures a safe environment for teenage babysitters.',
  ),
  OnboardingData(
    imagePath: 'assets/onboarding-2.jpg',
    title: 'Training & Certification',
    description:
        'Complete required certifications before applying to jobs. Build your skills and credibility.',
  ),
  OnboardingData(
    imagePath: 'assets/onboarding-3.jpg',
    title: 'Apply & Get Hired',
    description:
        'Browse verified job listings, apply to opportunities that fit your schedule, and communicate securely with families.',
  ),
  OnboardingData(
    imagePath: 'assets/onboarding-4.jpg',
    title: 'Track Time & Earn Transparently',
    description:
        'Use our clock-in/out system for accurate time tracking. Wages are automatically calculated based on your hours.',
  ),
];

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goToNext() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFirst = _currentPage == 0;
    final bool isLast = _currentPage == onboardingPages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // Sliding background images
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: onboardingPages.length,
            itemBuilder: (context, index) {
              final page = onboardingPages[index];
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(page.imagePath),
                    fit: BoxFit.cover,
                    alignment: page.imageAlignment,
                  ),
                ),
              );
            },
          ),
          // Gradient overlay
          Container(
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
          // Content overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  // Logo — 10px above the title
                  Image.asset(
                    'assets/logowhite.png',
                    height: 230,
                    width: 230,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    onboardingPages[_currentPage].title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      onboardingPages[_currentPage].description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  PaginationDots(
                    currentPage: _currentPage,
                    totalPages: onboardingPages.length,
                  ),
                  const SizedBox(height: 32),
                  if (isFirst)
                    PrimaryButton(
                      label: 'Next',
                      onPressed: _goToNext,
                    )
                  else if (isLast)
                    PrimaryButton(
                      label: 'Get Started',
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_seen', true);
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  const SignInScreen(),
                              transitionsBuilder:
                                  (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        }
                      },
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'Back',
                            onPressed: _goToBack,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Next',
                            onPressed: _goToNext,
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
