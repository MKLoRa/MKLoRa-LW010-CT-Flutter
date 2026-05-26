import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/ble_device_info.dart';

/// Resolves the device identifier passed to Nordic DFU.
///
/// Android uses the chip MAC (same as the native LW010 app).
/// iOS CoreBluetooth DFU requires the peripheral UUID from the BLE stack,
/// not the MAC read from the custom protocol.
String lw010DfuDeviceAddress({
  required BleDeviceInfo deviceInfo,
  required String chipMac,
}) {
  if (Platform.isIOS) {
    return deviceInfo.id.str;
  }
  return chipMac;
}

/// Copies a picked firmware zip into app-accessible storage when needed.
Future<String> lw010PrepareDfuFirmwarePath(PlatformFile picked) async {
  final name = picked.name.trim();
  if (name.isEmpty || !name.toLowerCase().endsWith('.zip')) {
    throw Lw010DfuFileException('File error!');
  }

  final bytes = picked.bytes ??
      (picked.path == null ? null : await File(picked.path!).readAsBytes());
  if (bytes == null || bytes.isEmpty) {
    throw Lw010DfuFileException('File error!');
  }

  if (!Platform.isIOS && picked.path != null) {
    final source = File(picked.path!);
    if (source.existsSync()) {
      return source.absolute.path;
    }
  }

  final tempDir = Directory.systemTemp.createTempSync('lw010_dfu_');
  final fileName = name.split('/').last.split('\\').last;
  final target = File('${tempDir.path}/$fileName');
  await target.writeAsBytes(bytes, flush: true);
  debugPrint('[LW010 DFU] firmware copied to ${target.path} (${bytes.length} bytes)');
  return target.path;
}

class Lw010DfuFileException implements Exception {
  Lw010DfuFileException(this.message);

  final String message;

  @override
  String toString() => message;
}
