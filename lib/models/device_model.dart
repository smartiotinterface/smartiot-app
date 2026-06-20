// lib/models/device_model.dart
// [FIX HIGH-6] DeviceStatus.empty is now static const
// Added extra fields: dryRun, pumpCycles, pumpTotalS, bootCount

import '../core/constants.dart';
import '../core/utils.dart';

class DeviceStatus {
  final String waterLevel;     // "EMPTY" | "LOW" | "MID" | "FULL"
  final int waterLevelPct;     // 0–100
  final String pumpState;      // "ON" | "OFF"
  final String pumpMode;       // "AUTO" | "MANUAL"
  final String sensorMode;     // "FLOAT" | "ULTRA"
  final int wifiRssi;
  final String uptime;
  final dynamic timestamp;
  final bool alarmActive;
  final bool dryRunActive;
  final int pumpCycles;
  final int pumpTotalSeconds;
  final int bootCount;
  final int heapFree;

  const DeviceStatus({
    required this.waterLevel,
    required this.waterLevelPct,
    required this.pumpState,
    required this.pumpMode,
    required this.sensorMode,
    required this.wifiRssi,
    required this.uptime,
    required this.timestamp,
    required this.alarmActive,
    this.dryRunActive = false,
    this.pumpCycles = 0,
    this.pumpTotalSeconds = 0,
    this.bootCount = 0,
    this.heapFree = 0,
  });

  /// [FIX HIGH-6]: Was an instance getter, now correct static const
  static const DeviceStatus empty = DeviceStatus(
    waterLevel: 'EMPTY',
    waterLevelPct: 0,
    pumpState: 'OFF',
    pumpMode: 'AUTO',
    sensorMode: 'FLOAT',
    wifiRssi: 0,
    uptime: '--',
    timestamp: null,
    alarmActive: false,
  );

  factory DeviceStatus.fromMap(Map<dynamic, dynamic> map) {
    final rawPct = AppUtils.safeParse<int>(map, AppConstants.fieldWaterLevelPct, -1);
    final level  = AppUtils.safeParse<String>(map, AppConstants.fieldWaterLevel, AppConstants.levelEmpty);
    return DeviceStatus(
      waterLevel:       level,
      waterLevelPct:    rawPct >= 0
          ? rawPct.clamp(0, 100)
          : AppUtils.waterLevelToPercent(level, null),
      pumpState:        AppUtils.safeParse<String>(map, AppConstants.fieldPumpState, AppConstants.pumpOff),
      pumpMode:         AppUtils.safeParse<String>(map, AppConstants.fieldPumpMode, AppConstants.modeAuto),
      sensorMode:       AppUtils.safeParse<String>(map, AppConstants.fieldSensorMode, AppConstants.sensorFloat),
      wifiRssi:         AppUtils.safeParse<int>(map, AppConstants.fieldWifiRssi, 0),
      uptime:           AppUtils.safeParse<String>(map, AppConstants.fieldUptime, '--'),
      timestamp:        map[AppConstants.fieldTimestamp],
      alarmActive:      AppUtils.safeParse<bool>(map, AppConstants.fieldAlarm, false),
      dryRunActive:     AppUtils.safeParse<bool>(map, AppConstants.fieldDryRun, false),
      pumpCycles:       AppUtils.safeParse<int>(map, AppConstants.fieldPumpCycles, 0),
      pumpTotalSeconds: AppUtils.safeParse<int>(map, AppConstants.fieldPumpTotalS, 0),
      bootCount:        AppUtils.safeParse<int>(map, AppConstants.fieldBootCount, 0),
      heapFree:         AppUtils.safeParse<int>(map, AppConstants.fieldHeapFree, 0),
    );
  }

  bool get isPumpOn => pumpState.toUpperCase() == AppConstants.pumpOn;
  bool get isAutoMode => pumpMode.toUpperCase() == AppConstants.modeAuto;
  bool get isUltrasonic => sensorMode.toUpperCase() == AppConstants.sensorUltrasonic;

  /// Formatted pump run time as human-readable string
  String get formattedPumpTime {
    final h = pumpTotalSeconds ~/ 3600;
    final m = (pumpTotalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${pumpTotalSeconds % 60}s';
  }
}

class DeviceMeta {
  final String serial;
  final String firmware;
  final String deviceName;
  final String ownerId;
  final int registeredAt;

  const DeviceMeta({
    required this.serial,
    required this.firmware,
    required this.deviceName,
    required this.ownerId,
    required this.registeredAt,
  });

  factory DeviceMeta.fromMap(Map<dynamic, dynamic> map) {
    return DeviceMeta(
      serial:       AppUtils.safeParse<String>(map, AppConstants.fieldSerial, 'Unknown'),
      firmware:     AppUtils.safeParse<String>(map, AppConstants.fieldFirmware, '--'),
      deviceName:   AppUtils.safeParse<String>(map, 'device_name', 'Water Tank'),
      ownerId:      AppUtils.safeParse<String>(map, 'owner_id', ''),
      registeredAt: AppUtils.safeParse<int>(map, 'registered_at', 0),
    );
  }

  Map<String, dynamic> toMap() => {
        AppConstants.fieldSerial:   serial,
        AppConstants.fieldFirmware: firmware,
        'device_name':   deviceName,
        'owner_id':      ownerId,
        'registered_at': registeredAt,
      };
}
