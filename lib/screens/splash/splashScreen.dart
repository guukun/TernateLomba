import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/appTheme.dart';
import '../auth/authScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAF2FF), Color(0xFFF8FAFF), Color(0xFFE5F2FF)],
            ),
          ),
          child: Stack(
            children: [
              // Ilustrasi laut dan gunung.
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: const CustomPaint(painter: SeaPainter()),
                ),
              ),

              // Logo dan slogan.
              Center(
                child: FadeTransition(
                  opacity: _animation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/logo/logo.png',
                            width: 130,
                            height: 130,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'CARI LOMBA? GAS!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Temukan peluang dan raih prestasimu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // Identitas aplikasi.
              Positioned(
                bottom: 25,
                left: 20,
                right: 20,
                child: Text(
                  'PUSAT INFO LOMBA & PRESTASI MALUKU UTARA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    fontSize: 9,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SeaPainter extends CustomPainter {
  const SeaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Siluet gunung.
    final mountainPath = Path()
      ..moveTo(0, height * 0.70)
      ..lineTo(width * 0.50, height * 0.20)
      ..lineTo(width, height * 0.70)
      ..close();

    canvas.drawPath(mountainPath, Paint()..color = const Color(0xFFC9DDF7));

    // Laut bagian atas.
    canvas.drawRect(
      Rect.fromLTWH(0, height * 0.65, width, height * 0.35),
      Paint()..color = const Color(0xFFB8E5F8),
    );

    // Laut bagian bawah.
    canvas.drawRect(
      Rect.fromLTWH(0, height * 0.80, width, height * 0.20),
      Paint()..color = const Color(0xFF83CFF0),
    );
  }

  @override
  bool shouldRepaint(covariant SeaPainter oldDelegate) => false;
}