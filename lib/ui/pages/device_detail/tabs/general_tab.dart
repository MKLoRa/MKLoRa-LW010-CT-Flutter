import 'package:flutter/material.dart';

import '../../../../../ble/lw010.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../general/auxiliary_operation_page.dart';
import '../general/axis_setting_page.dart';
import '../general/ble_settings_page.dart';
import '../general/device_mode_page.dart';

class GeneralTab extends StatefulWidget {
  const GeneralTab({super.key, required this.session, required this.onSaveReady});

  final Lw010DeviceSession session;
  final void Function(Future<bool> Function() save) onSaveReady;

  @override
  State<GeneralTab> createState() => GeneralTabState();
}

class GeneralTabState extends State<GeneralTab> {
  final _heartbeatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.onSaveReady(_save);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final result = await widget.session.protocol.readHeartbeatInterval();
      if (!mounted) return;
      _heartbeatController.text =
          Lw010ParamHelpers.uint16(result.data).toString();
    });
  }

  Future<bool> _save() async {
    final text = _heartbeatController.text.trim();
    final value = int.tryParse(text);
    if (value == null || value < 1 || value > 14400) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Heartbeat interval must be 1~14400')),
        );
      }
      return false;
    }
    return widget.session.protocol
        .writeHeartbeatInterval(Lw010ParamHelpers.uint16Bytes(value));
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SettingsCard(
          child: SettingsNavRow(
            title: 'Device Mode',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DeviceModePage(session: widget.session),
              ),
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Auxiliary Operation',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AuxiliaryOperationPage(session: widget.session),
              ),
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'BLE Settings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BleSettingsPage(session: widget.session),
              ),
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: '3-axis Setting',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AxisSettingPage(session: widget.session),
              ),
            ),
          ),
        ),
        SettingsCard(
          child: SettingsLabelRow(
            label: 'Heartbeat Interval',
            child: SettingsTextField(
              controller: _heartbeatController,
              hint: '1~14400',
              maxLength: 5,
              suffix: 'Mins',
            ),
          ),
        ),
      ],
    );
  }
}
