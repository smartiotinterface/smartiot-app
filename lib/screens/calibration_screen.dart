// lib/screens/calibration_screen.dart
// SmartIoT v4.0.0 — Sensor Calibration Screen
// Stores: RTDB /devices/{id}/meta/calibration + SharedPreferences local

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../core/utils.dart';

class CalibrationScreen extends StatefulWidget {
  final DeviceService deviceService;
  const CalibrationScreen({super.key, required this.deviceService});
  @override State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final _heightCtrl   = TextEditingController();
  final _emptyCtrl    = TextEditingController();
  final _fullCtrl     = TextEditingController();
  final _capacityCtrl = TextEditingController();
  bool _loading = true;
  bool _saving  = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _heightCtrl.dispose(); _emptyCtrl.dispose();
    _fullCtrl.dispose();   _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) { setState(() => _loading = false); return; }
    try {
      final cal = await FirebaseService().getCalibration(deviceId);
      if (cal != null && mounted) {
        _heightCtrl.text   = (cal['tank_height_cm']   ?? '').toString();
        _emptyCtrl.text    = (cal['empty_dist_cm']    ?? '').toString();
        _fullCtrl.text     = (cal['full_dist_cm']     ?? '').toString();
        _capacityCtrl.text = (cal['capacity_liters']  ?? '').toString();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) return;
    setState(() => _saving = true);
    try {
      final cal = {
        'tank_height_cm':  int.parse(_heightCtrl.text.trim()),
        'empty_dist_cm':   int.parse(_emptyCtrl.text.trim()),
        'full_dist_cm':    int.parse(_fullCtrl.text.trim()),
        'capacity_liters': int.parse(_capacityCtrl.text.trim()),
        'updated_at':      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      await FirebaseService().saveCalibration(deviceId, cal);
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).calib_saved);
    } catch (_) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).calib_save_failed, isError: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  // Live calculated values
  double? get _currentLiters {
    final status = widget.deviceService.status;
    if (status == null) return null;
    final pct = status.waterLevelPct / 100.0;
    final cap = int.tryParse(_capacityCtrl.text.trim());
    if (cap == null || cap <= 0) return null;
    return pct * cap;
  }

  int? get _heightCm => int.tryParse(_heightCtrl.text.trim());
  int? get _emptyCm  => int.tryParse(_emptyCtrl.text.trim());
  int? get _fullCm   => int.tryParse(_fullCtrl.text.trim());
  int? get _capL     => int.tryParse(_capacityCtrl.text.trim());

  bool get _valuesValid {
    final h = _heightCm; final e = _emptyCm;
    final f = _fullCm;   final c = _capL;
    return h != null && e != null && f != null && c != null
        && h > 0 && e > f && f >= 0 && c > 0 && e <= h;
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(l10n.calib_title),
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    _InfoCard(isDark: isDark, l10n: l10n),
                    const SizedBox(height: 20),

                    // Tank diagram
                    if (_valuesValid) ...[
                      _TankDiagram(
                        heightCm: _heightCm!,
                        emptyCm:  _emptyCm!,
                        fullCm:   _fullCm!,
                        capL:     _capL!,
                        currentPct: widget.deviceService.status?.waterLevelPct ?? 0,
                        currentL:   _currentLiters ?? 0,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Input fields
                    _SectionHeader(l10n.calib_tank_dimensions, isDark),
                    _CalibField(
                      controller: _heightCtrl,
                      label: l10n.calib_tank_height,
                      hint: '200',
                      unit: 'cm',
                      icon: Icons.height,
                      isDark: isDark,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return l10n.calib_err_positive;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _CalibField(
                      controller: _capacityCtrl,
                      label: l10n.calib_capacity,
                      hint: '500',
                      unit: 'L',
                      icon: Icons.water,
                      isDark: isDark,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return l10n.calib_err_positive;
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _SectionHeader(l10n.calib_sensor_distances, isDark),
                    _CalibHint(l10n.calib_sensor_hint, isDark),
                    const SizedBox(height: 8),
                    _CalibField(
                      controller: _emptyCtrl,
                      label: l10n.calib_empty_distance,
                      hint: '190',
                      unit: 'cm',
                      icon: Icons.arrow_downward,
                      isDark: isDark,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        final h = _heightCm;
                        if (n == null || n <= 0) return l10n.calib_err_positive;
                        if (h != null && n > h) return l10n.calib_err_exceeds_height;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _CalibField(
                      controller: _fullCtrl,
                      label: l10n.calib_full_distance,
                      hint: '10',
                      unit: 'cm',
                      icon: Icons.arrow_upward,
                      isDark: isDark,
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        final e = _emptyCm;
                        if (n == null || n < 0) return l10n.calib_err_nonneg;
                        if (e != null && n >= e) return l10n.calib_err_full_less_empty;
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Live preview
                    if (_valuesValid && _currentLiters != null)
                      _LivePreview(liters: _currentLiters!, capL: _capL!, isDark: isDark, l10n: l10n),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? l10n.saving : l10n.calib_save,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final bool isDark; final AppLocalizations l10n;
  const _InfoCard({required this.isDark, required this.l10n});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline, color: AppTheme.primaryLight, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(l10n.calib_info,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54))),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text; final bool isDark;
  const _SectionHeader(this.text, this.isDark);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
        color: AppTheme.primaryLight, letterSpacing: 0.5)),
  );
}

class _CalibHint extends StatelessWidget {
  final String text; final bool isDark;
  const _CalibHint(this.text, this.isDark);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 12,
        color: isDark ? Colors.white38 : Colors.black38)),
  );
}

class _CalibField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint, unit;
  final IconData icon;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String> validator;
  const _CalibField({required this.controller, required this.label,
    required this.hint, required this.unit, required this.icon,
    required this.isDark, required this.onChanged, required this.validator});
  @override Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit,
        prefixIcon: Icon(icon, color: AppTheme.primaryLight, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? AppTheme.darkCard : Colors.white,
      ),
    );
  }
}

class _TankDiagram extends StatelessWidget {
  final int heightCm, emptyCm, fullCm, capL, currentPct;
  final double currentL;
  final bool isDark;
  const _TankDiagram({required this.heightCm, required this.emptyCm,
    required this.fullCm, required this.capL, required this.currentPct,
    required this.currentL, required this.isDark});
  @override Widget build(BuildContext context) {
    final usableRange = emptyCm - fullCm;
    final emptyPct  = usableRange > 0 ? ((emptyCm - fullCm) / heightCm * 100).round() : 0;
    final fullPct   = usableRange > 0 ? ((heightCm - fullCm) / heightCm * 100).round() : 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(children: [
        Text('Tank Diagram', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _DiagramStat('Height',    '$heightCm cm', Icons.straighten),
          _DiagramStat('Empty at',  '$emptyPct%',   Icons.arrow_downward),
          _DiagramStat('Full at',   '$fullPct%',     Icons.arrow_upward),
          _DiagramStat('Capacity',  '$capL L',       Icons.water_drop),
        ]),
      ]),
    );
  }
}

class _DiagramStat extends StatelessWidget {
  final String label, value; final IconData icon;
  const _DiagramStat(this.label, this.value, this.icon);
  @override Widget build(BuildContext context) => Column(children: [
    Icon(icon, size: 18, color: AppTheme.primaryLight),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);
}

class _LivePreview extends StatelessWidget {
  final double liters; final int capL;
  final bool isDark; final AppLocalizations l10n;
  const _LivePreview({required this.liters, required this.capL,
    required this.isDark, required this.l10n});
  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.water_drop, color: AppTheme.success, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(
          '${l10n.calib_current_water}: ${liters.toStringAsFixed(0)} L / $capL L',
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.success),
        )),
      ]),
    );
  }
}
