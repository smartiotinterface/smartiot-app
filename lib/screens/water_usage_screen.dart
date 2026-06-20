// lib/screens/water_usage_screen.dart
// SmartIoT v4.0.0 — Water Usage / Consumption Tracking
// Calculates: pump_total_seconds × flow_rate_lpm → liters
// Data source: LocalHistoryService (already tracks pump events)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/device_service.dart';
import '../services/local_history_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class WaterUsageScreen extends StatefulWidget {
  final DeviceService deviceService;
  const WaterUsageScreen({super.key, required this.deviceService});
  @override State<WaterUsageScreen> createState() => _WaterUsageScreenState();
}

class _WaterUsageScreenState extends State<WaterUsageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool _loading = true;

  // Pump flow rate (liters per minute) — editable per-device
  double _flowRateLpm = 15.0;  // typical 0.5HP pump

  // Stats derived from pumpTotalSeconds in RTDB status
  int    _totalPumpSeconds = 0;
  int    _todayPumpSeconds = 0;
  int    _weekPumpSeconds  = 0;

  // Daily chart data (last 7 days)
  List<_DayUsage> _weekData  = [];
  // Monthly chart data (last 30 days)
  List<_DayUsage> _monthData = [];

  // Calibration capacity
  int _capacityL = 0;

  @override void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) { setState(() => _loading = false); return; }

    try {
      // Get flow rate + capacity from calibration
      final cal = await FirebaseService().getCalibration(deviceId);
      if (cal != null) {
        _capacityL = ((cal['capacity_liters'] ?? 0) as num).toInt();
        final savedFlow = cal['flow_rate_lpm'];
        if (savedFlow != null) _flowRateLpm = (savedFlow as num).toDouble();
      }

      // Get total pump runtime from device status
      final status = widget.deviceService.status;
      _totalPumpSeconds = status?.pumpTotalSeconds ?? 0;

      // Build daily usage from history events
      final events = await LocalHistoryService.getEvents(deviceId, limit: 500);
      final now   = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Group pump_on/pump_off events to calculate runtime per day
      final Map<String, int> dailySeconds = {};

      DateTime? pumpOnTime;
      for (final ev in events.reversed) {  // oldest first
        final ts   = DateTime.fromMillisecondsSinceEpoch(ev.ts);
        final date = '${ts.year}-${ts.month.toString().padLeft(2,'0')}-${ts.day.toString().padLeft(2,'0')}';
        if (ev.event.toLowerCase().contains('pump on') || ev.event.toLowerCase().contains('pump_on')) {
          pumpOnTime = ts;
        } else if ((ev.event.toLowerCase().contains('pump off') || ev.event.toLowerCase().contains('pump_off')) && pumpOnTime != null) {
          final dur = ts.difference(pumpOnTime).inSeconds;
          dailySeconds[date] = (dailySeconds[date] ?? 0) + dur;
          pumpOnTime = null;
        }
      }

      // Today's pump seconds
      final todayKey = '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';
      _todayPumpSeconds = dailySeconds[todayKey] ?? 0;
      // This week
      _weekPumpSeconds = 0;
      for (int i = 0; i < 7; i++) {
        final d = today.subtract(Duration(days: i));
        final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        _weekPumpSeconds += dailySeconds[k] ?? 0;
      }

      // Build week chart (7 days)
      _weekData = List.generate(7, (i) {
        final d = today.subtract(Duration(days: 6 - i));
        final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        return _DayUsage(date: d, seconds: dailySeconds[k] ?? 0);
      });

      // Build month chart (30 days)
      _monthData = List.generate(30, (i) {
        final d = today.subtract(Duration(days: 29 - i));
        final k = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        return _DayUsage(date: d, seconds: dailySeconds[k] ?? 0);
      });

    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  double _toLiters(int seconds) => (seconds / 60) * _flowRateLpm;

  Future<void> _editFlowRate() async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: _flowRateLpm.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.usage_flow_rate_title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l10n.usage_flow_rate_hint,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.usage_flow_rate_label,
              suffixText: 'L/min',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.usage_flow_hint,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v != null && v > 0) Navigator.pop(ctx, v);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _flowRateLpm = result);
      // Save to Firebase meta
      final deviceId = widget.deviceService.selectedDeviceId;
      if (deviceId != null) {
        await FirebaseService().saveFlowRate(deviceId, result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalL  = _toLiters(_totalPumpSeconds);
    final todayL  = _toLiters(_todayPumpSeconds);
    final weekL   = _toLiters(_weekPumpSeconds);
    final monthL  = _weekData.fold(0.0, (s, d) => s + _toLiters(d.seconds))
        + _monthData.fold(0.0, (s, d) => s + _toLiters(d.seconds));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(l10n.usage_title),
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        foregroundColor: isDark ? Colors.white : AppTheme.primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _editFlowRate,
            icon: const Icon(Icons.tune_rounded),
            tooltip: l10n.usage_flow_rate_title,
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryLight,
          tabs: [Tab(text: l10n.usage_tab_week), Tab(text: l10n.usage_tab_month)],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _UsageTab(
                  data:      _weekData,
                  todayL:    todayL,
                  periodL:   weekL,
                  totalL:    totalL,
                  flowRate:  _flowRateLpm,
                  capacityL: _capacityL,
                  periodLabel: l10n.usage_this_week,
                  isDark:    isDark,
                  l10n:      l10n,
                  toLiters:  _toLiters,
                  onTap:     _editFlowRate,
                ),
                _UsageTab(
                  data:      _monthData,
                  todayL:    todayL,
                  periodL:   monthL,
                  totalL:    totalL,
                  flowRate:  _flowRateLpm,
                  capacityL: _capacityL,
                  periodLabel: l10n.usage_this_month,
                  isDark:    isDark,
                  l10n:      l10n,
                  toLiters:  _toLiters,
                  onTap:     _editFlowRate,
                ),
              ],
            ),
    );
  }
}

class _DayUsage { final DateTime date; final int seconds;
  _DayUsage({required this.date, required this.seconds}); }

class _UsageTab extends StatelessWidget {
  final List<_DayUsage> data;
  final double todayL, periodL, totalL, flowRate;
  final int capacityL;
  final String periodLabel;
  final bool isDark;
  final AppLocalizations l10n;
  final double Function(int) toLiters;
  final VoidCallback onTap;
  const _UsageTab({required this.data, required this.todayL, required this.periodL,
    required this.totalL, required this.flowRate, required this.capacityL,
    required this.periodLabel, required this.isDark, required this.l10n,
    required this.toLiters, required this.onTap});

  @override Widget build(BuildContext context) {
    final maxL = data.isEmpty ? 1.0
        : data.map((d) => toLiters(d.seconds)).reduce((a,b) => a>b?a:b).clamp(1.0, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Stats row
        Row(children: [
          _StatCard(l10n.usage_today,    '${todayL.toStringAsFixed(0)} L', Icons.today, AppTheme.primaryLight, isDark),
          const SizedBox(width: 10),
          _StatCard(periodLabel,          '${periodL.toStringAsFixed(0)} L', Icons.bar_chart, AppTheme.accent, isDark),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _StatCard(l10n.usage_total,    '${(totalL/1000).toStringAsFixed(1)} kL', Icons.water, AppTheme.success, isDark),
          const SizedBox(width: 10),
          _StatCard(l10n.usage_flow_rate, '${flowRate.toStringAsFixed(0)} L/min', Icons.speed, AppTheme.warning, isDark,
            onTap: onTap),
        ]),
        const SizedBox(height: 20),

        // Bar chart
        if (data.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.usage_daily_chart, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: BarChart(BarChartData(
                  maxY: maxL * 1.2,
                  gridData: FlGridData(
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07))),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}L', style: const TextStyle(fontSize: 9)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= data.length) return const SizedBox();
                        final d = data[i].date;
                        if (data.length <= 7) return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 9));
                        return i % 5 == 0 ? Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 9)) : const SizedBox();
                      })),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  barGroups: data.asMap().entries.map((e) {
                    final liters = toLiters(e.value.seconds);
                    final isToday = e.value.date.day == DateTime.now().day
                        && e.value.date.month == DateTime.now().month;
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(
                        toY: liters,
                        color: isToday ? AppTheme.primaryLight : AppTheme.primaryBlue.withValues(alpha: 0.6),
                        width: data.length <= 7 ? 22 : 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ]);
                  }).toList(),
                )),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // Tank fill counter
        if (capacityL > 0) ...[
          _TankFillCard(periodL: periodL, capacityL: capacityL, isDark: isDark, l10n: l10n),
          const SizedBox(height: 16),
        ],

        // Flow rate note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.usage_estimate_note,
                style: const TextStyle(fontSize: 12, color: AppTheme.warning))),
          ]),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value; final IconData icon;
  final Color color; final bool isDark; final VoidCallback? onTap;
  const _StatCard(this.label, this.value, this.icon, this.color, this.isDark, {this.onTap});
  @override Widget build(BuildContext context) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis)),
          if (onTap != null) const Icon(Icons.edit, size: 12, color: Colors.grey),
        ]),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  ));
}

class _TankFillCard extends StatelessWidget {
  final double periodL; final int capacityL;
  final bool isDark; final AppLocalizations l10n;
  const _TankFillCard({required this.periodL, required this.capacityL,
    required this.isDark, required this.l10n});
  @override Widget build(BuildContext context) {
    final fills = capacityL > 0 ? (periodL / capacityL) : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.water_drop_outlined, color: AppTheme.accent, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(
          '${l10n.usage_tank_fills}: ${fills.toStringAsFixed(1)}× ($capacityL L tank)',
          style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.accent, fontSize: 13),
        )),
      ]),
    );
  }
}
