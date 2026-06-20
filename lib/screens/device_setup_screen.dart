// lib/screens/device_setup_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v4.0.0 — Device Onboarding Screen
//
//  CHANGELOG v4.0.0:
//   ✅ Register tab REMOVED — BLE auto-registers the device
//   ✅ Single-flow corporate onboarding with animated pre-flight checklist
//   ✅ Animated hero header with rotating BLE beacon
//   ✅ Step-by-step visual flow (no tabs, no manual serial entry)
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'ble_provisioning_screen.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final Animation<double>   _fadeIn;
  late final Animation<Offset>   _slideUp;

  // Interactive pre-flight checklist
  final _ticked = [false, false, false, false];

  static const _checks = [
    (Icons.bluetooth_rounded,       'ds_check_bt',       'ds_check_bt_sub'),
    (Icons.power_settings_new_rounded,'ds_check_power',       'ds_check_power_sub'),
    (Icons.wifi_off_rounded,        'ds_check_nowifi',       'ds_check_nowifi_sub'),
    (Icons.location_on_rounded,     'ds_check_location',       'ds_check_location_sub'),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 680));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();

    _fadeIn  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  Future<void> _startBle() async {
    final isDark = context.read<ThemeNotifier>().isDark;
    final fb     = context.read<FirebaseService>();
    // [FIX-NAV] Provisioning screen returns serial string on success,
    // or null if the user presses back without completing.
    final serial = await Navigator.push<String>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: a,
          child: Provider.value(
            value: fb,
            child: BleProvisioningScreen(isDark: isDark),
          ),
        ),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    // [FIX-NAV] If provisioning & registration succeeded, go straight to
    // Dashboard instead of leaving the user on DeviceSetupScreen.
    if (serial != null && serial.isNotEmpty && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final bg     = isDark ? AppTheme.darkBg : const Color(0xFFEEF2FF);
    final card   = isDark ? AppTheme.darkCard : Colors.white;
    final txtClr = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted  = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark, txtClr),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 108, left: 20, right: 20, bottom: 36),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

              // ── Hero ────────────────────────────────────────────────
              _buildHero(isDark),
              const SizedBox(height: 26),

              // ── Flow ────────────────────────────────────────────────
              _sectionLabel(AppLocalizations.of(context).ds_how_it_works, isDark),
              const SizedBox(height: 10),
              _buildFlowCard(card, muted, isDark),
              const SizedBox(height: 24),

              // ── Checklist ───────────────────────────────────────────
              _sectionLabel(AppLocalizations.of(context).ds_before_start, isDark),
              const SizedBox(height: 10),
              _buildChecklist(card, txtClr, muted, isDark),
              const SizedBox(height: 28),

              // ── CTA ─────────────────────────────────────────────────
              _buildCta(),
              const SizedBox(height: 14),

              // ── Notes ───────────────────────────────────────────────
              _buildNote(Icons.lock_rounded, muted, AppLocalizations.of(context).ds_note_account),
              const SizedBox(height: 6),
              _buildNote(Icons.autorenew_rounded, AppTheme.success.withValues(alpha: 0.75),
                  AppLocalizations.of(context).ds_note_auto),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDark, Color txtClr) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCard.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.9),
          border: Border(bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder.withValues(alpha: 0.4) : const Color(0xFFCBD5E1),
          )),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: txtClr),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).add_new_device,
                      style: TextStyle(color: txtClr, fontWeight: FontWeight.w700, fontSize: 17)),
                  Text(AppLocalizations.of(context).ble_wifi_provisioning,
                      style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.8), fontSize: 11)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.25)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, size: 11, color: AppTheme.primaryLight),
                  SizedBox(width: 4),
                  Text('Espressif', style: TextStyle(fontSize: 10, color: AppTheme.primaryLight, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(width: 8),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── Hero Header ──────────────────────────────────────────────────────────
  Widget _buildHero(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.darkCard, const Color(0xFF0A1F3D), const Color(0xFF0D2B50)]
              : [AppTheme.primaryBlue.withValues(alpha: 0.07), AppTheme.accent.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.accent.withValues(alpha: isDark ? 0.2 : 0.12)),
      ),
      child: Column(children: [
        // Animated beacon icon
        AnimatedBuilder(
          animation: Listenable.merge([_pulseCtrl, _rotateCtrl]),
          builder: (_, __) {
            final scale = Tween<double>(begin: 0.93, end: 1.06)
                .evaluate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
            return Stack(alignment: Alignment.center, children: [
              Transform.rotate(
                angle: _rotateCtrl.value * 2 * math.pi,
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [
                      AppTheme.accent.withValues(alpha: 0.0),
                      AppTheme.accent.withValues(alpha: 0.3),
                      AppTheme.primaryBlue.withValues(alpha: 0.25),
                      AppTheme.accent.withValues(alpha: 0.0),
                    ]),
                  ),
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 74, height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accent.withValues(alpha: 0.09),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.22), blurRadius: 18)],
                  ),
                  child: const Icon(Icons.bluetooth_searching_rounded, color: AppTheme.accent, size: 34),
                ),
              ),
            ]);
          },
        ),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context).wifi_provisioning_title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3,
          )),
        const SizedBox(height: 6),
        Text(AppLocalizations.of(context).ble_provision_desc,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF475569), fontSize: 13, height: 1.55)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.timer_outlined, size: 13, color: AppTheme.success),
            const SizedBox(width: 5),
            Text(AppLocalizations.of(context).ble_time_note,
                style: const TextStyle(color: AppTheme.success, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  // ─── 4-Step Flow Card ─────────────────────────────────────────────────────
  static const _flowSteps = [
    (Icons.bluetooth_searching_rounded,  AppTheme.accent,         'ds_flow_ble_scan',    'ds_flow_ble_scan_desc'),
    (Icons.wifi_find_rounded,            AppTheme.primaryLight,   'ds_flow_wifi_scan',   'ds_flow_wifi_scan_desc'),
    (Icons.lock_open_rounded,            Color(0xFF8B5CF6),       'ds_flow_credentials', 'ds_flow_credentials_desc'),
    (Icons.cloud_done_rounded,           AppTheme.success,        'ds_flow_register','ds_flow_register_desc'),
  ];

  Widget _buildFlowCard(Color card, Color muted, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Column(
        children: List.generate(_flowSteps.length, (i) {
          final (icon, color, title, desc) = _flowSteps[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (i < _flowSteps.length - 1)
                  Container(width: 1.5, height: 12, margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_resolveKey(title, AppLocalizations.of(context)), style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(_resolveKey(desc, AppLocalizations.of(context)), style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
              ])),
            ]),
          );
        }),
      ),
    );
  }

  // ─── Interactive Checklist ────────────────────────────────────────────────
  Widget _buildChecklist(Color card, Color txtClr, Color muted, bool isDark) {
    final allDone = _ticked.every((t) => t);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: allDone
              ? AppTheme.success.withValues(alpha: 0.4)
              : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
          width: allDone ? 1.5 : 1,
        ),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Column(children: [
        ...List.generate(_checks.length, (i) {
          final (icon, label, sublabel) = _checks[i];
          return GestureDetector(
            onTap: () { if (mounted) setState(() => _ticked[i] = !_ticked[i]); },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: _ticked[i] ? AppTheme.success : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: _ticked[i] ? AppTheme.success : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      width: 2,
                    ),
                  ),
                  child: _ticked[i]
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: _ticked[i] ? AppTheme.success : AppTheme.accent),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_resolveKey(label, AppLocalizations.of(context)), style: TextStyle(
                    color: _ticked[i] ? AppTheme.success : txtClr,
                    fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(_resolveKey(sublabel, AppLocalizations.of(context)), style: TextStyle(color: muted, fontSize: 11, height: 1.3)),
                ])),
              ]),
            ),
          );
        }),
        if (allDone) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 16),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).ble_ready,
                  style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ]),
          ),
        ],
      ]),
    );
  }

  // ─── CTA Button ───────────────────────────────────────────────────────────
  Widget _buildCta() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        final glow = Tween<double>(begin: 0.28, end: 0.52)
            .evaluate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
        return Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: AppTheme.accentGradient,
            boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: glow), blurRadius: 22, offset: const Offset(0, 6))],
          ),
          child: child,
        );
      },
      child: ElevatedButton.icon(
        onPressed: _startBle,
        icon: const Icon(Icons.bluetooth_searching_rounded, size: 22),
        label: Text(AppLocalizations.of(context).start_ble_setup,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildNote(IconData icon, Color color, String text) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 5),
      Text(text, style: TextStyle(fontSize: 11, color: color)),
    ]);
  }


  String _resolveKey(String key, AppLocalizations l10n) {
    switch (key) {
      case 'ds_check_bt': return l10n.ds_check_bt;
      case 'ds_check_bt_sub': return l10n.ds_check_bt_sub;
      case 'ds_check_power': return l10n.ds_check_power;
      case 'ds_check_power_sub': return l10n.ds_check_power_sub;
      case 'ds_check_nowifi': return l10n.ds_check_nowifi;
      case 'ds_check_nowifi_sub': return l10n.ds_check_nowifi_sub;
      case 'ds_check_location': return l10n.ds_check_location;
      case 'ds_check_location_sub': return l10n.ds_check_location_sub;
      case 'ds_flow_ble_scan': return l10n.ds_flow_ble_scan;
      case 'ds_flow_ble_scan_desc': return l10n.ds_flow_ble_scan_desc;
      case 'ds_flow_wifi_scan': return l10n.ds_flow_wifi_scan;
      case 'ds_flow_wifi_scan_desc': return l10n.ds_flow_wifi_scan_desc;
      case 'ds_flow_credentials': return l10n.ds_flow_credentials;
      case 'ds_flow_credentials_desc': return l10n.ds_flow_credentials_desc;
      case 'ds_flow_register': return l10n.ds_flow_register;
      case 'ds_flow_register_desc': return l10n.ds_flow_register_desc;
      default: return key;
    }
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Row(children: [
      Container(
        width: 3, height: 13, margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2)),
      ),
      Text(label.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
            fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.1,
          )),
    ]);
  }
}
