import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_data_codec.dart';
import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class LightMonitorPage extends StatefulWidget {
  const LightMonitorPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<LightMonitorPage> createState() => _LightMonitorPageState();
}

class _LightMonitorPageState extends State<LightMonitorPage> {
  bool _monitor = false;
  bool _alarm = false;
  final _sampleRate = TextEditingController();
  final _threshold = TextEditingController();
  String _currentLight = '-';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readLightMonitorEnable(),
        api.readLightSampleRate(),
        api.readLightCurrent(),
        api.readLightAlarmThreshold(),
      ]);
      if (!mounted) return;
      final enable = Lw010ParamHelpers.uint8(results[0].data);
      _monitor = (enable & 1) == 1;
      _alarm = (enable >> 1 & 1) == 1;
      _sampleRate.text = Lw010ParamHelpers.uint16(results[1].data).toString();
      if (_monitor && results[2].data.length >= 2) {
        _currentLight = '${Lw010ParamHelpers.uint16(results[2].data)} lux';
      }
      _threshold.text = Lw010ParamHelpers.uint8(results[3].data).toString();
      setState(() {});
    });
  }

  bool _validate() {
    final rate = int.tryParse(_sampleRate.text.trim());
    final threshold = int.tryParse(_threshold.text.trim());
    if (rate == null || rate < 1 || rate > 3600) return false;
    if (threshold == null || threshold < 10 || threshold > 200) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = (await Future.wait([
        api.writeLightMonitorEnable(Lw010DataCodec.encodeLightEnable(monitor: _monitor, alarm: _alarm)),
        api.writeLightSampleRate(Lw010ParamHelpers.uint16Bytes(int.parse(_sampleRate.text.trim()))),
        api.writeLightAlarmThreshold([int.parse(_threshold.text.trim())]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _sampleRate.dispose();
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Light Monitor Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Light Monitor', value: _monitor, onChanged: (v) => setState(() => _monitor = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Light Alarm', value: _alarm, onChanged: (v) => setState(() => _alarm = v))),
          if (_monitor)
            SettingsCard(child: SettingsLabelRow(label: 'Current Light', child: Text(_currentLight, style: const TextStyle(fontWeight: FontWeight.w600)))),
          SettingsCard(child: SettingsLabelRow(label: 'Sample Rate', child: SettingsTextField(controller: _sampleRate, hint: '1~3600', suffix: 's'))),
          SettingsCard(child: SettingsLabelRow(label: 'Alarm Threshold', child: SettingsTextField(controller: _threshold, hint: '10~200', suffix: 'lux'))),
        ],
      ),
    );
  }
}
