import 'package:flutter/material.dart';

import '../../../../../ble/lw010.dart';
import '../../../../../ble/lw010_data_codec.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';

class MessageTypeSettingsPage extends StatefulWidget {
  const MessageTypeSettingsPage({super.key, required this.session});
  final Lw010DeviceSession session;
  @override
  State<MessageTypeSettingsPage> createState() => _MessageTypeSettingsPageState();
}

class _PayloadRow {
  _PayloadRow(this.label, this.read, this.write);
  final String label;
  final Future<dynamic> Function() read;
  final Future<bool> Function(List<int>) write;
  bool confirmed = false;
  int retransIndex = 0;
}

class _MessageTypeSettingsPageState extends State<MessageTypeSettingsPage> {
  late final List<_PayloadRow> _rows;

  @override
  void initState() {
    super.initState();
    final api = widget.session.protocol;
    _rows = [
      _PayloadRow('Device Info', api.readDeviceInfoPayload, api.writeDeviceInfoPayload),
      _PayloadRow('Heartbeat', api.readHeartbeatPayload, api.writeHeartbeatPayload),
      _PayloadRow('Positioning', api.readPositioningPayload, api.writePositioningPayload),
      _PayloadRow('Low Power', api.readLowPowerPayload, api.writeLowPowerPayload),
      _PayloadRow('Shock', api.readShockPayload, api.writeShockPayload),
      _PayloadRow('Event', api.readEventPayload, api.writeEventPayload),
      _PayloadRow('GPS Limit', api.readGpsLimitPayload, api.writeGpsLimitPayload),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      for (final row in _rows) {
        final result = await row.read();
        final cfg = Lw010PayloadConfig.fromBytes(result.data);
        row.confirmed = cfg.confirmed;
        row.retransIndex = cfg.retransIndex;
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _pickType(_PayloadRow row) async {
    final index = await showBottomPicker(context: context, options: Lw010OptionLists.payloadTypes, selectedIndex: row.confirmed ? 1 : 0);
    if (index != null) setState(() => row.confirmed = index == 1);
  }

  Future<void> _pickRetrans(_PayloadRow row) async {
    final index = await showBottomPicker(context: context, options: Lw010OptionLists.retransmissionTimes, selectedIndex: row.retransIndex);
    if (index != null) setState(() => row.retransIndex = index);
  }

  Future<void> _save() async {
    await runWithBleLoading(context, () async {
      final results = await Future.wait(_rows.map((r) => r.write(Lw010PayloadConfig(confirmed: r.confirmed, retransIndex: r.retransIndex).toBytes())));
      final ok = results.every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Message Type Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          for (final row in _rows) ...[
            SettingsCard(
              child: Column(
                children: [
                  SettingsLabelRow(label: row.label, child: BlueValueButton(text: row.confirmed ? 'Confirmed' : 'Unconfirmed', onTap: () => _pickType(row))),
                  if (row.confirmed) ...[
                    const SettingsDivider(),
                    SettingsLabelRow(label: 'Max Retransmission Times', child: BlueValueButton(text: Lw010OptionLists.retransmissionTimes[row.retransIndex], onTap: () => _pickRetrans(row))),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
