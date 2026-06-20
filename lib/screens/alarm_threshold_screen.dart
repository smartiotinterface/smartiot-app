// lib/screens/alarm_threshold_screen.dart
// SmartIoT v4.0.0 — Alarm Threshold Settings
// Saves to: RTDB /devices/{id}/control/thresholds + /devices/{id}/meta/thresholds

import 'package:flutter/material.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../core/utils.dart';

class AlarmThresholdScreen extends StatefulWidget {
  final DeviceService deviceService;
  const AlarmThresholdScreen({super.key, required this.deviceService});
  @override State<AlarmThresholdScreen> createState() => _AlarmThresholdScreenState();
}

class _AlarmThresholdScreenState extends State<AlarmThresholdScreen> {
  double _lowAlert   = 15.0;   // % — local notification when below
  double _fullStop   = 90.0;   // % — pump stops when above
  double _emptyStart = 10.0;   // % — pump starts when below
  double _dryRunPct  = 5.0;    // % — dry-run alarm threshold
  bool _loading = true;
  bool _saving  = false;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) { setState(() => _loading = false); return; }
    try {
      final t = await FirebaseService().getThresholds(deviceId);
      if (t != null && mounted) {
        setState(() {
          _lowAlert   = ((t['low_alert_pct']   ?? 15) as num).toDouble().clamp(1, 50);
          _fullStop   = ((t['full_stop_pct']   ?? 90) as num).toDouble().clamp(60, 99);
          _emptyStart = ((t['empty_start_pct'] ?? 10) as num).toDouble().clamp(1, 40);
          _dryRunPct  = ((t['dry_run_pct']     ?? 5)  as num).toDouble().clamp(1, 20);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) return;
    setState(() => _saving = true);
    try {
      final thresholds = {
        'low_alert_pct':   _lowAlert.round(),
        'full_stop_pct':   _fullStop.round(),
        'empty_start_pct': _emptyStart.round(),
        'dry_run_pct':     _dryRunPct.round(),
        'updated_at':      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      await FirebaseService().saveThresholds(deviceId, thresholds);
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).thresh_saved);
    } catch (_) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).thresh_save_failed, isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = widget.deviceService.status;
    final currentPct = status?.waterLevelPct ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(l10n.thresh_title),
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current level indicator
                  _CurrentLevelCard(pct: currentPct, isDark: isDark, l10n: l10n),
                  const SizedBox(height: 20),

                  // Visual threshold bar
                  _ThresholdBar(
                    currentPct:  currentPct,
                    emptyStart:  _emptyStart,
                    lowAlert:    _lowAlert,
                    fullStop:    _fullStop,
                    dryRunPct:   _dryRunPct,
                    isDark:      isDark,
                  ),
                  const SizedBox(height: 24),

                  // Pump thresholds
                  _ThresholdSection(
                    title: l10n.thresh_pump_control,
                    icon: Icons.power_settings_new,
                    isDark: isDark,
                    children: [
                      _SliderTile(
                        label:   l10n.thresh_pump_start,
                        subtitle: l10n.thresh_pump_start_sub,
                        value:   _emptyStart,
                        min: 1, max: 40,
                        color:   AppTheme.danger,
                        icon:    Icons.play_arrow_rounded,
                        isDark:  isDark,
                        onChanged: (v) => setState(() => _emptyStart = v < _dryRunPct ? _dryRunPct + 1 : v),
                      ),
                      const Divider(height: 1),
                      _SliderTile(
                        label:   l10n.thresh_pump_stop,
                        subtitle: l10n.thresh_pump_stop_sub,
                        value:   _fullStop,
                        min: 60, max: 99,
                        color:   AppTheme.success,
                        icon:    Icons.stop_rounded,
                        isDark:  isDark,
                        onChanged: (v) => setState(() => _fullStop = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alert thresholds
                  _ThresholdSection(
                    title: l10n.thresh_alerts,
                    icon: Icons.notifications_active_outlined,
                    isDark: isDark,
                    children: [
                      _SliderTile(
                        label:   l10n.thresh_low_alert,
                        subtitle: l10n.thresh_low_alert_sub,
                        value:   _lowAlert,
                        min: 1, max: 50,
                        color:   AppTheme.warning,
                        icon:    Icons.warning_amber_rounded,
                        isDark:  isDark,
                        onChanged: (v) => setState(() => _lowAlert = v),
                      ),
                      const Divider(height: 1),
                      _SliderTile(
                        label:   l10n.thresh_dry_run,
                        subtitle: l10n.thresh_dry_run_sub,
                        value:   _dryRunPct,
                        min: 1, max: 20,
                        color:   Colors.red.shade700,
                        icon:    Icons.error_outline_rounded,
                        isDark:  isDark,
                        onChanged: (v) => setState(() {
                          _dryRunPct = v;
                          if (_emptyStart <= v) _emptyStart = v + 1;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Validation warning
                  if (_emptyStart <= _dryRunPct)
                    _WarningCard(l10n.thresh_warn_order, isDark),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: (_saving || _emptyStart <= _dryRunPct) ? null : _save,
                      icon: _saving
                          ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? l10n.saving : l10n.thresh_save,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CurrentLevelCard extends StatelessWidget {
  final int pct; final bool isDark; final AppLocalizations l10n;
  const _CurrentLevelCard({required this.pct, required this.isDark, required this.l10n});
  @override Widget build(BuildContext context) {
    final color = pct < 15 ? AppTheme.danger : pct > 85 ? AppTheme.success : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.water_drop, color: color, size: 22),
        const SizedBox(width: 10),
        Text('${l10n.thresh_current_level}: $pct%',
            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 15)),
      ]),
    );
  }
}

class _ThresholdBar extends StatelessWidget {
  final int currentPct;
  final double emptyStart, lowAlert, fullStop, dryRunPct;
  final bool isDark;
  const _ThresholdBar({required this.currentPct, required this.emptyStart,
    required this.lowAlert, required this.fullStop, required this.dryRunPct, required this.isDark});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Threshold Preview', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 12),
          Stack(children: [
            // Background bar
            Container(height: 28, decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            )),
            // Colored zones
            Row(children: [
              Expanded(flex: dryRunPct.round(), child: Container(height: 28,
                decoration: BoxDecoration(color: Colors.red.shade900,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(6))))),
              Expanded(flex: (emptyStart - dryRunPct).round().clamp(0,100),
                child: Container(height: 28, color: AppTheme.danger.withValues(alpha: 0.7))),
              Expanded(flex: (lowAlert - emptyStart).round().clamp(0,100),
                child: Container(height: 28, color: AppTheme.warning.withValues(alpha: 0.6))),
              Expanded(flex: (fullStop - lowAlert).round().clamp(0,100),
                child: Container(height: 28, color: AppTheme.success.withValues(alpha: 0.5))),
              Expanded(flex: (100 - fullStop).round().clamp(0,100),
                child: Container(height: 28,
                  decoration: const BoxDecoration(color: AppTheme.success,
                    borderRadius: BorderRadius.horizontal(right: Radius.circular(6))))),
            ]),
            // Current level marker
            Positioned(
              left: (currentPct / 100) * (MediaQuery.sizeOf(context).width - 72),
              top: 0, bottom: 0,
              child: Container(width: 3, color: Colors.white,
                child: const Align(alignment: Alignment.topCenter,
                  child: Icon(Icons.arrow_drop_down, size: 16, color: Colors.white))),
            ),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BarLegend('Dry-run', Colors.red.shade900),
              const _BarLegend('Start pump', AppTheme.danger),
              const _BarLegend('Low alert', AppTheme.warning),
              const _BarLegend('Normal', AppTheme.success),
              const _BarLegend('Full', AppTheme.success),
            ]),
        ],
      ),
    );
  }
}

class _BarLegend extends StatelessWidget {
  final String label; final Color color;
  const _BarLegend(this.label, this.color);
  @override Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 3),
    Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
  ]);
}

class _ThresholdSection extends StatelessWidget {
  final String title; final IconData icon;
  final bool isDark; final List<Widget> children;
  const _ThresholdSection({required this.title, required this.icon,
    required this.isDark, required this.children});
  @override Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.primaryLight),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight)),
        ]),
      ),
      Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Column(children: children),
      ),
    ]);
  }
}

class _SliderTile extends StatelessWidget {
  final String label, subtitle;
  final double value, min, max;
  final Color color; final IconData icon;
  final bool isDark;
  final ValueChanged<double> onChanged;
  const _SliderTile({required this.label, required this.subtitle,
    required this.value, required this.min, required this.max,
    required this.color, required this.icon, required this.isDark,
    required this.onChanged});
  @override Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            Text(subtitle, style: TextStyle(fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${value.round()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(value: value, min: min, max: max, divisions: (max-min).round(), onChanged: onChanged),
        ),
      ]),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String text; final bool isDark;
  const _WarningCard(this.text, this.isDark);
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.danger.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_rounded, color: AppTheme.danger, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
    ]),
  );
}
