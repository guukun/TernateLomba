import 'dart:math';
import 'package:flutter/material.dart';

/// Logo monogram "TL" (digambar dengan kode, tanpa file gambar).
class TLLogo extends StatelessWidget {
  final double size;
  final bool shadow;
  const TLLogo({super.key, this.size = 100, this.shadow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: const Color(0xFF1E6FE8).withAlpha(80),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.1),
                )
              ]
            : null,
      ),
      child: CustomPaint(painter: _TLPainter()),
    );
  }
}

class _TLPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    const box = Rect.fromLTWH(0, 0, 100, 100);
    final rrect = RRect.fromRectAndRadius(box, const Radius.circular(26));

    // latar gradasi biru
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2370E8), Color(0xFF0E4AB8)],
        ).createShader(box),
    );

    // cincin & segitiga (gunung) samar
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawCircle(
        const Offset(50, 54),
        38,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.white.withAlpha(45));
    canvas.drawPath(
      Path()
        ..moveTo(50, 22)
        ..lineTo(78, 76)
        ..lineTo(22, 76)
        ..close(),
      Paint()..color = Colors.white.withAlpha(22),
    );
    canvas.restore();

    // busur biru muda
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(48, 57), radius: 25),
      200 * pi / 180,
      -170 * pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF86D6FB),
    );

    final white = Paint()..color = const Color(0xFFF7FBFF);
    // huruf T (garis atas)
    canvas.drawRRect(
        RRect.fromLTRBR(22, 24, 78, 36, const Radius.circular(6)), white);
    // huruf L (batang + kaki + bendera kecil)
    canvas.drawRRect(
        RRect.fromLTRBR(46, 38, 59, 70, const Radius.circular(6)), white);
    canvas.drawRRect(
        RRect.fromLTRBR(46, 58, 74, 70, const Radius.circular(6)), white);
    canvas.drawRRect(
        RRect.fromLTRBR(38, 40, 52, 49, const Radius.circular(4.5)), white);

    // kilau bintang
    canvas.drawPath(
      Path()
        ..moveTo(50, 6)
        ..quadraticBezierTo(51, 11, 56, 12)
        ..quadraticBezierTo(51, 13, 50, 18)
        ..quadraticBezierTo(49, 13, 44, 12)
        ..quadraticBezierTo(49, 11, 50, 6),
      white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
