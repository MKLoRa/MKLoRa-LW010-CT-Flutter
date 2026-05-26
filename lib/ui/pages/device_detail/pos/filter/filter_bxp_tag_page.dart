import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_data_codec.dart';
import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterBxpTagPage extends StatefulWidget {
  const FilterBxpTagPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterBxpTagPage> createState() => _FilterBxpTagPageState();
}

class _FilterBxpTagPageState extends State<FilterBxpTagPage> {
  bool _enable = false;
  bool _precise = false;
  bool _reverse = false;
  final List<TextEditingController> _tags = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readFilterBxpTagEnable(),
        api.readFilterBxpTagPrecise(),
        api.readFilterBxpTagReverse(),
        api.readFilterBxpTagRules(),
      ]);
      if (!mounted) return;
      for (final c in _tags) {
        c.dispose();
      }
      _tags.clear();
      _enable = Lw010ParamHelpers.uint8(results[0].data) == 1;
      _precise = Lw010ParamHelpers.uint8(results[1].data) == 1;
      _reverse = Lw010ParamHelpers.uint8(results[2].data) == 1;
      for (final tag in Lw010DataCodec.decodeMacRules(results[3].data)) {
        _tags.add(TextEditingController(text: tag));
      }
      setState(() {});
    });
  }

  void _addTag() {
    if (_tags.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can set up to 10 filters!')));
      return;
    }
    setState(() => _tags.add(TextEditingController()));
  }

  void _delTag() {
    if (_tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('There are currently no filters to delete')));
      return;
    }
    setState(() => _tags.removeLast().dispose());
  }

  bool _validate() {
    for (final c in _tags) {
      final tag = c.text.trim();
      if (tag.isEmpty || tag.length % 2 != 0 || tag.length > 12) return false;
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
      final tags = _tags.map((c) => c.text.trim().toUpperCase()).toList();
      final ok = (await Future.wait([
        api.writeFilterBxpTagEnable([_enable ? 1 : 0]),
        api.writeFilterBxpTagPrecise([_precise ? 1 : 0]),
        api.writeFilterBxpTagReverse([_reverse ? 1 : 0]),
        api.writeFilterBxpTagRules(Lw010DataCodec.encodeMacRules(tags)),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    for (final c in _tags) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by BXP Tag',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Enable', value: _enable, onChanged: (v) => setState(() => _enable = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Precise Match', value: _precise, onChanged: (v) => setState(() => _precise = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Reverse Filter', value: _reverse, onChanged: (v) => setState(() => _reverse = v))),
          for (var i = 0; i < _tags.length; i++)
            SettingsCard(
              child: SettingsLabelRow(
                label: 'Tag ID ${i + 1}',
                child: Expanded(child: SettingsHexField(controller: _tags[i], hint: 'Up to 12 hex', maxLength: 12)),
              ),
            ),
          SettingsCard(
            child: Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _addTag, child: const Text('Add'))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(onPressed: _delTag, child: const Text('Delete'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
