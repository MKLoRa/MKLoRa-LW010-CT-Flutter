import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_data_codec.dart';
import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/theme/device_detail_theme.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class _OtherCondition {
  _OtherCondition()
      : dataType = TextEditingController(),
        min = TextEditingController(),
        max = TextEditingController(),
        rawData = TextEditingController();

  final TextEditingController dataType;
  final TextEditingController min;
  final TextEditingController max;
  final TextEditingController rawData;

  void dispose() {
    dataType.dispose();
    min.dispose();
    max.dispose();
    rawData.dispose();
  }
}

class FilterOtherPage extends StatefulWidget {
  const FilterOtherPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterOtherPage> createState() => _FilterOtherPageState();
}

class _FilterOtherPageState extends State<FilterOtherPage> {
  bool _enable = false;
  int _relationshipIndex = 0;
  final List<_OtherCondition> _conditions = [];

  List<String> get _relationshipOptions {
    final count = _conditions.length;
    if (count <= 1) return const ['A'];
    if (count == 2) return const ['A & B', 'A | B'];
    return const ['A & B & C', '(A & B) | C', 'A | B | C'];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readFilterOtherEnable(),
        api.readFilterOtherRelationship(),
        api.readFilterOtherRules(),
      ]);
      if (!mounted) return;
      for (final c in _conditions) {
        c.dispose();
      }
      _conditions.clear();
      _enable = Lw010ParamHelpers.uint8(results[0].data) == 1;
      final relationship = Lw010ParamHelpers.uint8(results[1].data);
      for (final rule in Lw010DataCodec.decodeMacRules(results[2].data)) {
        final condition = _OtherCondition();
        if (rule.length >= 6) {
          final dataTypeStr = rule.substring(0, 2);
          condition.dataType.text = dataTypeStr == '00' ? '' : dataTypeStr;
          condition.min.text = int.parse(rule.substring(2, 4), radix: 16).toString();
          condition.max.text = int.parse(rule.substring(4, 6), radix: 16).toString();
          condition.rawData.text = rule.substring(6);
        }
        _conditions.add(condition);
      }
      _relationshipIndex = _pickerIndexFromDevice(relationship);
      setState(() {});
    });
  }

  int _pickerIndexFromDevice(int relationship) {
    final count = _conditions.length;
    if (count <= 1) return 0;
    if (count == 2) return (relationship - 1).clamp(0, 1);
    return (relationship - 3).clamp(0, 2);
  }

  int _deviceRelationshipFromPicker() {
    final count = _conditions.length;
    if (count <= 1) return 0;
    if (count == 2) return _relationshipIndex + 1;
    return _relationshipIndex + 3;
  }

  void _addCondition() {
    if (_conditions.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can set up to 3 filters!')));
      return;
    }
    setState(() {
      final count = _conditions.length;
      _conditions.add(_OtherCondition());
      if (count == 0) {
        _relationshipIndex = 0;
      } else if (count == 1) {
        _relationshipIndex = 1;
      } else if (count == 2) {
        _relationshipIndex = 2;
      }
    });
  }

  void _delCondition() {
    if (_conditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There are currently no filters to delete')));
      return;
    }
    setState(() {
      final count = _conditions.length;
      _conditions.removeLast().dispose();
      if (count == 1) {
        _relationshipIndex = 0;
      } else if (count == 2) {
        _relationshipIndex = 0;
      } else if (count == 3) {
        _relationshipIndex = 1;
      }
    });
  }

  bool _validate() {
    for (final c in _conditions) {
      final dataTypeStr = c.dataType.text.trim();
      final rawDataStr = c.rawData.text.trim();
      if (rawDataStr.isEmpty) return false;
      if (rawDataStr.length % 2 != 0) return false;
      final dataType = dataTypeStr.isEmpty ? 0 : int.tryParse(dataTypeStr, radix: 16);
      if (dataType == null || dataType < 0 || dataType > 0xFF) return false;
      var min = 0;
      var max = 0;
      if (dataType != 0) {
        final minStr = c.min.text.trim();
        final maxStr = c.max.text.trim();
        if (minStr.isNotEmpty) min = int.tryParse(minStr) ?? -1;
        if (maxStr.isNotEmpty) max = int.tryParse(maxStr) ?? -1;
        if (min == 0 && max != 0) return false;
        if (min > 29 || max > 29 || max < min) return false;
        if (min > 0) {
          final interval = max - min;
          if (rawDataStr.length != (interval + 1) * 2) return false;
        }
      } else {
        c.min.text = '0';
        c.max.text = '0';
      }
    }
    return true;
  }

  List<String> _encodeRules() {
    final rules = <String>[];
    for (final c in _conditions) {
      final dataTypeStr = c.dataType.text.trim();
      final dataType = dataTypeStr.isEmpty ? 0 : int.parse(dataTypeStr, radix: 16);
      final min = int.parse(c.min.text.trim().isEmpty ? '0' : c.min.text.trim());
      final max = int.parse(c.max.text.trim().isEmpty ? '0' : c.max.text.trim());
      final raw = c.rawData.text.trim().toUpperCase();
      rules.add('${dataType.toRadixString(16).padLeft(2, '0')}${min.toRadixString(16).padLeft(2, '0')}${max.toRadixString(16).padLeft(2, '0')}$raw');
    }
    return rules;
  }

  Future<void> _save() async {
    if (!_validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = (await Future.wait([
        api.writeFilterOtherRules(Lw010DataCodec.encodeMacRules(_encodeRules())),
        api.writeFilterOtherRelationship([_deviceRelationshipFromPicker()]),
        api.writeFilterOtherEnable([_enable ? 1 : 0]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  Future<void> _pickRelationship() async {
    final options = _relationshipOptions;
    final index = await showBottomPicker(context: context, options: options, selectedIndex: _relationshipIndex.clamp(0, options.length - 1));
    if (index != null) setState(() => _relationshipIndex = index);
  }

  @override
  void dispose() {
    for (final c in _conditions) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Condition A', 'Condition B', 'Condition C'];
    final options = _relationshipOptions;
    return DetailScaffold(
      title: 'Filter by Other',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Enable', value: _enable, onChanged: (v) => setState(() => _enable = v))),
          if (_conditions.isNotEmpty)
            SettingsCard(
              child: SettingsLabelRow(
                label: 'Relationship',
                child: BlueValueButton(text: options[_relationshipIndex.clamp(0, options.length - 1)], onTap: _pickRelationship),
              ),
            ),
          for (var i = 0; i < _conditions.length; i++) ...[
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(labels[i], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SettingsLabelRow(
                    label: 'Data Type',
                    child: SizedBox(
                      width: 80,
                      child: SettingsHexField(
                        controller: _conditions[i].dataType,
                        hint: 'Hex',
                        maxLength: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SettingsLabelRow(
                    label: 'Min',
                    child: SettingsTextField(
                      controller: _conditions[i].min,
                      hint: '0~29',
                      width: 80,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SettingsLabelRow(
                    label: 'Max',
                    child: SettingsTextField(
                      controller: _conditions[i].max,
                      hint: '0~29',
                      width: 80,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Raw Data',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DeviceDetailTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SettingsHexField(
                    controller: _conditions[i].rawData,
                    hint: 'Hex',
                  ),
                ],
              ),
            ),
          ],
          SettingsCard(
            child: Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _addCondition, child: const Text('Add'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _delCondition, child: const Text('Delete'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
