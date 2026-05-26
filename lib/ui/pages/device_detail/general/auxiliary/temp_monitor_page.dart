import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_data_codec.dart';
import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class TempMonitorPage extends StatefulWidget {
  const TempMonitorPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<TempMonitorPage> createState() => _TempMonitorPageState();
}

class _TempMonitorPageState extends State<TempMonitorPage> {
  bool _monitor = false;
  bool _alarm = false;
  final _sampleRate = TextEditingController();
  final _alarmMin = TextEditingController();
  final _alarmMax = TextEditingController();
  String _currentTemp = '-';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readTempMonitorEnable(),
        api.readTempSampleRate(),
        api.readTempCurrent(),
        api.readTempAlarmThreshold(),
      ]);
      if (!mounted) return;
      final enable = Lw010ParamHelpers.uint8(results[0].data);
      _monitor = (enable & 1) == 1;
      _alarm = (enable >> 1 & 1) == 1;
      _sampleRate.text = Lw010ParamHelpers.uint16(results[1].data).toString();
      if (_monitor && results[2].data.isNotEmpty) {
        _currentTemp = '${Lw010ParamHelpers.byte0(results[2].data)}℃';
      }
      final threshold = results[3].data;
      if (threshold.length >= 2) {
        _alarmMin.text = Lw010ParamHelpers.byte0(threshold).toString();
        _alarmMax.text = threshold[1].toString();
      }
      setState(() {});
    });
  }

  bool _validate() {
    final rate = int.tryParse(_sampleRate.text.trim());
    final min = int.tryParse(_alarmMin.text.trim());
    final max = int.tryParse(_alarmMax.text.trim());
    if (rate == null || rate < 1 || rate > 3600) return false;
    if (min == null || max == null || min < -20 || min > 60 || max < -20 || max > 60) return false;
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
        api.writeTempMonitorEnable(Lw010DataCodec.encodeTempEnable(monitor: _monitor, alarm: _alarm)),
        api.writeTempSampleRate(Lw010ParamHelpers.uint16Bytes(int.parse(_sampleRate.text.trim()))),
        api.writeTempAlarmThreshold(Lw010DataCodec.encodeTempThreshold(int.parse(_alarmMin.text.trim()), int.parse(_alarmMax.text.trim()))),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _sampleRate.dispose();
    _alarmMin.dispose();
    _alarmMax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Temp Monitor Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Temp Monitor', value: _monitor, onChanged: (v) => setState(() => _monitor = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Temp Alarm', value: _alarm, onChanged: (v) => setState(() => _alarm = v))),
          if (_monitor)
            SettingsCard(child: SettingsLabelRow(label: 'Current Temp', child: Text(_currentTemp, style: const TextStyle(fontWeight: FontWeight.w600)))),
          SettingsCard(child: SettingsLabelRow(label: 'Sample Rate', child: SettingsTextField(controller: _sampleRate, hint: '1~3600', suffix: 's'))),
          SettingsCard(child: SettingsLabelRow(label: 'Alarm Min', child: SettingsTextField(controller: _alarmMin, hint: '-20~60'))),
          SettingsCard(child: SettingsLabelRow(label: 'Alarm Max', child: SettingsTextField(controller: _alarmMax, hint: '-20~60'))),
        ],
      ),
    );
  }
}
