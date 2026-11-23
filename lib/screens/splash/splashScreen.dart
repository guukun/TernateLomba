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
  late final Animation<double> _opacity;
  // TERNATELOMBA_SMOOTH_MOTION_V1
  late final Animation<double> _logoScale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _logoScale = Tween<double>(
      begin: 0.92,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2200), () {
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
    final p = context.tl;
    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -70,
            bottom: -90,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _opacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 148,
                          height: 148,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(42),
                            border: Border.all(color: p.fieldBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .05),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/Logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.emoji_events_rounded,
                              color: p.primary,
                              size: 72,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'LOCK IN. LEVEL UP.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w900,
                          color: p.grey,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Ternate Lomba',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 52,
                          height: .95,
                          letterSpacing: -2.2,
                          fontWeight: FontWeight.w900,
                          color: p.navy,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your next challenge starts here. Less scrolling. More doing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          height: 1.55,
                          color: p.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: p.primary,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'FOCUS · COMPETE · ACHIEVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: 110,
                        child: LinearProgressIndicator(
                          color: p.primary,
                          backgroundColor: p.fieldBorder,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
