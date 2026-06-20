// lib/screens/dashboard_screen.dart
// SmartIoT v7.0.0 — Tuya-Style UI (matching screenshots)
// ✅ Blurred room background
// SmartIoT v8.0.0 — 5-tab: Devices | Schedules | Scenes ✅ | Automations ✅ | Settings
// ✅ Purple accent #7C61D4
// ✅ Frosted glass cards + empty state illustration
// ✅ All existing device monitoring functionality preserved

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../core/utils.dart';

import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/tank_widget.dart';
import '../widgets/control_panel.dart';
import '../widgets/premium_widgets.dart';
import 'login_screen.dart';
import 'device_setup_screen.dart';

import 'settings_screen.dart';
import 'schedule_screen.dart';
import 'scenes_screen.dart';
import 'automations_screen.dart';
import 'history_screen.dart';

// ════════════════════════════════════════════════════════════════
//  DashboardScreen — root with 5-tab Tuya-style navigation
// ════════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late DeviceService _deviceService;
  int _navIndex = 0;
  late AnimationController _headerCtrl;

  // [FIX CRASH-1] Tracks whether _deviceService/_headerCtrl were actually
  // initialized. Without this, an invalid auth state (uid null) left both
  // `late` fields unset — but build() and dispose() touched them
  // unconditionally before the postFrameCallback redirect could run,
  // causing a LateInitializationError crash instead of a clean redirect.
  bool _authValid = true;

  // [FIX BUG-3] Allows child widgets to switch tabs programmatically
  set navIndex(int i) => setState(() => _navIndex = i);

  @override
  void initState() {
    super.initState();
    // [FIX HIGH-1] Guard against null/empty uid — redirect to login if auth state invalid
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      _authValid = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
      return;
    }
    _deviceService = DeviceService(
      uid: uid,
      firebaseService: context.read<FirebaseService>(),
    );
    _deviceService.loadDevices();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    // [FIX CRASH-1] Only dispose fields that initState() actually created.
    if (_authValid) {
      _deviceService.dispose();
      _headerCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.logout, color: AppTheme.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Text(l10n.sign_out),
        ]),
        content: Text(l10n.sign_out_confirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.sign_out,
                  style: const TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthService>();
    final navigator = Navigator.of(context);
    await auth.logout();
    if (mounted) {
      navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false);
    }
  }

  void _openDeviceSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: _deviceService,
          child: const DeviceSetupScreen(),
        ),
      ),
    ).then((_) {
      if (mounted) _deviceService.loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    // [FIX CRASH-1] Auth invalid (uid was null in initState) — postFrameCallback
    // is about to redirect to LoginScreen. Return a blank frame instead of
    // touching the uninitialized _deviceService/_headerCtrl late fields.
    if (!_authValid) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final isDark = context.watch<ThemeNotifier>().isDark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
    return ChangeNotifierProvider.value(
      value: _deviceService,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const _RoomBackground(),
            SafeArea(
              bottom: false,
              child: _buildPage(),
            ),
          ],
        ),
        bottomNavigationBar: _TuyaBottomNav(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_navIndex) {
      case 0:
        return _DevicesPage(
            deviceService: _deviceService,
            onAddDevice: _openDeviceSetup);
      case 1:
        return _deviceService.hasDevice
            ? ScheduleScreen(deviceService: _deviceService)
            : _NoDevicePage(onAdd: _openDeviceSetup, title: 'Schedules');
      case 2:
        return _deviceService.hasDevice
            ? ScenesScreen(deviceService: _deviceService)
            : _NoDevicePage(onAdd: _openDeviceSetup, title: 'Scenes');
      case 3:
        return _deviceService.hasDevice
            ? AutomationsScreen(deviceService: _deviceService)
            : _NoDevicePage(onAdd: _openDeviceSetup, title: 'Automations');
      case 4:
        return SettingsScreen(
            deviceService: _deviceService, onLogout: _logout);
      default:
        return _DevicesPage(
            deviceService: _deviceService,
            onAddDevice: _openDeviceSetup);
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  _DevicesPage — "My Devices" (tab 0) — matches screenshot 1
// ════════════════════════════════════════════════════════════════
class _DevicesPage extends StatelessWidget {
  final DeviceService deviceService;
  final VoidCallback onAddDevice;

  const _DevicesPage(
      {required this.deviceService,
      required this.onAddDevice});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TuyaTitleBar(
          title: 'My Devices',
          trailing: _UserAvatarBtn(onTap: () {
            // [FIX BUG-3] Navigate to Settings tab
            final scaffold = context.findAncestorStateOfType<_DashboardScreenState>();
            scaffold?.navIndex = 4;
          }),
        ),

        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 6),
          child: Builder(builder: (ctx) {
            final isDark = ctx.watch<ThemeNotifier>().isDark;
            return Row(
              children: [
                Text(
                  'All Devices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.lightText,
                    decoration: TextDecoration.underline,
                    decorationColor: isDark ? Colors.white : AppTheme.lightText,
                    decorationThickness: 1.5,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (_) => Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 1.5),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white54 : AppTheme.lightTextSub),
                      ),
                    ),
                  ),
                  // [FIX BUG-6] Was a no-op — now shows informative snackbar until feature ships
                  onSelected: (val) {
                    AppUtils.showSnack(
                      context,
                      val == 'sort' ? 'Sort: coming in next update' : 'Group View: coming in next update',
                    );
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'sort', child: Text('Sort Devices')),
                    PopupMenuItem(value: 'group', child: Text('Group View')),
                  ],
                ),
              ],
            );
          }),
        ),

        // Content
        if (device.isLoading)
          const Expanded(child: _LoadingState())
        else if (!device.hasDevice)
          Expanded(child: _TuyaEmptyState(onAdd: onAddDevice))
        else
          Expanded(child: _DeviceDashboardBody(device: device)),

        // Add Device button
        _TuyaAddButton(label: l10n.dash_add_device, onTap: onAddDevice),
        const SizedBox(height: 88),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  _TuyaEmptyState — "No Device Added" — matches screenshot 1
// ════════════════════════════════════════════════════════════════
class _TuyaEmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _TuyaEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 170,
          height: 155,
          child: CustomPaint(painter: _BoxIllustrationPainter(isDark: isDark)),
        ),
        const SizedBox(height: 20),
        Text(
          'No Device Added',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : AppTheme.lightTextSub,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          // [FIX BUG-5] Was a no-op onTap: () {} — now actually reloads device list
          onTap: () => context.read<DeviceService>().loadDevices(),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.refresh_rounded,
                size: 26,
                color: isDark ? Colors.white24 : AppTheme.smartPurple.withValues(alpha: 0.25)),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PurpleDot(active: true),
            SizedBox(width: 6),
            _PurpleDot(active: false),
          ],
        ),
      ],
    );
  }
}

class _DeviceDashboardBody extends StatelessWidget {
  final DeviceService device;
  const _DeviceDashboardBody({required this.device});

  @override
  Widget build(BuildContext context) {
    final status = device.status;
    final pct = status?.waterLevelPct ?? 0;
    final waterColor = AppUtils.waterLevelColor(pct);
    final l10n = AppLocalizations.of(context);
    final isDark = context.watch<ThemeNotifier>().isDark;

    return RefreshIndicator(
      color: AppTheme.smartPurple,
      backgroundColor: Colors.white,
      onRefresh: () => device.loadDevices(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Device selector
            if (device.deviceIds.length > 1) ...[
              _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: DropdownButton<String>(
                    value: device.selectedDeviceId,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    icon: Icon(Icons.unfold_more_rounded,
                        size: 18,
                        color: isDark ? Colors.white54 : AppTheme.lightTextSub),
                    dropdownColor:
                        isDark ? AppTheme.darkCard : Colors.white,
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.lightText,
                        fontSize: 14),
                    items: device.deviceIds
                        .map((id) => DropdownMenuItem(
                              value: id,
                              child: Row(children: [
                                const Icon(Icons.device_hub,
                                    size: 14,
                                    color: AppTheme.smartPurple),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(device.deviceName(id),
                                        overflow: TextOverflow.ellipsis)),
                              ]),
                            ))
                        .toList(),
                    onChanged: (id) {
                      if (id != null) device.selectDevice(id);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Online badge
            Center(
              child: AnimatedStatusBadge(
                isOnline: device.isDeviceOnline,
                onlineLabel: l10n.dash_device_online,
                offlineLabel: l10n.dash_device_offline,
              ),
            ),
            const SizedBox(height: 14),

            // Hero card: tank + stats
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    TankWidget(percent: pct, width: 110, height: 165),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            child: Text(
                              '$pct%',
                              style: TextStyle(
                                  fontSize: 66,
                                  fontWeight: FontWeight.w900,
                                  color: waterColor,
                                  height: 1.0),
                            ),
                          ),
                          Text(
                            status != null
                                ? AppUtils.levelLabelL10n(
                                    status.waterLevel, l10n)
                                : '—',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : AppTheme.lightTextSub),
                          ),
                          const SizedBox(height: 12),
                          if (status != null) ...[
                            PumpStatusCard(
                                isOn: status.isPumpOn, isDark: isDark),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: [
                                GradientBadge(
                                  label: status.pumpMode,
                                  gradient: status.isAutoMode
                                      ? const LinearGradient(colors: [
                                          AppTheme.smartPurple,
                                          AppTheme.smartPurpleLight,
                                        ])
                                      : AppTheme.warmGradient,
                                  icon: status.isAutoMode
                                      ? Icons.auto_awesome
                                      : Icons.touch_app,
                                ),
                                if (status.alarmActive ||
                                    status.dryRunActive)
                                  GradientBadge(
                                    label: status.dryRunActive
                                        ? l10n.dash_dry_run
                                        : l10n.dash_alarm,
                                    gradient: AppTheme.dangerGradient,
                                    icon: Icons.warning_amber_rounded,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Alarm banner
            if (status?.alarmActive == true) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(
                        status?.dryRunActive == true
                            ? Icons.warning_amber_rounded
                            : Icons.notifications_active,
                        color: AppTheme.danger,
                        size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status?.dryRunActive == true
                            ? l10n.dash_dry_run_alert
                            : l10n.dash_critical_alert,
                        style: const TextStyle(
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Control panel
            const _GlassCard(
              child: Padding(
                padding: EdgeInsets.all(4),
                child: ControlPanel(),
              ),
            ),
            const SizedBox(height: 12),

            // Info cards
            if (status != null) ...[
              _SectionLabel(label: l10n.dash_device_info),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _InfoCard(
                  icon: Icons.access_time_rounded,
                  label: l10n.dash_last_update,
                  value: AppUtils.formatTimestamp(status.timestamp),
                  color: AppTheme.smartPurple,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: _InfoCard(
                  icon: Icons.radar,
                  label: l10n.dash_sensor_mode,
                  value: status.sensorMode,
                  color: AppTheme.primaryLight,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: _InfoCard(
                  icon: Icons.timer_outlined,
                  label: l10n.dash_uptime_label,
                  value: status.uptime,
                  color: AppTheme.accentCyan,
                )),
              ]),
              const SizedBox(height: 12),
              _SectionLabel(label: l10n.dash_pump_stats),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: _InfoCard(
                  icon: Icons.repeat_rounded,
                  label: l10n.dash_cycles,
                  value: '${status.pumpCycles}',
                  color: AppTheme.success,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: _InfoCard(
                  icon: Icons.schedule_rounded,
                  label: l10n.dash_total_run,
                  value: status.formattedPumpTime,
                  color: AppTheme.warning,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: _InfoCard(
                  icon: Icons.wifi_rounded,
                  label: l10n.dash_signal_label,
                  value: '${status.wifiRssi} dBm',
                  color: AppTheme.primaryLight,
                )),
              ]),
              const SizedBox(height: 8),

              // [FIX BUG-2] Quick access to History & Analytics
              _GlassCard(
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(deviceService: device),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(children: [
                      const Icon(Icons.history_rounded, size: 20, color: AppTheme.smartPurple),
                      const SizedBox(width: 12),
                      Text(
                        l10n.history,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.lightText),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? Colors.white24 : AppTheme.smartPurple.withValues(alpha: 0.25)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  Placeholder tabs
// ════════════════════════════════════════════════════════════════
// ignore: unused_element
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return Column(children: [
      _TuyaTitleBar(title: label),
      Expanded(
        child: Center(
          child: _GlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 36, vertical: 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: 44,
                    color: AppTheme.smartPurple.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(label,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.lightText)),
                const SizedBox(height: 6),
                Text('Coming soon',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : AppTheme.lightTextSub)),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _NoDevicePage extends StatelessWidget {
  final VoidCallback onAdd;
  final String title;
  const _NoDevicePage({required this.onAdd, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return Column(children: [
      _TuyaTitleBar(title: title),
      Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.device_unknown_outlined,
                  size: 48,
                  color: AppTheme.smartPurple.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context).dash_no_device,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.lightText)),
              const SizedBox(height: 24),
              _TuyaAddButton(
                label: AppLocalizations.of(context).dash_add_device,
                onTap: onAdd,
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════
//  Shared UI components — HD 3D Professional v12
// ════════════════════════════════════════════════════════════════

// ── Title Bar ────────────────────────────────────────────────
class _TuyaTitleBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _TuyaTitleBar({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.30)
            : Colors.white.withValues(alpha: 0.70),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : AppTheme.smartPurple.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Row(children: [
          if (trailing != null) const SizedBox(width: 36),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.lightText,
                letterSpacing: 0.3,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 36),
        ]),
      ),
    );
  }
}

// ── Add Device Button — gradient with glow ────────────────────
class _TuyaAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TuyaAddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            gradient: isDark
                ? AppTheme.purpleGradientH
                : AppTheme.purpleGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.buttonGlow,
          ),
          child: Stack(
            children: [
              // Shine overlay
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glass Card — 3D professional style ───────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return Container(
      decoration: AppTheme.glassCard(isDark: isDark, radius: 18),
      child: isDark
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: child,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: child,
            ),
    );
  }
}

// ── Section Label — accent pill style ────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          gradient: AppTheme.purpleGradientH,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.smartPurple.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          height: 0.5,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.smartPurple.withValues(alpha: 0.12),
        ),
      ),
    ]);
  }
}

// ── Info Card — 3D depth ──────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.lightText,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? Colors.white38 : AppTheme.lightTextSub,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }
}

// ── Loading State ─────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppTheme.smartPurple.withValues(alpha: isDark ? 0.15 : 0.08),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.smartPurple.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.smartPurple,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).loading_devices,
          style: TextStyle(
            color: isDark ? Colors.white54 : AppTheme.lightTextSub,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }
}

// ── User Avatar Button ─────────────────────────────────────────
class _UserAvatarBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _UserAvatarBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;
    final name = user?.displayName;
    final email = user?.email ?? '';
    String initials;
    if (name != null && name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : name[0].toUpperCase();
    } else {
      initials = email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.purpleGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.smartPurple.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: photoUrl != null
            ? ClipOval(
                child: Image.network(photoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                        child: Text(initials,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)))))
            : Center(
                child: Text(initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
      ),
    );
  }
}

// ── Purple Dot ─────────────────────────────────────────────────
class _PurpleDot extends StatelessWidget {
  final bool active;
  const _PurpleDot({required this.active});
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        gradient: active ? AppTheme.purpleGradientH : null,
        color: active ? null : (isDark ? Colors.white12 : const Color(0xFFCBC5E8)),
        borderRadius: BorderRadius.circular(4),
        boxShadow: active
            ? [BoxShadow(color: AppTheme.smartPurple.withValues(alpha: 0.40), blurRadius: 6, offset: const Offset(0, 2))]
            : null,
      ),
    );
  }
}

// ── Bottom Navigation — premium glass ─────────────────────────
class _TuyaBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const _TuyaBottomNav({required this.currentIndex, required this.onTap});

  static const _tabs = [
    (icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,      label: 'Devices'),
    (icon: Icons.check_box_outlined, activeIcon: Icons.check_box_rounded, label: 'Schedules'),
    (icon: Icons.play_circle_outline,activeIcon: Icons.play_circle,       label: 'Scenes'),
    (icon: Icons.send_outlined,      activeIcon: Icons.send_rounded,      label: 'Automations'),
    (icon: Icons.settings_outlined,  activeIcon: Icons.settings_rounded,  label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : AppTheme.smartPurple.withValues(alpha: 0.10),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.40)
                    : AppTheme.smartPurple.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final active = currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: active ? 42 : 32,
                            height: active ? 32 : 32,
                            decoration: active
                                ? BoxDecoration(
                                    gradient: AppTheme.purpleGradient,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.smartPurple.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  )
                                : null,
                            child: Icon(
                              active ? tab.activeIcon : tab.icon,
                              size: 22,
                              color: active
                                  ? Colors.white
                                  : (isDark ? Colors.white38 : AppTheme.lightTextSub),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                              color: active
                                  ? AppTheme.smartPurple
                                  : (isDark ? Colors.white38 : AppTheme.lightTextSub),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Background — HD Gradient Mesh ─────────────────────────────
class _RoomBackground extends StatelessWidget {
  const _RoomBackground();
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    return Stack(fit: StackFit.expand, children: [
      CustomPaint(painter: _GradientMeshPainter(isDark: isDark)),
      BackdropFilter(
        filter: ImageFilter.blur(),
        child: Container(color: Colors.transparent),
      ),
    ]);
  }
}

class _GradientMeshPainter extends CustomPainter {
  final bool isDark;
  const _GradientMeshPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;

    if (isDark) {
      // ── Dark: deep navy + purple/cyan blobs ───────────────
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07091A),
              Color(0xFF0A0F22),
              Color(0xFF0D1428),
              Color(0xFF080D1E),
            ],
            stops: [0.0, 0.30, 0.65, 1.0],
          ).createShader(rect),
      );
      // Purple blob top-right
      _blob(canvas, Offset(w * 0.80, h * 0.12), 200,
          AppTheme.smartPurple.withValues(alpha: 0.18));
      // Cyan blob center-left
      _blob(canvas, Offset(w * 0.15, h * 0.40), 180,
          AppTheme.accentCyan.withValues(alpha: 0.10));
      // Purple blob bottom
      _blob(canvas, Offset(w * 0.55, h * 0.85), 250,
          AppTheme.smartPurpleDark.withValues(alpha: 0.14));
      // Subtle blue center glow
      _blob(canvas, Offset(w * 0.50, h * 0.50), 320,
          const Color(0xFF1D4ED8).withValues(alpha: 0.05));
      // Small teal accent
      _blob(canvas, Offset(w * 0.88, h * 0.65), 120,
          AppTheme.accent.withValues(alpha: 0.08));

      // Subtle grid lines
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.025)
        ..strokeWidth = 0.5;
      for (double x = 0; x < w; x += 48) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
      }
      for (double y = 0; y < h; y += 48) {
        canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
      }
    } else {
      // ── Light: clean purple-white gradient mesh ────────────
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F2FF), // soft lavender
              Color(0xFFEEF2FF), // blue-white
              Color(0xFFEDE8FF), // purple-white
              Color(0xFFF0F4FF), // cool white
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ).createShader(rect),
      );

      // Large purple ambient blob top-left
      _blob(canvas, Offset(w * 0.05, h * 0.05), 280,
          AppTheme.smartPurple.withValues(alpha: 0.09));
      // Blue blob top-right
      _blob(canvas, Offset(w * 0.92, h * 0.10), 220,
          AppTheme.primaryLight.withValues(alpha: 0.08));
      // Purple blob bottom-right
      _blob(canvas, Offset(w * 0.85, h * 0.88), 260,
          AppTheme.smartPurple.withValues(alpha: 0.10));
      // Cyan blob bottom-left
      _blob(canvas, Offset(w * 0.10, h * 0.90), 200,
          AppTheme.accentCyan.withValues(alpha: 0.07));
      // Center ambient
      _blob(canvas, Offset(w * 0.50, h * 0.50), 350,
          AppTheme.smartPurpleLight.withValues(alpha: 0.05));

      // Decorative floating circles (geometric elements)
      final circlePaint = Paint()
        ..color = AppTheme.smartPurple.withValues(alpha: 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(w * 0.85, h * 0.15), 60, circlePaint);
      canvas.drawCircle(Offset(w * 0.85, h * 0.15), 100, circlePaint..color = AppTheme.smartPurple.withValues(alpha: 0.025));
      canvas.drawCircle(Offset(w * 0.12, h * 0.80), 50, circlePaint..color = AppTheme.accent.withValues(alpha: 0.04));
      canvas.drawCircle(Offset(w * 0.12, h * 0.80), 85, circlePaint..color = AppTheme.accent.withValues(alpha: 0.02));

      // Small decorative dots
      final dotPaint = Paint()..style = PaintingStyle.fill;
      final dots = [
        (Offset(w * 0.75, h * 0.25), AppTheme.smartPurple.withValues(alpha: 0.12), 4.0),
        (Offset(w * 0.20, h * 0.30), AppTheme.accent.withValues(alpha: 0.10), 3.0),
        (Offset(w * 0.90, h * 0.55), AppTheme.smartPurple.withValues(alpha: 0.08), 5.0),
        (Offset(w * 0.05, h * 0.60), AppTheme.accentCyan.withValues(alpha: 0.10), 3.5),
        (Offset(w * 0.60, h * 0.05), AppTheme.smartPurpleLight.withValues(alpha: 0.12), 4.0),
      ];
      for (final d in dots) {
        canvas.drawCircle(d.$1, d.$3, dotPaint..color = d.$2);
      }
    }
  }

  void _blob(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color, Colors.transparent])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(covariant _GradientMeshPainter old) => old.isDark != isDark;
}

// ── Box Illustration (Empty State) ────────────────────────────
class _BoxIllustrationPainter extends CustomPainter {
  final bool isDark;
  const _BoxIllustrationPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const purple = AppTheme.smartPurple;

    // Box colors: adapt to dark/light
    final c1 = isDark ? const Color(0xFF2D2060) : const Color(0xFFE8E2FF);
    final c2 = isDark ? const Color(0xFF1E1545) : const Color(0xFFD4CCF5);
    final c3 = isDark ? const Color(0xFF261A55) : const Color(0xFFDDD8FF);

    // Shadow under box
    final shadowPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(cx + 10, cy + 60), width: 110, height: 18));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = purple.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Box body (front face)
    canvas.drawPath(
      Path()
        ..moveTo(cx - 42, cy + 8)
        ..lineTo(cx + 52, cy + 8)
        ..lineTo(cx + 52, cy + 58)
        ..lineTo(cx - 42, cy + 58)
        ..close(),
      Paint()..color = c1,
    );
    // Right face (3D side)
    canvas.drawPath(
      Path()
        ..moveTo(cx + 52, cy + 8)
        ..lineTo(cx + 68, cy - 8)
        ..lineTo(cx + 68, cy + 42)
        ..lineTo(cx + 52, cy + 58)
        ..close(),
      Paint()..color = c2,
    );
    // Top face (3D top)
    canvas.drawPath(
      Path()
        ..moveTo(cx - 42, cy + 8)
        ..lineTo(cx - 26, cy - 8)
        ..lineTo(cx + 68, cy - 8)
        ..lineTo(cx + 52, cy + 8)
        ..close(),
      Paint()..color = c3,
    );

    // Edge highlights (3D effect)
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.12 : 0.60)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 42, cy + 8), Offset(cx + 52, cy + 8), edgePaint);
    canvas.drawLine(Offset(cx - 42, cy + 8), Offset(cx - 26, cy - 8), edgePaint);

    // Grid on top face
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 4; i++) {
      final t = i / 5;
      canvas.drawLine(
          Offset(cx - 42 + t * 94, cy + 8 - t * 16),
          Offset(cx - 26 + t * 94, cy - 8 - t * 16 + 16),
          grid);
    }

    // Magnifying glass with glow
    final gc = Offset(cx + 30, cy - 18);
    canvas.drawCircle(gc, 23, Paint()..color = purple.withValues(alpha: 0.15));
    canvas.drawCircle(
        gc, 23,
        Paint()
          ..color = purple
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke);
    canvas.drawLine(
        gc + const Offset(14, 14),
        gc + const Offset(30, 30),
        Paint()
          ..color = purple.withValues(alpha: 0.90)
          ..strokeWidth = 6.5
          ..strokeCap = StrokeCap.round);

    // Question badge with gradient-like effect
    canvas.drawCircle(
        Offset(cx - 22, cy - 24), 16,
        Paint()..color = purple);
    canvas.drawCircle(
        Offset(cx - 22, cy - 24), 16,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..shader = const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0x30FFFFFF), Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset(cx - 22, cy - 24), radius: 16)));

    final tp = TextPainter(
      text: const TextSpan(
          text: '?',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - 22 - tp.width / 2, cy - 24 - tp.height / 2));

    // Floating dots
    canvas.drawCircle(Offset(cx - 56, cy + 12), 5,
        Paint()..color = purple.withValues(alpha: isDark ? 0.40 : 0.20));
    canvas.drawCircle(Offset(cx + 72, cy - 32), 4,
        Paint()..color = AppTheme.smartPurpleLight.withValues(alpha: 0.50));
  }

  @override
  bool shouldRepaint(covariant _BoxIllustrationPainter old) => old.isDark != isDark;
}

// ── Shared constants ──────────────────────────────────────────
// (Use AppTheme.lightText and AppTheme.lightTextSub directly)
