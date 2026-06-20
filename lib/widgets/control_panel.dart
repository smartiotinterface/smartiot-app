// lib/widgets/control_panel.dart
// SmartIoT v4.0.0 — Control Panel: gradient states, smooth animations, haptic

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/device_service.dart';
import '../core/utils.dart';
import '../theme/app_theme.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceService>();
    final status = device.status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (status == null) return const SizedBox.shrink();

    final isOnline  = device.isDeviceOnline;
    final isPumpOn  = status.isPumpOn;
    final isAuto    = status.isAutoMode;
    final isDryRun  = status.dryRunActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section header ──────────────────────────────
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CONTROLS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
            const Spacer(),
            if (!isOnline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppTheme.dangerGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'OFFLINE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Pump toggle ─────────────────────────────────
        _ControlCard(
          label: AppLocalizations.of(context).ctrl_water_pump,
          sublabel: isPumpOn
              ? 'Running — tap to stop'
              : isAuto
                  ? 'Auto-controlled'
                  : 'Stopped — tap to start',
          icon: isPumpOn ? Icons.water_drop : Icons.water_drop_outlined,
          isActive: isPumpOn,
          gradient: isPumpOn ? AppTheme.successGradient : null,
          isDisabled: !isOnline || device.isSending || isAuto || isDryRun,
          disabledReason: !isOnline
              ? AppLocalizations.of(context).ctrl_device_offline
              : device.isSending
                  ? AppLocalizations.of(context).ctrl_sending
                  : isAuto
                      ? AppLocalizations.of(context).ctrl_manual_required
                      : 'Dry-run protection active',
          onTap: () {
            HapticFeedback.mediumImpact();
            device.togglePump();
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        // ── Mode toggle ─────────────────────────────────
        _ControlCard(
          label: AppLocalizations.of(context).ctrl_mode_label,
          sublabel: isAuto ? AppLocalizations.of(context).ctrl_mode_auto_sub : AppLocalizations.of(context).ctrl_mode_manual_sub,
          icon: isAuto ? Icons.auto_awesome : Icons.touch_app_outlined,
          isActive: isAuto,
          gradient: isAuto ? AppTheme.accentGradient : null,
          isDisabled: !isOnline || device.isSending,
          disabledReason: !isOnline ? AppLocalizations.of(context).ctrl_device_offline : AppLocalizations.of(context).ctrl_sending,
          onTap: () {
            HapticFeedback.selectionClick();
            device.toggleMode();
          },
          isDark: isDark,
        ),

        if (isDryRun) ...[
          const SizedBox(height: 10),
          _ControlCard(
            label: 'Reset Dry-Run',
            sublabel: 'Clear protection & resume normal operation',
            icon: Icons.restart_alt_rounded,
            isActive: false,
            gradient: AppTheme.warmGradient,
            isDisabled: !isOnline || device.isSending,
            disabledReason: AppLocalizations.of(context).ctrl_device_offline,
            onTap: () {
              HapticFeedback.heavyImpact();
              device.resetDryRun();
            },
            isDark: isDark,
            forceGradient: true,
          ),
        ],
      ],
    );
  }
}

// ── Control card ────────────────────────────────────────────
class _ControlCard extends StatefulWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isActive;
  final Gradient? gradient;
  final bool isDisabled;
  final String disabledReason;
  final VoidCallback onTap;
  final bool isDark;
  final bool forceGradient;

  const _ControlCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.isActive,
    this.gradient,
    required this.isDisabled,
    required this.disabledReason,
    required this.onTap,
    required this.isDark,
    this.forceGradient = false,
  });

  @override
  State<_ControlCard> createState() => _ControlCardState();
}

class _ControlCardState extends State<_ControlCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isDisabled) {
      AppUtils.showSnack(
        context,
        widget.disabledReason,
      );
      return;
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final showGradient = (widget.isActive || widget.forceGradient) && widget.gradient != null;
    final activeColor = widget.isActive ? AppTheme.success : AppTheme.accent;

    return GestureDetector(
      onTapDown: widget.isDisabled ? null : (_) => _pressCtrl.forward(),
      onTapUp: widget.isDisabled ? null : (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _pressAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: showGradient ? widget.gradient : null,
            color: showGradient
                ? null
                : (widget.isDark ? AppTheme.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showGradient
                  ? Colors.white.withValues(alpha: 0.15)
                  : (widget.isActive
                      ? activeColor.withValues(alpha: 0.3)
                      : (widget.isDark ? AppTheme.darkBorder : AppTheme.lightBorder)),
            ),
            boxShadow: showGradient
                ? [
                    BoxShadow(
                      color: (widget.gradient as LinearGradient?)
                              ?.colors
                              .last
                              .withValues(alpha: 0.25) ??
                          Colors.transparent,
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : (widget.isDark ? AppTheme.cardShadow : []),
          ),
          child: Row(
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: showGradient
                      ? Colors.white.withValues(alpha: 0.2)
                      : (widget.isActive
                          ? activeColor.withValues(alpha: 0.15)
                          : (widget.isDark ? AppTheme.darkSurface : const Color(0xFFF1F5F9))),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: showGradient
                      ? Colors.white
                      : (widget.isActive
                          ? activeColor
                          : (widget.isDark ? Colors.white54 : Colors.black45)),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: showGradient
                            ? Colors.white
                            : (widget.isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isDisabled && !widget.forceGradient
                          ? widget.disabledReason
                          : widget.sublabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: showGradient
                            ? Colors.white.withValues(alpha: 0.75)
                            : (widget.isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ],
                ),
              ),

              // Toggle indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? (showGradient
                          ? Colors.white.withValues(alpha: 0.25)
                          : activeColor.withValues(alpha: 0.15))
                      : (widget.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isActive
                        ? (showGradient
                            ? Colors.white.withValues(alpha: 0.3)
                            : activeColor.withValues(alpha: 0.3))
                        : Colors.transparent,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: widget.isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: widget.isActive
                                ? (showGradient ? Colors.white : activeColor)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
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
