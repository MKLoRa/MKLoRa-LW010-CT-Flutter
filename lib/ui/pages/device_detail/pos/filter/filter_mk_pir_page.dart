import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterMkPirPage extends StatefulWidget {
  const FilterMkPirPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterMkPirPage> createState() => _FilterMkPirPageState();
}

class _FilterMkPirPageState extends State<FilterMkPirPage> {
  static const _detectionStatus = ['No motion detected', 'Motion detected', 'All'];
  static const _sensorSensitivity = ['Low', 'Medium', 'High', 'All'];
  static const _doorStatus = ['Close', 'Open', 'All'];
  static const _delayResStatus = ['Low delay', 'Medium delay', 'High delay', 'All'];

  bool _enable = false;
  int _detectionIndex = 0;
  int _sensitivityIndex = 0;
  int _doorIndex = 0;
  int _delayIndex = 0;
  final _majorMin = TextEditingController();
  final _majorMax = TextEditingController();
  final _minorMin = TextEditingController();
  final _minorMax = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readFilterMkPirEnable(),
        api.readFilterMkPirDetectionStatus(),
        api.readFilterMkPirSensorSensitivity(),
        api.readFilterMkPirDoorStatus(),
        api.readFilterMkPirDelayResStatus(),
        api.readFilterMkPirMajor(),
        api.readFilterMkPirMinor(),
      ]);
      if (!mounted) return;
      _enable = Lw010ParamHelpers.uint8(results[0].data) == 1;
      _detectionIndex = Lw010ParamHelpers.uint8(results[1].data).clamp(0, 2);
      _sensitivityIndex = Lw010ParamHelpers.uint8(results[2].data).clamp(0, 3);
      _doorIndex = Lw010ParamHelpers.uint8(results[3].data).clamp(0, 2);
      _delayIndex = Lw010ParamHelpers.uint8(results[4].data).clamp(0, 3);
      final major = results[5].data;
      if (major.length >= 4) {
        _majorMin.text = Lw010ParamHelpers.uint16(major).toString();
        _majorMax.text = Lw010ParamHelpers.uint16(major, offset: 2).toString();
      }
      final minor = results[6].data;
      if (minor.length >= 4) {
        _minorMin.text = Lw010ParamHelpers.uint16(minor).toString();
        _minorMax.text = Lw010ParamHelpers.uint16(minor, offset: 2).toString();
      }
      setState(() {});
    });
  }

  List<int> _rangeBytes(int min, int max) => [
        ...Lw010ParamHelpers.uint16Bytes(min),
        ...Lw010ParamHelpers.uint16Bytes(max),
      ];

  bool _validateRange(TextEditingController minC, TextEditingController maxC) {
    final minStr = minC.text.trim();
    final maxStr = maxC.text.trim();
    if (minStr.isEmpty && maxStr.isEmpty) return true;
    if (minStr.isEmpty || maxStr.isEmpty) return false;
    final min = int.tryParse(minStr);
    final max = int.tryParse(maxStr);
    if (min == null || max == null || min > 65535 || max > 65535 || max < min) return false;
    return true;
  }

  bool _validate() => _validateRange(_majorMin, _majorMax) && _validateRange(_minorMin, _minorMax);

  Future<void> _save() async {
    if (!_validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final majorMinStr = _majorMin.text.trim();
      final majorMaxStr = _majorMax.text.trim();
      final minorMinStr = _minorMin.text.trim();
      final minorMaxStr = _minorMax.text.trim();
      final majorRange = majorMinStr.isEmpty && majorMaxStr.isEmpty
          ? _rangeBytes(0, 0xFFFF)
          : _rangeBytes(int.parse(majorMinStr), int.parse(majorMaxStr));
      final minorRange = minorMinStr.isEmpty && minorMaxStr.isEmpty
          ? _rangeBytes(0, 0xFFFF)
          : _rangeBytes(int.parse(minorMinStr), int.parse(minorMaxStr));
      final ok = (await Future.wait([
        api.writeFilterMkPirEnable([_enable ? 1 : 0]),
        api.writeFilterMkPirDetectionStatus([_detectionIndex]),
        api.writeFilterMkPirSensorSensitivity([_sensitivityIndex]),
        api.writeFilterMkPirDoorStatus([_doorIndex]),
        api.writeFilterMkPirDelayResStatus([_delayIndex]),
        api.writeFilterMkPirMajor(majorRange),
        api.writeFilterMkPirMinor(minorRange),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  Future<void> _pick(List<String> options, int selected, ValueChanged<int> onSelected) async {
    final index = await showBottomPicker(context: context, options: options, selectedIndex: selected);
    if (index != null) setState(() => onSelected(index));
  }

  @override
  void dispose() {
    _majorMin.dispose();
    _majorMax.dispose();
    _minorMin.dispose();
    _minorMax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by MK PIR',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Enable', value: _enable, onChanged: (v) => setState(() => _enable = v))),
          SettingsCard(child: SettingsLabelRow(label: 'Detection Status', child: BlueValueButton(text: _detectionStatus[_detectionIndex], onTap: () => _pick(_detectionStatus, _detectionIndex, (i) => _detectionIndex = i)))),
          SettingsCard(child: SettingsLabelRow(label: 'Sensor Sensitivity', child: BlueValueButton(text: _sensorSensitivity[_sensitivityIndex], onTap: () => _pick(_sensorSensitivity, _sensitivityIndex, (i) => _sensitivityIndex = i)))),
          SettingsCard(child: SettingsLabelRow(label: 'Door Status', child: BlueValueButton(text: _doorStatus[_doorIndex], onTap: () => _pick(_doorStatus, _doorIndex, (i) => _doorIndex = i)))),
          SettingsCard(child: SettingsLabelRow(label: 'Delay Response', child: BlueValueButton(text: _delayResStatus[_delayIndex], onTap: () => _pick(_delayResStatus, _delayIndex, (i) => _delayIndex = i)))),
          SettingsCard(child: SettingsLabelRow(label: 'Major Min', child: SettingsTextField(controller: _majorMin, hint: '0~65535'))),
          SettingsCard(child: SettingsLabelRow(label: 'Major Max', child: SettingsTextField(controller: _majorMax, hint: '0~65535'))),
          SettingsCard(child: SettingsLabelRow(label: 'Minor Min', child: SettingsTextField(controller: _minorMin, hint: '0~65535'))),
          SettingsCard(child: SettingsLabelRow(label: 'Minor Max', child: SettingsTextField(controller: _minorMax, hint: '0~65535'))),
        ],
      ),
    );
  }
}
