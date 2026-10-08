import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_screens.dart';
import 'logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.85, end: 1)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // TODO: ganti dengan cek token login (auto-login) bila API sudah ada.
    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SceneryPainter())),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      children: [
                        const TLLogo(size: 100),
                        const SizedBox(height: 22),
                        const BrandName(fontSize: 30),
                        const SizedBox(height: 10),
                        const Text(
                          'CARI LOMBA? GAS!',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 7),
                const Text(
                  'PUSAT INFO LOMBA & PRESTASI MALUKU UTARA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tulisan "Ternate" (navy) + "Lomba" (biru).
class BrandName extends StatelessWidget {
  final double fontSize;
  const BrandName({super.key, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
            fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        children: const [
          TextSpan(text: 'Ternate', style: TextStyle(color: AppColors.navy)),
          TextSpan(text: 'Lomba', style: TextStyle(color: AppColors.primary)),
        ],
      ),
    );
  }
}

/// Latar: langit, awan, burung, gunung, laut berlapis, pohon kelapa.
class _SceneryPainter extends CustomPainter {
  Path _wave(Size s, double y, double amp, double phase) {
    final p = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, y);
    for (double x = 0; x <= s.width; x += 4) {
      p.lineTo(x, y + amp * sin(x / s.width * 2 * pi * 1.4 + phase));
    }
    return p
      ..lineTo(s.width, s.height)
      ..close();
  }

  void _bird(Canvas c, Offset o, double w) {
    c.drawPath(
      Path()
        ..moveTo(o.dx - w, o.dy)
        ..quadraticBezierTo(o.dx - w / 2, o.dy - w / 1.5, o.dx, o.dy)
        ..quadraticBezierTo(o.dx + w / 2, o.dy - w / 1.5, o.dx + w, o.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3B82C4),
    );
  }

  void _palm(Canvas c, Offset base, double h, double lean) {
    final top = Offset(base.dx + lean * h, base.dy - h);
    c.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx + lean * h * 0.1, base.dy - h * 0.6, top.dx, top.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.05
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2A5B73),
    );
    final frond = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.035
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1F7A8C);
    for (final a in [-3.0, -2.4, -1.57, -0.75, -0.15]) {
      final ctrl = top + Offset(cos(a) * h * 0.3, sin(a) * h * 0.3 - h * 0.12);
      final end = top + Offset(cos(a) * h * 0.52, sin(a) * h * 0.52 + h * 0.1);
      c.drawPath(Path()..moveTo(top.dx, top.dy)..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy), frond);
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;

    // langit
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3F1FB), Color(0xFFF8FCFF), Color(0xFFDDF2FE)],
          stops: [0, 0.45, 1],
        ).createShader(Offset.zero & s),
    );

    // awan lembut
    final cloud = Paint()
      ..color = Colors.white.withAlpha(200)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .2, h * .1), width: w * .6, height: h * .07), cloud);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .8, h * .16), width: w * .55, height: h * .06), cloud);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * .5, h * .06), width: w * .8, height: h * .04),
        Paint()
          ..color = const Color(0xFFBFE3FA).withAlpha(120)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));

    // burung
    _bird(canvas, Offset(w * .15, h * .085), 6);
    _bird(canvas, Offset(w * .26, h * .06), 5);
    _bird(canvas, Offset(w * .82, h * .07), 6);
    _bird(canvas, Offset(w * .7, h * .12), 4);

    // gunung (Gamalama) samar
    canvas.drawPath(
      Path()
        ..moveTo(w * .14, h * .84)
        ..lineTo(w * .5, h * .62)
        ..lineTo(w * .86, h * .84)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFB8DAF8).withAlpha(210), const Color(0xFFDDF2FE).withAlpha(0)],
        ).createShader(Rect.fromLTWH(w * .14, h * .62, w * .72, h * .22)),
    );

    // laut berlapis
    canvas.drawPath(_wave(s, h * .80, 5, 0), Paint()..color = const Color(0xFFA9E2FB));
    canvas.drawPath(_wave(s, h * .85, 6, 1.5), Paint()..color = const Color(0xFF5CBDEE));
    canvas.drawPath(_wave(s, h * .90, 6, 3), Paint()..color = AppColors.seaDeep);
    canvas.drawPath(_wave(s, h * .955, 4, 4.5), Paint()..color = const Color(0xFF1B78C2));

    // pohon kelapa & batu
    _palm(canvas, Offset(w * .1, h * .905), h * .17, .12);
    _palm(canvas, Offset(w * .92, h * .9), h * .12, -.14);
    final rock = Paint()..color = const Color(0xFF2B3A4A);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .1, h * .915), width: w * .22, height: h * .03), rock);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .93, h * .91), width: w * .16, height: h * .025), rock);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
