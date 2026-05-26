import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_option_lists.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';
import 'alert_alarm_page.dart';
import 'alarm_sos_page.dart';

class AlarmFunctionPage extends StatefulWidget {
  const AlarmFunctionPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<AlarmFunctionPage> createState() => _AlarmFunctionPageState();
}

class _AlarmFunctionPageState extends State<AlarmFunctionPage> {
  int _alarmTypeIndex = 0;
  final _exitTime = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final results = await Future.wait([
        widget.session.protocol.readAlarmType(),
        widget.session.protocol.readAlarmExitTime(),
      ]);
      if (!mounted) return;
      _alarmTypeIndex = Lw010ParamHelpers.uint8(results[0].data).clamp(0, 2);
      _exitTime.text = Lw010ParamHelpers.uint8(results[1].data).toString();
      setState(() {});
    });
  }

  bool _validate() {
    final time = int.tryParse(_exitTime.text.trim());
    return time != null && time >= 5 && time <= 15;
  }

  Future<void> _save() async {
    if (!_validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = (await Future.wait([
        api.writeAlarmType([_alarmTypeIndex]),
        api.writeAlarmExitTime([int.parse(_exitTime.text.trim())]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _exitTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return DetailScaffold(
      title: 'Alarm Function',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Alarm Type',
              child: BlueValueButton(
                text: Lw010OptionLists.alarmTypes[_alarmTypeIndex],
                onTap: () async {
                  final index = await showBottomPicker(context: context, options: Lw010OptionLists.alarmTypes, selectedIndex: _alarmTypeIndex);
                  if (index != null) setState(() => _alarmTypeIndex = index);
                },
              ),
            ),
          ),
          SettingsCard(child: SettingsLabelRow(label: 'Exit Alarm Time', child: SettingsTextField(controller: _exitTime, hint: '5~15', suffix: 's'))),
          SettingsCard(child: SettingsNavRow(title: 'Alert Alarm Settings', onTap: () => pushDetailPage(context, AlertAlarmPage(session: session)))),
          SettingsCard(child: SettingsNavRow(title: 'SOS Alarm Settings', onTap: () => pushDetailPage(context, AlarmSosPage(session: session)))),
        ],
      ),
    );
  }
}
