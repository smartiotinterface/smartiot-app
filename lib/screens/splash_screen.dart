// lib/screens/splash_screen.dart
// PREMIUM v4 — Cinematic 5-phase intro: particle burst → logo → shimmer text
// → progress → fade out. Perfectly sized logo with glow ring.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Phase 1 — Background deep glow
  late AnimationController _bgCtrl;
  late Animation<double> _bgFade;

  // Phase 2 — Logo burst in
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  // Phase 3 — Glow ring pulse (repeating)
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  // Phase 4 — Particles
  late AnimationController _particleCtrl;

  // Phase 5 — Text shimmer
  late AnimationController _textCtrl;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late AnimationController _shimmerCtrl;

  // Phase 6 — Progress bar
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  // Phase 7 — Exit wipe
  late AnimationController _exitCtrl;
  late Animation<double> _exitScale;
  late Animation<double> _exitFade;

  // Ambient floating orbs
  late AnimationController _orbCtrl;

  static const _logoW = 280.0;
  static const _logoH = 100.0;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn);

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();

    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut);

    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _exitScale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn),
    );

    _orbCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat();

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Phase 1: BG fade in
    await _bgCtrl.forward();

    // Phase 2: Logo burst
    _particleCtrl.forward();
    await _logoCtrl.forward();

    // Phase 3: Text slides up (slight delay after logo)
    await Future.delayed(const Duration(milliseconds: 100));
    await _textCtrl.forward();

    // Phase 4: Progress bar fills
    await Future.delayed(const Duration(milliseconds: 100));
    _barCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));

    // Phase 5: Exit
    await _exitCtrl.forward();
    _navigate();
  }

  // [FIX BUG-17] Made async so signOut() is awaited before navigation
  Future<void> _navigate() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;

    Widget next;
    if (user == null) {
      // Not logged in
      next = const LoginScreen();
    } else {
      // [v5.0.0] Google/social provider accounts are always verified on the
      // provider side — skip the email verification gate for them.
      final isSocialProvider = user.providerData.any((p) =>
          p.providerId == 'google.com' ||
          p.providerId == 'apple.com' ||
          p.providerId == 'facebook.com');

      if (!user.emailVerified && !isSocialProvider) {
        // Email/password login with unverified email — sign out and gate
        await FirebaseAuth.instance.signOut(); // [FIX] was unawaited
        next = const LoginScreen(showVerifyBanner: true);
      } else {
        next = const DashboardScreen();
      }
    }
    if (!mounted) return; // re-check after async gap
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _particleCtrl.dispose();
    _textCtrl.dispose();
    _shimmerCtrl.dispose();
    _barCtrl.dispose();
    _exitCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020B18),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgFade, _logoCtrl, _glowAnim, _particleCtrl,
          _textFade, _shimmerCtrl, _barAnim, _exitCtrl, _orbCtrl,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitFade.value,
            child: Transform.scale(
              scale: _exitScale.value,
              child: Stack(
                children: [
                  // ── Deep background ─────────────────────
                  Opacity(
                    opacity: _bgFade.value,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.2),
                          radius: 1.2,
                          colors: [
                            Color(0xFF081A38),
                            Color(0xFF041225),
                            Color(0xFF020B18),
                          ],
                          stops: [0, 0.5, 1],
                        ),
                      ),
                    ),
                  ),

                  // ── Floating ambient orbs ───────────────
                  _buildOrbs(size),

                  // ── Particle burst ──────────────────────
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ParticlePainter(
                        progress: _particleCtrl.value,
                        center: Offset(size.width / 2, size.height / 2 - 60),
                      ),
                    ),
                  ),

                  // ── Main content ────────────────────────
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glow halo + logo
                        _buildLogoSection(),

                        const SizedBox(height: 28),

                        // App name + tagline
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textFade,
                            child: _buildTextSection(),
                          ),
                        ),

                        const SizedBox(height: 52),

                        // Progress bar
                        FadeTransition(
                          opacity: _textFade,
                          child: _buildProgressBar(),
                        ),
                      ],
                    ),
                  ),

                  // ── Grid overlay ────────────────────────
                  Positioned.fill(
                    child: Opacity(
                      opacity: _bgFade.value * 0.6,
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 320,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(
                    alpha: 0.10 + _glowAnim.value * 0.18),
                blurRadius: 70 + _glowAnim.value * 40,
                spreadRadius: -10,
              ),
              BoxShadow(
                color: AppTheme.accentCyan.withValues(
                    alpha: 0.06 + _glowAnim.value * 0.10),
                blurRadius: 120,
                spreadRadius: -20,
              ),
            ],
          ),
        ),

        // Inner glass frame
        Opacity(
          opacity: _logoFade.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Container(
              width: 310,
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFF020B18).withValues(alpha: 0.3),
                // [FIX LOGO] dark bg match — logo transparent PNG blends perfectly,
                border: Border.all(
                  color: AppTheme.accent.withValues(
                      alpha: 0.12 + _glowAnim.value * 0.10),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Image.asset(
                'assets/images/smart_iot_logo.png',
                width: _logoW,
                height: _logoH,
                fit: BoxFit.contain,
                // [FIX C-2] Graceful fallback if PNG missing — prevents release crash
                errorBuilder: (ctx, error, stack) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop_rounded,
                        size: 56, color: Color(0xFF38BDF8)),
                    SizedBox(height: 10),
                    Text(
                      AppConstants.brandName,
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Corner accent dots
        Opacity(
          opacity: _logoFade.value,
          child: SizedBox(
            width: 310,
            height: 210,
            child: Stack(
              children: [
                Positioned(top: 10, left: 10, child: _CornerDot(glow: _glowAnim.value)),
                Positioned(top: 10, right: 10, child: _CornerDot(glow: _glowAnim.value)),
                Positioned(bottom: 10, left: 10, child: _CornerDot(glow: _glowAnim.value)),
                Positioned(bottom: 10, right: 10, child: _CornerDot(glow: _glowAnim.value)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextSection() {
    return Column(
      children: [
        // App name with shimmer
        ShaderMask(
          shaderCallback: (bounds) {
            final shimmerPos = _shimmerCtrl.value;
            return LinearGradient(
              colors: const [
                Color(0xFF7DD3FC),
                Color(0xFFBAE6FD),
                Color(0xFF38BDF8),
                Color(0xFF7DD3FC),
              ],
              stops: [
                (shimmerPos - 0.4).clamp(0.0, 1.0),
                shimmerPos.clamp(0.0, 1.0),
                (shimmerPos + 0.1).clamp(0.0, 1.0),
                (shimmerPos + 0.4).clamp(0.0, 1.0),
              ],

            ).createShader(bounds);
          },
          child: const Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              height: 1.3,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Divider line
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppTheme.accent.withValues(alpha: 0.5)],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                color: AppTheme.accent.withValues(alpha: 0.07),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withValues(
                          alpha: 0.6 + _glowAnim.value * 0.4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    AppConstants.brandName,
                    style: TextStyle(
                      color: Color(0xFF7DD3FC),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accent.withValues(alpha: 0.5), Colors.transparent],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          AppLocalizations.of(context).made_with_love,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.28),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          // Segmented progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  // Background track
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  // Animated fill with gradient
                  FractionallySizedBox(
                    widthFactor: _barAnim.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1D4ED8),
                            AppTheme.accent,
                            Color.lerp(AppTheme.accent, AppTheme.accentCyan, _barAnim.value)!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Shimmer spark at head
                  if (_barAnim.value > 0 && _barAnim.value < 1)
                    Positioned(
                      left: 220 * _barAnim.value - 8,
                      child: Container(
                        width: 16,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.transparent, Colors.white, Colors.transparent],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).initializing,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${(_barAnim.value * 100).toInt()}%',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrbs(Size size) {
    final t = _orbCtrl.value;
    return Stack(
      children: [
        Positioned(
          left: size.width * 0.05 + 40 * math.sin(t * 2 * math.pi),
          top: size.height * 0.1 + 30 * math.cos(t * 2 * math.pi),
          child: _GlowOrb(size: 240, color: AppTheme.primaryBlue, opacity: _bgFade.value * 0.18),
        ),
        Positioned(
          right: size.width * 0.05 + 30 * math.cos(t * 2 * math.pi + 2),
          bottom: size.height * 0.12 + 40 * math.sin(t * 2 * math.pi + 2),
          child: _GlowOrb(size: 200, color: const Color(0xFF0891B2), opacity: _bgFade.value * 0.14),
        ),
        Positioned(
          left: size.width * 0.4 + 20 * math.sin(t * 2 * math.pi + 4),
          bottom: size.height * 0.05 + 25 * math.cos(t * 2 * math.pi + 4),
          child: _GlowOrb(size: 160, color: AppTheme.accent, opacity: _bgFade.value * 0.10),
        ),
      ],
    );
  }
}

// ── Glowing orb ──────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final double size, opacity;
  final Color color;
  const _GlowOrb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.5), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ── Corner accent dot ────────────────────────────────────────
class _CornerDot extends StatelessWidget {
  final double glow;
  const _CornerDot({required this.glow});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.accent.withValues(alpha: 0.5 + glow * 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.4 + glow * 0.4),
            blurRadius: 8 + glow * 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ── Particle burst painter ────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Offset center;
  static final _rng = math.Random(42);
  static final _particles = List.generate(28, (i) {
    final angle = (i / 28) * 2 * math.pi + _rng.nextDouble() * 0.4;
    final speed = 80.0 + _rng.nextDouble() * 120;
    final size   = 2.0 + _rng.nextDouble() * 3;
    return (angle: angle, speed: speed, size: size);
  });

  _ParticlePainter({required this.progress, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress > 0.9) return;
    final eased = Curves.easeOut.transform(progress);
    final fade  = progress < 0.5 ? progress * 2 : (1 - progress) * 2;

    for (final p in _particles) {
      final dist = p.speed * eased;
      final dx = center.dx + math.cos(p.angle) * dist;
      final dy = center.dy + math.sin(p.angle) * dist;

      final paint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: (fade * 0.7).clamp(0, 1))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.size * (1 - eased * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── Grid overlay painter ─────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
