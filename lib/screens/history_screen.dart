// lib/screens/history_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v4.0.0 — History & Analytics (Local-First)
//
//  HISTORY:
//  ✅ LOCAL-FIRST — সব history Hive (ফোন স্টোরেজ)-এ সেভ হয়
//  ✅ Unlimited local entries (max 5000, auto-trim)
//  ✅ Firebase RTDB-এ শুধু critical events → Spark plan safe
//  ✅ 30-day chart (ছিল ৭ দিন)
//  ✅ Filter chips: All / Pump / Alert / Boot
//  ✅ Event search
//  ✅ Animated stats counters
//  ✅ Pull-to-refresh + infinite scroll
//  ✅ Donut chart + line chart
//  ✅ Cloud sync badge on events
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/device_service.dart';
import '../services/local_history_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../core/utils.dart';

class HistoryScreen extends StatefulWidget {
  final DeviceService deviceService;
  const HistoryScreen({super.key, required this.deviceService});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  List<HistoryEvent> _events = [];
  PumpStats _stats = PumpStats.empty;
  Map<DateTime, int> _chartData = {};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  static const int _pageSize = 30;
  String _activeFilter = 'all';
  String _searchQuery = '';
  bool _showSearch = false;
  late TabController _tabCtrl;
  late AnimationController _statsAnimCtrl;
  late Animation<double> _statsAnim;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _statsAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _statsAnim = CurvedAnimation(parent: _statsAnimCtrl, curve: Curves.easeOut);
    _scrollCtrl.addListener(_onScroll);
    _initialLoad();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _statsAnimCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }


  String _resolveError(String raw, AppLocalizations l10n) {
    if (raw.startsWith('hist_load_failed:')) {
      return l10n.hist_load_failed(raw.substring('hist_load_failed:'.length));
    }
    if (raw == 'hist_no_device' || raw.contains('ডিভাইস')) {
      return l10n.hist_no_device;
    }
    return raw;
  }

  Future<void> _initialLoad() async {
    setState(() { _loading = true; _error = null; });
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) {
      setState(() { _loading = false; _error = 'hist_no_device'; });
      return;
    }
    try {
      await _mergeCloud(deviceId);
      await _loadPage(reset: true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'hist_load_failed:$e'; _loading = false; });
    }
  }

  Future<void> _mergeCloud(String deviceId) async {
    try {
      final cloudEvents = await FirebaseService().getHistory(deviceId, limit: 200);
      final imported = await LocalHistoryService.mergeCloudEvents(deviceId, cloudEvents);
      if (imported > 0) debugPrint('[History] Merged $imported cloud events');
    } catch (_) {}
  }

  Future<void> _loadPage({bool reset = false}) async {
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) return;
    if (reset) setState(() { _offset = 0; _events = []; _hasMore = true; });
    final fetched = await LocalHistoryService.getEvents(deviceId, limit: _pageSize, offset: _offset, filterType: _activeFilter);
    final newStats = await LocalHistoryService.getPumpStats(deviceId);
    final chartData = await LocalHistoryService.getEventsByDay(deviceId);
    if (!mounted) return;
    setState(() {
      if (reset) { _events = fetched; } else { _events.addAll(fetched); }
      _stats = newStats;
      _chartData = chartData;
      _offset += fetched.length;
      _hasMore = fetched.length >= _pageSize;
      _loading = false;
      _loadingMore = false;
    });
    _statsAnimCtrl.forward(from: 0);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels > _scrollCtrl.position.maxScrollExtent - 200 && !_loadingMore && _hasMore) {
      setState(() => _loadingMore = true);
      _loadPage();
    }
  }

  void _setFilter(String f) {
    if (_activeFilter == f) return;
    setState(() { _activeFilter = f; _loading = true; });
    _loadPage(reset: true);
  }

  List<HistoryEvent> get _filteredEvents {
    if (_searchQuery.isEmpty) return _events;
    return _events.where((e) => e.event.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Future<void> _clearLocalHistory() async {
    final deviceId = widget.deviceService.selectedDeviceId;
    if (deviceId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).history_clear_title),
        content: Text(AppLocalizations.of(context).history_clear_msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context).cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed != true) return;
    await LocalHistoryService.clearDevice(deviceId);
    if (mounted) {
      AppUtils.showSnack(context, AppLocalizations.of(context).history_cleared);
      await _initialLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n  = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFEEF2FF),
      appBar: _buildAppBar(isDark),
      body: _loading
          ? _LoadingView(isDark: isDark)
          : _error != null
              ? _ErrorView(message: _resolveError(_error!, l10n), onRetry: _initialLoad)
              // [FIX] RefreshIndicator moved inside each tab — TabBarView must NOT
              // be the direct child of RefreshIndicator (causes layout exceptions).
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    RefreshIndicator(
                      onRefresh: _initialLoad,
                      color: AppTheme.primaryLight,
                      child: _EventsTab(
                        events: _filteredEvents,
                        isDark: isDark,
                        hasMore: _hasMore && _searchQuery.isEmpty,
                        loadingMore: _loadingMore,
                        scrollCtrl: _scrollCtrl,
                        stats: _stats,
                        statsAnim: _statsAnim,
                        activeFilter: _activeFilter,
                        onFilter: _setFilter,
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: _initialLoad,
                      color: AppTheme.primaryLight,
                      child: _AnalyticsTab(isDark: isDark, stats: _stats, chartData: _chartData, statsAnim: _statsAnim),
                    ),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      elevation: 0,
      title: _showSearch
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(hintText: AppLocalizations.of(context).search_events, hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38), border: InputBorder.none),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).history_analytics, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(AppLocalizations.of(context).hist_events_saved(_stats.totalEvents), style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
            ]),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) { _searchQuery = ''; _searchCtrl.clear(); }
          }),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (v) { if (v == 'clear') _clearLocalHistory(); if (v == 'refresh') _initialLoad(); },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'refresh', child: Row(children: [const Icon(Icons.refresh_rounded, size: 18), const SizedBox(width: 8), Text(AppLocalizations.of(context).refresh)])),
            PopupMenuItem(value: 'clear', child: Row(children: [const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text(AppLocalizations.of(context).clear_history, style: const TextStyle(color: Colors.redAccent))])),
          ],
        ),
      ],
      bottom: TabBar(
        controller: _tabCtrl,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        tabs: [
          Tab(icon: const Icon(Icons.list_alt_rounded, size: 20), text: AppLocalizations.of(context).tab_events),
          Tab(icon: const Icon(Icons.analytics_rounded, size: 20), text: AppLocalizations.of(context).tab_analytics),
        ],
      ),
    );
  }
}

// ── Events Tab ────────────────────────────────────────────────────────────────

class _EventsTab extends StatelessWidget {
  final List<HistoryEvent> events;
  final bool isDark, hasMore, loadingMore;
  final ScrollController scrollCtrl;
  final PumpStats stats;
  final Animation<double> statsAnim;
  final String activeFilter;
  final ValueChanged<String> onFilter;
  const _EventsTab({required this.events, required this.isDark, required this.hasMore, required this.loadingMore, required this.scrollCtrl, required this.stats, required this.statsAnim, required this.activeFilter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _AnimatedStatsRow(stats: stats, isDark: isDark, anim: statsAnim),
        const SizedBox(height: 12),
        _FilterChips(active: activeFilter, onFilter: onFilter, isDark: isDark),
        const SizedBox(height: 14),
        if (events.isEmpty)
          _EmptyState(isDark: isDark)
        else ...[
          ...events.map((e) => _EventTile(event: e, isDark: isDark)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: loadingMore
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Center(child: Text(
                    hasMore ? AppLocalizations.of(context).hist_scroll_more : AppLocalizations.of(context).hist_all_seen,
                    style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12))),
          ),
        ],
      ],
    );
  }
}

// ── Analytics Tab ─────────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  final bool isDark;
  final PumpStats stats;
  final Map<DateTime, int> chartData;
  final Animation<double> statsAnim;
  const _AnalyticsTab({required this.isDark, required this.stats, required this.chartData, required this.statsAnim});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppTheme.darkSurface : Colors.white;
    if (stats.totalEvents == 0) return _EmptyState(isDark: isDark);
    final sortedDays = chartData.keys.toList()..sort();
    final spots = sortedDays.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (chartData[e.value] ?? 0).toDouble())).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(children: [
        _StorageBanner(isDark: isDark, totalEvents: stats.totalEvents),
        const SizedBox(height: 16),
        _FullStatsGrid(stats: stats, isDark: isDark, anim: statsAnim),
        const SizedBox(height: 16),
        _ChartCard(isDark: isDark, surface: surface, title: AppLocalizations.of(context).events_last_30, icon: Icons.show_chart_rounded,
            child: _LineChartWidget(spots: spots, sortedDays: sortedDays, isDark: isDark)),
        const SizedBox(height: 14),
        _ChartCard(isDark: isDark, surface: surface, title: AppLocalizations.of(context).event_by_type, icon: Icons.donut_large_rounded,
            child: _DonutChart(stats: stats, isDark: isDark)),
        const SizedBox(height: 14),
        _PumpRuntimeCard(stats: stats, isDark: isDark, surface: surface),
      ]),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _StorageBanner extends StatelessWidget {
  final bool isDark;
  final int totalEvents;
  const _StorageBanner({required this.isDark, required this.totalEvents});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryLight.withValues(alpha: 0.15), AppTheme.accent.withValues(alpha: 0.08)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.storage_rounded, color: AppTheme.primaryLight, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppLocalizations.of(context).hist_events_count(totalEvents), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryLight)),
          Text(AppLocalizations.of(context).firebase_sync_note, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
        ])),
        const Icon(Icons.cloud_done_rounded, color: AppTheme.success, size: 18),
      ]),
    );
  }
}

class _AnimatedStatsRow extends StatelessWidget {
  final PumpStats stats;
  final bool isDark;
  final Animation<double> anim;
  const _AnimatedStatsRow({required this.stats, required this.isDark, required this.anim});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Row(children: [
        _MiniStat(label: AppLocalizations.of(context).hist_stat_total, value: (stats.totalEvents * anim.value).round(), icon: Icons.event_note_rounded, color: AppTheme.primaryLight, isDark: isDark),
        const SizedBox(width: 8),
        _MiniStat(label: AppLocalizations.of(context).hist_stat_pump_on, value: (stats.pumpOnCount * anim.value).round(), icon: Icons.power_rounded, color: AppTheme.success, isDark: isDark),
        const SizedBox(width: 8),
        _MiniStat(label: AppLocalizations.of(context).hist_stat_alert, value: ((stats.alarmCount + stats.dryRunCount) * anim.value).round(), icon: Icons.warning_amber_rounded, color: AppTheme.warning, isDark: isDark),
        const SizedBox(width: 8),
        _MiniStat(label: AppLocalizations.of(context).hist_stat_low, value: (stats.lowLevelCount * anim.value).round(), icon: Icons.water_drop_outlined, color: AppTheme.danger, isDark: isDark),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _MiniStat({required this.label, required this.value, required this.icon, required this.color, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text('$value', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String active;
  final ValueChanged<String> onFilter;
  final bool isDark;
  const _FilterChips({required this.active, required this.onFilter, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = [('all', l10n.hist_filter_all, Icons.all_inclusive_rounded), ('pump', l10n.hist_stat_pump_on, Icons.power_rounded), ('alert', l10n.hist_stat_alert, Icons.warning_amber_rounded), ('boot', 'Boot', Icons.devices_rounded)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: filters.map((f) {
        final isActive = active == f.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onFilter(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryLight : (isDark ? AppTheme.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? AppTheme.primaryLight : (isDark ? Colors.white12 : Colors.black12)),
              ),
              child: Row(children: [
                Icon(f.$3, size: 14, color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54)),
                const SizedBox(width: 5),
                Text(f.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54))),
              ]),
            ),
          ),
        );
      }).toList()),
    );
  }
}

class _EventTile extends StatelessWidget {
  final HistoryEvent event;
  final bool isDark;
  const _EventTile({required this.event, required this.isDark});

  ({IconData icon, Color color}) _info(String e) {
    if (e.contains('pump on') || e.contains('pump_on')) return (icon: Icons.power, color: AppTheme.success);
    if (e.contains('pump off') || e.contains('pump_off')) return (icon: Icons.power_off, color: Colors.grey);
    if (e.contains('mode')) return (icon: Icons.autorenew, color: AppTheme.accent);
    if (e.contains('low') || e.contains('empty')) return (icon: Icons.water_drop_outlined, color: AppTheme.danger);
    if (e.contains('full')) return (icon: Icons.water, color: AppTheme.primaryLight);
    if (e.contains('dry')) return (icon: Icons.warning_amber, color: AppTheme.warning);
    if (e.contains('alarm')) return (icon: Icons.notifications_active_rounded, color: AppTheme.danger);
    if (e.contains('boot') || e.contains('register')) return (icon: Icons.devices, color: AppTheme.primaryLight);
    if (e.contains('ota') || e.contains('update')) return (icon: Icons.system_update, color: AppTheme.success);
    return (icon: Icons.info_outline, color: AppTheme.accent);
  }

  String _timeAgo(DateTime dt, AppLocalizations l10n) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.hist_just_now;
    if (diff.inMinutes < 60) return l10n.hist_minutes_ago(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hist_hours_ago(diff.inHours);
    if (diff.inDays < 7) return l10n.hist_days_ago(diff.inDays);
    return DateFormat('dd MMM, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final info = _info(event.event.toLowerCase());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: info.color.withValues(alpha: 0.12),
          child: Icon(info.icon, color: info.color, size: 18),
        ),
        title: Text(event.event, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
        subtitle: Row(children: [
          Icon(Icons.access_time_rounded, size: 11, color: isDark ? Colors.white38 : Colors.black38),
          const SizedBox(width: 3),
          Text('${_timeAgo(event.dateTime, AppLocalizations.of(context))}  ·  ${DateFormat('dd MMM, HH:mm').format(event.dateTime)}',
              style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.black38)),
        ]),
        trailing: event.isCloudSynced
            ? Tooltip(message: 'Firebase sync', child: Icon(Icons.cloud_done_rounded, size: 14, color: AppTheme.success.withValues(alpha: 0.7)))
            : Tooltip(message: AppLocalizations.of(context).hist_saved_phone, child: Icon(Icons.phone_android_rounded, size: 14, color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.24))),
      ),
    );
  }
}

class _FullStatsGrid extends StatelessWidget {
  final PumpStats stats;
  final bool isDark;
  final Animation<double> anim;
  const _FullStatsGrid({required this.stats, required this.isDark, required this.anim});
  @override
  Widget build(BuildContext context) {
    final items = [
      (AppLocalizations.of(context).hist_grid_total, stats.totalEvents, Icons.event_note_rounded, AppTheme.primaryLight),
      (AppLocalizations.of(context).hist_grid_pump_on, stats.pumpOnCount, Icons.power_rounded, AppTheme.success),
      (AppLocalizations.of(context).hist_grid_pump_off, stats.pumpOffCount, Icons.power_off_rounded, Colors.grey),
      (AppLocalizations.of(context).hist_grid_low, stats.lowLevelCount, Icons.water_drop_outlined, AppTheme.danger),
      (AppLocalizations.of(context).hist_grid_dry, stats.dryRunCount, Icons.warning_amber_rounded, AppTheme.warning),
      (AppLocalizations.of(context).hist_grid_alarm, stats.alarmCount, Icons.notifications_active_rounded, Colors.deepOrange),
    ];
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => GridView.count(
        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
        children: items.map((item) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.$4.withValues(alpha: 0.2)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(item.$3, color: item.$4, size: 22),
              const SizedBox(height: 6),
              Text('${(item.$2 * anim.value).round()}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: isDark ? Colors.white : Colors.black87)),
              Text(item.$1, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final bool isDark;
  final Color surface;
  final String title;
  final IconData icon;
  final Widget child;
  const _ChartCard({required this.isDark, required this.surface, required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: AppTheme.primaryLight),
          const SizedBox(width: 7),
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final List<FlSpot> spots;
  final List<DateTime> sortedDays;
  final bool isDark;
  const _LineChartWidget({required this.spots, required this.sortedDays, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white38 : Colors.black38;
    if (spots.isEmpty) return SizedBox(height: 140, child: Center(child: Text(AppLocalizations.of(context).no_data)));
    return SizedBox(
      height: 160,
      child: LineChart(LineChartData(
        gridData: FlGridData(getDrawingHorizontalLine: (_) => FlLine(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 26, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 9, color: textColor)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 7, getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= sortedDays.length) return const SizedBox.shrink();
            return Text(DateFormat('dd/MM').format(sortedDays[i]), style: TextStyle(fontSize: 8, color: textColor));
          })),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.4,
          color: AppTheme.primaryLight,
          barWidth: 2.5,
          dotData: FlDotData(getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(radius: 3, color: spot.y > 0 ? AppTheme.primaryLight : Colors.transparent)),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppTheme.primaryLight.withValues(alpha: 0.2), AppTheme.primaryLight.withValues(alpha: 0.0)])),
        )],
      )),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final PumpStats stats;
  final bool isDark;
  const _DonutChart({required this.stats, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final sections = <PieChartSectionData>[];
    final legend = <({String label, int count, Color color})>[];
    void add(String label, int value, Color color) {
      if (value <= 0) return;
      sections.add(PieChartSectionData(color: color, value: value.toDouble(), radius: 44, title: '$value', titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)));
      legend.add((label: label, count: value, color: color));
    }
    add('Pump ON', stats.pumpOnCount, AppTheme.success);
    add('Pump OFF', stats.pumpOffCount, Colors.grey);
    add('Low Level', stats.lowLevelCount, AppTheme.danger);
    add('Dry Run', stats.dryRunCount, AppTheme.warning);
    add('Alarm', stats.alarmCount, Colors.deepOrange);
    if (sections.isEmpty) return Center(child: Text(AppLocalizations.of(context).no_data));
    return Row(children: [
      SizedBox(height: 130, width: 130, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 30, sectionsSpace: 2, startDegreeOffset: -90))),
      const SizedBox(width: 20),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: legend.map((l) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: l.color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 7),
          Expanded(child: Text(l.label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7)))),
          Text('${l.count}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      )).toList())),
    ]);
  }
}

class _PumpRuntimeCard extends StatelessWidget {
  final PumpStats stats;
  final bool isDark;
  final Color surface;
  const _PumpRuntimeCard({required this.stats, required this.isDark, required this.surface});
  String get _efficiency {
    final total = stats.pumpOnCount + stats.pumpOffCount;
    if (total == 0) return 'N/A';
    return '${(stats.pumpOnCount / total * 100).round()}%';
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.water_damage_rounded, size: 16, color: AppTheme.accent),
          const SizedBox(width: 7),
          Text(AppLocalizations.of(context).pump_overview, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _OvItem(label: 'ON cycles', value: '${stats.pumpOnCount}', isDark: isDark),
          _Sep(), _OvItem(label: 'OFF cycles', value: '${stats.pumpOffCount}', isDark: isDark),
          _Sep(), _OvItem(label: 'ON ratio', value: _efficiency, isDark: isDark),
          _Sep(), _OvItem(label: 'Dry runs', value: '${stats.dryRunCount}', isDark: isDark, danger: stats.dryRunCount > 0),
        ]),
      ]),
    );
  }
}

class _OvItem extends StatelessWidget {
  final String label, value;
  final bool isDark;
  final bool danger;
  const _OvItem({required this.label, required this.value, required this.isDark, this.danger = false});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: danger && value != '0' ? AppTheme.danger : (isDark ? Colors.white : Colors.black87))),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey), textAlign: TextAlign.center),
    ]));
  }
}

class _Sep extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(height: 30, width: 1, color: Colors.grey.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.history_toggle_off_rounded, size: 56, color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.24)),
      const SizedBox(height: 14),
      Text(AppLocalizations.of(context).no_events, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
      const SizedBox(height: 6),
      Text(AppLocalizations.of(context).events_hint, style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12)),
    ]),
  );
}

class _LoadingView extends StatelessWidget {
  final bool isDark;
  const _LoadingView({required this.isDark});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircularProgressIndicator(strokeWidth: 2.5),
    const SizedBox(height: 16),
    Text(AppLocalizations.of(context).history_loading, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
  ]));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
    const SizedBox(height: 12),
    Text(message, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
    const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(AppLocalizations.of(context).try_again), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryLight, foregroundColor: Colors.white)),
  ]));
}
