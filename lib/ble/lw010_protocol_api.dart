import 'lw010_ble_client.dart';
import 'lw010_param_key.dart';

class Lw010ProtocolApi {
  Lw010ProtocolApi(this._client);

  final Lw010BleClient _client;

  Lw010BleClient get client => _client;

  Future<bool> verifyPassword(String password) {
    return _client.verifyPassword(password);
  }

  Future<Lw010ParamResult> readParam(
    Lw010ParamKey key, {
    Lw010ParamChannel channel = Lw010ParamChannel.runtime,
    bool packet = false,
  }) {
    if (!key.canRead) {
      throw Lw010ProtocolException('Parameter ${key.name} is write-only');
    }
    return _client.readParam(
      cmd: key.cmd,
      subCmd: key.subCmd,
      channel: channel,
      packet: packet,
    );
  }

  Future<bool> writeParam(
    Lw010ParamKey key,
    List<int> data, {
    Lw010ParamChannel channel = Lw010ParamChannel.runtime,
    bool packet = false,
  }) {
    if (!key.canWrite) {
      throw Lw010ProtocolException('Parameter ${key.name} is read-only');
    }
    return _client.writeParam(
      cmd: key.cmd,
      subCmd: key.subCmd,
      data: data,
      channel: channel,
      packet: packet,
    );
  }

  Future<Lw010ParamResult> readDefaultParam(Lw010ParamKey key) {
    return readParam(key, channel: Lw010ParamChannel.defaultConfig);
  }

  Future<bool> writeDefaultParam(Lw010ParamKey key, List<int> data) {
    return writeParam(key, data, channel: Lw010ParamChannel.defaultConfig);
  }

  Future<bool> enterProductionTestMode() {
    return _client.writeParam(
      cmd: 0x0A,
      subCmd: 0x00,
      data: const [],
      channel: Lw010ParamChannel.productionTest,
    );
  }

  Future<Lw010ParamResult> readProductionTestStatus() {
    return _client.readParam(
      cmd: 0x0A,
      subCmd: 0x02,
      channel: Lw010ParamChannel.productionTest,
    );
  }
}

class Lw010DeviceInfoApi {
  Lw010DeviceInfoApi(this._client);

  final Lw010BleClient _client;

  Future<String> readModelNumber() => _client.readModelNumber();
  Future<String> readSerialNumber() => _client.readSerialNumber();
  Future<String> readFirmwareRevision() => _client.readFirmwareRevision();
  Future<String> readHardwareRevision() => _client.readHardwareRevision();
  Future<String> readSoftwareRevision() => _client.readSoftwareRevision();
  Future<String> readManufacturerName() => _client.readManufacturerName();
}
