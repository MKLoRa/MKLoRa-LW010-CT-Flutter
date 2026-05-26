import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_option_lists.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class ManDownDetectionPage extends StatefulWidget {
  const ManDownDetectionPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<ManDownDetectionPage> createState() => _ManDownDetectionPageState();
}

class _ManDownDetectionPageState extends State<ManDownDetectionPage> {
  bool _detection = false;
  bool _notifyStart = false;
  bool _notifyEnd = false;
  int _strategyIndex = 0;
  final _timeout = TextEditingController();
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
        api.readManDownDetectionEnable(),
        api.readManDownDetectionTimeout(),
        api.readManDownDetectionPosStrategy(),
        api.readManDownDetectionReportInterval(),
      ]);
      if (!mounted) return;
      final enable = Lw010ParamHelpers.uint8(results[0].data);
      _detection = (enable & 1) == 1;
      _notifyStart = (enable >> 1 & 1) == 1;
      _notifyEnd = (enable >> 2 & 1) == 1;
      _timeout.text = Lw010ParamHelpers.uint8(results[1].data).toString();
      _strategyIndex = Lw010ParamHelpers.uint8(results[2].data).clamp(0, 3);
      _interval.text = Lw010ParamHelpers.uint16(results[3].data).toString();
      setState(() {});
    });
  }

  bool _validate() {
    final timeout = int.tryParse(_timeout.text.trim());
    final interval = int.tryParse(_interval.text.trim());
    if (timeout == null || timeout < 1 || timeout > 120) return false;
    if (interval == null || interval < 10 || interval > 600) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final flag = (_detection ? 1 : 0) | (_notifyStart ? 2 : 0) | (_notifyEnd ? 4 : 0);
      final ok = (await Future.wait([
        api.writeManDownDetectionEnable([flag]),
        api.writeManDownDetectionTimeout([int.parse(_timeout.text.trim())]),
        api.writeManDownDetectionPosStrategy([_strategyIndex]),
        api.writeManDownDetectionReportInterval(Lw010ParamHelpers.uint16Bytes(int.parse(_interval.text.trim()))),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _timeout.dispose();
    _interval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Man Down Detection',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Man Down Detection', value: _detection, onChanged: (v) => setState(() => _detection = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Notify Man Down Start', value: _notifyStart, onChanged: (v) => setState(() => _notifyStart = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Notify Man Down End', value: _notifyEnd, onChanged: (v) => setState(() => _notifyEnd = v))),
          SettingsCard(child: SettingsLabelRow(label: 'Detection Timeout', child: SettingsTextField(controller: _timeout, hint: '1~120', suffix: 'min'))),
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
        ],
      ),
    );
  }
}
