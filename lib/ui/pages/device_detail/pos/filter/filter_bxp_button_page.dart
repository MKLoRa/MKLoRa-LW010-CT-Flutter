import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterBxpButtonPage extends StatefulWidget {
  const FilterBxpButtonPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterBxpButtonPage> createState() => _FilterBxpButtonPageState();
}

class _FilterBxpButtonPageState extends State<FilterBxpButtonPage> {
  bool _enable = false;
  bool _single = false;
  bool _double = false;
  bool _longPress = false;
  bool _abnormal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readFilterBxpButtonEnable(),
        api.readFilterBxpButtonRules(),
      ]);
      if (!mounted) return;
      _enable = Lw010ParamHelpers.uint8(results[0].data) == 1;
      final rules = results[1].data;
      if (rules.length >= 4) {
        _single = rules[0] == 1;
        _double = rules[1] == 1;
        _longPress = rules[2] == 1;
        _abnormal = rules[3] == 1;
      }
      setState(() {});
    });
  }

  Future<void> _save() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final rules = [_single ? 1 : 0, _double ? 1 : 0, _longPress ? 1 : 0, _abnormal ? 1 : 0];
      final ok = (await Future.wait([
        api.writeFilterBxpButtonRules(rules),
        api.writeFilterBxpButtonEnable([_enable ? 1 : 0]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by BXP Button',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Enable', value: _enable, onChanged: (v) => setState(() => _enable = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Single Press', value: _single, onChanged: (v) => setState(() => _single = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Double Press', value: _double, onChanged: (v) => setState(() => _double = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Long Press', value: _longPress, onChanged: (v) => setState(() => _longPress = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Abnormal Inactivity', value: _abnormal, onChanged: (v) => setState(() => _abnormal = v))),
        ],
      ),
    );
  }
}
