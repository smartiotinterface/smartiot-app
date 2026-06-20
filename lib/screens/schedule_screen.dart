// lib/screens/schedule_screen.dart
// [FIX H-4 / F-2] Pump Schedule UI — Firebase CRUD implemented, UI was missing
// Allows users to add, toggle, and delete time-based pump schedules.

import 'package:flutter/material.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../core/utils.dart';

class ScheduleScreen extends StatefulWidget {
  final DeviceService deviceService;
  const ScheduleScreen({super.key, required this.deviceService});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) {
      setState(() { _loading = false; _error = AppLocalizations.of(context).no_devices; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final fb = FirebaseService();
      final list = await fb.getSchedules(deviceId);
      if (!mounted) return;
      setState(() { _schedules = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = AppLocalizations.of(context).failed; _loading = false; });
    }
  }

  Future<void> _delete(String scheduleId) async {
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) return;
    try {
      await FirebaseService().deleteSchedule(deviceId, scheduleId);
      setState(() => _schedules.removeWhere((s) => s['id'] == scheduleId));
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).schedule_deleted);
    } catch (_) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).schedule_delete_failed, isError: true);
    }
  }

  // [FIX] Toggle schedule active/inactive without deleting
  Future<void> _toggle(String scheduleId, bool currentActive) async {
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) return;
    final newActive = !currentActive;
    try {
      await FirebaseService().saveSchedule(deviceId, scheduleId, {'active': newActive, 'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000});
      setState(() {
        final idx = _schedules.indexWhere((s) => s['id'] == scheduleId);
        if (idx >= 0) _schedules[idx] = {..._schedules[idx], 'active': newActive};
      });
    } catch (_) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).failed, isError: true);
    }
  }

  Future<void> _showAddDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'SELECT PUMP START TIME',
    );
    if (picked == null || !mounted) return;

    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) return;

    // Ask for duration
    final int? durationMin = await _askDuration();
    if (durationMin == null || !mounted) return;

    // Ask for repeat days
    final List<int> days = await _askRepeatDays() ?? [1,2,3,4,5,6,7];
    if (!mounted) return;

    final scheduleId = 'sched_${DateTime.now().millisecondsSinceEpoch}';
    final data = {
      'hour':         picked.hour,
      'minute':       picked.minute,
      'duration_min': durationMin,
      'days':         days,
      'active':       true,
      'ts':           DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    try {
      await FirebaseService().saveSchedule(deviceId, scheduleId, data);
      setState(() => _schedules.add({'id': scheduleId, ...data}));
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).schedule_saved);
    } catch (_) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).schedule_save_failed, isError: true);
    }
  }

  Future<int?> _askDuration() {
    int selected = 15;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text(AppLocalizations.of(context).pump_duration),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).pump_duration_question),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: selected,
                items: [5, 10, 15, 20, 30, 45, 60]
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text('$m minutes'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDlgState(() => selected = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context).cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: Text(AppLocalizations.of(context).confirm),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<int>?> _askRepeatDays() async {
    const dayNamesEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayNamesBn = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি', 'রবি'];
    List<int> selected = [1, 2, 3, 4, 5, 6, 7];
    return showDialog<List<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final isBn = Localizations.localeOf(context).languageCode == 'bn';
          final names = isBn ? dayNamesBn : dayNamesEn;
          return AlertDialog(
            title: const Text('Repeat Days'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Which days should this schedule run?',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final on = selected.contains(day);
                    return FilterChip(
                      label: Text(names[i], style: const TextStyle(fontSize: 12)),
                      selected: on,
                      onSelected: (v) => setDlg(() {
                        if (v) { selected.add(day); selected.sort(); }
                        else if (selected.length > 1) { selected.remove(day); }
                      }),
                      selectedColor: AppTheme.primaryLight.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primaryLight,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => setDlg(() => selected = [1,2,3,4,5,6,7]),
                  icon: const Icon(Icons.select_all, size: 14),
                  label: const Text('Every day', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: Text(AppLocalizations.of(context).confirm),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).pump_schedules_title),
        backgroundColor:
            isDark ? AppTheme.darkSurface : AppTheme.lightCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_alarm_rounded),
        label: Text(AppLocalizations.of(context).add_schedule),
        backgroundColor: AppTheme.primaryLight,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _schedules.isEmpty
                  ? _EmptyView(onAdd: _showAddDialog)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _schedules.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final s = _schedules[i];
                          return _ScheduleCard(
                            schedule: s,
                            isDark: isDark,
                            timeLabel:
                                _fmt(s['hour'] as int, s['minute'] as int),
                            onDelete: () => _delete(s['id'] as String),
                            onToggle: () => _toggle(s['id'] as String, s['active'] == true),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ── Schedule card widget ───────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final bool isDark;
  final String timeLabel;
  final VoidCallback onDelete;
  final VoidCallback onToggle;  // [FIX] Toggle active/inactive

  const _ScheduleCard({
    required this.schedule,
    required this.isDark,
    required this.timeLabel,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = schedule['active'] == true;
    final int duration = (schedule['duration_min'] as int?) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? AppTheme.primaryLight.withValues(alpha: 0.4)
              : (isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: enabled
              ? AppTheme.primaryLight.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.12),
          child: Icon(
            Icons.alarm_rounded,
            color: enabled ? AppTheme.primaryLight : Colors.grey,
          ),
        ),
        title: Text(
          timeLabel,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: enabled
                ? (isDark ? Colors.white : Colors.black87)
                : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).schedule_summary(duration,
                  enabled ? AppLocalizations.of(context).schedule_enabled
                           : AppLocalizations.of(context).schedule_disabled),
              style: TextStyle(fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54),
            ),
            if (schedule['days'] != null &&
                (schedule['days'] is List ? (schedule['days'] as List).length : 0) < 7) ...[
              const SizedBox(height: 4),
              _DaysRow(days: schedule['days'] is List ? List<int>.from(schedule['days'] as List) : []),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // [FIX] Toggle switch
            Switch(
              value: enabled,
              onChanged: (_) => onToggle(),
              activeThumbColor: AppTheme.primaryLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              tooltip: 'Delete schedule',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm_off_rounded,
                size: 64, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).no_schedules,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Add a schedule to automatically turn the pump ON at a set time each day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_alarm_rounded),
              label: Text(AppLocalizations.of(context).add_first_schedule),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Days row widget ────────────────────────────────────────────────────────

class _DaysRow extends StatelessWidget {
  final List<int> days;
  const _DaysRow({required this.days});

  static const _names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: List.generate(7, (i) {
        final day = i + 1;
        final on = days.contains(day);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: on
                ? AppTheme.primaryLight.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: on
                  ? AppTheme.primaryLight.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            _names[i],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: on ? AppTheme.primaryLight : Colors.grey,
            ),
          ),
        );
      }),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }
}
