import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterTlmPage extends StatefulWidget {
  const FilterTlmPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterTlmPage> createState() => _FilterTlmPageState();
}

class _FilterTlmPageState extends State<FilterTlmPage> {
  static const _versions = ['Null', 'version 0', 'version 1'];

  bool _enable = false;
  int _versionIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readFilterEddystoneTlmVersion(),
        api.readFilterEddystoneTlmEnable(),
      ]);
      if (!mounted) return;
      _versionIndex = Lw010ParamHelpers.uint8(results[0].data).clamp(0, 2);
      _enable = Lw010ParamHelpers.uint8(results[1].data) == 1;
      setState(() {});
    });
  }

  Future<void> _saveEnable(bool value) async {
    setState(() => _enable = value);
    await runWithBleLoading(context, () async {
      final ok = await widget.session.protocol.writeFilterEddystoneTlmEnable([value ? 1 : 0]);
      if (mounted) await saveWithToast(context, () async => ok);
      if (!ok && mounted) setState(() => _enable = !value);
    });
  }

  Future<void> _pickVersion() async {
    final index = await showBottomPicker(context: context, options: _versions, selectedIndex: _versionIndex);
    if (index == null || !mounted) return;
    setState(() => _versionIndex = index);
    await runWithBleLoading(context, () async {
      final ok = await widget.session.protocol.writeFilterEddystoneTlmVersion([index]);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by TLM',
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Enable', value: _enable, onChanged: _saveEnable)),
          SettingsCard(
            child: SettingsLabelRow(
              label: 'TLM Version',
              child: BlueValueButton(text: _versions[_versionIndex], onTap: _pickVersion),
            ),
          ),
        ],
      ),
    );
  }
}
