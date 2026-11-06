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
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _pulseController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // ANIMASI UTAMA
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.78,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // ANIMASI DEKORASI
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _controller.forward();

    // NAVIGASI OTOMATIS
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
    _pulseController.dispose();
    super.dispose();
  }

  // =====================================================
  // LOGO APLIKASI
  // =====================================================

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1 + (_pulseController.value * 0.025);

        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 125,
        height: 125,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.creamLight,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.creamDark, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Image.asset('assets/logo/logo.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  // =====================================================
  // DEKORASI PIALA
  // =====================================================

  Widget _buildTrophyDecoration() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.cream,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cream.withValues(alpha: 0.15),
            blurRadius: 22,
          ),
        ],
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }

  // =====================================================
  // LOADING INDICATOR
  // =====================================================

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 110,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cream),
        ),
      ),
    );
  }

  // =====================================================
  // MAIN BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      body: SizedBox.expand(
        child: Stack(
          children: [
            // BACKGROUND DECORATION
            Positioned.fill(
              child: CustomPaint(painter: SplashBackgroundPainter()),
            ),

            // DEKORASI LINGKARAN KANAN ATAS
            Positioned(
              top: -95,
              right: -85,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cream.withValues(alpha: 0.08),
                    width: 30,
                  ),
                ),
              ),
            ),

            // DEKORASI KIRI BAWAH
            Positioned(
              bottom: 90,
              left: -100,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cream.withValues(alpha: 0.035),
                ),
              ),
            ),

            // KONTEN UTAMA
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // LOGO DAN PIALA
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                _buildLogo(),

                                Positioned(
                                  right: -17,
                                  bottom: -10,
                                  child: _buildTrophyDecoration(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 38),

                            // NAMA APLIKASI
                            const Text(
                              'TERNATELOMBA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 29,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // GARIS AKSEN
                            Container(
                              width: 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.cream,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // SLOGAN
                            const Text(
                              'CARI LOMBA? GAS!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.cream,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.5,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Text(
                              'Temukan peluang, kembangkan potensi,\ndan raih prestasi terbaikmu.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                height: 1.7,
                              ),
                            ),

                            const SizedBox(height: 45),

                            // LOADING
                            _buildLoadingIndicator(),

                            const SizedBox(height: 13),

                            Text(
                              'MEMPERSIAPKAN PENGALAMAN TERBAIK...',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // FOOTER
            Positioned(
              bottom: 25,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    width: 35,
                    height: 1,
                    color: AppColors.cream.withValues(alpha: 0.35),
                  ),

                  const SizedBox(height: 13),

                  const Text(
                    'PUSAT INFO LOMBA & PRESTASI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 9,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'MALUKU UTARA',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// CUSTOM BACKGROUND PAINTER
// =========================================================

class SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // GELOMBANG BAGIAN BAWAH
    final wavePaint = Paint()
      ..color = AppColors.primaryDark.withValues(alpha: 0.55);

    final wavePath = Path()
      ..moveTo(0, height * 0.78)
      ..cubicTo(
        width * 0.30,
        height * 0.68,
        width * 0.65,
        height * 0.91,
        width,
        height * 0.76,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(wavePath, wavePaint);

    // GELOMBANG KEDUA
    final secondWavePaint = Paint()
      ..color = AppColors.primaryDeep.withValues(alpha: 0.55);

    final secondWave = Path()
      ..moveTo(0, height * 0.88)
      ..cubicTo(
        width * 0.35,
        height * 0.78,
        width * 0.72,
        height * 0.98,
        width,
        height * 0.85,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    canvas.drawPath(secondWave, secondWavePaint);

    // AKSEN TITIK DEKORATIF
    final dotPaint = Paint()..color = AppColors.cream.withValues(alpha: 0.16);

    final dots = [
      Offset(width * 0.13, height * 0.18),
      Offset(width * 0.84, height * 0.28),
      Offset(width * 0.76, height * 0.53),
      Offset(width * 0.20, height * 0.65),
    ];

    for (final dot in dots) {
      canvas.drawCircle(dot, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SplashBackgroundPainter oldDelegate) {
    return false;
  }
}