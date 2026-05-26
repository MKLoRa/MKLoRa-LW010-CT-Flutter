import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_option_lists.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class AlarmSosPage extends StatefulWidget {
  const AlarmSosPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<AlarmSosPage> createState() => _AlarmSosPageState();
}

class _AlarmSosPageState extends State<AlarmSosPage> {
  int _triggerIndex = 0;
  int _strategyIndex = 0;
  bool _notifyStart = false;
  bool _notifyEnd = false;
  final _interval = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readAlarmSosTriggerType(),
        api.readAlarmSosPosStrategy(),
        api.readAlarmSosReportInterval(),
        api.readAlarmSosNotifyEnable(),
      ]);
      if (!mounted) return;
      _triggerIndex = Lw010ParamHelpers.uint8(results[0].data).clamp(0, 4);
      _strategyIndex = Lw010ParamHelpers.uint8(results[1].data).clamp(0, 3);
      _interval.text = Lw010ParamHelpers.uint16(results[2].data).toString();
      final notify = Lw010ParamHelpers.uint8(results[3].data);
      _notifyStart = (notify & 1) == 1;
      _notifyEnd = (notify >> 1 & 1) == 1;
      setState(() {});
    });
  }

  bool _validate() {
    final interval = int.tryParse(_interval.text.trim());
    return interval != null && interval >= 10 && interval <= 600;
  }

  Future<void> _save() async {
    if (!_validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final notify = (_notifyStart ? 1 : 0) | (_notifyEnd ? 2 : 0);
      final ok = (await Future.wait([
        api.writeAlarmSosTriggerType([_triggerIndex]),
        api.writeAlarmSosPosStrategy([_strategyIndex]),
        api.writeAlarmSosReportInterval(Lw010ParamHelpers.uint16Bytes(int.parse(_interval.text.trim()))),
        api.writeAlarmSosNotifyEnable([notify]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _interval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'SOS Alarm Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Trigger Mode',
              child: BlueValueButton(
                text: Lw010OptionLists.sosTriggerModes[_triggerIndex],
                onTap: () async {
                  final index = await showBottomPicker(context: context, options: Lw010OptionLists.sosTriggerModes, selectedIndex: _triggerIndex);
                  if (index != null) setState(() => _triggerIndex = index);
                },
              ),
            ),
          ),
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Position Strategy',
              child: BlueValueButton(
                text: Lw010OptionLists.posStrategy4[_strategyIndex],
                onTap: () async {
                  final index = await showBottomPicker(context: context, options: Lw010OptionLists.posStrategy4, selectedIndex: _strategyIndex);
                  if (index != null) setState(() => _strategyIndex = index);
                },
              ),
            ),
          ),
          SettingsCard(child: SettingsLabelRow(label: 'Report Interval', child: SettingsTextField(controller: _interval, hint: '10~600', suffix: 's'))),
          SettingsCard(child: SettingsSwitchRow(label: 'Notify SOS Start', value: _notifyStart, onChanged: (v) => setState(() => _notifyStart = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Notify SOS End', value: _notifyEnd, onChanged: (v) => setState(() => _notifyEnd = v))),
        ],
      ),
    );
  }
}
