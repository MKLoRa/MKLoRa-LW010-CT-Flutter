import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_data_codec.dart';
import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterMkTofPage extends StatefulWidget {
  const FilterMkTofPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterMkTofPage> createState() => _FilterMkTofPageState();
}

class _FilterMkTofPageState extends State<FilterMkTofPage> {
  bool _enable = false;
  final List<TextEditingController> _codes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final results = await Future.wait([
        widget.session.protocol.readFilterMkTofEnable(),
        widget.session.protocol.readFilterMkTofMfgCode(),
      ]);
      if (!mounted) return;
      for (final c in _codes) {
        c.dispose();
      }
      _codes.clear();
      _enable = Lw010ParamHelpers.uint8(results[0].data) == 1;
      for (final code in Lw010DataCodec.decodeMacRules(results[1].data)) {
        _codes.add(TextEditingController(text: code));
      }
      setState(() {});
    });
  }

  void _addCode() {
    if (_codes.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can set up to 10 filters!')));
      return;
    }
    setState(() => _codes.add(TextEditingController()));
  }

  void _delCode() {
    if (_codes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There are currently no filters to delete')));
      return;
    }
    setState(() => _codes.removeLast().dispose());
  }

  bool _validate() {
    for (final c in _codes) {
      final code = c.text.trim();
      if (code.isEmpty || code.length % 2 != 0 || code.length > 12) return false;
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
      final codes = _codes.map((c) => c.text.trim().toUpperCase()).toList();
      final ok = (await Future.wait([
        api.writeFilterMkTofEnable([_enable ? 1 : 0]),
        api.writeFilterMkTofMfgCode(Lw010DataCodec.encodeMacRules(codes)),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    for (final c in _codes) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by MK TOF',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Enable', value: _enable, onChanged: (v) => setState(() => _enable = v))),
          for (var i = 0; i < _codes.length; i++)
            SettingsCard(
              child: SettingsLabelRow(
                label: 'Code ${i + 1}',
                child: Expanded(child: SettingsHexField(controller: _codes[i], hint: 'Up to 12 hex', maxLength: 12)),
              ),
            ),
          SettingsCard(
            child: Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _addCode, child: const Text('Add'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _delCode, child: const Text('Delete'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
