import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterBxpIbeaconPage extends StatefulWidget {
  const FilterBxpIbeaconPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterBxpIbeaconPage> createState() => _FilterBxpIbeaconPageState();
}

class _FilterBxpIbeaconPageState extends State<FilterBxpIbeaconPage> {
  bool _enable = false;
  final _uuid = TextEditingController();
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
        api.readFilterBxpIbeaconEnable(),
        api.readFilterBxpIbeaconUuid(),
        api.readFilterBxpIbeaconMajorRange(),
        api.readFilterBxpIbeaconMinorRange(),
      ]);
      if (!mounted) return;
      _enable = Lw010ParamHelpers.uint8(results[0].data) == 1;
      _uuid.text = Lw010ParamHelpers.bytesToHex(results[1].data);
      final major = results[2].data;
      if (major.length >= 4) {
        _majorMin.text = Lw010ParamHelpers.uint16(major).toString();
        _majorMax.text = Lw010ParamHelpers.uint16(major, offset: 2).toString();
      }
      final minor = results[3].data;
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

  bool _validate() {
    final uuid = _uuid.text.trim();
    if (uuid.isNotEmpty && uuid.length % 2 != 0) return false;
    return _validateRange(_majorMin, _majorMax) && _validateRange(_minorMin, _minorMax);
  }

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
          ? _rangeBytes(0, 65535)
          : _rangeBytes(int.parse(majorMinStr), int.parse(majorMaxStr));
      final minorRange = minorMinStr.isEmpty && minorMaxStr.isEmpty
          ? _rangeBytes(0, 65535)
          : _rangeBytes(int.parse(minorMinStr), int.parse(minorMaxStr));
      final ok = (await Future.wait([
        api.writeFilterBxpIbeaconUuid(Lw010ParamHelpers.hexToBytes(_uuid.text.trim())),
        api.writeFilterBxpIbeaconMajorRange(majorRange),
        api.writeFilterBxpIbeaconMinorRange(minorRange),
        api.writeFilterBxpIbeaconEnable([_enable ? 1 : 0]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _uuid.dispose();
    _majorMin.dispose();
    _majorMax.dispose();
    _minorMin.dispose();
    _minorMax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by BXP iBeacon',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Enable', value: _enable, onChanged: (v) => setState(() => _enable = v))),
          SettingsCard(child: SettingsLabelRow(label: 'UUID', child: Expanded(child: SettingsHexField(controller: _uuid, hint: 'Hex UUID')))),
          SettingsCard(child: SettingsLabelRow(label: 'Major Min', child: SettingsTextField(controller: _majorMin, hint: '0~65535'))),
          SettingsCard(child: SettingsLabelRow(label: 'Major Max', child: SettingsTextField(controller: _majorMax, hint: '0~65535'))),
          SettingsCard(child: SettingsLabelRow(label: 'Minor Min', child: SettingsTextField(controller: _minorMin, hint: '0~65535'))),
          SettingsCard(child: SettingsLabelRow(label: 'Minor Max', child: SettingsTextField(controller: _minorMax, hint: '0~65535'))),
        ],
      ),
    );
  }
}
