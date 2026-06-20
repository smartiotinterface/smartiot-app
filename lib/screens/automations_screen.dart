// lib/screens/automations_screen.dart
// SmartIoT v8.0.0 — Automations (Condition-based rules, runs on ESP32)
// Automation = "যদি X হয় → তাহলে Y করো"
// Rule stored in Firebase: /automations/{deviceId}/{ruleId}
// ESP32 reads these rules and evaluates them locally
// Spark-plan safe: read once on boot + periodic poll

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../core/utils.dart';

// ── Model ─────────────────────────────────────────────────────
class AutomationModel {
  final String id;
  final String name;
  final String triggerType;   // 'level_below' | 'level_above' | 'pump_on_mins' | 'time_of_day'
  final int triggerValue;     // % or minutes or hour (0-23)
  final String actionType;    // 'pump_on' | 'pump_off' | 'mode_auto' | 'mode_manual' | 'alert'
  final bool enabled;
  final int createdAt;

  const AutomationModel({
    required this.id,
    required this.name,
    required this.triggerType,
    required this.triggerValue,
    required this.actionType,
    required this.enabled,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'triggerType': triggerType,
    'triggerValue': triggerValue,
    'actionType': actionType,
    'enabled': enabled,
    'createdAt': createdAt,
  };

  factory AutomationModel.fromMap(String id, Map<dynamic, dynamic> m) =>
      AutomationModel(
        id: id,
        name: m['name']?.toString() ?? 'Rule',
        triggerType: m['triggerType']?.toString() ?? 'level_below',
        triggerValue: (m['triggerValue'] as num?)?.toInt() ?? 20,
        actionType: m['actionType']?.toString() ?? 'pump_on',
        enabled: m['enabled'] == true,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
      );

  String get triggerLabel {
    switch (triggerType) {
      case 'level_below':   return 'Water below $triggerValue%';
      case 'level_above':   return 'Water above $triggerValue%';
      case 'pump_on_mins':  return 'Pump ON > $triggerValue min';
      case 'time_of_day':   return 'Every day at ${triggerValue.toString().padLeft(2,'0')}:00';
      default: return triggerType;
    }
  }

  String get actionLabel {
    switch (actionType) {
      case 'pump_on':      return 'Turn Pump ON';
      case 'pump_off':     return 'Turn Pump OFF';
      case 'mode_auto':    return 'Switch to AUTO';
      case 'mode_manual':  return 'Switch to MANUAL';
      case 'alert':        return 'Send Alert';
      default: return actionType;
    }
  }

  IconData get triggerIcon {
    switch (triggerType) {
      case 'level_below':  return Icons.arrow_downward_rounded;
      case 'level_above':  return Icons.arrow_upward_rounded;
      case 'pump_on_mins': return Icons.timer_outlined;
      case 'time_of_day':  return Icons.schedule_rounded;
      default: return Icons.rule_rounded;
    }
  }

  IconData get actionIcon {
    switch (actionType) {
      case 'pump_on':     return Icons.power_rounded;
      case 'pump_off':    return Icons.power_off_rounded;
      case 'mode_auto':   return Icons.auto_mode_rounded;
      case 'mode_manual': return Icons.touch_app_rounded;
      case 'alert':       return Icons.notifications_active_rounded;
      default: return Icons.play_arrow_rounded;
    }
  }

  Color get actionColor {
    switch (actionType) {
      case 'pump_on':    return AppTheme.success;
      case 'pump_off':   return AppTheme.danger;
      case 'mode_auto':  return AppTheme.accent;
      case 'alert':      return AppTheme.warning;
      default:           return AppTheme.smartPurple;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────
class AutomationsScreen extends StatefulWidget {
  final DeviceService deviceService;
  const AutomationsScreen({super.key, required this.deviceService});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  final _fb = FirebaseService();
  List<AutomationModel> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _deviceId => widget.deviceService.selectedDeviceId;

  Future<void> _load() async {
    if (_deviceId == null) { setState(() => _loading = false); return; }
    setState(() => _loading = true);
    try {
      final snap = await _fb.db.ref('automations/$_deviceId').get();
      final list = <AutomationModel>[];
      if (snap.exists && snap.value != null) {
        final map = Map<dynamic, dynamic>.from(snap.value is Map ? snap.value as Map<dynamic,dynamic> : {});
        for (final e in map.entries) {
          list.add(AutomationModel.fromMap(
              e.key.toString(), Map<dynamic, dynamic>.from(e.value is Map ? e.value as Map<dynamic,dynamic> : {})));
        }
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      if (mounted) setState(() { _rules = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRule(AutomationModel rule) async {
    if (_deviceId == null) return;
    final newVal = !rule.enabled;
    try {
      await _fb.db
          .ref('automations/$_deviceId/${rule.id}')
          .update({'enabled': newVal});
      final idx = _rules.indexWhere((r) => r.id == rule.id);
      if (idx != -1 && mounted) {
        setState(() {
          _rules[idx] = AutomationModel(
            id: rule.id, name: rule.name,
            triggerType: rule.triggerType, triggerValue: rule.triggerValue,
            actionType: rule.actionType, enabled: newVal, createdAt: rule.createdAt,
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      _snack('${AppLocalizations.of(context).failed} (update)', true);
    }
  }

  Future<void> _deleteRule(AutomationModel rule) async {
    if (_deviceId == null) return;
    final isDark = context.read<ThemeNotifier>().isDark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Delete Automation',
        body: 'Delete "${rule.name}"?',
        isDark: isDark,
      ),
    );
    if (ok != true) return;
    try {
      await _fb.db.ref('automations/$_deviceId/${rule.id}').remove();
      setState(() => _rules.removeWhere((r) => r.id == rule.id));
      if (mounted) _snack(AppLocalizations.of(context).automation_deleted, false);
    } catch (_) {
      if (!mounted) return;
      _snack('${AppLocalizations.of(context).failed} (delete)', true);
    }
  }

  Future<void> _openAddRule() async {
    final isDark = context.read<ThemeNotifier>().isDark;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRuleSheet(
        isDark: isDark,
        onSave: (name, triggerType, triggerValue, actionType) async {
          if (_deviceId == null) return;
          final ref = _fb.db.ref('automations/$_deviceId').push();
          await ref.set({
            'name': name,
            'triggerType': triggerType,
            'triggerValue': triggerValue,
            'actionType': actionType,
            'enabled': true,
            'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });
          await _load();
        },
      ),
    );
  }

  void _snack(String msg, bool isError) {
    if (!mounted) return;
    AppUtils.showSnack(context, msg, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;

    return Container(
      color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      child: Column(children: [
        // ── Title bar ──────────────────────────────────────────
        _TitleBar(
          title: 'Automations',
          isDark: isDark,
          action: IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppTheme.smartPurple,
            onPressed: _openAddRule,
            tooltip: 'Add rule',
          ),
        ),

        // ── ESP32 note banner ──────────────────────────────────
        if (!_loading && _deviceId != null)
          _InfoBanner(isDark: isDark),

        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.smartPurple))
          : _deviceId == null
            ? _NoDevice(isDark: isDark)
            : _rules.isEmpty
              ? _EmptyRules(isDark: isDark, onAdd: _openAddRule)
              : RefreshIndicator(
                  color: AppTheme.smartPurple,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: _rules.length,
                    itemBuilder: (_, i) => _RuleCard(
                      rule: _rules[i],
                      isDark: isDark,
                      onToggle: () => _toggleRule(_rules[i]),
                      onDelete: () => _deleteRule(_rules[i]),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

// ── Rule Card ─────────────────────────────────────────────────
class _RuleCard extends StatelessWidget {
  final AutomationModel rule;
  final bool isDark;
  final VoidCallback onToggle, onDelete;

  const _RuleCard({
    required this.rule, required this.isDark,
    required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = rule.actionColor;
    return Dismissible(
      key: ValueKey(rule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // manual delete in onDelete
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: rule.enabled
                ? actionColor.withValues(alpha: isDark ? 0.25 : 0.15)
                : Colors.grey.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: rule.enabled
                  ? actionColor.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: isDark
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: _RuleContent(rule: rule, isDark: isDark, onToggle: onToggle, actionColor: actionColor),
                )
              : _RuleContent(rule: rule, isDark: isDark, onToggle: onToggle, actionColor: actionColor),
        ),
      ),
    );
  }
}

class _RuleContent extends StatelessWidget {
  final AutomationModel rule;
  final bool isDark;
  final VoidCallback onToggle;
  final Color actionColor;
  const _RuleContent({required this.rule, required this.isDark, required this.onToggle, required this.actionColor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subColor = isDark ? Colors.white38 : AppTheme.lightTextSub;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(children: [
        // Left: icon
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: actionColor.withValues(alpha: rule.enabled ? 0.15 : 0.07),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(rule.actionIcon,
              color: actionColor.withValues(alpha: rule.enabled ? 1 : 0.4),
              size: 22),
        ),
        const SizedBox(width: 14),

        // Center: details
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            rule.name,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: rule.enabled ? textColor : textColor.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 5),
          // Trigger row
          Row(children: [
            Icon(rule.triggerIcon, size: 12, color: AppTheme.accent.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(l10n.auto_if_label(rule.triggerLabel),
                style: TextStyle(fontSize: 11, color: AppTheme.accent.withValues(alpha: rule.enabled ? 0.85 : 0.4))),
          ]),
          const SizedBox(height: 3),
          // Action row
          Row(children: [
            Icon(Icons.arrow_forward_rounded, size: 12, color: actionColor.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(l10n.auto_then_label(rule.actionLabel),
                style: TextStyle(fontSize: 11, color: actionColor.withValues(alpha: rule.enabled ? 0.85 : 0.4))),
          ]),
          const SizedBox(height: 4),
          Text(
            l10n.swipe_to_delete,
            style: TextStyle(fontSize: 9, color: subColor.withValues(alpha: 0.6)),
          ),
        ])),

        // Right: toggle
        Switch.adaptive(
          value: rule.enabled,
          onChanged: (_) => onToggle(),
          activeThumbColor: AppTheme.smartPurple,
          activeTrackColor: AppTheme.smartPurple.withValues(alpha: 0.3),
        ),
      ]),
    );
  }
}

// ── Add Rule Bottom Sheet ─────────────────────────────────────
class _AddRuleSheet extends StatefulWidget {
  final bool isDark;
  final Future<void> Function(String, String, int, String) onSave;
  const _AddRuleSheet({required this.isDark, required this.onSave});

  @override
  State<_AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends State<_AddRuleSheet> {
  final _nameCtrl = TextEditingController();
  String _triggerType = 'level_below';
  int _triggerValue = 20;
  String _actionType = 'pump_on';
  bool _saving = false;

  static const _triggers = [
    ('level_below',  'Water below %', Icons.arrow_downward_rounded),
    ('level_above',  'Water above %', Icons.arrow_upward_rounded),
    ('pump_on_mins', 'Pump ON > min', Icons.timer_outlined),
    ('time_of_day',  'Time of day',   Icons.schedule_rounded),
  ];

  static const _actions = [
    ('pump_on',     'Turn Pump ON',    Icons.power_rounded,           AppTheme.success),
    ('pump_off',    'Turn Pump OFF',   Icons.power_off_rounded,       AppTheme.danger),
    ('mode_auto',   'Switch to AUTO',  Icons.auto_mode_rounded,       AppTheme.accent),
    ('mode_manual', 'Switch MANUAL',   Icons.touch_app_rounded,       AppTheme.smartPurple),
    ('alert',       'Send Alert',      Icons.notifications_active_rounded, AppTheme.warning),
  ];

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  String get _valueSuffix {
    switch (_triggerType) {
      case 'level_below':
      case 'level_above':   return '%';
      case 'pump_on_mins':  return ' min';
      case 'time_of_day':   return ':00';
      default: return '';
    }
  }

  int get _valueMax => _triggerType == 'time_of_day' ? 23 : _triggerType == 'pump_on_mins' ? 120 : 100;
  int get _valueMin => 1;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_nameCtrl.text.trim(), _triggerType, _triggerValue, _actionType);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bg = widget.isDark ? AppTheme.darkCard : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppTheme.lightText;
    final subColor = widget.isDark ? Colors.white38 : AppTheme.lightTextSub;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(l10n.auto_new_title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Rule Name',
                labelStyle: TextStyle(color: subColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.smartPurple.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.smartPurple, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Trigger
            Row(children: [
              Container(width: 3, height: 16,
                  decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(l10n.auto_if_trigger, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accent)),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _triggers.map((t) {
                final selected = _triggerType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() {
                    _triggerType = t.$1;
                    _triggerValue = t.$1 == 'time_of_day' ? 6 : 20;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppTheme.accent : Colors.grey.withValues(alpha: 0.3),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t.$3, size: 15, color: selected ? AppTheme.accent : subColor),
                      const SizedBox(width: 6),
                      Text(t.$2, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? AppTheme.accent : subColor,
                      )),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Trigger value slider
            Row(children: [
              Text(
                _triggerType == 'time_of_day'
                    ? '${_triggerValue.toString().padLeft(2,'0')}:00'
                    : '$_triggerValue$_valueSuffix',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    thumbColor: AppTheme.accent,
                    activeTrackColor: AppTheme.accent,
                    inactiveTrackColor: AppTheme.accent.withValues(alpha: 0.2),
                    overlayColor: AppTheme.accent.withValues(alpha: 0.1),
                  ),
                  child: Slider(
                    value: _triggerValue.toDouble(),
                    min: _valueMin.toDouble(),
                    max: _valueMax.toDouble(),
                    divisions: _valueMax - _valueMin,
                    onChanged: (v) => setState(() => _triggerValue = v.round()),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 18),

            // Action
            Row(children: [
              Container(width: 3, height: 16,
                  decoration: BoxDecoration(color: AppTheme.smartPurple, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(l10n.auto_then_action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.smartPurple)),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _actions.map((a) {
                final selected = _actionType == a.$1;
                return GestureDetector(
                  onTap: () => setState(() => _actionType = a.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? a.$4.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? a.$4 : Colors.grey.withValues(alpha: 0.3),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(a.$3, size: 15, color: selected ? a.$4 : subColor),
                      const SizedBox(width: 6),
                      Text(a.$2, style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? a.$4 : subColor,
                      )),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // Save
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.smartPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(l10n.auto_save,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final bool isDark;
  const _InfoBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: isDark ? 0.1 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.memory_rounded, size: 16, color: AppTheme.accent.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Rules run on ESP32 device. Firmware v15+ required.',
            style: TextStyle(
              fontSize: 11, color: AppTheme.accent.withValues(alpha: isDark ? 0.8 : 0.7),
            ),
          ),
        ),
      ]),
    );
  }
}

class _EmptyRules extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;
  const _EmptyRules({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rule_rounded, size: 56,
                color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text(l10n.auto_empty_title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.lightText)),
            const SizedBox(height: 8),
            Text(l10n.auto_empty_sub,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: isDark ? Colors.white38 : AppTheme.lightTextSub)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: Text(l10n.auto_add_first, style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.smartPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDevice extends StatelessWidget {
  final bool isDark;
  const _NoDevice({required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(AppLocalizations.of(context).no_devices,
        style: TextStyle(color: isDark ? Colors.white38 : AppTheme.lightTextSub)),
  );
}

class _TitleBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget? action;
  const _TitleBar({required this.title, required this.isDark, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.smartPurple.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(children: [
        Text(title,
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.lightText,
              letterSpacing: 0.3,
            )),
        const Spacer(),
        if (action != null) action!,
      ]),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title, body;
  final bool isDark;
  const _ConfirmDialog({required this.title, required this.body, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.lightText, fontWeight: FontWeight.w700)),
      content: Text(body, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.lightTextSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.delete, style: const TextStyle(color: AppTheme.danger)),
        ),
      ],
    );
  }
}
