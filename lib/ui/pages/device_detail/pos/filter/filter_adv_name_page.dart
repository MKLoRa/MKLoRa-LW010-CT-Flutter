import 'package:flutter/material.dart';

import '../../../../../../ble/lw010.dart';
import '../../../../../../ble/lw010_data_codec.dart';
import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterAdvNamePage extends StatefulWidget {
  const FilterAdvNamePage({super.key, required this.session});
  final Lw010DeviceSession session;
  @override
  State<FilterAdvNamePage> createState() => _FilterAdvNamePageState();
}

class _FilterAdvNamePageState extends State<FilterAdvNamePage> {
  bool _precise = false;
  bool _reverse = false;
  final List<TextEditingController> _names = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final precise = await api.readFilterNamePrecise();
      final reverse = await api.readFilterNameReverse();
      final rules = await api.readFilterNameRules();
      if (!mounted) return;
      for (final c in _names) { c.dispose(); }
      _names.clear();
      _precise = Lw010ParamHelpers.uint8(precise.data) == 1;
      _reverse = Lw010ParamHelpers.uint8(reverse.data) == 1;
      for (final name in Lw010DataCodec.decodeNameRules(rules.data)) {
        _names.add(TextEditingController(text: name));
      }
      setState(() {});
    });
  }

  void _addName() {
    if (_names.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can set up to 10 filters!')));
      return;
    }
    setState(() => _names.add(TextEditingController()));
  }

  void _delName() {
    if (_names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There are currently no filters to delete')));
      return;
    }
    setState(() => _names.removeLast().dispose());
  }

  bool _validate() {
    for (final c in _names) {
      final name = c.text.trim();
      if (name.isEmpty || name.length > 20) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final names = _names.map((c) => c.text.trim()).toList();
      final ok = (await Future.wait([
        api.writeFilterNamePrecise([_precise ? 1 : 0]),
        api.writeFilterNameReverse([_reverse ? 1 : 0]),
        api.writeFilterNameRules(Lw010DataCodec.encodeNameRules(names)),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    for (final c in _names) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by ADV Name',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Precise Match', value: _precise, onChanged: (v) => setState(() => _precise = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Reverse Filter', value: _reverse, onChanged: (v) => setState(() => _reverse = v))),
          for (var i = 0; i < _names.length; i++)
            SettingsCard(child: SettingsLabelRow(label: 'Name ${i + 1}', child: Expanded(child: TextField(controller: _names[i], maxLength: 20, decoration: const InputDecoration(hintText: '1~20 chars', counterText: ''))))),
          SettingsCard(child: Row(children: [
            Expanded(child: ElevatedButton(onPressed: _addName, child: const Text('Add'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: _delName, child: const Text('Delete'))),
          ])),
        ],
      ),
    );
  }
}
