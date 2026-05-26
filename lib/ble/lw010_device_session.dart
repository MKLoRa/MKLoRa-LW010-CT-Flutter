import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/ble_device_info.dart';
import 'lw010_ble_client.dart';
import 'lw010_protocol_api.dart';

class Lw010DeviceSession {
  Lw010DeviceSession._({
    required this.deviceInfo,
    required this.client,
    required this.protocol,
    required this.deviceInfoApi,
  });

  final BleDeviceInfo deviceInfo;
  final Lw010BleClient client;
  final Lw010ProtocolApi protocol;
  final Lw010DeviceInfoApi deviceInfoApi;

  static Lw010DeviceSession? _active;

  static Lw010DeviceSession? get active => _active;

  static Future<Lw010DeviceSession> connect({
    required BleDeviceInfo deviceInfo,
    String? password,
  }) async {
    final bluetoothDevice = BluetoothDevice.fromId(deviceInfo.id.str);
    final client = Lw010BleClient();

    await client.connectWithRetry(bluetoothDevice);

    if (password != null && password.isNotEmpty) {
      final verified = await client.verifyPassword(password);
      if (!verified) {
        await client.disconnect();
        throw Lw010ProtocolException('Password verification failed');
      }
    }

    final session = Lw010DeviceSession._(
      deviceInfo: deviceInfo,
      client: client,
      protocol: Lw010ProtocolApi(client),
      deviceInfoApi: Lw010DeviceInfoApi(client),
    );
    _active = session;
    return session;
  }

  Future<void> disconnect() async {
    await client.disconnect();
    clearActiveIfMatches(this);
  }

  static void clearActiveIfMatches(Lw010DeviceSession session) {
    if (_active == session) {
      _active = null;
    }
  }
}
