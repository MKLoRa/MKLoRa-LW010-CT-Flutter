import 'package:flutter_blue_plus/flutter_blue_plus.dart';

String hexString(List<int> data) {
  return data
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
}

class BleDeviceInfo {
  final DeviceIdentifier id;
  final String name;
  final String macAddress;
  final int rssi;
  final int? txPowerLevel;
  final int deviceType;
  final int batteryPercent;
  final int batteryVoltageMv;
  final bool passwordEnabled;
  final List<int> rawServiceData;
  final int lastScanMs;
  final int scanIntervalMs;

  BleDeviceInfo({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.rssi,
    required this.txPowerLevel,
    required this.deviceType,
    required this.batteryPercent,
    required this.batteryVoltageMv,
    required this.passwordEnabled,
    required this.rawServiceData,
    this.lastScanMs = 0,
    this.scanIntervalMs = 0,
  });

  String get scanIntervalLabel =>
      scanIntervalMs == 0 ? '<->N/A' : '<->${scanIntervalMs}ms';

  BleDeviceInfo copyWith({
    DeviceIdentifier? id,
    String? name,
    String? macAddress,
    int? rssi,
    int? txPowerLevel,
    int? deviceType,
    int? batteryPercent,
    int? batteryVoltageMv,
    bool? passwordEnabled,
    List<int>? rawServiceData,
    int? lastScanMs,
    int? scanIntervalMs,
  }) {
    return BleDeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      rssi: rssi ?? this.rssi,
      txPowerLevel: txPowerLevel ?? this.txPowerLevel,
      deviceType: deviceType ?? this.deviceType,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      batteryVoltageMv: batteryVoltageMv ?? this.batteryVoltageMv,
      passwordEnabled: passwordEnabled ?? this.passwordEnabled,
      rawServiceData: rawServiceData ?? this.rawServiceData,
      lastScanMs: lastScanMs ?? this.lastScanMs,
      scanIntervalMs: scanIntervalMs ?? this.scanIntervalMs,
    );
  }

  static BleDeviceInfo? fromScanResult(ScanResult result) {
    for (final data in result.advertisementData.serviceData.values) {
      if (data.length >= 12) {
        final deviceType = data[0];
        final batteryPercent = data.length > 7 ? data[7] : 0;
        final batteryVoltageMv = data.length > 9 ? (data[8] << 8 | data[9]) : 0;
        final passwordEnabled = data.length > 10
            ? (data[10] & 0x80) != 0
            : false;
        final macAddress = data
            .sublist(1, 7)
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':');

        return BleDeviceInfo(
          id: result.device.remoteId,
          name: result.advertisementData.advName.isNotEmpty
              ? result.advertisementData.advName
              : result.device.advName,
          macAddress: macAddress,
          rssi: result.rssi,
          txPowerLevel: result.advertisementData.txPowerLevel,
          deviceType: deviceType,
          batteryPercent: batteryPercent,
          batteryVoltageMv: batteryVoltageMv,
          passwordEnabled: passwordEnabled,
          rawServiceData: data,
        );
      }
    }
    return null;
  }
}
