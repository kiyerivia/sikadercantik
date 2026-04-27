import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  final double headerHeight;

  const AuthBackground({
    super.key,
    required this.child,
    this.headerHeight = 350,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blue Header with Topographic Pattern
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            height: headerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.secondaryBlue,
                  AppTheme.primaryBlue,
                ],
              ),
            ),
            child: CustomPaint(
              painter: TopographicPainter(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);

    var firstStart = Offset(size.width * 0.4, size.height - 100);
    var firstEnd = Offset(size.width * 0.7, size.height - 40);
    path.quadraticBezierTo(
      firstStart.dx,
      firstStart.dy,
      firstEnd.dx,
      firstEnd.dy,
    );

    var secondStart = Offset(size.width * 0.9, size.height + 10);
    var secondEnd = Offset(size.width, size.height - 60);
    path.quadraticBezierTo(
      secondStart.dx,
      secondStart.dy,
      secondEnd.dx,
      secondEnd.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class TopographicPainter extends CustomPainter {
  final Color color;

  TopographicPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final random = math.Random(42);

    for (int i = 0; i < 15; i++) {
      final path = Path();
      double x = -50;
      double y = i * 40.0;
      path.moveTo(x, y);

      while (x < size.width + 50) {
        x += 20 + random.nextDouble() * 30;
        double dy = (random.nextDouble() - 0.5) * 40;
        path.quadraticBezierTo(
          x - 10,
          y + dy * 1.5,
          x,
          y + dy,
        );
        y += dy * 0.5;
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
