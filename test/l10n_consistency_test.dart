// test/l10n_consistency_test.dart
// SmartIoT v1.0.2 — Localization regression tests
// Run: flutter test
//
// Why this file exists: in the v8.2.8 audit pass, two new keys
// (automation_deleted, scene_deleted) were added directly to the
// *generated* lib/l10n/app_localizations*.dart files instead of their
// app_en.arb / app_bn.arb source. The next `flutter gen-l10n` regenerated
// those files from ARB and silently dropped both keys, causing
// "undefined_getter" compile errors that only surfaced on a real machine.
//
// AppLocalizationsEn/Bn are plain Dart classes (no Flutter binding needed
// to construct them), so this test instantiates them directly — it runs in
// milliseconds and will fail loudly with a clear stack trace if a key is
// ever again present in one place but not the other.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_iot_interface/l10n/app_localizations.dart';
import 'package:smart_iot_interface/l10n/app_localizations_en.dart';
import 'package:smart_iot_interface/l10n/app_localizations_bn.dart';

void main() {
  final en = AppLocalizationsEn();
  final bn = AppLocalizationsBn();

  group('Localization — keys that broke compilation before (regression guard)', () {
    test('automation_deleted exists and is non-empty in both languages', () {
      expect(en.automation_deleted, isNotEmpty);
      expect(bn.automation_deleted, isNotEmpty);
    });

    test('scene_deleted exists and is non-empty in both languages', () {
      expect(en.scene_deleted, isNotEmpty);
      expect(bn.scene_deleted, isNotEmpty);
    });
  });

  group('Localization — spot-check across feature areas (both languages)', () {
    // One key from each of: core app info, error/link handling, dashboard,
    // device setup, BLE provisioning, settings, history/events, schedules.
    // Function type is the shared abstract base so it works for en AND bn.
    final keysToCheck = <String, String Function(AppLocalizations)>{
      'app_name':            (l) => l.app_name,
      'schedule_deleted':    (l) => l.schedule_deleted,
      'could_not_open_link': (l) => l.could_not_open_link,
      'failed':              (l) => l.failed,
      'no_devices':          (l) => l.no_devices,
      'tab_events':          (l) => l.tab_events,
      'appearance':          (l) => l.appearance,
      'dash_total_run':      (l) => l.dash_total_run,
      'dash_device_info':    (l) => l.dash_device_info,
      'ble_wifi_ssid_hint':  (l) => l.ble_wifi_ssid_hint,
      'pump_status':         (l) => l.pump_status,
    };

    for (final entry in keysToCheck.entries) {
      test('${entry.key} is non-empty in English', () {
        expect(entry.value(en), isNotEmpty, reason: '${entry.key} missing/empty in EN');
      });
      test('${entry.key} is non-empty in Bengali', () {
        expect(entry.value(bn), isNotEmpty, reason: '${entry.key} missing/empty in BN');
      });
    }
  });

  group('Localization — EN and BN never return identical text for real Bengali content', () {
    // A handful of keys whose Bengali translation should clearly differ from
    // English (catches the "copy-pasted English into the bn.arb value" mistake).
    final pairs = <String, List<String>>{
      'app_name':         [en.app_name, bn.app_name],
      'failed':           [en.failed, bn.failed],
      'no_devices':       [en.no_devices, bn.no_devices],
      'schedule_deleted': [en.schedule_deleted, bn.schedule_deleted],
      'automation_deleted': [en.automation_deleted, bn.automation_deleted],
      'scene_deleted':    [en.scene_deleted, bn.scene_deleted],
    };
    pairs.forEach((key, values) {
      test('$key: Bengali differs from English', () {
        expect(values[1], isNot(equals(values[0])), reason: '$key looks untranslated');
      });
    });
  });
}
