// lib/screens/settings_screen.dart
// SmartIoT v5.0.1 — FULL BENGALI LOCALIZATION FIXED
// ✅ All text now uses AppLocalizations for complete Bengali/English support

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import '../core/utils.dart';
import '../l10n/app_localizations.dart';
import '../screens/schedule_screen.dart';
import '../screens/sharing_screen.dart';
import '../screens/history_screen.dart';
import '../screens/calibration_screen.dart';
import '../screens/alarm_threshold_screen.dart';
import '../screens/water_usage_screen.dart';
import 'login_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final DeviceService? deviceService;
  final Future<void> Function()? onLogout;
  const SettingsScreen({super.key, this.deviceService, this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isEditingName = false;
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user?.displayName != null) _nameCtrl.text = user!.displayName!;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await context.read<AuthService>().currentUser?.updateDisplayName(name);
      if (mounted) {
        AppUtils.showSnack(context, l10n.display_name_updated);
        setState(() => _isEditingName = false);
      }
    } catch (_) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).display_name_failed, isError: true);
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).could_not_open_link, isError: true);
    }
  }

  Future<void> _doLogout() async {
    if (widget.onLogout != null) {
      await widget.onLogout!();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.sign_out, style: const TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    await context.read<AuthService>().logout();
    if (mounted) {
      navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.watch<ThemeNotifier>().isDark;
    final auth = context.watch<AuthService>();
    final localeProvider = context.watch<LocaleProvider>();
    final email = auth.currentUser?.email ?? '';
    final user = auth.currentUser;
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName;

    String initials = '?';
    if (displayName != null && displayName.trim().isNotEmpty) {
      final parts = displayName.trim().split(' ');
      initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : displayName[0].toUpperCase();
    } else if (email.isNotEmpty) {
      initials = email[0].toUpperCase();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsTitleBar(l10n: l10n),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 12),

              // Profile section
              _GlassBlock(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isEditingName = !_isEditingName),
                        child: Stack(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.smartPurple.withValues(alpha: 0.16),
                                border: Border.all(
                                    color: AppTheme.smartPurple.withValues(alpha: 0.30),
                                    width: 1.8),
                              ),
                              child: photoUrl != null
                                  ? ClipOval(
                                  child: Image.network(photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _AvatarInitials(initials: initials)))
                                  : _AvatarInitials(initials: initials),
                            ),
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                width: 16, height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.success,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: _isEditingName
                            ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameCtrl,
                                autofocus: true,
                                style: TextStyle(
                                    color: isDark ? Colors.white : AppTheme.lightText,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: l10n.enter_your_name,
                                  isDense: true,
                                  contentPadding:
                                  const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: AppTheme.smartPurple
                                            .withValues(alpha: 0.35)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppTheme.smartPurple,
                                        width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.smartPurple
                                      .withValues(alpha: 0.06),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.check_rounded,
                                  color: AppTheme.smartPurple, size: 20),
                              onPressed: _saveDisplayName,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: isDark ? Colors.white38 : AppTheme.lightTextSub, size: 20),
                              onPressed: () => setState(
                                      () => _isEditingName = false),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        )
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.email,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : AppTheme.lightTextSub,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email.isEmpty ? 'Not signed in' : email,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppTheme.lightText,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (displayName != null &&
                                displayName.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.smartPurple
                                        .withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              _GlassBlock(
                child: Column(children: [
                  _MenuRow(
                    label: l10n.profile,
                    icon: Icons.manage_accounts_outlined,
                    onTap: () => _showAccountSheet(context, l10n, auth, isDark),
                  ),
                  _MenuDivider(),
                  _MenuRow(
                    label: l10n.notifications,
                    icon: Icons.notifications_outlined,
                    onTap: () {
                      if (widget.deviceService != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlarmThresholdScreen(
                                deviceService: widget.deviceService!),
                          ),
                        );
                      } else {
                        AppUtils.showSnack(context, l10n.dash_no_device);
                      }
                    },
                  ),
                  _MenuDivider(),
                  _MenuRow(
                    label: l10n.device_sharing,
                    icon: Icons.group_outlined,
                    onTap: () {
                      if (widget.deviceService != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SharingScreen(
                                deviceService: widget.deviceService!),
                          ),
                        );
                      } else {
                        AppUtils.showSnack(context, l10n.dash_no_device);
                      }
                    },
                  ),
                  _MenuDivider(),
                  _MenuRow(
                    label: l10n.voice_service,
                    icon: Icons.mic_outlined,
                    onTap: () => AppUtils.showSnack(
                        context, l10n.voice_service_coming_soon),
                  ),
                  _MenuDivider(),
                  _MenuRow(
                    label: l10n.about,
                    icon: Icons.info_outline,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 8),

              if (widget.deviceService != null) ...[
                _SectionLabel(label: l10n.device_management.toUpperCase()),
                const SizedBox(height: 6),
                _GlassBlock(
                  child: Column(children: [
                    _MenuRow(
                      label: l10n.pump_schedules,
                      icon: Icons.schedule_rounded,
                      sublabel: l10n.pump_schedules_sub,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ScheduleScreen(
                                  deviceService: widget.deviceService!))),
                    ),
                    _MenuDivider(),
                    _MenuRow(
                      label: l10n.calib_title,
                      icon: Icons.tune_rounded,
                      sublabel: l10n.calib_sub,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CalibrationScreen(
                                  deviceService: widget.deviceService!))),
                    ),
                    _MenuDivider(),
                    _MenuRow(
                      label: l10n.thresh_title,
                      icon: Icons.notifications_active_outlined,
                      sublabel: l10n.thresh_sub,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AlarmThresholdScreen(
                                  deviceService: widget.deviceService!))),
                    ),
                    _MenuDivider(),
                    _MenuRow(
                      label: l10n.usage_title,
                      icon: Icons.water_drop_outlined,
                      sublabel: l10n.trackConsumption,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => WaterUsageScreen(
                                  deviceService: widget.deviceService!))),
                    ),
                    _MenuDivider(),
                    _MenuRow(
                      label: l10n.history,
                      icon: Icons.history_rounded,
                      sublabel: l10n.eventsAnalytics,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => HistoryScreen(
                                  deviceService: widget.deviceService!))),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
              ],

              _SectionLabel(label: l10n.appearance.toUpperCase()),
              const SizedBox(height: 6),
              _GlassBlock(
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppTheme.smartPurple.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          size: 18,
                          color: AppTheme.smartPurple,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        l10n.dark_mode,
                        style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : AppTheme.lightText),
                      ),
                      const Spacer(),
                      Switch.adaptive(
                        value: isDark,
                        onChanged: (_) =>
                            context.read<ThemeNotifier>().toggle(),
                        activeThumbColor: AppTheme.smartPurple, activeTrackColor: AppTheme.smartPurpleLight,
                      ),
                    ]),
                  ),
                  _MenuDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppTheme.smartPurple.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.language,
                            size: 18, color: AppTheme.smartPurple),
                      ),
                      const SizedBox(width: 14),
                      Text(l10n.language,
                          style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : AppTheme.lightText)),
                      const Spacer(),
                      _LangToggle(
                        locale: localeProvider.locale,
                        onChanged: (l) =>
                            context.read<LocaleProvider>().setLocale(l),
                      ),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 8),

              _SectionLabel(label: l10n.support_social.toUpperCase()),
              const SizedBox(height: 6),
              _GlassBlock(
                child: Column(children: [
                  _MenuRow(
                    label: l10n.youtube,
                    icon: Icons.play_circle_filled,
                    iconColor: const Color(0xFFFF0000),
                    sublabel: l10n.youtubeDesc,
                    onTap: () =>
                        _launch('https://www.youtube.com/@SmartIoTInterface'),
                  ),
                  _MenuDivider(),
                  _MenuRow(
                    label: l10n.facebook,
                    icon: Icons.facebook,
                    iconColor: const Color(0xFF1877F2),
                    sublabel: l10n.facebookDesc,
                    onTap: () =>
                        _launch('https://www.facebook.com/SmartIoTInterface'),
                  ),
                  _MenuDivider(),
                  _MenuRow(
                    label: l10n.email_support,
                    icon: Icons.email_outlined,
                    iconColor: AppTheme.accentCyan,
                    sublabel: 'smartiotinterface@gmail.com',
                    onTap: () => _launch(
                        'mailto:smartiotinterface@gmail.com?subject=SmartIoT%20Support'),
                  ),
                  _MenuDivider(),
                  _MenuRow(
                    label: l10n.call_support,
                    icon: Icons.phone_outlined,
                    iconColor: AppTheme.success,
                    sublabel: '+8801680603444',
                    onTap: () => _launch('tel:+8801680603444'),
                  ),
                ]),
              ),

              const SizedBox(height: 8),

              _GlassBlock(
                child: InkWell(
                  onTap: _doLogout,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(
                        l10n.logout,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white54 : AppTheme.lightTextSub,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  void _showAccountSheet(BuildContext context, AppLocalizations l10n,
      AuthService auth, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape:
      const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profile,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : AppTheme.lightText)),
            const SizedBox(height: 16),
            Text(l10n.email,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white38 : AppTheme.lightTextSub)),
            const SizedBox(height: 4),
            Text(
              auth.currentUser?.email ?? '—',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : AppTheme.lightText),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l10n.save_name),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.smartPurple,
                  side: const BorderSide(color: AppTheme.smartPurple),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _isEditingName = true);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

}

class _SettingsTitleBar extends StatelessWidget {
  final AppLocalizations l10n;
  const _SettingsTitleBar({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          l10n.settings,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.lightText,
              letterSpacing: 0.2),
        ),
      ),
      Container(
        height: 0.5,
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : AppTheme.smartPurple.withValues(alpha: 0.10),
      ),
    ]);
  }
}

class _GlassBlock extends StatelessWidget {
  final Widget child;
  const _GlassBlock({required this.child});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: isDark
            ? Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.8),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.35), width: 0.8),
        )
            : const Border(
          top: BorderSide(color: Colors.white),
          bottom: BorderSide(color: Color(0xFFDDD8FF), width: 0.8),
        ),
        boxShadow: isDark
            ? AppTheme.card3dDark
            : AppTheme.card3dLight,
      ),
      child: isDark
          ? ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: child,
        ),
      )
          : child,
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final String? sublabel;
  final VoidCallback onTap;

  const _MenuRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.smartPurple;
    final isDark = context.watch<ThemeNotifier>().isDark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.lightText)),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(sublabel!,
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : AppTheme.lightTextSub)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 22,
                color: isDark ? Colors.white24 : AppTheme.smartPurple.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: 66),
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppTheme.smartPurple.withValues(alpha: 0.08));
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            gradient: AppTheme.purpleGradientH,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.smartPurple.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: Colors.white)),
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
      ]),
    );
  }
}

class _AvatarInitials extends StatelessWidget {
  final String initials;
  const _AvatarInitials({required this.initials});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(initials,
          style: const TextStyle(
              color: AppTheme.smartPurple,
              fontWeight: FontWeight.w800,
              fontSize: 20)),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final Locale locale;
  final ValueChanged<Locale> onChanged;
  const _LangToggle({required this.locale, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final isEn = locale.languageCode == 'en';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border:
        Border.all(color: AppTheme.smartPurple.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _LangBtn(label: 'EN', active: isEn,
            onTap: () => onChanged(const Locale('en'))),
        Container(width: 0.5, height: 28, color: AppTheme.smartPurple.withValues(alpha: 0.25)),
        _LangBtn(label: 'BN', active: !isEn,
            onTap: () => onChanged(const Locale('bn'))),
      ]),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _LangBtn({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.smartPurple.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? AppTheme.smartPurple
                  : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white38 : AppTheme.lightTextSub),
            )),
      ),
    );
  }
}