import 'package:flutter/material.dart';

import '../../../../../ble/lw010_data_codec.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';

class AxisSettingPage extends StatefulWidget {
  const AxisSettingPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<AxisSettingPage> createState() => _AxisSettingPageState();
}

class _AxisSettingPageState extends State<AxisSettingPage> {
  final _wakeupThreshold = TextEditingController();
  final _wakeupDuration = TextEditingController();
  final _motionThreshold = TextEditingController();
  final _motionDuration = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final results = await Future.wait([
        widget.session.protocol.readAccWakeupCondition(),
        widget.session.protocol.readAccMotionCondition(),
      ]);
      if (!mounted) return;
      final wakeup = results[0].data;
      final motion = results[1].data;
      if (wakeup.length >= 2) {
        _wakeupThreshold.text = wakeup[0].toString();
        _wakeupDuration.text = wakeup[1].toString();
      }
      if (motion.length >= 2) {
        _motionThreshold.text = motion[0].toString();
        _motionDuration.text = motion[1].toString();
      }
    });
  }

  bool _validate() {
    final wakeTh = int.tryParse(_wakeupThreshold.text.trim());
    final wakeDur = int.tryParse(_wakeupDuration.text.trim());
    final motionTh = int.tryParse(_motionThreshold.text.trim());
    final motionDur = int.tryParse(_motionDuration.text.trim());
    if (wakeTh == null || wakeTh < 1 || wakeTh > 20) return false;
    if (wakeDur == null || wakeDur < 1 || wakeDur > 10) return false;
    if (motionTh == null || motionTh < 10 || motionTh > 250) return false;
    if (motionDur == null || motionDur < 1 || motionDur > 50) return false;
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
        api.writeAccWakeupCondition(Lw010DataCodec.encodeAccCondition(int.parse(_wakeupThreshold.text.trim()), int.parse(_wakeupDuration.text.trim()))),
        api.writeAccMotionCondition(Lw010DataCodec.encodeAccCondition(int.parse(_motionThreshold.text.trim()), int.parse(_motionDuration.text.trim()))),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _wakeupThreshold.dispose();
    _wakeupDuration.dispose();
    _motionThreshold.dispose();
    _motionDuration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: '3-axis Setting',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsLabelRow(label: 'Wakeup Threshold', child: SettingsTextField(controller: _wakeupThreshold, hint: '1~20'))),
          SettingsCard(child: SettingsLabelRow(label: 'Wakeup Duration', child: SettingsTextField(controller: _wakeupDuration, hint: '1~10'))),
          SettingsCard(child: SettingsLabelRow(label: 'Motion Threshold', child: SettingsTextField(controller: _motionThreshold, hint: '10~250'))),
          SettingsCard(child: SettingsLabelRow(label: 'Motion Duration', child: SettingsTextField(controller: _motionDuration, hint: '1~50'))),
        ],
      ),
    );
  }
}
