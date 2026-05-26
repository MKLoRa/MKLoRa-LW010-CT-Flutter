# MKLoRa LW010-CT Flutter

Flutter client for LW010-CT devices. Supports BLE scanning, connection, parameter read/write, disconnect notifications, and Nordic DFU firmware updates on Android and iOS physical devices.

Native Android reference project: `LW010_CT_Android`.

## Requirements

- Flutter SDK `^3.12.0`
- Android / iOS **physical device** (simulators do not support BLE)
- iOS: grant Bluetooth permission on first launch; run `pod install` in `ios/` when using CocoaPods

## Quick Start

```bash
flutter pub get
flutter run
```

The app opens on the scan page. Tap **CONNECT** on a device to connect and open the detail page.

---

## Project Structure

```
lib/
├── ble/                    # BLE connection and LW010 protocol layer
│   ├── lw010_ble_client.dart       # Connect, read/write frames, Notify handling
│   ├── lw010_protocol_api.dart     # Generic readParam / writeParam
│   ├── lw010_protocol_named_api.dart  # Named helpers (readLoraMode, etc.)
│   ├── lw010_device_session.dart   # Session wrapper (connection + API entry)
│   └── lw010_protocol_logger.dart  # Debug protocol logging
├── dfu/                    # Nordic DFU upgrade
├── models/                 # Scan result models
├── viewmodels/             # Scan page ViewModel
└── ui/                     # Pages and widgets
```

---

## 1. Scanning for Devices

Scanning is handled by `BleScanViewModel` via `flutter_blue_plus`, filtering LW010 advertisements by:

- Service Data UUID: `0000aa15-...` / `0000bb10-...`
- Parsed fields: RSSI, MAC, battery, Tx Power, password flag, scan interval, etc.

### Usage in UI Code

```dart
final vm = BleScanViewModel();
await vm.init(context);                    // Start scanning
await vm.startScan(context: context, clearDevices: true);
vm.stopScan();

final devices = vm.filteredDevices;        // Sorted by RSSI
await vm.applyFilter(context: context, keyword: 'LW010', rssiDbm: -80);
```

### Scan Result Model

```dart
for (final device in vm.filteredDevices) {
  print(device.name);
  print(device.macAddress);       // From advertisement Service Data
  print('${device.rssi}dBm');
  print(device.scanIntervalLabel);  // "<->N/A" or "<->1234ms"
  print(device.passwordEnabled);    // Whether a password is required
}
```

---

## 2. Connecting to a Device

Scanning stops before connecting. A GATT connection is established and the password is verified when required. Returns a `Lw010DeviceSession`.

```dart
import 'package:lw010ct_flutter/ble/lw010.dart';

// Pick a device from the scan list
final device = vm.filteredDevices.first;

// If device.passwordEnabled == true, prompt the user for a password first
final session = await vm.connectDevice(
  context: context,
  device: device,
  password: device.passwordEnabled ? '123456' : null,
);

// Or use the lower-level API directly
final session = await Lw010DeviceSession.connect(
  deviceInfo: device,
  password: '123456',
);
```

After a successful connection:

- `session.protocol` — parameter read/write API
- `session.deviceInfoApi` — standard Device Information characteristics (model, SN, firmware version, etc.)
- `session.client.disconnectEvents` — device-initiated disconnect notifications

Connection details (`Lw010BleClient.connectWithRetry`):

- Up to 5 retries, 50s total timeout
- Android requests MTU 247; iOS negotiates MTU automatically
- Waits 500ms after connect before sending protocol frames

---

## 3. Reading and Writing Protocol Parameters

Frame format: `ED [flag] [cmd] [subCmd] [len] [data...]`

- `flag=0x00` read, `flag=0x01` write
- Responses arrive asynchronously via Notify characteristics

### 3.1 Named API (Recommended)

`Lw010ProtocolNamedReadApi` / `Lw010ProtocolNamedWriteApi` provide semantic methods for each parameter:

```dart
final api = session.protocol;

// Read LoRa mode (OTAA=2, ABP=1)
final mode = await api.readLoraMode();
print(Lw010ParamHelpers.uint8(mode.data));   // Payload bytes
print(mode.raw);                             // Full response frame

// Read LoRa region
final region = await api.readLoraRegion();

// Read advertisement name
final advName = await api.readAdvName();
print(Lw010ParamHelpers.bytesToString(advName.data));

// Write time zone (example: UTC+8 → 8)
final ok = await api.writeTimeZone([8]);
if (ok) print('write success');

// Write LoRa OTAA mode
await api.writeLoraMode([2]);

// Sync UTC time (called automatically when entering the detail page)
await api.syncTime();

// Trigger reboot (some writes require reboot to take effect)
await api.writeRebootEmpty();
```

### 3.2 Generic API

Read and write any parameter via `Lw010ParamKey`:

```dart
// Read
final result = await api.readParam(Lw010ParamKey.advTxPower);
final txPower = Lw010ParamHelpers.byte0(result.data);

// Write
final success = await api.writeParam(
  Lw010ParamKey.advInterval,
  Lw010ParamHelpers.uint16Bytes(500),
);
```

### 3.3 GATT Device Information

```dart
final info = session.deviceInfoApi;
final model = await info.readModelNumber();
final firmware = await info.readFirmwareRevision();
final serial = await info.readSerialNumber();
```

### 3.4 Return Values

| Type | Field | Description |
|------|-------|-------------|
| `Lw010ParamResult` | `data` | Parsed payload bytes |
| | `raw` | Full frame returned by the device |
| | `cmd` / `subCmd` | Parameter command bytes |
| `writeParam` | returns `bool` | `true` when the device ACKs successfully |

Common parsing helpers are in `Lw010ParamHelpers`: `uint8`, `uint16`, `bytesToString`, `hexToBytes`, etc.

---

## 4. Receiving Data (Notify)

Device responses and disconnect notifications are delivered via BLE Notify. `Lw010BleClient` matches incoming frames to pending requests and completes the corresponding `Future`.

### Protocol Responses

Each `readParam` / `writeParam` call:

1. Writes a request frame to the characteristic (TX)
2. Waits for a Notify response with the same `cmd/subCmd` (RX)
3. Reassembles multi-packet responses automatically when `head=0xEE`

You do not need to subscribe to the params characteristic manually — use the API directly.

### Disconnect Notifications

Listen for device-initiated disconnects via `session.client.disconnectEvents`:

```dart
session.client.disconnectEvents.listen((event) {
  print('type=${event.type}');
  print(event.message);
  // type: 1=password timeout 2=password changed 3=3-min idle 4=reboot 5=factory reset
});
```

Example raw Notify frame:

```
ED 02 00 01 01 04   → type=4, device rebooted
```

The detail page handles this globally: on any sub-page, a dialog is shown and the user is returned to the scan page to rescan after confirming.

---

## 5. Disconnecting

### Manual Disconnect

```dart
await session.disconnect();
// or
await vm.disconnectDevice();
await vm.onReturnedFromDetail(context);  // Disconnect + clear list and rescan
```

### Unexpected Disconnect

When the device sends a disconnect Notify or the BLE link drops, `disconnectEvents` emits an event. The detail page flow:

1. Show a dialog (OK only)
2. Call `session.disconnect()`
3. `popUntil` back to the scan page
4. Scan page `onReturnedFromDetail` restarts scanning

Disconnect events are ignored during DFU to avoid false dialogs.

---

## 6. DFU Firmware Update

UI entry: **Device Settings → Device Information → DFU**

Flow (`Lw010DfuService` + `nordic_dfu`):

1. User selects a `.zip` firmware package
2. MAC address is saved; current GATT connection is closed
3. DFU progress dialog is shown
4. Nordic DFU starts using the MAC address
5. Success: shows *Update firmware successfully! Please reconnect the device.* and returns to the scan page
6. Failure: error shown via SnackBar

### Code Example

```dart
import 'package:lw010ct_flutter/dfu/lw010_dfu_coordinator.dart';
import 'package:lw010ct_flutter/dfu/lw010_dfu_service.dart';

Lw010DfuCoordinator.begin(mac: device.macAddress);
await session.disconnect();

await Lw010DfuService.start(
  address: device.macAddress,
  filePath: '/path/to/firmware.zip',
  onStatus: (status) => print(status),    // Connecting..., Progress:45%
  onProgress: (percent) => print('$percent%'),
);

Lw010DfuCoordinator.end();
// Rescan and reconnect after the update completes
```

Notes:

- Firmware package must be a **ZIP** file
- Do not rely on the original GATT session during DFU; the device reboots when done
- On iOS, disable Swift Package Manager in `pubspec.yaml` to use the CocoaPods NordicDFU build

---

## 7. Debug Protocol Logging

In debug builds, the console prints all TX/RX frames for protocol inspection:

```
[LW010 TX] params | READ loraMode (0x0501) | frame=ED 00 05 01 00
[LW010 RX] params | loraMode (0x0501) | frame=ED 00 05 01 01 02 | data=02
```

Disable logging:

```dart
Lw010ProtocolLogger.enabled = false;
```

---

## 8. Permissions

| Platform | Permissions |
|----------|-------------|
| Android | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, location (required for scanning) |
| iOS | `NSBluetoothAlwaysUsageDescription` (configured in Info.plist) |

---

## 9. Typical Flow

```
Scan page
  └─ startScan → device list
  └─ connectDevice → Lw010DeviceSession
       └─ Detail page
            ├─ protocol.readXxx / writeXxx
            ├─ disconnectEvents → dialog → back to scan page
            └─ DFU → pick zip → upgrade → back to scan page and reconnect
```

---

## Repository

- GitHub: [MKLoRa/MKLoRa-LW010-CT-Flutter](https://github.com/MKLoRa/MKLoRa-LW010-CT-Flutter)
