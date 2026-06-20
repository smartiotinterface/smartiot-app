// lib/widgets/tank_widget.dart
// SmartIoT v4.0.0 — Ultra-Realistic 3D Water Tank
// Features: Cylindrical 3D, metallic walls, rivets, inlet/outlet pipes,
// dual-wave water, caustic light, rising bubbles, gauge, % label with glow

import 'dart:math';
import 'package:flutter/material.dart';
import '../core/utils.dart';
import '../theme/app_theme.dart';

class TankWidget extends StatefulWidget {
  final int percent;
  final double width;
  final double height;
  final bool animate;
  final bool showLabel;

  const TankWidget({
    super.key,
    required this.percent,
    this.width = 160,
    this.height = 260,
    this.animate = true,
    this.showLabel = true,
  });

  @override
  State<TankWidget> createState() => _TankWidgetState();
}

class _TankWidgetState extends State<TankWidget> with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late AnimationController _fillCtrl;
  late AnimationController _bubbleCtrl;
  late AnimationController _causticCtrl;
  late Animation<double> _fillAnim;
  int _lastPercent = 0;

  @override
  void initState() {
    super.initState();
    _lastPercent = widget.percent;

    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();
    _fillCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _bubbleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))
      ..repeat();
    _causticCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _fillAnim = Tween<double>(
      begin: widget.percent / 100,
      end: widget.percent / 100,
    ).animate(CurvedAnimation(parent: _fillCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(TankWidget old) {
    super.didUpdateWidget(old);
    if (old.percent != widget.percent) {
      _fillAnim = Tween<double>(
        begin: _lastPercent / 100,
        end: widget.percent / 100,
      ).animate(CurvedAnimation(parent: _fillCtrl, curve: Curves.easeInOut));
      _fillCtrl.forward(from: 0);
      _lastPercent = widget.percent;
    }
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _fillCtrl.dispose();
    _bubbleCtrl.dispose();
    _causticCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterColor = AppUtils.waterLevelColor(widget.percent);
    return AnimatedBuilder(
      animation: Listenable.merge([_waveCtrl, _fillAnim, _bubbleCtrl, _causticCtrl]),
      builder: (context, _) => SizedBox(
        width: widget.width + 44,
        height: widget.height + 20,
        child: CustomPaint(
          painter: _Tank3DPainter(
            fillLevel: _fillAnim.value,
            wavePhase: _waveCtrl.value * 2 * pi,
            wavePhase2: _waveCtrl.value * 2 * pi * 1.37,
            bubblePhase: _bubbleCtrl.value,
            causticPhase: _causticCtrl.value,
            waterColor: waterColor,
            percent: widget.percent,
            showLabel: widget.showLabel,
          ),
        ),
      ),
    );
  }
}

class _Tank3DPainter extends CustomPainter {
  final double fillLevel;
  final double wavePhase;
  final double wavePhase2;
  final double bubblePhase;
  final double causticPhase;
  final Color waterColor;
  final int percent;
  final bool showLabel;

  const _Tank3DPainter({
    required this.fillLevel,
    required this.wavePhase,
    required this.wavePhase2,
    required this.bubblePhase,
    required this.causticPhase,
    required this.waterColor,
    required this.percent,
    required this.showLabel,
  });

  static const double _gaugeW  = 30.0;
  static const double _pipeW   = 10.0;
  static const double _wallT   = 9.0;
  static const double _capH    = 24.0;
  static const double _rivetR  = 2.8;
  static const double _flangeH = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final tW = size.width - _gaugeW - 10;
    final tH = size.height;
    final r = Rect.fromLTWH(0, 0, tW, tH);

    _drawShadow(canvas, r);
    _drawBody(canvas, r);
    _drawWater(canvas, r);
    _drawInnerRing(canvas, r);
    _drawTopCap(canvas, r);
    _drawBottomCap(canvas, r);
    _drawRivets(canvas, r);
    _drawPipes(canvas, r);
    _drawGauge(canvas, r, size);
    if (showLabel) _drawLabel(canvas, r);
  }

  void _drawShadow(Canvas canvas, Rect r) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r.center.dx + 5, r.bottom + 9),
        width: r.width * 0.82,
        height: 16,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  void _drawBody(Canvas canvas, Rect r) {
    final bodyRect = Rect.fromLTRB(r.left, r.top + _capH / 2, r.right, r.bottom - _capH / 2);
    canvas.drawRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
                    colors: [
            Color(0xFF1C2333), Color(0xFF2E3D52), Color(0xFF3A4F6A),
            Color(0xFF4A6481), Color(0xFF3A4F6A), Color(0xFF2E3D52), Color(0xFF1C2333),
          ],
          stops: [0.0, 0.12, 0.28, 0.5, 0.72, 0.88, 1.0],
        ).createShader(bodyRect),
    );
    // Primary specular highlight
    canvas.drawRect(
      Rect.fromLTWH(r.left + r.width * 0.17, bodyRect.top, r.width * 0.07, bodyRect.height),
      Paint()
        ..shader = LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.11), Colors.white.withValues(alpha: 0.0)],
        ).createShader(bodyRect),
    );
    // Secondary specular
    canvas.drawRect(
      Rect.fromLTWH(r.left + r.width * 0.71, bodyRect.top, r.width * 0.04, bodyRect.height),
      Paint()
        ..shader = LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.06), Colors.white.withValues(alpha: 0.0)],
        ).createShader(bodyRect),
    );
  }

  void _drawWater(Canvas canvas, Rect r) {
    if (fillLevel < 0.005) return;

    final iL = r.left + _wallT;
    final iR = r.right - _wallT;
    final iW = iR - iL;
    final iTop = r.top + _capH;
    final iBot = r.bottom - _capH;
    final iH = iBot - iTop;
    final waterTop = iBot - iH * fillLevel;
    final cf = _waveAmpFactor(fillLevel);
    final a1 = cf * 7.0;
    final a2 = cf * 4.0;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(iL, iTop, iR, iBot));

    // Water body
    canvas.drawPath(
      _buildWavePath(waterTop, iL, iR, iBot, a1, a2),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            waterColor.withValues(alpha: 0.78),
            waterColor,
            _darken(waterColor, 0.15),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTRB(iL, waterTop, iR, iBot)),
    );

    // Caustic ripples
    _drawCaustics(canvas, iL, iW, waterTop, iBot);

    // Wave shimmer
    canvas.drawPath(
      _buildWaveLinePath(waterTop, iL, iR, a1, a2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      _buildWaveLinePath(waterTop + 4, iL, iR, a2 * 0.7, a1 * 0.4),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Bubbles
    if (fillLevel > 0.06 && fillLevel < 0.96) {
      _drawBubbles(canvas, iL, iR, waterTop, iBot);
    }

    // Left wall reflection
    canvas.drawRect(
      Rect.fromLTWH(iL, waterTop + 5, 5, iBot - waterTop - 5),
      Paint()
        ..shader = LinearGradient(
                    colors: [Colors.white.withValues(alpha: 0.12), Colors.transparent],
        ).createShader(Rect.fromLTWH(iL, 0, 18, 1)),
    );

    canvas.restore();

    // Surface glow
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(r.left, r.top + _capH, r.right, r.bottom - _capH));
    canvas.drawRect(
      Rect.fromLTWH(r.left, waterTop - 10, r.width, 20),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, waterColor.withValues(alpha: 0.22), Colors.transparent],
        ).createShader(Rect.fromLTWH(r.left, waterTop - 10, r.width, 20)),
    );
    canvas.restore();
  }

  void _drawCaustics(Canvas canvas, double iL, double iW, double waterTop, double iBot) {
    final rng = Random(7);
    final p = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.8;
    for (int i = 0; i < 6; i++) {
      final bx = iL + rng.nextDouble() * iW;
      final by = waterTop + 8 + rng.nextDouble() * 22;
      final rx = (8 + rng.nextDouble() * 14) * (0.7 + causticPhase * 0.3);
      final ry = (3 + rng.nextDouble() * 5) * (0.7 + causticPhase * 0.3);
      final alpha = ((0.04 + causticPhase * 0.06) * (1 - i * 0.12)).clamp(0.0, 0.12);
      p.color = Colors.white.withValues(alpha: alpha);
      canvas.drawOval(Rect.fromCenter(center: Offset(bx, by), width: rx * 2, height: ry * 2), p);
    }
  }

  void _drawBubbles(Canvas canvas, double iL, double iR, double waterTop, double iBot) {
    final rng = Random(42);
    final iW = iR - iL;
    final waterH = iBot - waterTop;
    for (int i = 0; i < 7; i++) {
      final baseX = iL + 12 + rng.nextDouble() * (iW - 24);
      final speed = 0.25 + rng.nextDouble() * 0.65;
      final phase = rng.nextDouble();
      final maxR  = 2.2 + rng.nextDouble() * 2.8;
      final wobble = 5.0 + rng.nextDouble() * 5;
      final t = (bubblePhase * speed + phase) % 1.0;
      final y = iBot - t * waterH * 0.72;
      final x = baseX + sin(t * 2 * pi * 3 + i) * wobble;
      if (y < waterTop + 6) continue;
      final radius = maxR * (1 - t * 0.5);
      final alpha  = 0.18 * (1 - t * 0.8);
      canvas.drawCircle(Offset(x, y), radius,
          Paint()..color = Colors.white.withValues(alpha: alpha)..style = PaintingStyle.stroke..strokeWidth = 0.9);
      canvas.drawCircle(Offset(x - radius * 0.3, y - radius * 0.3), radius * 0.3,
          Paint()..color = Colors.white.withValues(alpha: alpha * 0.6));
    }
  }

  void _drawInnerRing(Canvas canvas, Rect r) {
    final oval = Rect.fromCenter(
      center: Offset(r.center.dx, r.top + _capH),
      width: r.width - _wallT * 2,
      height: _capH * 0.6,
    );
    canvas.drawOval(oval, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1320), Color(0xFF1C2A3A)],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 20)));
  }

  void _drawTopCap(Canvas canvas, Rect r) {
    final oval = Rect.fromCenter(
      center: Offset(r.center.dx, r.top + _capH / 2),
      width: r.width,
      height: _capH,
    );
    canvas.drawOval(oval, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.3),
        radius: 0.9,
        colors: [Color(0xFF5A7FA0), Color(0xFF2E4A66), Color(0xFF1C2E42), Color(0xFF0F1C2A)],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(oval));
    canvas.drawOval(oval.inflate(1),
        Paint()..color = const Color(0xFF3A5068)..style = PaintingStyle.stroke..strokeWidth = _flangeH);
    canvas.drawArc(oval.deflate(3), pi * 1.2, pi * 0.6, false,
        Paint()..color = Colors.white.withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);
  }

  void _drawBottomCap(Canvas canvas, Rect r) {
    final oval = Rect.fromCenter(
      center: Offset(r.center.dx, r.bottom - _capH / 2),
      width: r.width,
      height: _capH,
    );
    canvas.drawOval(oval, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF253545), Color(0xFF0F1C2A)],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 30)));
    canvas.drawOval(oval.inflate(1),
        Paint()..color = const Color(0xFF2A3A4C)..style = PaintingStyle.stroke..strokeWidth = _flangeH);
    canvas.drawArc(oval.deflate(3), 0, pi, false,
        Paint()..color = Colors.black.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  void _drawRivets(Canvas canvas, Rect r) {
    _placeRivets(canvas, r.center.dx, r.top + _capH / 2, r.width / 2 + 2, 12);
    _placeRivets(canvas, r.center.dx, r.bottom - _capH / 2, r.width / 2 + 2, 12);
  }

  void _placeRivets(Canvas canvas, double cx, double cy, double rx, int n) {
    for (int i = 0; i < n; i++) {
      final angle = (i / n) * 2 * pi - pi / 2;
      final ry = rx * 0.28;
      final x = cx + cos(angle) * rx;
      final y = cy + sin(angle) * ry;
      canvas.save();
      canvas.translate(x, y);
      canvas.drawCircle(Offset.zero, _rivetR, Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF8BA0B5), Color(0xFF3A5068)],
          stops: [0.3, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: _rivetR)));
      canvas.drawCircle(const Offset(-0.8, -0.8), _rivetR * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.5));
      canvas.restore();
    }
  }

  void _drawPipes(Canvas canvas, Rect r) {
    _drawPipe(canvas, r.right - 10, r.top + _capH * 1.6, isInlet: true);
    _drawPipe(canvas, r.left + 8,   r.bottom - _capH * 1.8, isInlet: false);
  }

  void _drawPipe(Canvas canvas, double x, double y, {required bool isInlet}) {
    const len = 20.0;
    final pRect = Rect.fromLTWH(isInlet ? x : x - len, y - _pipeW / 2, len, _pipeW);
    canvas.drawRect(pRect, Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4A6480), Color(0xFF1E3048), Color(0xFF0D1826), Color(0xFF1E3048)],
        stops: [0, 0.3, 0.7, 1],
      ).createShader(pRect));
    final flangeX = isInlet ? x + len - 1 : x - len;
    canvas.drawRect(Rect.fromLTWH(flangeX - 2, y - _pipeW / 2 - 3, 5, _pipeW + 6),
        Paint()..color = const Color(0xFF2E4A66));
    canvas.drawRect(Rect.fromLTWH(pRect.left, y - _pipeW / 2, pRect.width, 2),
        Paint()..color = Colors.white.withValues(alpha: 0.14));
    final tp = TextPainter(
      text: TextSpan(
        text: isInlet ? 'IN' : 'OUT',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(
      isInlet ? x + len / 2 - tp.width / 2 + 2 : x - len / 2 - tp.width / 2 - 2,
      y - tp.height / 2,
    ));
  }

  void _drawGauge(Canvas canvas, Rect tankR, Size size) {
    final gX = tankR.right + 8;
    final gTop = tankR.top + _capH;
    final gBot = tankR.bottom - _capH;
    final gH = gBot - gTop;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(gX, gTop, 10, gH), const Radius.circular(5)),
      Paint()..color = const Color(0xFF1A2535),
    );

    if (fillLevel > 0.01) {
      final fillH = gH * fillLevel;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(gX + 1, gBot - fillH + 1, 8, fillH - 2), const Radius.circular(4)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [waterColor, waterColor.withValues(alpha: 0.6)],
          ).createShader(Rect.fromLTWH(gX, gTop, 10, gH)),
      );
    }

    for (final t in const [0, 25, 50, 75, 100]) {
      final y = gBot - gH * (t / 100);
      canvas.drawLine(Offset(gX - 4, y), Offset(gX, y),
          Paint()..color = Colors.white.withValues(alpha: 0.35)..strokeWidth = 1);
      final tp = TextPainter(
        text: TextSpan(
          text: '$t',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.42), fontSize: 7.5, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(gX + 13, y - tp.height / 2));
    }

    final iY = gBot - gH * fillLevel;
    canvas.drawLine(Offset(gX - 6, iY), Offset(gX + 11, iY),
        Paint()..color = waterColor..strokeWidth = 2..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(gX + 5, iY), 4, Paint()..color = waterColor);
    canvas.drawCircle(Offset(gX + 5, iY), 2.2, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  void _drawLabel(Canvas canvas, Rect r) {
    final isLow = percent < 20;
    final textColor = isLow ? const Color(0xFFFF6B6B) : Colors.white;

    if (fillLevel > 0.2) {
      canvas.drawCircle(r.center, 32, Paint()
        ..color = waterColor.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    }

    final numTP = TextPainter(
      text: TextSpan(
        text: '$percent',
        style: TextStyle(
          color: textColor, fontSize: 36, fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.65), blurRadius: 8),
            if (isLow) const Shadow(color: Color(0x66FF6B6B), blurRadius: 20),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final symTP = TextPainter(
      text: TextSpan(
        text: '%',
        style: TextStyle(
          color: textColor.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final totalW = numTP.width + symTP.width + 2;
    final cx = r.center.dx - totalW / 2;
    final cy = r.center.dy - numTP.height / 2 + 2;
    numTP.paint(canvas, Offset(cx, cy));
    symTP.paint(canvas, Offset(cx + numTP.width + 2, cy + 10));

    if (percent >= 95 || percent <= 10) {
      final badge = percent >= 95 ? 'FULL' : 'LOW';
      const bColor = AppTheme.success;
      final badgeColor = percent >= 95 ? bColor : AppTheme.danger;
      final bTP = TextPainter(
        text: TextSpan(
          text: badge,
          style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900,
              letterSpacing: 1.5, shadows: [Shadow(color: badgeColor.withValues(alpha: 0.5), blurRadius: 8)]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      bTP.paint(canvas, Offset(r.center.dx - bTP.width / 2, cy + numTP.height + 4));
    }
  }

  // ── Wave helpers ───────────────────────────────────────────────
  Path _buildWavePath(double waterTop, double l, double r2, double bot, double a1, double a2) {
    final path = Path()
      ..moveTo(l, bot)
      ..lineTo(l, _wY(waterTop, 0, a1, a2));
    const segs = 10;
    final segW = (r2 - l) / segs;
    for (int i = 0; i < segs; i++) {
      final x1 = l + (i + 0.5) * segW;
      final x2 = l + (i + 1.0) * segW;
      final t1 = (x1 - l) / (r2 - l);
      final t2 = (x2 - l) / (r2 - l);
      path.quadraticBezierTo(x1, _wY(waterTop, t1, a1, a2), x2, _wY(waterTop, t2, a1, a2));
    }
    return path
      ..lineTo(r2, bot)
      ..close();
  }

  Path _buildWaveLinePath(double waterTop, double l, double r2, double a1, double a2) {
    const segs = 10;
    final segW = (r2 - l) / segs;
    final path = Path()..moveTo(l, _wY(waterTop, 0, a1, a2));
    for (int i = 0; i < segs; i++) {
      final x1 = l + (i + 0.5) * segW;
      final x2 = l + (i + 1.0) * segW;
      final t1 = (x1 - l) / (r2 - l);
      final t2 = (x2 - l) / (r2 - l);
      path.quadraticBezierTo(x1, _wY(waterTop, t1, a1, a2), x2, _wY(waterTop, t2, a1, a2));
    }
    return path;
  }

  double _wY(double base, double t, double a1, double a2) =>
      base + sin(t * 2 * pi * 2.5 + wavePhase) * a1 + cos(t * 2 * pi * 1.5 + wavePhase2) * a2;

  double _waveAmpFactor(double level) {
    if (level < 0.05) return level / 0.05;
    if (level > 0.94) return (1 - level) / 0.06;
    return 1.0;
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant _Tank3DPainter old) =>
      old.fillLevel != fillLevel ||
      old.wavePhase != wavePhase ||
      old.bubblePhase != bubblePhase ||
      old.causticPhase != causticPhase ||
      old.waterColor != waterColor ||
      old.percent != percent;
}
