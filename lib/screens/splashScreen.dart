import 'dart:async';
import 'package:flutter/material.dart';

import '../appTheme.dart';
import 'authScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _animation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    _timer = Timer(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AuthScreen(),
          ),
        );
      },
    );
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
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xffE3F1FB),
              Color(0xffF8FCFF),
              Color(0xffDDF2FE),
            ],
          ),
        ),
        child: Stack(
          children: [
// gambar laut dan gunung

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: CustomPaint(
                  painter: SeaPainter(),
                ),
              ),
            ),

// konten utama

            Center(
              child: FadeTransition(
                opacity: _animation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        width: 140,
                        height: 140,
                      ),
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    const Text(
                      "CARI LOMBA? GAS!",
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: Text(
                "PUSAT INFO LOMBA & PRESTASI MALUKU UTARA",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

// gunung

    canvas.drawPath(
      Path()
        ..moveTo(0, h * .7)
        ..lineTo(w * .5, h * .2)
        ..lineTo(w, h * .7)
        ..close(),
      Paint()..color = const Color(0xffB8DAF8),
    );

// laut 1

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        h * .65,
        w,
        h * .35,
      ),
      Paint()..color = const Color(0xffA9E2FB),
    );

// laut 2

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        h * .78,
        w,
        h * .22,
      ),
      Paint()..color = const Color(0xff5CBDEE),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
