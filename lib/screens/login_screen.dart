// lib/screens/login_screen.dart
// SmartIoT v1.0.2 — Phone Number Authentication added
// ✅ Email/Password sign-in + registration
// ✅ Google Sign-In (one-tap)
// ✅ Phone Number OTP sign-in
// ✅ All UI strings use l10n (no hardcoded strings)
// ✅ Premium glassmorphism + water animation

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../core/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import '../widgets/google_sign_in_button.dart';
import '../services/country_code_service.dart';

// ── Auth mode enum ─────────────────────────────────────────
enum _AuthMode { email, phoneNumber, phoneOtp }

class LoginScreen extends StatefulWidget {
  final bool showVerifyBanner;
  const LoginScreen({super.key, this.showVerifyBanner = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Email controllers ──────────────────────────────────
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _nameCtrl   = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  // ── Phone controllers ──────────────────────────────────
  final _phoneCtrl  = TextEditingController();
  final _otpCtrl    = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey   = GlobalKey<FormState>();
  String _sentToPhone = '';
  String _dialCode = '+880';         // auto-detected dial prefix

  // ── State ─────────────────────────────────────────────
  _AuthMode _authMode    = _AuthMode.email;
  bool _isLogin          = true;
  bool _obscurePass      = true;
  bool _rememberMe       = false;

  // ── Animation controllers ──────────────────────────────
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _cardSlide;
  late AnimationController _bgCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000))
      ..repeat();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _entryCtrl.forward();
    _loadRememberedEmail();
    _detectCountryCode();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefRememberEmail);
    if (saved != null && mounted) {
      setState(() {
        _emailCtrl.text = saved;
        _rememberMe = true;
      });
    }
  }

  // ── Auto-detect SIM/network country code ──────────────────────────────
  Future<void> _detectCountryCode() async {
    try {
      final code = await CountryCodeService.getDialCode();
      if (!mounted) return;
      setState(() {
        _dialCode = code;
        // If phone field is empty, pre-fill the country prefix
        if (_phoneCtrl.text.isEmpty) {
          _phoneCtrl.text = code;
          // Move cursor to end
          _phoneCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _phoneCtrl.text.length),
          );
        }
      });
    } catch (_) {
      // Silently fall back to +880
      if (mounted) setState(() { _dialCode = '+880'; });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _entryCtrl.dispose();
    _bgCtrl.dispose();
    _waveCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Navigate to Dashboard ──────────────────────────────
  void _navigateToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (_) => false,
    );
  }

  // ── Email submit ───────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    auth.clearError();

    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text;

    bool ok;
    if (_isLogin) {
      ok = await auth.login(email, pass);
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setString(AppConstants.prefRememberEmail, email);
        } else {
          await prefs.remove(AppConstants.prefRememberEmail);
        }
      }
    } else {
      ok = await auth.register(email, pass);
      if (ok && mounted) {
        if (_nameCtrl.text.trim().isNotEmpty) {
          try { await auth.currentUser?.updateDisplayName(_nameCtrl.text.trim()); } catch (_) {}
        }
        if (!mounted) return;
        AppUtils.showSnack(context, AppLocalizations.of(context).account_created);
        setState(() => _isLogin = true);
        _passCtrl.clear();
        return;
      }
    }

    if (ok && mounted) _navigateToDashboard();
  }

  // ── Forgot password ────────────────────────────────────
  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      AppUtils.showSnack(context, AppLocalizations.of(context).enter_email_first, isError: true);
      return;
    }
    final auth = context.read<AuthService>();
    final ok = await auth.sendPasswordReset(email);
    if (mounted) {
      AppUtils.showSnack(
        context,
        ok ? AppLocalizations.of(context).reset_email_sent
           : AppLocalizations.of(context).reset_email_failed,
        isError: !ok,
      );
    }
  }

  // ── Google sign-in ─────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthService>();
    auth.clearError();
    final ok = await auth.signInWithGoogle();
    if (!mounted) return;
    if (ok) {
      _navigateToDashboard();
    } else if (auth.errorMessage != null) {
      final l10n = AppLocalizations.of(context);
      AppUtils.showSnack(context, _resolveAuthError(auth.errorMessage!, l10n), isError: true);
    }
  }

  // ── Phone: send OTP ────────────────────────────────────
  Future<void> _sendOTP() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final l10n = AppLocalizations.of(context);
    auth.clearError();

    final phone = _phoneCtrl.text.trim();
    await auth.sendPhoneOTP(
      phone,
      dialCode: _dialCode,
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _sentToPhone = phone;
          _authMode = _AuthMode.phoneOtp;
        });
        _entryCtrl.forward(from: 0.5);
        AppUtils.showSnack(context, '${l10n.otp_sent}: $phone');
      },
      onError: (key) {
        if (!mounted) return;
        AppUtils.showSnack(context, _resolveAuthError(key, l10n), isError: true);
      },
    );
  }

  // ── Phone: verify OTP ──────────────────────────────────
  Future<void> _verifyOTP() async {
    if (!_otpFormKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final l10n = AppLocalizations.of(context);
    auth.clearError();

    final ok = await auth.verifyPhoneOTP(_otpCtrl.text.trim());
    if (!mounted) return;

    if (ok) {
      _navigateToDashboard();
    } else if (auth.errorMessage != null) {
      AppUtils.showSnack(context, _resolveAuthError(auth.errorMessage!, l10n), isError: true);
    }
  }

  // ── Switch auth mode ───────────────────────────────────
  void _switchToPhone() {
    setState(() { _authMode = _AuthMode.phoneNumber; });
    context.read<AuthService>().clearError();
    _entryCtrl.forward(from: 0.5);
  }

  void _switchToEmail() {
    setState(() {
      _authMode = _AuthMode.email;
      _otpCtrl.clear();
      _phoneCtrl.clear();
    });
    context.read<AuthService>().clearError();
    _entryCtrl.forward(from: 0.5);
  }

  void _backToPhoneNumber() {
    setState(() {
      _authMode = _AuthMode.phoneNumber;
      _otpCtrl.clear();
    });
    _entryCtrl.forward(from: 0.5);
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _passCtrl.clear();
    });
    context.read<AuthService>().clearError();
    _entryCtrl.forward(from: 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF020B18),
      body: Stack(
        children: [
          _OceanBackground(bgCtrl: _bgCtrl),
          _WaveDecoration(waveCtrl: _waveCtrl, screenHeight: size.height),

          // ── Email-not-verified banner ─────────────────
          if (widget.showVerifyBanner)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_outlined,
                          color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.verify_email_banner,
                          style: const TextStyle(color: Color(0xFFD97706), fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Main content ──────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: FadeTransition(
                  opacity: _entryFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BrandHeader(pulseCtrl: _pulseCtrl),
                        const SizedBox(height: 32),

                        // ── Content switches by auth mode ──
                        if (_authMode == _AuthMode.email) ...[
                          _PremiumFormCard(
                            isLogin: _isLogin,
                            emailCtrl: _emailCtrl,
                            passCtrl: _passCtrl,
                            nameCtrl: _nameCtrl,
                            formKey: _formKey,
                            obscurePass: _obscurePass,
                            rememberMe: _rememberMe,
                            onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
                            onToggleRemember: (v) => setState(() => _rememberMe = v ?? false),
                            onForgotPassword: _forgotPassword,
                            onSubmit: _submit,
                          ),
                          const SizedBox(height: 20),
                          _OrDivider(),
                          const SizedBox(height: 16),
                          GoogleSignInButton(onPressed: _signInWithGoogle),
                          const SizedBox(height: 12),
                          _PhoneSignInButton(onPressed: _switchToPhone),
                          const SizedBox(height: 20),
                          _ToggleRow(isLogin: _isLogin, onToggle: _toggleMode),
                        ],

                        if (_authMode == _AuthMode.phoneNumber) ...[
                          _PhoneInputCard(
                            phoneCtrl: _phoneCtrl,
                            formKey: _phoneFormKey,
                            onSendOTP: _sendOTP,
                            onBackToEmail: _switchToEmail,
                          ),
                        ],

                        if (_authMode == _AuthMode.phoneOtp) ...[
                          _OtpVerifyCard(
                            otpCtrl: _otpCtrl,
                            formKey: _otpFormKey,
                            sentToPhone: _sentToPhone,
                            onVerify: _verifyOTP,
                            onResend: _backToPhoneNumber,
                            onChangeNumber: _backToPhoneNumber,
                          ),
                        ],

                        const SizedBox(height: 24),
                        _Footer(),
                      ],
                    ),
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

// ── Top-level error resolver ───────────────────────────────
String _resolveAuthError(String key, AppLocalizations l10n) {
  switch (key) {
    case 'auth_err_no_account':      return l10n.auth_err_no_account;
    case 'auth_err_wrong_password':  return l10n.auth_err_wrong_password;
    case 'auth_err_invalid_email':   return l10n.auth_err_invalid_email;
    case 'auth_err_disabled':        return l10n.auth_err_disabled;
    case 'auth_err_email_in_use':    return l10n.auth_err_email_in_use;
    case 'auth_err_weak_password':   return l10n.auth_err_weak_password;
    case 'auth_err_not_allowed':     return l10n.auth_err_not_allowed;
    case 'auth_err_network':         return l10n.auth_err_network;
    case 'auth_err_too_many':        return l10n.auth_err_too_many;
    case 'auth_err_unexpected':      return l10n.auth_err_unexpected;
    case 'auth_err_google_failed':   return l10n.auth_err_google_failed;
    case 'auth_err_account_exists':  return l10n.auth_err_account_exists;
    case 'auth_err_invalid_phone':   return l10n.auth_err_invalid_phone;
    case 'auth_err_invalid_otp':     return l10n.auth_err_invalid_otp;
    case 'auth_err_otp_expired':     return l10n.auth_err_otp_expired;
    case 'auth_err_phone_failed':    return l10n.auth_err_phone_failed;
    case 'email_not_verified':       return l10n.email_not_verified_msg;
    default: return key.startsWith('auth_err') ? l10n.auth_err_generic : key;
  }
}

// ── Or Divider ─────────────────────────────────────────────
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.10))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            AppLocalizations.of(context).or_continue_with,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12,
                fontWeight: FontWeight.w500, letterSpacing: 0.5),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.10))),
      ],
    );
  }
}

// ── Phone Sign-In Button ───────────────────────────────────
class _PhoneSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _PhoneSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.phone_android_rounded, size: 20,
            color: AppTheme.accent),
        label: Text(
          l10n.phone_sign_in,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white.withValues(alpha: 0.03),
        ),
      ),
    );
  }
}

// ── Phone Input Card ───────────────────────────────────────
class _PhoneInputCard extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSendOTP;
  final VoidCallback onBackToEmail;

  const _PhoneInputCard({
    required this.phoneCtrl,
    required this.formKey,
    required this.onSendOTP,
    required this.onBackToEmail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_android_rounded,
                    color: AppTheme.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.phone_sign_in,
                      style: const TextStyle(color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  Text(l10n.phone_sign_in_subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: AppTheme.accent.withValues(alpha: 0.12)),
          const SizedBox(height: 20),

          Form(
            key: formKey,
            child: _LoginField(
              controller: phoneCtrl,
              label: l10n.phone_number,
              hint: l10n.phone_number_hint,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
              onFieldSubmitted: (_) => onSendOTP(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.phone_number_required;
                final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length < 10) return l10n.phone_number_invalid;
                return null;
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.phone_country_hint,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: auth.isPhoneLoading ? null : onSendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: auth.isPhoneLoading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(l10n.send_otp,
                      style: const TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              onPressed: onBackToEmail,
              icon: const Icon(Icons.email_outlined, size: 16, color: Colors.white54),
              label: Text(l10n.use_email_instead,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── OTP Verify Card ────────────────────────────────────────
class _OtpVerifyCard extends StatelessWidget {
  final TextEditingController otpCtrl;
  final GlobalKey<FormState> formKey;
  final String sentToPhone;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeNumber;

  const _OtpVerifyCard({
    required this.otpCtrl,
    required this.formKey,
    required this.sentToPhone,
    required this.onVerify,
    required this.onResend,
    required this.onChangeNumber,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sms_outlined, color: AppTheme.success, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.enter_otp_title,
                        style: const TextStyle(color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    Text('${l10n.otp_sent}: $sentToPhone',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: AppTheme.success.withValues(alpha: 0.12)),
          const SizedBox(height: 20),

          Text(l10n.enter_otp_subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
          const SizedBox(height: 14),

          Form(
            key: formKey,
            child: _LoginField(
              controller: otpCtrl,
              label: l10n.otp_code,
              hint: l10n.otp_hint,
              icon: Icons.lock_clock_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6)],
              onFieldSubmitted: (_) => onVerify(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.otp_required;
                if (v.trim().length < 6) return l10n.otp_invalid_length;
                return null;
              },
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: auth.isPhoneVerifyLoading ? null : onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: auth.isPhoneVerifyLoading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(l10n.verify_otp,
                      style: const TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onResend,
                child: Text(l10n.resend_otp,
                    style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
              ),
              Text('•', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
              TextButton(
                onPressed: onChangeNumber,
                child: Text(l10n.change_number,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Ocean animated background ──────────────────────────────
class _OceanBackground extends StatelessWidget {
  final AnimationController bgCtrl;
  const _OceanBackground({required this.bgCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bgCtrl,
      builder: (_, __) {
        final t = bgCtrl.value;
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF020B18), Color(0xFF041225),
                      Color(0xFF061830), Color(0xFF020B18)],
                  stops: [0, 0.3, 0.7, 1],
                ),
              ),
            ),
            Positioned(
              left: -80 + 60 * math.sin(t * 2 * math.pi),
              top: -80 + 50 * math.cos(t * 2 * math.pi),
              child: Container(
                width: 320, height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              right: -100 + 40 * math.cos(t * 2 * math.pi + 1),
              bottom: -100 + 60 * math.sin(t * 2 * math.pi + 1),
              child: Container(
                width: 380, height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFF7C3AED).withValues(alpha: 0.06),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Wave decoration ────────────────────────────────────────
class _WaveDecoration extends StatelessWidget {
  final AnimationController waveCtrl;
  final double screenHeight;
  const _WaveDecoration({required this.waveCtrl, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: waveCtrl,
      builder: (_, __) => Positioned(
        top: -screenHeight * 0.22,
        left: -40,
        right: -40,
        child: SizedBox(
          height: screenHeight * 0.4,
          child: CustomPaint(
            painter: _WavePainter(waveCtrl.value),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0EA5E9).withValues(alpha: 0.08),
          const Color(0xFF0EA5E9).withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.6 +
          math.sin((x / size.width * 2 * math.pi) + t * 2 * math.pi) * 20 +
          math.sin((x / size.width * 4 * math.pi) + t * 2 * math.pi * 1.5) * 10;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

// ── Brand Header ───────────────────────────────────────────
class _BrandHeader extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _BrandHeader({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: pulseCtrl,
          builder: (_, child) => Transform.scale(
            scale: 1.0 + 0.02 * pulseCtrl.value,
            child: child,
          ),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF7C3AED)],
              ),
              boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                  blurRadius: 20, spreadRadius: 2)],
            ),
            child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          AppConstants.appName,
          style: TextStyle(color: Colors.white, fontSize: 20,
              fontWeight: FontWeight.w800, letterSpacing: 0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          AppConstants.brandName,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

// ── Toggle Row ─────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;
  const _ToggleRow({required this.isLogin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? l10n.no_account : l10n.have_account,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
        ),
        TextButton(
          onPressed: onToggle,
          child: Text(
            isLogin ? l10n.register_now : l10n.sign_in_now,
            style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ── Footer ─────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (_, snap) {
        final version = snap.data?.version ?? '1.0.0';
        return Text(
          'v$version • ${AppConstants.brandName}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.2),
              fontSize: 11, letterSpacing: 0.5),
        );
      },
    );
  }
}

// ── Premium Form Card ──────────────────────────────────────
class _PremiumFormCard extends StatelessWidget {
  final bool isLogin;
  final TextEditingController emailCtrl, passCtrl, nameCtrl;
  final GlobalKey<FormState> formKey;
  final bool obscurePass, rememberMe;
  final VoidCallback onToggleObscure, onForgotPassword, onSubmit;
  final ValueChanged<bool?> onToggleRemember;

  const _PremiumFormCard({
    required this.isLogin,
    required this.emailCtrl,
    required this.passCtrl,
    required this.nameCtrl,
    required this.formKey,
    required this.obscurePass,
    required this.rememberMe,
    required this.onToggleObscure,
    required this.onToggleRemember,
    required this.onForgotPassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final auth  = context.watch<AuthService>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                  color: Colors.white, size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLogin ? l10n.welcome_back : l10n.create_account,
                    style: const TextStyle(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  Text(
                    isLogin ? l10n.sign_in_subtitle : l10n.join_subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),
          Container(height: 1, color: AppTheme.accent.withValues(alpha: 0.12)),
          const SizedBox(height: 22),

          Form(
            key: formKey,
            child: Column(
              children: [
                if (!isLogin) ...[
                  _LoginField(
                    controller: nameCtrl,
                    label: l10n.display_name,
                    hint: l10n.display_name_hint,
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                ],

                _LoginField(
                  controller: emailCtrl,
                  label: l10n.email_address,
                  hint: AppConstants.emailHintPlaceholder,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.email_required;
                    if (!RegExp(r'^[\w.+-]+@[\w-]+\.\w{2,}$').hasMatch(v.trim())) {
                      return l10n.email_invalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _LoginField(
                  controller: passCtrl,
                  label: l10n.password,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscureText: obscurePass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSubmit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white38, size: 19,
                    ),
                    onPressed: onToggleObscure,
                  ),
                  validator: (v) {
                    final key = AuthService.validatePassword(v, isLogin: isLogin);
                    if (key == null) return null;
                    switch (key) {
                      case 'pwd_required':    return l10n.pwd_required;
                      case 'pwd_min_8':       return l10n.pwd_min_8;
                      case 'pwd_need_upper':  return l10n.pwd_need_upper;
                      case 'pwd_need_number': return l10n.pwd_need_number;
                      default:                return key;
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (isLogin)
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  onChanged: onToggleRemember,
                  activeColor: AppTheme.accent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(l10n.remember_me,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: onForgotPassword,
                  child: Text(l10n.forgot_password,
                      style: const TextStyle(color: AppTheme.accent, fontSize: 13)),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Error message
          if (auth.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: Text(
                _resolveAuthError(auth.errorMessage!, AppLocalizations.of(context)),
                style: const TextStyle(color: AppTheme.danger, fontSize: 12),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: auth.isEmailLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF7C3AED)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: auth.isEmailLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          isLogin ? l10n.sign_in : l10n.create_account_btn,
                          style: const TextStyle(color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w700),
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

// ── Login Field ─────────────────────────────────────────────
class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppTheme.danger, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
