// lib/core/utils.dart
// SmartIoT v5.0.0 — Utility helpers
// [FIX] waterLevelToPercent: EMPTY now returns 0 (was falling through to default → 5)

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class AppUtils {
  AppUtils._();

  static int waterLevelToPercent(String level, int? rawPct) {
    if (rawPct != null) return rawPct.clamp(0, 100);
    switch (level.toUpperCase()) {
      case AppConstants.levelFull:  return 100;
      case AppConstants.levelMid:   return 60;
      case AppConstants.levelLow:   return 25;
      case AppConstants.levelEmpty: return 0;   // [FIX] was missing → fell to default → 5
      default:                      return 0;   // unknown level → treat as 0
    }
  }

  static Color waterLevelColor(int pct) {
    if (pct >= 75) return const Color(0xFF0EA5E9); // sky blue
    if (pct >= 40) return const Color(0xFF22C55E); // green
    if (pct >= 15) return const Color(0xFFF59E0B); // amber
    return const Color(0xFFEF4444);                 // red
  }

  /// Localized water level label — use this instead of levelLabel() everywhere
  static String levelLabelL10n(String level, AppLocalizations l10n) {
    switch (level.toUpperCase()) {
      case 'FULL':  return l10n.level_full;
      case 'MID':   return l10n.level_mid;
      case 'LOW':   return l10n.level_low;
      case 'EMPTY': return l10n.level_empty;
      default:      return level;
    }
  }

  static String levelLabel(String level) {
    switch (level.toUpperCase()) {
      case AppConstants.levelFull:  return 'Full';
      case AppConstants.levelMid:   return 'Medium';
      case AppConstants.levelLow:   return 'Low';
      case AppConstants.levelEmpty: return 'Empty';
      default:                      return level;
    }
  }

  static String formatTimestamp(dynamic ts) {
    if (ts == null) return 'Unknown';
    try {
      final int epoch = (ts is String) ? int.parse(ts) : (ts as num).toInt();
      final dt = epoch > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(epoch)
          : DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
      return DateFormat('dd MMM HH:mm:ss').format(dt.toLocal());
    } catch (_) {
      return 'Unknown';
    }
  }

  static T safeParse<T>(Map<dynamic, dynamic> map, String key, T defaultVal) {
    try {
      final val = map[key];
      if (val == null) return defaultVal;
      if (val is T) return val;
      if (T == int)    return int.tryParse(val.toString()) as T? ?? defaultVal;
      if (T == double) return double.tryParse(val.toString()) as T? ?? defaultVal;
      if (T == bool) {
        if (val is bool) return val as T;
        return (val.toString().toLowerCase() == 'true' || val.toString() == '1') as T;
      }
      return val.toString() as T;
    } catch (_) {
      return defaultVal;
    }
  }

  static void showSnack(BuildContext context, String msg,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }
}
