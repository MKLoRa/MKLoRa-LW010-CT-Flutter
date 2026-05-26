import 'package:flutter/material.dart';

import '../../../../../../ble/lw010.dart';
import '../../../../../../ble/lw010_data_codec.dart';
import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterMacPage extends StatefulWidget {
  const FilterMacPage({super.key, required this.session});
  final Lw010DeviceSession session;
  @override
  State<FilterMacPage> createState() => _FilterMacPageState();
}

class _FilterMacPageState extends State<FilterMacPage> {
  bool _precise = false;
  bool _reverse = false;
  final List<TextEditingController> _macs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final precise = await api.readFilterMacPrecise();
      final reverse = await api.readFilterMacReverse();
      final rules = await api.readFilterMacRules();
      if (!mounted) return;
      for (final c in _macs) { c.dispose(); }
      _macs.clear();
      _precise = Lw010ParamHelpers.uint8(precise.data) == 1;
      _reverse = Lw010ParamHelpers.uint8(reverse.data) == 1;
      for (final mac in Lw010DataCodec.decodeMacRules(rules.data)) {
        _macs.add(TextEditingController(text: mac));
      }
      setState(() {});
    });
  }

  void _addMac() {
    if (_macs.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can set up to 10 filters!')));
      return;
    }
    setState(() => _macs.add(TextEditingController()));
  }

  void _delMac() {
    if (_macs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There are currently no filters to delete')));
      return;
    }
    setState(() {
      _macs.removeLast().dispose();
    });
  }

  bool _validate() {
    for (final c in _macs) {
      final mac = c.text.trim();
      if (mac.isEmpty || mac.length % 2 != 0 || mac.length > 12) return false;
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
      final macs = _macs.map((c) => c.text.trim().toUpperCase()).toList();
      final ok = (await Future.wait([
        api.writeFilterMacPrecise([_precise ? 1 : 0]),
        api.writeFilterMacReverse([_reverse ? 1 : 0]),
        api.writeFilterMacRules(Lw010DataCodec.encodeMacRules(macs)),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    for (final c in _macs) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by MAC',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Precise Match', value: _precise, onChanged: (v) => setState(() => _precise = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Reverse Filter', value: _reverse, onChanged: (v) => setState(() => _reverse = v))),
          for (var i = 0; i < _macs.length; i++)
            SettingsCard(child: SettingsLabelRow(label: 'MAC ${i + 1}', child: Expanded(child: SettingsHexField(controller: _macs[i], hint: 'Up to 12 hex', maxLength: 12)))),
          SettingsCard(child: Row(children: [
            Expanded(child: ElevatedButton(onPressed: _addMac, child: const Text('Add'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton(onPressed: _delMac, child: const Text('Delete'))),
          ])),
        ],
      ),
    );
  }
}
