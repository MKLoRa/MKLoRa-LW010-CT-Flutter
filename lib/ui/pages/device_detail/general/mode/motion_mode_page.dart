import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_option_lists.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class MotionModePage extends StatefulWidget {
  const MotionModePage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<MotionModePage> createState() => _MotionModePageState();
}

class _MotionModePageState extends State<MotionModePage> {
  bool _notifyStart = false;
  bool _fixStart = false;
  bool _notifyTrip = false;
  bool _fixTrip = false;
  bool _notifyEnd = false;
  bool _fixEnd = false;
  bool _fixStationary = false;
  int _startStrategy = 0;
  int _tripStrategy = 0;
  int _endStrategy = 0;
  int _stationaryStrategy = 0;
  final _startNumber = TextEditingController();
  final _tripInterval = TextEditingController();
  final _endTimeout = TextEditingController();
  final _endNumber = TextEditingController();
  final _endInterval = TextEditingController();
  final _stationaryInterval = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readMotionModeStartEnable(),
        api.readMotionModeStartFixEnable(),
        api.readMotionModeStartNumber(),
        api.readMotionModeStartPosStrategy(),
        api.readMotionModeTripEnable(),
        api.readMotionModeTripFixEnable(),
        api.readMotionModeTripReportInterval(),
        api.readMotionModeTripPosStrategy(),
        api.readMotionModeEndEnable(),
        api.readMotionModeEndFixEnable(),
        api.readMotionModeEndTimeout(),
        api.readMotionModeEndNumber(),
        api.readMotionModeEndReportInterval(),
        api.readMotionModeEndPosStrategy(),
        api.readMotionModeStationaryFixEnable(),
        api.readMotionModeStationaryReportInterval(),
        api.readMotionModeStationaryPosStrategy(),
      ]);
      if (!mounted) return;
      _notifyStart = Lw010ParamHelpers.uint8(results[0].data) == 1;
      _fixStart = Lw010ParamHelpers.uint8(results[1].data) == 1;
      _startNumber.text = Lw010ParamHelpers.uint8(results[2].data).toString();
      _startStrategy = Lw010ParamHelpers.uint8(results[3].data).clamp(0, 3);
      _notifyTrip = Lw010ParamHelpers.uint8(results[4].data) == 1;
      _fixTrip = Lw010ParamHelpers.uint8(results[5].data) == 1;
      _tripInterval.text = Lw010ParamHelpers.int32(results[6].data).toString();
      _tripStrategy = Lw010ParamHelpers.uint8(results[7].data).clamp(0, 4);
      _notifyEnd = Lw010ParamHelpers.uint8(results[8].data) == 1;
      _fixEnd = Lw010ParamHelpers.uint8(results[9].data) == 1;
      _endTimeout.text = Lw010ParamHelpers.uint8(results[10].data).toString();
      _endNumber.text = Lw010ParamHelpers.uint8(results[11].data).toString();
      _endInterval.text = Lw010ParamHelpers.int32(results[12].data).toString();
      _endStrategy = Lw010ParamHelpers.uint8(results[13].data).clamp(0, 3);
      _fixStationary = Lw010ParamHelpers.uint8(results[14].data) == 1;
      _stationaryInterval.text = Lw010ParamHelpers.int32(results[15].data).toString();
      _stationaryStrategy = Lw010ParamHelpers.uint8(results[16].data).clamp(0, 3);
      setState(() {});
    });
  }

  bool _validate() {
    final startNumber = int.tryParse(_startNumber.text.trim());
    final tripInterval = int.tryParse(_tripInterval.text.trim());
    final endTimeout = int.tryParse(_endTimeout.text.trim());
    final endNumber = int.tryParse(_endNumber.text.trim());
    final endInterval = int.tryParse(_endInterval.text.trim());
    final stationaryInterval = int.tryParse(_stationaryInterval.text.trim());
    if (startNumber == null || startNumber < 1 || startNumber > 10) return false;
    if (tripInterval == null || tripInterval < 10 || tripInterval > 86400) return false;
    if (endTimeout == null || endTimeout < 1 || endTimeout > 180) return false;
    if (endNumber == null || endNumber < 1 || endNumber > 10) return false;
    if (endInterval == null || endInterval < 10 || endInterval > 300) return false;
    if (stationaryInterval == null || stationaryInterval < 1 || stationaryInterval > 14400) return false;
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
        api.writeMotionModeStartEnable([_notifyStart ? 1 : 0]),
        api.writeMotionModeStartFixEnable([_fixStart ? 1 : 0]),
        api.writeMotionModeStartNumber([int.parse(_startNumber.text.trim())]),
        api.writeMotionModeStartPosStrategy([_startStrategy]),
        api.writeMotionModeTripEnable([_notifyTrip ? 1 : 0]),
        api.writeMotionModeTripFixEnable([_fixTrip ? 1 : 0]),
        api.writeMotionModeTripReportInterval(Lw010ParamHelpers.int32Bytes(int.parse(_tripInterval.text.trim()))),
        api.writeMotionModeTripPosStrategy([_tripStrategy]),
        api.writeMotionModeEndEnable([_notifyEnd ? 1 : 0]),
        api.writeMotionModeEndFixEnable([_fixEnd ? 1 : 0]),
        api.writeMotionModeEndTimeout([int.parse(_endTimeout.text.trim())]),
        api.writeMotionModeEndNumber([int.parse(_endNumber.text.trim())]),
        api.writeMotionModeEndReportInterval(Lw010ParamHelpers.int32Bytes(int.parse(_endInterval.text.trim()))),
        api.writeMotionModeEndPosStrategy([_endStrategy]),
        api.writeMotionModeStationaryFixEnable([_fixStationary ? 1 : 0]),
        api.writeMotionModeStationaryReportInterval(Lw010ParamHelpers.int32Bytes(int.parse(_stationaryInterval.text.trim()))),
        api.writeMotionModeStationaryPosStrategy([_stationaryStrategy]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  Future<void> _pickStrategy(List<String> options, int selected, ValueChanged<int> onSelected) async {
    final index = await showBottomPicker(context: context, options: options, selectedIndex: selected);
    if (index != null) setState(() => onSelected(index));
  }

  @override
  void dispose() {
    _startNumber.dispose();
    _tripInterval.dispose();
    _endTimeout.dispose();
    _endNumber.dispose();
    _endInterval.dispose();
    _stationaryInterval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Motion Mode',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: const Text('On Start', style: TextStyle(fontWeight: FontWeight.w700))),
          SettingsCard(child: SettingsSwitchRow(label: 'Notify on Start', value: _notifyStart, onChanged: (v) => setState(() => _notifyStart = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Fix on Start', value: _fixStart, onChanged: (v) => setState(() => _fixStart = v))),
          SettingsCard(child: SettingsLabelRow(label: 'Fix Number', child: SettingsTextField(controller: _startNumber, hint: '1~10'))),
          SettingsCard(child: SettingsLabelRow(label: 'Position Strategy', child: BlueValueButton(text: Lw010OptionLists.posStrategy4[_startStrategy], onTap: () => _pickStrategy(Lw010OptionLists.posStrategy4, _startStrategy, (i) => _startStrategy = i)))),
          SettingsCard(child: const Text('In Trip', style: TextStyle(fontWeight: FontWeight.w700))),
          SettingsCard(child: SettingsSwitchRow(label: 'Notify in Trip', value: _notifyTrip, onChanged: (v) => setState(() => _notifyTrip = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Fix in Trip', value: _fixTrip, onChanged: (v) => setState(() => _fixTrip = v))),
          SettingsCard(child: SettingsLabelRow(label: 'Report Interval', child: SettingsTextField(controller: _tripInterval, hint: '10~86400', suffix: 's'))),
          SettingsCard(child: SettingsLabelRow(label: 'Position Strategy', child: BlueValueButton(text: Lw010OptionLists.posStrategy5[_tripStrategy], onTap: () => _pickStrategy(Lw010OptionLists.posStrategy5, _tripStrategy, (i) => _tripStrategy = i)))),
          SettingsCard(child: const Text('On End', style: TextStyle(fontWeight: FontWeight.w700))),
          SettingsCard(child: SettingsSwitchRow(label: 'Notify on End', value: _notifyEnd, onChanged: (v) => setState(() => _notifyEnd = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Fix on End', value: _fixEnd, onChanged: (v) => setState(() => _fixEnd = v))),
          SettingsCard(child: SettingsLabelRow(label: 'Trip End Timeout', child: SettingsTextField(controller: _endTimeout, hint: '1~180', suffix: 'min'))),
          SettingsCard(child: SettingsLabelRow(label: 'Fix Number', child: SettingsTextField(controller: _endNumber, hint: '1~10'))),
          SettingsCard(child: SettingsLabelRow(label: 'Report Interval', child: SettingsTextField(controller: _endInterval, hint: '10~300', suffix: 's'))),
          SettingsCard(child: SettingsLabelRow(label: 'Position Strategy', child: BlueValueButton(text: Lw010OptionLists.posStrategy4[_endStrategy], onTap: () => _pickStrategy(Lw010OptionLists.posStrategy4, _endStrategy, (i) => _endStrategy = i)))),
          SettingsCard(child: const Text('On Stationary', style: TextStyle(fontWeight: FontWeight.w700))),
          SettingsCard(child: SettingsSwitchRow(label: 'Fix on Stationary', value: _fixStationary, onChanged: (v) => setState(() => _fixStationary = v))),
          SettingsCard(child: SettingsLabelRow(label: 'Report Interval', child: SettingsTextField(controller: _stationaryInterval, hint: '1~14400', suffix: 's'))),
          SettingsCard(child: SettingsLabelRow(label: 'Position Strategy', child: BlueValueButton(text: Lw010OptionLists.posStrategy4[_stationaryStrategy], onTap: () => _pickStrategy(Lw010OptionLists.posStrategy4, _stationaryStrategy, (i) => _stationaryStrategy = i)))),
        ],
      ),
    );
  }
}
