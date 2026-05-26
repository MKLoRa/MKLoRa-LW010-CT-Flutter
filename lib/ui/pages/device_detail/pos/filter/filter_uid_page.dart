import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterUidPage extends StatefulWidget {
  const FilterUidPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterUidPage> createState() => _FilterUidPageState();
}

class _FilterUidPageState extends State<FilterUidPage> {
  bool _enable = false;
  final _namespace = TextEditingController();
  final _instance = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readFilterEddystoneUidEnable(),
        api.readFilterEddystoneUidNamespace(),
        api.readFilterEddystoneUidInstance(),
      ]);
      if (!mounted) return;
      _enable = Lw010ParamHelpers.uint8(results[0].data) == 1;
      _namespace.text = Lw010ParamHelpers.bytesToHex(results[1].data);
      _instance.text = Lw010ParamHelpers.bytesToHex(results[2].data);
      setState(() {});
    });
  }

  bool _validate() {
    for (final text in [_namespace.text.trim(), _instance.text.trim()]) {
      if (text.isNotEmpty && text.length % 2 != 0) return false;
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
      final ok = (await Future.wait([
        api.writeFilterEddystoneUidNamespace(Lw010ParamHelpers.hexToBytes(_namespace.text.trim())),
        api.writeFilterEddystoneUidInstance(Lw010ParamHelpers.hexToBytes(_instance.text.trim())),
        api.writeFilterEddystoneUidEnable([_enable ? 1 : 0]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _namespace.dispose();
    _instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by UID',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Enable', value: _enable, onChanged: (v) => setState(() => _enable = v))),
          SettingsCard(child: SettingsLabelRow(label: 'Namespace', child: Expanded(child: SettingsHexField(controller: _namespace, hint: 'Hex namespace')))),
          SettingsCard(child: SettingsLabelRow(label: 'Instance', child: Expanded(child: SettingsHexField(controller: _instance, hint: 'Hex instance')))),
        ],
      ),
    );
  }
}
