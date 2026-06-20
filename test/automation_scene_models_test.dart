// test/automation_scene_models_test.dart
// SmartIoT v1.0.2 — Automation & Scene model tests
// Run: flutter test
// These mirror the existing DeviceStatus/DeviceMeta tests in widget_test.dart,
// extended to cover AutomationModel and SceneModel (added in v8.0, never had
// dedicated test coverage before this pass).

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_iot_interface/screens/automations_screen.dart';
import 'package:smart_iot_interface/screens/scenes_screen.dart';
import 'package:smart_iot_interface/theme/app_theme.dart';

void main() {
  // ── AutomationModel ────────────────────────────────────────────────────
  group('AutomationModel', () {
    test('fromMap parses all known fields correctly', () {
      final rule = AutomationModel.fromMap('rule1', {
        'name': 'Low water alert',
        'triggerType': 'level_below',
        'triggerValue': 25,
        'actionType': 'pump_on',
        'enabled': true,
        'createdAt': 1700000000,
      });
      expect(rule.id, equals('rule1'));
      expect(rule.name, equals('Low water alert'));
      expect(rule.triggerType, equals('level_below'));
      expect(rule.triggerValue, equals(25));
      expect(rule.actionType, equals('pump_on'));
      expect(rule.enabled, isTrue);
      expect(rule.createdAt, equals(1700000000));
    });

    test('fromMap falls back to safe defaults when fields are missing', () {
      final rule = AutomationModel.fromMap('rule2', {});
      expect(rule.name, equals('Rule'));
      expect(rule.triggerType, equals('level_below'));
      expect(rule.triggerValue, equals(20));
      expect(rule.actionType, equals('pump_on'));
      expect(rule.enabled, isFalse);
      expect(rule.createdAt, equals(0));
    });

    test('toMap excludes id (id is the Firebase key, not a field)', () {
      const rule = AutomationModel(
        id: 'rule3', name: 'Test', triggerType: 'pump_on_mins',
        triggerValue: 10, actionType: 'alert', enabled: true, createdAt: 123,
      );
      final map = rule.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['name'], equals('Test'));
      expect(map['triggerValue'], equals(10));
    });

    test('triggerLabel produces the expected text for every known trigger type', () {
      const below = AutomationModel(id: '1', name: '', triggerType: 'level_below',
          triggerValue: 30, actionType: 'pump_on', enabled: true, createdAt: 0);
      const above = AutomationModel(id: '2', name: '', triggerType: 'level_above',
          triggerValue: 90, actionType: 'pump_off', enabled: true, createdAt: 0);
      const pumpMins = AutomationModel(id: '3', name: '', triggerType: 'pump_on_mins',
          triggerValue: 15, actionType: 'alert', enabled: true, createdAt: 0);
      const timeOfDay = AutomationModel(id: '4', name: '', triggerType: 'time_of_day',
          triggerValue: 8, actionType: 'mode_auto', enabled: true, createdAt: 0);

      expect(below.triggerLabel, equals('Water below 30%'));
      expect(above.triggerLabel, equals('Water above 90%'));
      expect(pumpMins.triggerLabel, equals('Pump ON > 15 min'));
      expect(timeOfDay.triggerLabel, equals('Every day at 08:00'));
    });

    test('triggerLabel falls back to the raw triggerType string for unknown values', () {
      const unknown = AutomationModel(id: '5', name: '', triggerType: 'something_new',
          triggerValue: 1, actionType: 'pump_on', enabled: true, createdAt: 0);
      expect(unknown.triggerLabel, equals('something_new'));
    });
  });

  // ── SceneModel ─────────────────────────────────────────────────────────
  group('SceneModel', () {
    test('fromMap parses all known fields correctly', () {
      final scene = SceneModel.fromMap('scene1', {
        'name': 'Night Mode',
        'icon': '🌙',
        'pumpCmd': 'OFF',
        'modeCmd': 'AUTO',
        'color': 'blue',
        'createdAt': 1700000000,
      });
      expect(scene.id, equals('scene1'));
      expect(scene.name, equals('Night Mode'));
      expect(scene.icon, equals('🌙'));
      expect(scene.pumpCmd, equals('OFF'));
      expect(scene.modeCmd, equals('AUTO'));
      expect(scene.color, equals('blue'));
    });

    test('fromMap falls back to safe defaults when fields are missing', () {
      final scene = SceneModel.fromMap('scene2', {});
      expect(scene.name, equals('Scene'));
      expect(scene.icon, equals('⚡'));
      expect(scene.pumpCmd, equals('NONE'));
      expect(scene.modeCmd, equals('NONE'));
      expect(scene.color, equals('purple'));
      expect(scene.createdAt, equals(0));
    });

    test('toMap excludes id (id is the Firebase key, not a field)', () {
      const scene = SceneModel(
        id: 'scene3', name: 'Test', icon: '💧', pumpCmd: 'ON',
        modeCmd: 'MANUAL', color: 'green', createdAt: 456,
      );
      final map = scene.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['pumpCmd'], equals('ON'));
    });

    test('accentColor maps every known color name to its AppTheme equivalent', () {
      const blue   = SceneModel(id: '1', name: '', icon: '', pumpCmd: 'NONE', modeCmd: 'NONE', color: 'blue', createdAt: 0);
      const green  = SceneModel(id: '2', name: '', icon: '', pumpCmd: 'NONE', modeCmd: 'NONE', color: 'green', createdAt: 0);
      const orange = SceneModel(id: '3', name: '', icon: '', pumpCmd: 'NONE', modeCmd: 'NONE', color: 'orange', createdAt: 0);
      const red    = SceneModel(id: '4', name: '', icon: '', pumpCmd: 'NONE', modeCmd: 'NONE', color: 'red', createdAt: 0);
      const other  = SceneModel(id: '5', name: '', icon: '', pumpCmd: 'NONE', modeCmd: 'NONE', color: 'purple', createdAt: 0);

      expect(blue.accentColor, equals(AppTheme.accent));
      expect(green.accentColor, equals(AppTheme.success));
      expect(orange.accentColor, equals(AppTheme.warning));
      expect(red.accentColor, equals(AppTheme.danger));
      expect(other.accentColor, equals(AppTheme.smartPurple));
    });

    test('accentColor falls back to smartPurple for an unrecognised color name', () {
      const scene = SceneModel(id: '6', name: '', icon: '', pumpCmd: 'NONE', modeCmd: 'NONE', color: 'made_up_color', createdAt: 0);
      expect(scene.accentColor, equals(AppTheme.smartPurple));
    });
  });
}
