import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class ShockDetectionPage extends StatefulWidget {
  const ShockDetectionPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<ShockDetectionPage> createState() => _ShockDetectionPageState();
}

class _ShockDetectionPageState extends State<ShockDetectionPage> {
  bool _enable = false;
  final _threshold = TextEditingController();
  final _interval = TextEditingController();
  final _timeout = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readShockDetectionEnable(),
        api.readShockThreshold(),
        api.readShockReportInterval(),
        api.readShockTimeout(),
      ]);
      if (!mounted) return;
      _enable = Lw010ParamHelpers.uint8(results[0].data) == 1;
      _threshold.text = Lw010ParamHelpers.uint8(results[1].data).toString();
      _interval.text = Lw010ParamHelpers.uint8(results[2].data).toString();
      _timeout.text = Lw010ParamHelpers.uint8(results[3].data).toString();
      setState(() {});
    });
  }

  bool _validate() {
    final interval = int.tryParse(_interval.text.trim());
    final timeout = int.tryParse(_timeout.text.trim());
    final threshold = int.tryParse(_threshold.text.trim());
    if (interval == null || interval < 3 || interval > 255) return false;
    if (timeout == null || timeout < 1 || timeout > 20) return false;
    if (threshold == null || threshold < 10 || threshold > 255) return false;
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
        api.writeShockDetectionEnable([_enable ? 1 : 0]),
        api.writeShockThreshold([int.parse(_threshold.text.trim())]),
        api.writeShockReportInterval([int.parse(_interval.text.trim())]),
        api.writeShockTimeout([int.parse(_timeout.text.trim())]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _threshold.dispose();
    _interval.dispose();
    _timeout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Shock Detection',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Shock Detection', value: _enable, onChanged: (v) => setState(() => _enable = v))),
          SettingsCard(child: SettingsLabelRow(label: 'Shock Threshold', child: SettingsTextField(controller: _threshold, hint: '10~255'))),
          SettingsCard(child: SettingsLabelRow(label: 'Report Interval', child: SettingsTextField(controller: _interval, hint: '3~255', suffix: 's'))),
          SettingsCard(child: SettingsLabelRow(label: 'Timeout', child: SettingsTextField(controller: _timeout, hint: '1~20', suffix: 'min'))),
        ],
      ),
    );
  }
}
