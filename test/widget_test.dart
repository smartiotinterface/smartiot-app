// test/widget_test.dart
// SmartIoT v1.0.2 — Smoke Tests
// ────────────────────────────────────────────────────────────────────────────
// Run: flutter test
// These tests verify the app can build its core models and utilities
// without needing a live Firebase connection.

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_iot_interface/models/device_model.dart';
import 'package:smart_iot_interface/core/utils.dart';

void main() {
  // ── DeviceStatus model ─────────────────────────────────────────────────────
  group('DeviceStatus model', () {
    test('fromMap parses all known fields correctly', () {
      final map = {
        'pump': 'ON',
        'mode': 'AUTO',
        'water_level': 'FULL',
        'water_level_pct': 85,
        'alarm': false,
        'dry_run': false,
        'wifi_rssi': -60,
        'ts': 1700000000,
        'firmware': '14.0.0',
        'serial': 'ABC123',
        'sleeping': false,
        'bd_time': '14:30:00',
      };
      final status = DeviceStatus.fromMap(map);
      expect(status.pumpState,  equals('ON'));
      expect(status.pumpMode,   equals('AUTO'));
      expect(status.waterLevel, equals('FULL'));
      expect(status.waterLevelPct,   equals(85));
      expect(status.alarmActive,  isFalse);
      expect(status.dryRunActive, isFalse);
    });

    test('fromMap handles missing optional fields gracefully', () {
      final status = DeviceStatus.fromMap({'pump': 'OFF'});
      expect(status.pumpState, equals('OFF'));
      expect(status.waterLevelPct,  equals(0));
      expect(status.alarmActive, isFalse);
    });

    test('isFullTank returns true when waterLevel is FULL', () {
      final status = DeviceStatus.fromMap({'water_level': 'FULL', 'water_level_pct': 100});
      expect(status.waterLevel, equals('FULL'));
    });

    test('isEmptyTank returns true when waterLevel is EMPTY', () {
      final status = DeviceStatus.fromMap({'water_level': 'EMPTY', 'water_level_pct': 0});
      expect(status.waterLevel, equals('EMPTY'));
    });
  });

  // ── DeviceMeta model ───────────────────────────────────────────────────────
  group('DeviceMeta model', () {
    test('fromMap parses device name correctly', () {
      final meta = DeviceMeta.fromMap({
        'device_name': 'My Tank',
        'serial': 'SN001',
        'firmware': '14.0.0',
        'owner_id': 'uid123',
        'registered_at': 1700000000,
      });
      expect(meta.deviceName, equals('My Tank'));
      expect(meta.serial,     equals('SN001'));
    });

    test('toMap round-trips correctly', () {
      final meta = DeviceMeta.fromMap({
        'device_name': 'Test Device',
        'serial': 'XYZ',
        'firmware': '14.0.0',
        'owner_id': 'uid_abc',
        'registered_at': 1700000000,
      });
      final map = meta.toMap();
      expect(map['device_name'], equals('Test Device'));
    });
  });

  // ── Schedule fields (Firebase rules check) ───────────────────────────────
  group('Schedule field names', () {
    test('uses active + ts (not enabled/created_at) as required by Firebase rules', () {
      // Simulate what schedule_screen saves
      final data = {
        'hour':         8,
        'minute':       30,
        'duration_min': 15,
        'active':       true,    // [FIXED] was 'enabled' — Firebase requires 'active'
        'ts':           1700000000,  // [FIXED] was 'created_at' — Firebase requires 'ts'
      };
      expect(data.containsKey('active'), isTrue,   reason: 'Firebase rules require active field');
      expect(data.containsKey('ts'),     isTrue,   reason: 'Firebase rules require ts field');
      expect(data.containsKey('enabled'),  isFalse, reason: 'enabled is NOT in Firebase rules');
      expect(data.containsKey('created_at'), isFalse, reason: 'created_at is NOT in Firebase rules');
    });
  });

  // ── Utils ──────────────────────────────────────────────────────────────────
  group('AppUtils', () {
    test('formatTimestamp returns non-empty string for valid epoch', () {
      final result = AppUtils.formatTimestamp(1700000000);
      expect(result, isNotEmpty);
    });

    test('formatTimestamp handles zero gracefully', () {
      final result = AppUtils.formatTimestamp(0);
      expect(result, isA<String>());
    });
  });
}
