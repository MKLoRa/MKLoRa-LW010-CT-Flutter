import 'package:flutter/material.dart';

import '../../models/ble_device_info.dart';
import '../../viewmodels/ble_scan_view_model.dart';

class DeviceItem extends StatelessWidget {
  final BleDeviceInfo device;
  final VoidCallback onConnect;

  const DeviceItem({super.key, required this.device, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final name = device.name.isNotEmpty ? device.name : device.id.str;
    final voltageV = (device.batteryVoltageMv / 1000).toStringAsFixed(3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.signal_cellular_alt,
                            color: BleScanViewModel.titleBarColor,
                            size: 20,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${device.rssi}dBm',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MAC:${device.macAddress}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BleScanViewModel.titleBarColor,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                        ),
                        onPressed: onConnect,
                        child: const Text(
                          'CONNECT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.battery_full,
                      size: 18,
                      color: BleScanViewModel.titleBarColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${device.batteryPercent}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      'Tx Power:${device.txPowerLevel ?? 'N/A'}dBm',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${voltageV}V',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      device.scanIntervalLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
