import 'package:flutter/material.dart';

import '../../../../../ble/lw010_data_codec.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';

class IndicatorSettingsPage extends StatefulWidget {
  const IndicatorSettingsPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<IndicatorSettingsPage> createState() => _IndicatorSettingsPageState();
}

class _IndicatorSettingsPageState extends State<IndicatorSettingsPage> {
  int _alarmState = 0;
  bool _deviceState = false;
  bool _fix = false;
  bool _fixSuccess = false;
  bool _fixFail = false;
  bool _networkCheck = false;
  bool _fullCharge = false;
  bool _charging = false;
  bool _lowPower = false;
  bool _bleAdvCheck = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final result = await widget.session.protocol.readIndicatorStatus();
      if (!mounted || result.data.length < 2) return;
      final value = Lw010ParamHelpers.uint16(result.data);
      final decoded = Lw010DataCodec.decodeIndicator(value);
      _alarmState = decoded['alarmState']! ? 2 : 0;
      _deviceState = decoded['deviceState']!;
      _fix = decoded['fix']!;
      _fixSuccess = decoded['fixSuccess']!;
      _fixFail = decoded['fixFail']!;
      _networkCheck = decoded['networkCheck']!;
      _fullCharge = decoded['fullCharge']!;
      _charging = decoded['charging']!;
      _lowPower = decoded['lowPower']!;
      _bleAdvCheck = decoded['bleAdvCheck']!;
      setState(() {});
    });
  }

  Future<void> _save() async {
    await runWithBleLoading(context, () async {
      final value = Lw010DataCodec.encodeIndicator(
        deviceState: _deviceState,
        alarmState: _alarmState,
        fix: _fix,
        fixSuccess: _fixSuccess,
        fixFail: _fixFail,
        networkCheck: _networkCheck,
        fullCharge: _fullCharge,
        charging: _charging,
        lowPower: _lowPower,
        bleAdvCheck: _bleAdvCheck,
      );
      final ok = await widget.session.protocol.writeIndicatorStatus(Lw010ParamHelpers.uint16Bytes(value));
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Indicator Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Device State', value: _deviceState, onChanged: (v) => setState(() => _deviceState = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Fix', value: _fix, onChanged: (v) => setState(() => _fix = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Fix Success', value: _fixSuccess, onChanged: (v) => setState(() => _fixSuccess = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Fix Fail', value: _fixFail, onChanged: (v) => setState(() => _fixFail = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Network Check', value: _networkCheck, onChanged: (v) => setState(() => _networkCheck = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Full Charge', value: _fullCharge, onChanged: (v) => setState(() => _fullCharge = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Charging', value: _charging, onChanged: (v) => setState(() => _charging = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Low Power', value: _lowPower, onChanged: (v) => setState(() => _lowPower = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'BLE ADV Check', value: _bleAdvCheck, onChanged: (v) => setState(() => _bleAdvCheck = v))),
        ],
      ),
    );
  }
}
