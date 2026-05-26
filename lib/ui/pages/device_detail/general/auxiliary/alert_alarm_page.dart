import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_option_lists.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class AlertAlarmPage extends StatefulWidget {
  const AlertAlarmPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<AlertAlarmPage> createState() => _AlertAlarmPageState();
}

class _AlertAlarmPageState extends State<AlertAlarmPage> {
  int _triggerIndex = 0;
  int _strategyIndex = 0;
  bool _notifyStart = false;
  bool _notifyEnd = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readAlarmAlertTriggerType(),
        api.readAlarmAlertPosStrategy(),
        api.readAlarmAlertNotifyEnable(),
      ]);
      if (!mounted) return;
      _triggerIndex = Lw010ParamHelpers.uint8(results[0].data).clamp(0, 4);
      _strategyIndex = Lw010ParamHelpers.uint8(results[1].data).clamp(0, 3);
      final notify = Lw010ParamHelpers.uint8(results[2].data);
      _notifyStart = (notify & 1) == 1;
      _notifyEnd = (notify >> 1 & 1) == 1;
      setState(() {});
    });
  }

  Future<void> _save() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final notify = (_notifyStart ? 1 : 0) | (_notifyEnd ? 2 : 0);
      final ok = (await Future.wait([
        api.writeAlarmAlertTriggerType([_triggerIndex]),
        api.writeAlarmAlertPosStrategy([_strategyIndex]),
        api.writeAlarmAlertNotifyEnable([notify]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Alert Alarm Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Trigger Mode',
              child: BlueValueButton(
                text: Lw010OptionLists.alertTriggerModes[_triggerIndex],
                onTap: () async {
                  final index = await showBottomPicker(context: context, options: Lw010OptionLists.alertTriggerModes, selectedIndex: _triggerIndex);
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
          SettingsCard(child: SettingsSwitchRow(label: 'Notify Alert Start', value: _notifyStart, onChanged: (v) => setState(() => _notifyStart = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Notify Alert End', value: _notifyEnd, onChanged: (v) => setState(() => _notifyEnd = v))),
        ],
      ),
    );
  }
}
