import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WithdrawalSuccessScreen extends StatefulWidget {
  final String amount;

  const WithdrawalSuccessScreen({super.key, required this.amount});

  @override
  State<WithdrawalSuccessScreen> createState() =>
      _WithdrawalSuccessScreenState();
}

class _WithdrawalSuccessScreenState extends State<WithdrawalSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Auto-close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB30F172A), Color(0xFF0F172A)],
              ),
            ),
          ),

          // Content centered
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated check icon
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0x1AB5FFD9),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0x4DB5FFD9), width: 1.5),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/tick-icon.svg',
                          width: 44,
                          height: 44,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFB5FFD9),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Withdrawal Requested!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Your withdrawal of \$${widget.amount} has been initiated.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0x99A8D8EA),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Funds will arrive in 1-3 business days.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
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
