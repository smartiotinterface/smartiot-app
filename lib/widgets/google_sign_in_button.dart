// lib/widgets/google_sign_in_button.dart
// v5.0.0 — Google Sign-In button with loading state
// Uses Consumer<AuthService> to auto-disable during loading

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (_, auth, __) {
        final loading = auth.isGoogleLoading;
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: (auth.isLoading) ? null : onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: loading
                  ? AppTheme.accent.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.04),
              side: BorderSide(
                color: loading
                    ? AppTheme.accent.withValues(alpha: 0.5)
                    : AppTheme.accent.withValues(alpha: 0.22),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF38BDF8),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google "G" logo drawn as SVG-equivalent with text
                      _GoogleGLogo(),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context).sign_in_google,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r  = size.width / 2;

    // Draw circle background (white)
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Draw "G" using colored arc segments
    const strokeW = 3.0;

    // Red (top-right)
    _drawArc(canvas, cx, cy, r - 2, -60, 90,
        const Color(0xFFEA4335), strokeW);
    // Yellow (bottom-right)
    _drawArc(canvas, cx, cy, r - 2, 30, 90,
        const Color(0xFFFBBC05), strokeW);
    // Green (bottom-left)
    _drawArc(canvas, cx, cy, r - 2, 120, 90,
        const Color(0xFF34A853), strokeW);
    // Blue (left + bar)
    _drawArc(canvas, cx, cy, r - 2, 210, 90,
        const Color(0xFF4285F4), strokeW);

    // Horizontal bar of "G"
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r - 3, cy),
      barPaint,
    );
  }

  void _drawArc(Canvas canvas, double cx, double cy, double r,
      double startDeg, double sweepDeg, Color color, double strokeW) {
    const toRad = 3.14159265358979 / 180;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startDeg * toRad,
      sweepDeg * toRad,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter _) => false;
}
