import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../ble/lw010.dart';
import '../models/ble_device_info.dart';

class BleScanViewModel extends ChangeNotifier {
  static const titleBarColor = Color(0xFF2F84D0);

  final _advServiceUuid1 = '0000aa15-0000-1000-8000-00805f9b34fb';
  final _advServiceUuid2 = '0000bb10-0000-1000-8000-00805f9b34fb';

  final Map<DeviceIdentifier, BleDeviceInfo> _devices = {};
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _scanTimer;

  bool _isScanning = false;
  bool _retryScanOnResume = false;
  String? _lastError;

  String _filterKeyword = '';
  int _filterRssiDbm = -127;

  bool _disposed = false;

  Lw010DeviceSession? _connectedSession;

  Lw010DeviceSession? get connectedSession => _connectedSession;

  bool get isScanning => _isScanning;
  String? get lastError => _lastError;

  String get filterKeyword => _filterKeyword;
  int get filterRssiDbm => _filterRssiDbm;

  bool get hasFilter =>
      _filterKeyword.trim().isNotEmpty || _filterRssiDbm != -127;

  List<BleDeviceInfo> get filteredDevices {
    final list = _devices.values.where(matchesFilter).toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    return list;
  }

  String formatHexString(List<int> data) => hexString(data);

  Future<void> init(BuildContext context) async {
    await startScan(context: context, clearDevices: true);
  }

  @override
  void dispose() {
    _disposed = true;
    _scanTimer?.cancel();
    _scanTimer = null;
    stopScan();
    unawaited(_connectedSession?.disconnect());
    _connectedSession = null;
    super.dispose();
  }

  void onAppResumed(BuildContext context) {
    if (_retryScanOnResume && !_isScanning) {
      _retryScanOnResume = false;
      unawaited(startScan(context: context, clearDevices: false));
    }
  }

  String filterSummary() {
    final keyword = _filterKeyword.trim();
    final buffer = StringBuffer();
    if (keyword.isNotEmpty) {
      buffer.write(keyword);
      buffer.write(';');
    }
    if (_filterRssiDbm != -127) {
      buffer.write('$_filterRssiDbm');
      buffer.write('dBm;');
    }
    return buffer.toString();
  }

  bool matchesFilter(BleDeviceInfo device) {
    final rssiOk = _filterRssiDbm == -127 || device.rssi >= _filterRssiDbm;
    if (!rssiOk) {
      return false;
    }

    final keyword = _filterKeyword.trim();
    if (keyword.isEmpty) {
      return true;
    }

    final keywordLower = keyword.toLowerCase();
    final name = device.name.isNotEmpty ? device.name : device.id.str;
    final nameOk = name.toLowerCase().contains(keywordLower);
    if (nameOk) {
      return true;
    }

    final keywordForMac = keywordLower.replaceAll(':', '');
    if (keywordForMac.isEmpty) {
      return false;
    }

    final mac = device.macAddress.replaceAll(':', '').toLowerCase();
    final macOk = mac.contains(keywordForMac);
    return macOk;
  }

  Future<void> applyFilter({
    required BuildContext context,
    required String keyword,
    required int rssiDbm,
  }) async {
    _filterKeyword = keyword.trim();
    _filterRssiDbm = rssiDbm;
    _safeNotify();

    if (hasFilter) {
      await clearListAndRescan(context);
    }
  }

  Future<void> clearFilterAndRescan(BuildContext context) async {
    _filterKeyword = '';
    _filterRssiDbm = -127;
    await startScan(context: context, clearDevices: true);
  }

  Future<void> clearListAndRescan(BuildContext context) async {
    await startScan(context: context, clearDevices: true);
  }

  Future<void> startScan({
    required BuildContext context,
    required bool clearDevices,
  }) async {
    _lastError = null;
    if (clearDevices) {
      _devices.clear();
    }
    _setIsScanning(true);

    final granted = await _requestPermissions(context);
    if (!granted) {
      _lastError = 'Please allow Bluetooth scan permission first.';
      _setIsScanning(false);
      return;
    }

    try {
      _scanTimer?.cancel();
      _scanTimer = Timer(const Duration(seconds: 60), () {
        if (_isScanning) {
          stopScan();
        }
      });

      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(
        androidScanMode: AndroidScanMode.lowLatency,
        timeout: const Duration(seconds: 60),
        withServiceData: [
          ServiceDataFilter(Guid(_advServiceUuid1)),
          ServiceDataFilter(Guid(_advServiceUuid2)),
        ],
      );

      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          var changed = false;
          for (final result in results) {
            final parsed = BleDeviceInfo.fromScanResult(result);
            if (parsed != null) {
              final now = DateTime.now().millisecondsSinceEpoch;
              final previous = _devices[result.device.remoteId];
              final scanIntervalMs =
                  previous == null ? 0 : now - previous.lastScanMs;
              _devices[result.device.remoteId] = parsed.copyWith(
                lastScanMs: now,
                scanIntervalMs: scanIntervalMs,
              );
              changed = true;
            }
          }
          if (changed) {
            _safeNotify();
          }
        },
        onError: (error) {
          _lastError = error.toString();
          _setIsScanning(false);
        },
        onDone: () {
          _setIsScanning(false);
        },
      );
    } catch (error) {
      if (Platform.isIOS) {
        if (!context.mounted) {
          _lastError = error.toString();
          _setIsScanning(false);
          return;
        }
        await _ensureIosBluetoothReady(context: context, showDialog: true);
      }
      _scanTimer?.cancel();
      _scanTimer = null;
      _lastError = error.toString();
      _setIsScanning(false);
    }
  }

  void stopScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    FlutterBluePlus.stopScan();
    _setIsScanning(false);
  }

  Future<Lw010DeviceSession> connectDevice({
    required BuildContext context,
    required BleDeviceInfo device,
    String? password,
  }) async {
    stopScan();

    final granted = await _requestPermissions(context);
    if (!granted) {
      throw Lw010ProtocolException('Please allow Bluetooth connect permission first.');
    }

    await _connectedSession?.disconnect();
    final session = await Lw010DeviceSession.connect(
      deviceInfo: device,
      password: device.passwordEnabled ? password : null,
    );
    _connectedSession = session;
    _safeNotify();
    return session;
  }

  Future<void> onReturnedFromDetail(BuildContext context) async {
    await disconnectDevice();
    if (context.mounted) {
      await startScan(context: context, clearDevices: true);
    }
  }

  Future<void> disconnectDevice() async {
    await _connectedSession?.disconnect();
    _connectedSession = null;
    _safeNotify();
  }

  Future<bool> _requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      final allGranted = statuses.values.every((status) => status.isGranted);
      if (!allGranted) {
        final anyPermanentlyDenied =
            statuses.values.any((status) => status.isPermanentlyDenied);
        if (!context.mounted) {
          return false;
        }
        await _showPermissionDialog(context, anyPermanentlyDenied);
        return false;
      }

      final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationServiceEnabled) {
        await Geolocator.openLocationSettings();
        return false;
      }

      return true;
    }

    if (Platform.isIOS) {
      return _ensureIosBluetoothReady(context: context, showDialog: true);
    }

    return false;
  }

  Future<bool> _ensureIosBluetoothReady({
    required BuildContext context,
    required bool showDialog,
  }) async {
    final supported = await FlutterBluePlus.isSupported;
    if (!supported) {
      _lastError = 'Bluetooth is not supported on this device.';
      _safeNotify();
      return false;
    }

    BluetoothAdapterState state;
    try {
      state = await FlutterBluePlus.adapterState
          .where((s) => s != BluetoothAdapterState.unknown)
          .first
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => BluetoothAdapterState.unknown,
          );
    } catch (_) {
      state = BluetoothAdapterState.unknown;
    }

    if (state == BluetoothAdapterState.on) {
      return true;
    }

    if (!showDialog) {
      return false;
    }

    if (state == BluetoothAdapterState.unauthorized) {
      if (!context.mounted) {
        return false;
      }
      await _showBluetoothPermissionDialog(context);
      return false;
    }

    if (state == BluetoothAdapterState.off) {
      if (!context.mounted) {
        return false;
      }
      await _showBluetoothOffDialog(context);
      return false;
    }

    _lastError = 'Bluetooth is currently unavailable: $state';
    _safeNotify();
    return false;
  }

  Future<void> _showBluetoothPermissionDialog(BuildContext context) async {
    final goSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bluetooth Permission Required'),
          content: const Text(
            'Please allow Bluetooth permission in the system dialog. '
            'If you previously selected "Don\'t Allow", enable Bluetooth for this app in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(true);
                _retryScanOnResume = true;
                await openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
    if (goSettings == true && context.mounted) {
      await _showBluetoothSettingsGuide(context);
    }
  }

  Future<void> _showBluetoothOffDialog(BuildContext context) async {
    NavigatorState? dialogNavigator;
    final subscription = FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .listen((_) {
      if (dialogNavigator != null && dialogNavigator!.canPop()) {
        dialogNavigator!.pop(true);
      }
    });

    final turnedOn = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogNavigator = Navigator.of(context);
        return AlertDialog(
          title: const Text('Turn On Bluetooth'),
          content: const Text('Bluetooth is turned off. Please turn it on to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    await subscription.cancel();
    if (turnedOn == true && !_isScanning) {
      if (context.mounted) {
        unawaited(startScan(context: context, clearDevices: false));
      }
    }
  }

  Future<void> _showPermissionDialog(
    BuildContext context,
    bool permanentlyDenied,
  ) async {
    final shouldRetry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bluetooth Permission Required'),
          content: Text(
            permanentlyDenied
                ? 'Bluetooth permission has been permanently denied. Please enable it manually in Settings.'
                : 'This app needs Bluetooth permission to scan and connect to devices.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Exit'),
            ),
            TextButton(
              onPressed: () async {
                if (permanentlyDenied) {
                  Navigator.of(context).pop(false);
                  _retryScanOnResume = true;
                  await openAppSettings();
                  if (!context.mounted) {
                    return;
                  }
                  await _showBluetoothSettingsGuide(context);
                } else {
                  Navigator.of(context).pop(true);
                  _retryScanOnResume = true;
                  await openAppSettings();
                }
              },
              child: Text(permanentlyDenied ? 'Settings' : 'Retry'),
            ),
          ],
        );
      },
    );

    if (shouldRetry == true && !permanentlyDenied) {
      if (!context.mounted) {
        return;
      }
      await _requestPermissions(context);
    } else if (shouldRetry == false) {
      if (!Platform.isIOS) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Bluetooth permission is required. The app will now exit.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        SystemNavigator.pop();
      } else {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth permission denied. Some features are unavailable.')),
        );
      }
    }
  }

  Future<void> _showBluetoothSettingsGuide(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Bluetooth Permission'),
        content: const Text(
          'Please enable Bluetooth permission manually:\n\n'
          'Settings > Privacy & Security > Bluetooth\n\n'
          'Find this app and turn on Bluetooth access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setIsScanning(bool value) {
    if (_isScanning == value) {
      return;
    }
    _isScanning = value;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) {
      return;
    }
    notifyListeners();
  }
}
