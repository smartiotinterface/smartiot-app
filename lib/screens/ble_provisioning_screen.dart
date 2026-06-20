// lib/screens/ble_provisioning_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v1.0.2 — BLE Provisioning Screen  [PREMIUM CORPORATE UI]
//  Brand: Smart IoT Interface — Sobuj Billah
//  Package: flutter_esp_ble_prov ^0.1.7
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ble_provisioning_service.dart';
import '../services/firebase_service.dart';
import '../models/device_model.dart';

// ── Brand colors (matching Smart IoT Interface logo) ─────────────────────────
class _Brand {
  static const blue       = Color(0xFF0A84FF);
  static const blueDeep   = Color(0xFF003A99);
  static const blueGlow   = Color(0xFF4AABFF);
  static const dark       = Color(0xFF070D1A);
  static const darkCard   = Color(0xFF0D1526);
  static const darkCard2  = Color(0xFF111E33);
  static const border     = Color(0xFF1C2E4A);
  static const textPrim   = Color(0xFFE8F0FF);
  static const textMuted  = Color(0xFF6B89B8);
  static const success    = Color(0xFF00D97E);
  static const error      = Color(0xFFFF4D6A);
  static const warning    = Color(0xFFFFAB00);

  static const bgGradient = LinearGradient(
    colors: [Color(0xFF070D1A), Color(0xFF0A1428), Color(0xFF0D1A35)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
}

class BleProvisioningScreen extends StatelessWidget {
  final bool isDark;
  const BleProvisioningScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BleProvisioningService(),
      child: _ProvScreen(isDark: isDark),
    );
  }
}

class _ProvScreen extends StatefulWidget {
  final bool isDark;
  const _ProvScreen({required this.isDark});
  @override
  State<_ProvScreen> createState() => _ProvScreenState();
}

class _ProvScreenState extends State<_ProvScreen>
    with TickerProviderStateMixin {

  late final AnimationController _pulse;
  late final AnimationController _rotate;
  late final AnimationController _slideIn;
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _pulse   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _rotate  = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _slideIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _rotate.dispose();
    _slideIn.dispose();
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BleProvisioningService>();
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: _Brand.dark,
      body: Container(
        decoration: const BoxDecoration(gradient: _Brand.bgGradient),
        child: SafeArea(
          child: Column(children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: FadeTransition(
                  opacity: _slideIn,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(CurvedAnimation(parent: _slideIn, curve: Curves.easeOut)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _buildHeroBanner(svc),
                      const SizedBox(height: 16),
                      _buildStepIndicator(svc.step),
                      const SizedBox(height: 16),
                      _buildStatusCard(svc),
                      const SizedBox(height: 12),
                      if (svc.step == ProvStep.scanDone) _buildDeviceList(svc),
                      if (svc.step == ProvStep.wifiReady || svc.step == ProvStep.sending) _buildWifiSection(svc),
                      if (svc.step == ProvStep.success) _buildSuccessPanel(svc),
                      const SizedBox(height: 12),
                      _buildActionButtons(svc),
                      const SizedBox(height: 12),
                      _buildDisclaimer(),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _Brand.darkCard.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: _Brand.border)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _Brand.textPrim, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        // Brand logo mark
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_Brand.blue, _Brand.blueDeep]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: _Brand.blue.withValues(alpha: 0.4), blurRadius: 8)],
          ),
          child: const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppLocalizations.of(context).wifi_provisioning_title,
                style: const TextStyle(color: _Brand.textPrim, fontWeight: FontWeight.w700, fontSize: 15)),
            const Text('Smart IoT Interface',
                style: TextStyle(color: _Brand.textMuted, fontSize: 10.5, letterSpacing: 0.3)),
          ]),
        ),
        _buildBadge('Espressif BLE', Icons.verified_rounded),
        const SizedBox(width: 8),
      ]),
    );
  }

  Widget _buildBadge(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: _Brand.blue.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _Brand.blue.withValues(alpha: 0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _Brand.blue, size: 11),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: _Brand.blue, fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );

  // ── Hero Banner ───────────────────────────────────────────────────────────
  Widget _buildHeroBanner(BleProvisioningService svc) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _rotate]),
      builder: (_, __) {
        final glow = Tween<double>(begin: 0.15, end: 0.35).evaluate(
            CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _Brand.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Brand.border),
            boxShadow: [BoxShadow(color: _Brand.blue.withValues(alpha: glow * 0.3), blurRadius: 24, spreadRadius: -4)],
          ),
          child: Row(children: [
            // Animated icon
            Stack(alignment: Alignment.center, children: [
              Transform.rotate(
                angle: _rotate.value * 2 * math.pi,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [
                      _Brand.blue.withValues(alpha: 0.0),
                      _Brand.blue.withValues(alpha: glow),
                      _Brand.blueGlow.withValues(alpha: glow * 0.6),
                      _Brand.blue.withValues(alpha: 0.0),
                    ]),
                  ),
                ),
              ),
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_Brand.blue, _Brand.blueDeep],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: _Brand.blue.withValues(alpha: glow), blurRadius: 16)],
                ),
                child: Icon(
                  svc.step == ProvStep.success ? Icons.check_rounded : Icons.bluetooth_searching_rounded,
                  color: Colors.white, size: 26,
                ),
              ),
            ]),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Espressif ইউনিফাইড প্রোভিজনিং',
                  style: TextStyle(color: _Brand.blue, fontWeight: FontWeight.w800, fontSize: 13.5)),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).ble_advertise_note,
                  style: const TextStyle(color: _Brand.textMuted, fontSize: 12, height: 1.45)),
            ])),
          ]),
        );
      },
    );
  }

  // ── Step Indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator(ProvStep step) {
    final steps = [
      (Icons.bluetooth_searching_rounded, AppLocalizations.of(context).ble_scan_step),
      (Icons.link_rounded, AppLocalizations.of(context).ble_step_connect),
      (Icons.wifi_rounded, AppLocalizations.of(context).ble_step_wifi),
      (Icons.check_rounded, '✓'),
    ];
    final int active = switch (step) {
      ProvStep.scanning || ProvStep.scanDone   => 0,
      ProvStep.connecting                       => 1,
      ProvStep.wifiReady || ProvStep.sending    => 2,
      ProvStep.success                          => 3,
      _                                         => -1,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _Brand.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Brand.border),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final lineIdx = i ~/ 2;
            final filled = lineIdx < active;
            return Expanded(child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: filled
                    ? const LinearGradient(colors: [_Brand.blue, _Brand.blueGlow])
                    : null,
                color: filled ? null : _Brand.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ));
          }
          final idx  = i ~/ 2;
          final done = idx < active;
          final cur  = idx == active;
          final (icon, label) = steps[idx];
          return Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done || cur ? const LinearGradient(
                    colors: [_Brand.blue, _Brand.blueDeep],
                    begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                color: done || cur ? null : _Brand.darkCard2,
                border: Border.all(
                    color: done || cur ? _Brand.blue : _Brand.border, width: 1.5),
                boxShadow: cur ? [BoxShadow(color: _Brand.blue.withValues(alpha: 0.4), blurRadius: 10)] : [],
              ),
              child: Icon(icon,
                  size: 17,
                  color: done || cur ? Colors.white : _Brand.textMuted),
            ),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 9.5,
                    color: cur ? _Brand.blue : (done ? _Brand.textMuted : _Brand.textMuted.withValues(alpha: 0.5)),
                    fontWeight: cur ? FontWeight.w800 : FontWeight.w500)),
          ]);
        }),
      ),
    );
  }

  // ── Status Card ───────────────────────────────────────────────────────────
  Widget _buildStatusCard(BleProvisioningService svc) {
    final isErr  = svc.step == ProvStep.failed;
    final isOk   = svc.step == ProvStep.success;
    final accent = isOk ? _Brand.success : isErr ? _Brand.error : _Brand.blue;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = Tween<double>(begin: 0.1, end: 0.3)
            .evaluate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _Brand.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: svc.isBusy ? glow + 0.15 : 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: svc.isBusy ? glow * 0.4 : 0.05),
                  blurRadius: 16, spreadRadius: -2),
            ],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: svc.isBusy ? glow + 0.08 : 0.1),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: svc.isBusy && !isOk && !isErr
                  ? Padding(
                      padding: const EdgeInsets.all(11),
                      child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                    )
                  : Icon(_icon(svc.step), color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_title(svc.step, AppLocalizations.of(context)),
                  style: const TextStyle(color: _Brand.textPrim, fontWeight: FontWeight.w700, fontSize: 14.5)),
              const SizedBox(height: 5),
              Text(_resolveMsg(svc.error ?? svc.message, AppLocalizations.of(context)),
                  style: TextStyle(
                      color: isErr ? _Brand.error.withValues(alpha: 0.85) : _Brand.textMuted,
                      fontSize: 12.5, height: 1.5)),
            ])),
          ]),
        );
      },
    );
  }

  // ── Device List ───────────────────────────────────────────────────────────
  Widget _buildDeviceList(BleProvisioningService svc) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      _sectionHeader(
        AppLocalizations.of(context).ble_found_devices(svc.devices.length),
        Icons.devices_rounded,
      ),
      const SizedBox(height: 10),
      ...svc.devices.map((name) => _deviceTile(name, svc)),
      const SizedBox(height: 4),
    ]);
  }

  Widget _deviceTile(String name, BleProvisioningService svc) {
    return GestureDetector(
      onTap: svc.isCoolingDown ? null : () => svc.connectAndScanWifi(name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: _Brand.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Brand.blue.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: _Brand.blue.withValues(alpha: 0.08), blurRadius: 12)],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_Brand.blue, _Brand.blueDeep],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _Brand.blue.withValues(alpha: 0.35), blurRadius: 8)],
            ),
            child: const Icon(Icons.developer_board_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: _Brand.textPrim, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 3),
            Text(AppLocalizations.of(context).tap_to_scan,
                style: const TextStyle(color: _Brand.textMuted, fontSize: 11.5)),
          ])),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _Brand.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _Brand.blue.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.chevron_right_rounded, color: _Brand.blue, size: 18),
          ),
        ]),
      ),
    );
  }

  // ── WiFi Section ──────────────────────────────────────────────────────────
  Widget _buildWifiSection(BleProvisioningService svc) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 4),
      if (svc.wifiNetworks.isNotEmpty) ...[
        _sectionHeader(
          AppLocalizations.of(context).wifi_networks_found(svc.wifiNetworks.length),
          Icons.wifi_find_rounded,
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: _Brand.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Brand.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: svc.wifiNetworks.map((ssid) => _wifiTile(ssid)).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
      _sectionHeader(AppLocalizations.of(context).ble_wifi_enter, Icons.lock_open_rounded),
      const SizedBox(height: 10),
      _buildField(ctrl: _ssidCtrl, hint: AppLocalizations.of(context).ble_wifi_ssid_hint, icon: Icons.wifi_rounded),
      const SizedBox(height: 10),
      _buildField(
        ctrl: _passCtrl,
        hint: AppLocalizations.of(context).ble_wifi_pass_hint,
        icon: Icons.lock_rounded,
        obscure: _obscure,
        suffix: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: _Brand.textMuted, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      const SizedBox(height: 16),
      // Connect button
      Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_Brand.blue, _Brand.blueDeep]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _Brand.blue.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.wifi_protected_setup_rounded, size: 20),
          label: Text(
            svc.step == ProvStep.sending
                ? AppLocalizations.of(context).ble_connect_sending
                : AppLocalizations.of(context).ble_connect_wifi,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
          ),
          onPressed: svc.step == ProvStep.sending ? null
              : () => svc.sendCredentials(ssid: _ssidCtrl.text, password: _passCtrl.text),
        ),
      ),
      const SizedBox(height: 6),
      Center(
        child: TextButton.icon(
          onPressed: svc.isBusy ? null : svc.refreshWifiScan,
          icon: const Icon(Icons.refresh_rounded, size: 15, color: _Brand.blue),
          label: Text(AppLocalizations.of(context).wifi_list_refresh,
              style: const TextStyle(color: _Brand.blue, fontSize: 12)),
        ),
      ),
    ]);
  }

  Widget _wifiTile(String ssid) {
    final selected = _ssidCtrl.text == ssid;
    return GestureDetector(
      onTap: () => setState(() => _ssidCtrl.text = ssid),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? _Brand.blue.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _Brand.blue : Colors.transparent),
        ),
        child: Row(children: [
          Icon(Icons.wifi_rounded, color: selected ? _Brand.blue : _Brand.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(ssid,
              style: TextStyle(
                  color: selected ? _Brand.textPrim : _Brand.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.5))),
          if (selected)
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(color: _Brand.blue, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
            ),
        ]),
      ),
    );
  }

  // ── Success Panel ─────────────────────────────────────────────────────────
  Widget _buildSuccessPanel(BleProvisioningService svc) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = Tween<double>(begin: 0.15, end: 0.4)
            .evaluate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _Brand.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Brand.success.withValues(alpha: 0.4)),
            boxShadow: [BoxShadow(color: _Brand.success.withValues(alpha: glow * 0.3), blurRadius: 24)],
          ),
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Brand.success.withValues(alpha: 0.12),
                border: Border.all(color: _Brand.success.withValues(alpha: 0.4), width: 2),
                boxShadow: [BoxShadow(color: _Brand.success.withValues(alpha: glow), blurRadius: 20)],
              ),
              child: const Icon(Icons.check_circle_rounded, color: _Brand.success, size: 42),
            ),
            const SizedBox(height: 14),
            Text(AppLocalizations.of(context).provisioning_done,
                style: const TextStyle(color: _Brand.textPrim, fontWeight: FontWeight.w800, fontSize: 19)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).ble_prov_done_detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _Brand.textMuted, fontSize: 13, height: 1.55)),
            const SizedBox(height: 20),
            // Brand signature
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _Brand.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _Brand.blue.withValues(alpha: 0.2)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.wifi_tethering_rounded, color: _Brand.blue, size: 14),
                SizedBox(width: 6),
                Text('Smart IoT Interface',
                    style: TextStyle(color: _Brand.blue, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_Brand.success, Color(0xFF00AA60)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _Brand.success.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.app_registration_rounded),
                label: Text(AppLocalizations.of(context).register_firebase,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                onPressed: () => _registerDevice(context, svc),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).back_to_dashboard,
                  style: const TextStyle(color: _Brand.textMuted, fontSize: 13)),
            ),
          ]),
        );
      },
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────
  Widget _buildActionButtons(BleProvisioningService svc) {
    if (svc.step == ProvStep.success) return const SizedBox.shrink();
    return Column(children: [
      // Cooldown banner
      if (svc.isCoolingDown) ...[
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _Brand.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _Brand.warning.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _Brand.warning.withValues(alpha: 0.8))),
                const SizedBox(width: 10),
                Flexible(child: Text(
                  svc.autoRetryEnabled
                      ? 'Auto-retrying in ${svc.cooldownSecondsLeft}s...'
                      : 'BLE resetting... ${svc.cooldownSecondsLeft}s',
                  style: const TextStyle(color: _Brand.warning, fontWeight: FontWeight.w700, fontSize: 13.5),
                )),
              ]),
              const SizedBox(height: 6),
              Text(
                svc.connectFailCount >= 3
                    ? 'ESP32 power OFF করুন → ৫ সেকেন্ড → power ON করুন'
                    : 'পুরানো BLE connection বন্ধ হচ্ছে — Cooldown শেষে retry হবে।',
                style: const TextStyle(color: _Brand.textMuted, fontSize: 11.5, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
      ],

      // Main scan/retry button
      if (!svc.isBusy && svc.step != ProvStep.wifiReady)
        Container(
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: svc.isCoolingDown ? null : const LinearGradient(colors: [_Brand.blue, _Brand.blueDeep]),
            color: svc.isCoolingDown ? _Brand.blue.withValues(alpha: 0.2) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: svc.isCoolingDown ? [] : [
              BoxShadow(color: _Brand.blue.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: svc.isCoolingDown
                ? const Icon(Icons.hourglass_top_rounded, size: 18)
                : Icon(svc.step == ProvStep.failed ? Icons.refresh_rounded : Icons.bluetooth_searching_rounded, size: 20),
            label: Text(
              svc.isCoolingDown
                  ? 'Retry in ${svc.cooldownSecondsLeft}s...'
                  : (svc.step == ProvStep.failed
                      ? AppLocalizations.of(context).ble_retry
                      : AppLocalizations.of(context).ble_start_scan),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
            ),
            onPressed: svc.isCoolingDown ? null : svc.startBleScan,
          ),
        ),

      if (svc.step == ProvStep.scanning)
        Column(children: [
          const SizedBox(height: 12),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(2)),
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: _Brand.border,
              valueColor: AlwaysStoppedAnimation<Color>(_Brand.blue),
            ),
          ),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).ble_scanning_msg,
              style: const TextStyle(color: _Brand.textMuted, fontSize: 12)),
        ]),

      // Reset button
      if (svc.step != ProvStep.idle && !svc.isBusy)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: SizedBox(
            width: double.infinity, height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _Brand.textMuted,
                side: const BorderSide(color: _Brand.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 17, color: _Brand.textMuted),
              label: Text(AppLocalizations.of(context).reset,
                  style: const TextStyle(color: _Brand.textMuted, fontSize: 13)),
              onPressed: svc.reset,
            ),
          ),
        ),
    ]);
  }

  // ── Disclaimer ────────────────────────────────────────────────────────────
  Widget _buildDisclaimer() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _Brand.warning.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _Brand.warning.withValues(alpha: 0.2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.info_outline_rounded, color: _Brand.warning, size: 15),
      const SizedBox(width: 8),
      Expanded(child: Text(
        AppLocalizations.of(context).ble_note_existing,
        style: TextStyle(color: _Brand.warning.withValues(alpha: 0.8), fontSize: 11.5, height: 1.45),
      )),
    ]),
  );

  // ── Register Device ───────────────────────────────────────────────────────
  Future<void> _registerDevice(BuildContext ctx, BleProvisioningService svc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final name = svc.selectedDevice ?? '';
    // [FIX-SERIAL v8.2.7] Strip "PROV_SmartIoT_" prefix to recover the full serial.
    // Old split('_').last returned only the first 6 chars of the serial (e.g. "SWT-9C"
    // instead of "SWT-9C64A71AD6B8"). Flutter then registered device_owners/SWT-9C
    // and listened to devices/SWT-9C/status — never matching ESP32's actual RTDB path.
    const kBlePrefix = 'PROV_SmartIoT_';
    final serial = name.startsWith(kBlePrefix)
        ? name.substring(kBlePrefix.length)  // "PROV_SmartIoT_SWT-9C64A71AD6B8" → "SWT-9C64A71AD6B8"
        : name; // fallback: use the name as-is
    try {
      final fb = ctx.read<FirebaseService>();
      await fb.claimDevice(serial, uid);
      final meta = DeviceMeta(
        serial:       serial,
        firmware:     '--',
        deviceName:   'Water Tank',
        ownerId:      uid,
        registeredAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      await fb.setMeta(serial, meta);
      await fb.logHistoryEvent(serial, 'Device provisioned via BLE');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(ctx).device_registered),
          backgroundColor: _Brand.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(ctx, serial);
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(ctx).error_colon('$e')),
          backgroundColor: _Brand.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, IconData icon) => Row(children: [
    Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: _Brand.blue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _Brand.blue.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, size: 15, color: _Brand.blue),
    ),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(color: _Brand.textPrim, fontWeight: FontWeight.w700, fontSize: 13.5)),
  ]);

  Widget _buildField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: _Brand.textPrim, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _Brand.textMuted),
        prefixIcon: Icon(icon, color: _Brand.textMuted, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _Brand.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Brand.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Brand.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _Brand.blue, width: 1.5)),
      ),
    );
  }

  IconData _icon(ProvStep s) => switch (s) {
    ProvStep.scanning    => Icons.bluetooth_searching_rounded,
    ProvStep.scanDone    => Icons.devices_rounded,
    ProvStep.connecting  => Icons.wifi_find_rounded,
    ProvStep.wifiReady   => Icons.wifi_rounded,
    ProvStep.sending     => Icons.send_rounded,
    ProvStep.success     => Icons.check_circle_rounded,
    ProvStep.failed      => Icons.error_outline_rounded,
    _                    => Icons.bluetooth_rounded,
  };

  String _title(ProvStep s, AppLocalizations l10n) => switch (s) {
    ProvStep.scanning    => l10n.ble_step_scanning,
    ProvStep.scanDone    => l10n.ble_step_scan_done,
    ProvStep.connecting  => l10n.ble_step_connecting,
    ProvStep.wifiReady   => l10n.ble_step_wifi_ready,
    ProvStep.sending     => l10n.ble_step_sending,
    ProvStep.success     => l10n.ble_step_success,
    ProvStep.failed      => l10n.ble_step_failed,
    _                    => l10n.ble_step_default,
  };

  String _resolveMsg(String raw, AppLocalizations l10n) {
    if (raw.startsWith('ble_svc_scanning:')) return l10n.ble_svc_scanning_for(raw.substring('ble_svc_scanning:'.length));
    if (raw == 'ble_svc_no_device') return l10n.ble_svc_no_device;
    if (raw.startsWith('ble_svc_found:')) return l10n.ble_svc_found_count(int.tryParse(raw.substring('ble_svc_found:'.length)) ?? 0);
    if (raw.startsWith('ble_svc_scan_failed:')) return l10n.ble_svc_scan_failed(raw.substring('ble_svc_scan_failed:'.length));
    if (raw.startsWith('ble_svc_connecting:')) return l10n.ble_svc_connecting_to(raw.substring('ble_svc_connecting:'.length));
    if (raw == 'ble_svc_no_wifi') return l10n.ble_svc_no_wifi;
    if (raw.startsWith('ble_svc_wifi_found:')) return l10n.ble_svc_wifi_count(int.tryParse(raw.substring('ble_svc_wifi_found:'.length)) ?? 0);
    if (raw.startsWith('ble_svc_wifi_scan_failed:')) return l10n.ble_svc_wifi_scan_failed(raw.substring('ble_svc_wifi_scan_failed:'.length));
    if (raw == 'ble_svc_ssid_empty') return l10n.ble_svc_ssid_empty;
    if (raw == 'ble_svc_no_device_selected') return l10n.ble_svc_no_device_selected;
    if (raw.startsWith('ble_svc_sending:')) return l10n.ble_svc_sending(raw.substring('ble_svc_sending:'.length));
    if (raw.startsWith('ble_svc_success:')) return l10n.ble_svc_success(raw.substring('ble_svc_success:'.length));
    if (raw.startsWith('ble_svc_prov_failed:')) return l10n.ble_svc_prov_failed(raw.substring('ble_svc_prov_failed:'.length));
    if (raw == 'ble_svc_error') return l10n.ble_svc_error_occurred;
    return raw;
  }
}
