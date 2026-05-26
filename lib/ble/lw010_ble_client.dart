import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'lw010_constants.dart';
import 'lw010_disconnect_event.dart';
import 'lw010_protocol_codec.dart';
import 'lw010_protocol_logger.dart';

class Lw010BleClient {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _passwordChar;
  BluetoothCharacteristic? _disconnectChar;
  BluetoothCharacteristic? _paramsChar;
  BluetoothCharacteristic? _defaultParamsChar;
  BluetoothCharacteristic? _productionTestChar;
  BluetoothCharacteristic? _modelNumberChar;
  BluetoothCharacteristic? _serialNumberChar;
  BluetoothCharacteristic? _firmwareRevisionChar;
  BluetoothCharacteristic? _hardwareRevisionChar;
  BluetoothCharacteristic? _softwareRevisionChar;
  BluetoothCharacteristic? _manufacturerNameChar;

  final Map<String, StreamSubscription<List<int>>> _notifySubscriptions = {};
  final Map<String, Completer<List<int>>> _pendingRequests = {};
  final Map<String, List<List<int>>> _packetBuffers = {};
  final _disconnectController = StreamController<Lw010DisconnectEvent>.broadcast();
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  Future<void> _requestChain = Future<void>.value();

  Stream<Lw010DisconnectEvent> get disconnectEvents => _disconnectController.stream;

  BluetoothDevice? get device => _device;
  bool get isConnected => _device?.isConnected ?? false;

  Future<void> connectWithRetry(BluetoothDevice device) async {
    _device = device;
    final deadline = DateTime.now().add(Lw010ProtocolConstants.connectTotalTimeout);
    Object? lastError;

    for (var attempt = 0; attempt < Lw010ProtocolConstants.connectMaxAttempts; attempt++) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        throw TimeoutException(
          'Connection timed out after ${Lw010ProtocolConstants.connectTotalTimeout.inSeconds}s',
        );
      }

      try {
        if (device.isConnected) {
          await device.disconnect();
        }
        await device.connect(
          timeout: remaining,
          autoConnect: false,
        );
        if (Platform.isAndroid) {
          await device.requestMtu(247);
        }
        await _discoverServices(device);
        await _enableNotifications();
        // Match Android: wait briefly after connect before sending protocol frames.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _listenConnectionState(device);
        return;
      } catch (error) {
        lastError = error;
        debugPrint('LW010 connect attempt ${attempt + 1} failed: $error');
        if (attempt < Lw010ProtocolConstants.connectMaxAttempts - 1) {
          await Future<void>.delayed(
            const Duration(milliseconds: Lw010ProtocolConstants.connectRetryDelayMs),
          );
        }
      }
    }

    throw lastError ?? Exception('Connection failed');
  }

  Future<void> disconnect() async {
    await _clearSubscriptions();
    final device = _device;
    _device = null;
    if (device != null && device.isConnected) {
      await device.disconnect();
    }
  }

  Future<bool> verifyPassword(String password) async {
    final characteristic = _requireCharacteristic(_passwordChar, 'password');
    final response = await _sendFrame(
      characteristic: characteristic,
      payload: Lw010ProtocolCodec.buildPasswordFrame(password),
      cmd: Lw010ProtocolConstants.passwordCmd,
      subCmd: Lw010ProtocolConstants.passwordSubCmd,
      matcher: Lw010ProtocolCodec.isPasswordSuccess,
    );
    return Lw010ProtocolCodec.isPasswordSuccess(response);
  }

  Future<Lw010ParamResult> readParam({
    required int cmd,
    required int subCmd,
    Lw010ParamChannel channel = Lw010ParamChannel.runtime,
    bool packet = false,
  }) async {
    final characteristic = _characteristicForChannel(channel);
    final response = await _sendFrame(
      characteristic: characteristic,
      payload: Lw010ProtocolCodec.buildReadFrame(
        cmd: cmd,
        subCmd: subCmd,
        packet: packet,
      ),
      cmd: cmd,
      subCmd: subCmd,
    );
    final parsed = Lw010ProtocolCodec.parseReadResponse(response);
    if (parsed == null) {
      throw Lw010ProtocolException('Invalid read response for 0x${cmd.toRadixString(16)}${subCmd.toRadixString(16)}');
    }
    return Lw010ParamResult(
      cmd: parsed.cmd,
      subCmd: parsed.subCmd,
      data: parsed.data,
      raw: response,
    );
  }

  Future<bool> writeParam({
    required int cmd,
    required int subCmd,
    required List<int> data,
    Lw010ParamChannel channel = Lw010ParamChannel.runtime,
    bool packet = false,
  }) async {
    final characteristic = _characteristicForChannel(channel);
    final response = await _sendFrame(
      characteristic: characteristic,
      payload: Lw010ProtocolCodec.buildWriteFrame(
        cmd: cmd,
        subCmd: subCmd,
        data: data,
        packet: packet,
      ),
      cmd: cmd,
      subCmd: subCmd,
      matcher: (value) => Lw010ProtocolCodec.isWriteSuccess(value, cmd, subCmd),
    );
    return Lw010ProtocolCodec.isWriteSuccess(response, cmd, subCmd);
  }

  Future<String> readDeviceInfoString(
    BluetoothCharacteristic characteristic, {
    required String name,
  }) async {
    final value = await characteristic.read();
    Lw010ProtocolLogger.logGattRead(name: name, value: value);
    return String.fromCharCodes(value.where((b) => b != 0)).trim();
  }

  Future<String> readModelNumber() => readDeviceInfoString(
        _requireCharacteristic(_modelNumberChar, 'model number'),
        name: 'modelNumber',
      );
  Future<String> readSerialNumber() => readDeviceInfoString(
        _requireCharacteristic(_serialNumberChar, 'serial number'),
        name: 'serialNumber',
      );
  Future<String> readFirmwareRevision() => readDeviceInfoString(
        _requireCharacteristic(_firmwareRevisionChar, 'firmware revision'),
        name: 'firmwareRevision',
      );
  Future<String> readHardwareRevision() => readDeviceInfoString(
        _requireCharacteristic(_hardwareRevisionChar, 'hardware revision'),
        name: 'hardwareRevision',
      );
  Future<String> readSoftwareRevision() => readDeviceInfoString(
        _requireCharacteristic(_softwareRevisionChar, 'software revision'),
        name: 'softwareRevision',
      );
  Future<String> readManufacturerName() => readDeviceInfoString(
        _requireCharacteristic(_manufacturerNameChar, 'manufacturer name'),
        name: 'manufacturerName',
      );

  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();
    final deviceInfo = _findService(services, Lw010Uuids.deviceInfoService);
    final custom = _findService(services, Lw010Uuids.customService);

    if (deviceInfo == null) {
      throw Lw010ProtocolException('Device Information Service not found');
    }
    if (custom == null) {
      throw Lw010ProtocolException('Custom service 0xAA00 not found');
    }

    _modelNumberChar = _findCharacteristic(deviceInfo, Lw010Uuids.modelNumber);
    _serialNumberChar = _findCharacteristic(deviceInfo, Lw010Uuids.serialNumber);
    _firmwareRevisionChar = _findCharacteristic(deviceInfo, Lw010Uuids.firmwareRevision);
    _hardwareRevisionChar = _findCharacteristic(deviceInfo, Lw010Uuids.hardwareRevision);
    _softwareRevisionChar = _findCharacteristic(deviceInfo, Lw010Uuids.softwareRevision);
    _manufacturerNameChar = _findCharacteristic(deviceInfo, Lw010Uuids.manufacturerName);

    _passwordChar = _findCharacteristic(custom, Lw010Uuids.password);
    _disconnectChar = _findCharacteristic(custom, Lw010Uuids.disconnectNotify);
    _paramsChar = _findCharacteristic(custom, Lw010Uuids.params);
    _defaultParamsChar = _findCharacteristic(custom, Lw010Uuids.defaultParams);
    _productionTestChar = _findCharacteristic(custom, Lw010Uuids.productionTest);

    if (_passwordChar == null || _paramsChar == null || _disconnectChar == null) {
      throw Lw010ProtocolException('Required custom characteristics not found');
    }
  }

  Future<void> _enableNotifications() async {
    await _subscribeCharacteristic(_passwordChar!, 'password');
    await _subscribeCharacteristic(_disconnectChar!, 'disconnect');
    await _subscribeCharacteristic(_paramsChar!, 'params');
    if (_defaultParamsChar != null) {
      await _subscribeCharacteristic(_defaultParamsChar!, 'defaultParams');
    }
    if (_productionTestChar != null) {
      await _subscribeCharacteristic(_productionTestChar!, 'productionTest');
    }
  }

  Future<void> _subscribeCharacteristic(
    BluetoothCharacteristic characteristic,
    String key,
  ) async {
    await characteristic.setNotifyValue(true);
    await _notifySubscriptions[key]?.cancel();
    _notifySubscriptions[key] = characteristic.onValueReceived.listen(
      (value) => _handleNotification(key, value),
    );
  }

  void _handleNotification(String key, List<int> value) {
    if (value.isEmpty) {
      return;
    }

    if (key == 'disconnect') {
      Lw010ProtocolLogger.logDisconnectNotify(value);
      final event = Lw010DisconnectEvent.fromNotificationBytes(value);
      if (event != null) {
        _disconnectController.add(event);
      }
      return;
    }

    if (value[0] == Lw010ProtocolConstants.headPacket) {
      Lw010ProtocolLogger.logRx(channel: key, payload: value, partialPacket: true);
      final requestKey = _requestKeyFromPacket(value);
      _packetBuffers.putIfAbsent(requestKey, () => []).add(value);
      final packets = _packetBuffers[requestKey]!;
      final expectedCount = value[4];
      if (packets.length >= expectedCount) {
        final merged = Lw010ProtocolCodec.reassemblePacketResponses(packets);
        _packetBuffers.remove(requestKey);
        Lw010ProtocolLogger.logRx(channel: key, payload: merged);
        _completeRequest(requestKey, merged);
      }
      return;
    }

    Lw010ProtocolLogger.logRx(channel: key, payload: value);
    final requestKey = _requestKeyFromFrame(value);
    _completeRequest(requestKey, value);
  }

  Future<List<int>> _sendFrame({
    required BluetoothCharacteristic characteristic,
    required List<int> payload,
    required int cmd,
    required int subCmd,
    bool Function(List<int> value)? matcher,
  }) {
    return _enqueueRequest(() async {
      final requestKey = _requestKey(cmd, subCmd);
      final completer = Completer<List<int>>();
      _pendingRequests[requestKey] = completer;

      try {
        Lw010ProtocolLogger.logTx(
          channel: _channelNameForCharacteristic(characteristic),
          cmd: cmd,
          subCmd: subCmd,
          payload: payload,
        );
        final withoutResponse = _shouldWriteWithoutResponse(characteristic);
        await characteristic.write(payload, withoutResponse: withoutResponse);
        final response = await completer.future.timeout(
          Lw010ProtocolConstants.requestTimeout,
          onTimeout: () {
            Lw010ProtocolLogger.logError('Request timeout for $requestKey');
            throw TimeoutException('Request timeout for $requestKey');
          },
        );
        if (matcher != null && !matcher(response)) {
          Lw010ProtocolLogger.logError('Unexpected response for $requestKey');
          throw Lw010ProtocolException('Unexpected response for $requestKey');
        }
        return response;
      } finally {
        _pendingRequests.remove(requestKey);
        _packetBuffers.remove(requestKey);
      }
    });
  }

  Future<T> _enqueueRequest<T>(Future<T> Function() action) {
    final task = _requestChain.then((_) => action());
    _requestChain = task.then((_) {}, onError: (_) {});
    return task;
  }

  bool _shouldWriteWithoutResponse(BluetoothCharacteristic characteristic) {
    final properties = characteristic.properties;
    if (properties.write) {
      return false;
    }
    return properties.writeWithoutResponse;
  }

  void _completeRequest(String requestKey, List<int> value) {
    final completer = _pendingRequests[requestKey];
    if (completer != null && !completer.isCompleted) {
      completer.complete(value);
    }
  }

  BluetoothCharacteristic _characteristicForChannel(Lw010ParamChannel channel) {
    switch (channel) {
      case Lw010ParamChannel.runtime:
        return _requireCharacteristic(_paramsChar, 'params');
      case Lw010ParamChannel.defaultConfig:
        return _requireCharacteristic(_defaultParamsChar, 'default params');
      case Lw010ParamChannel.productionTest:
        return _requireCharacteristic(_productionTestChar, 'production test');
    }
  }

  BluetoothService? _findService(List<BluetoothService> services, String uuid) {
    final target = Guid(uuid);
    for (final service in services) {
      if (service.uuid == target) {
        return service;
      }
    }
    return null;
  }

  BluetoothCharacteristic? _findCharacteristic(
    BluetoothService service,
    String uuid,
  ) {
    final target = Guid(uuid);
    for (final characteristic in service.characteristics) {
      if (characteristic.uuid == target) {
        return characteristic;
      }
    }
    return null;
  }

  BluetoothCharacteristic _requireCharacteristic(
    BluetoothCharacteristic? characteristic,
    String name,
  ) {
    if (characteristic == null) {
      throw Lw010ProtocolException('$name characteristic unavailable');
    }
    return characteristic;
  }

  String _channelNameForCharacteristic(BluetoothCharacteristic characteristic) {
    if (identical(characteristic, _passwordChar)) return 'password';
    if (identical(characteristic, _paramsChar)) return 'params';
    if (identical(characteristic, _defaultParamsChar)) return 'defaultParams';
    if (identical(characteristic, _productionTestChar)) return 'productionTest';
    return characteristic.uuid.toString();
  }

  String _requestKey(int cmd, int subCmd) => '${cmd.toRadixString(16)}_${subCmd.toRadixString(16)}';

  String _requestKeyFromFrame(List<int> value) {
    if (value.length < 4) {
      return 'unknown';
    }
    return _requestKey(value[2], value[3]);
  }

  String _requestKeyFromPacket(List<int> value) {
    if (value.length < 4) {
      return 'unknown';
    }
    return _requestKey(value[2], value[3]);
  }

  void _listenConnectionState(BluetoothDevice device) {
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _disconnectController.add(Lw010DisconnectEvent.generic);
      }
    });
  }

  Future<void> _clearSubscriptions() async {
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    for (final subscription in _notifySubscriptions.values) {
      await subscription.cancel();
    }
    _notifySubscriptions.clear();
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          Lw010ProtocolException('Connection closed'),
        );
      }
    }
    _pendingRequests.clear();
    _packetBuffers.clear();
  }
}

enum Lw010ParamChannel {
  runtime,
  defaultConfig,
  productionTest,
}

class Lw010ParamResult {
  const Lw010ParamResult({
    required this.cmd,
    required this.subCmd,
    required this.data,
    required this.raw,
  });

  final int cmd;
  final int subCmd;
  final List<int> data;
  final List<int> raw;

  int get key => ((cmd & 0xFF) << 8) | (subCmd & 0xFF);
}

class Lw010ProtocolException implements Exception {
  Lw010ProtocolException(this.message);

  final String message;

  @override
  String toString() => 'Lw010ProtocolException: $message';
}
