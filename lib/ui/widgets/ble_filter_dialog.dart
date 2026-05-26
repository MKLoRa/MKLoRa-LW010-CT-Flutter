import 'package:flutter/material.dart';

import '../../models/ble_scan_filter.dart';
import '../../viewmodels/ble_scan_view_model.dart';

Future<BleScanFilter?> showBleFilterDialog({
  required BuildContext context,
  required String initialKeyword,
  required int initialRssiDbm,
}) {
  return showDialog<BleScanFilter>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final controller = TextEditingController(text: initialKeyword);
      var sliderValue = (initialRssiDbm + 127).clamp(0, 127);

      return StatefulBuilder(
        builder: (context, setState) {
          final rssiDbm = sliderValue - 127;
          final canClearText = controller.text.isNotEmpty;

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Device name or mac address',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(
                          color: BleScanViewModel.titleBarColor,
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: canClearText
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Color(0xFFBDBDBD),
                              ),
                              onPressed: () {
                                controller.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.wifi, color: BleScanViewModel.titleBarColor),
                      const SizedBox(width: 8),
                      const Text(
                        'RSSI:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: BleScanViewModel.titleBarColor,
                            inactiveTrackColor: const Color(0xFFE0E0E0),
                            thumbColor: const Color(0xFF8FD1F0),
                            overlayColor: BleScanViewModel.titleBarColor.withValues(
                              alpha: 0.12,
                            ),
                          ),
                          child: Slider(
                            value: sliderValue.toDouble(),
                            min: 0,
                            max: 127,
                            onChanged: (v) {
                              setState(() => sliderValue = v.round());
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 62,
                        child: Text(
                          '$rssiDbm',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Text(
                        'dBm',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BleScanViewModel.titleBarColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(
                          BleScanFilter(
                            keyword: controller.text.trim(),
                            rssiDbm: rssiDbm,
                          ),
                        );
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

