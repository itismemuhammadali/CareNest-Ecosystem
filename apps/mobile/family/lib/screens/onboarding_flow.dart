import 'package:flutter/material.dart';
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
  //1
  OnboardingData(
    imagePath: 'assets/onboarding_1.jpg',
    title: 'Safe Hiring',
    description:
        'All teen babysitters are verified and Certified checks and admin approval for your peace of mind.',
  ),
  //2
  OnboardingData(
    imagePath: 'assets/onboarding-2.jpg',
    title: 'Structured Workflow',
    description:
        'Post jobs, review applications, message candidates, and hire with confidence - all in one place.',
  ),
  //3
  OnboardingData(
    imagePath: 'assets/onboarding-3.jpg',
    title: 'Time Tracking & Wage Transparency',
    description:
        'Automated clock-in/out system with transparent, age-based wage calculation. No surprises.',
  ),
  //4
  OnboardingData(
    imagePath: 'assets/onboarding-4.jpg',
    title: 'Premium Membership',
    description:
        'Get access to top-rated verified candidates, priority visibility, and advanced filtering options.',
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    'assets/whiteLogo1.png',
                    height: 230,
                    width: 230,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    onboardingPages[_currentPage].title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    onboardingPages[_currentPage].description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
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
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const SignInScreen(),
                        ),
                      ),
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
