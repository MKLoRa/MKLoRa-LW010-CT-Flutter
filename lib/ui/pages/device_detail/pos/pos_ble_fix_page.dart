import 'package:flutter/material.dart';

import '../../../../../ble/lw010.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';
import 'filter/filter_adv_name_page.dart';
import 'filter/filter_mac_page.dart';
import 'filter/filter_raw_data_page.dart';

class PosBleFixPage extends StatefulWidget {
  const PosBleFixPage({super.key, required this.session});
  final Lw010DeviceSession session;
  @override
  State<PosBleFixPage> createState() => _PosBleFixPageState();
}

class _PosBleFixPageState extends State<PosBleFixPage> {
  final _timeout = TextEditingController();
  final _macNumber = TextEditingController();
  int _mechanismIndex = 0;
  int _relationshipIndex = 0;
  double _rssi = -127;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readBlePosTimeout(),
        api.readBlePosMacNumber(),
        api.readBlePosMechanism(),
        api.readFilterRssi(),
        api.readFilterRelationship(),
      ]);
      if (!mounted) return;
      _timeout.text = Lw010ParamHelpers.uint8(results[0].data).toString();
      _macNumber.text = Lw010ParamHelpers.uint8(results[1].data).toString();
      _mechanismIndex = Lw010ParamHelpers.uint8(results[2].data).clamp(0, 1);
      _rssi = Lw010ParamHelpers.byte0(results[3].data, defaultValue: -127).toDouble();
      _relationshipIndex = Lw010ParamHelpers.uint8(results[4].data).clamp(0, 6);
      setState(() {});
    });
  }

  Future<void> _save() async {
    final timeout = int.tryParse(_timeout.text.trim());
    final macNum = int.tryParse(_macNumber.text.trim());
    if (timeout == null || timeout < 1 || timeout > 10 || macNum == null || macNum < 1 || macNum > 15) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = (await Future.wait([
        api.writeBlePosTimeout([timeout]),
        api.writeBlePosMacNumber([macNum]),
        api.writeBlePosMechanism([_mechanismIndex]),
        api.writeFilterRssi([_rssi.round()]),
        api.writeFilterRelationship([_relationshipIndex]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _timeout.dispose();
    _macNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Bluetooth Fix',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsLabelRow(label: 'Position Timeout', child: SettingsTextField(controller: _timeout, hint: '1~10', suffix: 's'))),
          SettingsCard(child: SettingsLabelRow(label: 'MAC Number', child: SettingsTextField(controller: _macNumber, hint: '1~15'))),
          SettingsCard(child: SettingsLabelRow(label: 'BLE Fix Mechanism', child: BlueValueButton(text: Lw010OptionLists.bleFixMechanism[_mechanismIndex], onTap: () async {
            final i = await showBottomPicker(context: context, options: Lw010OptionLists.bleFixMechanism, selectedIndex: _mechanismIndex);
            if (i != null) setState(() => _mechanismIndex = i);
          }))),
          SettingsCard(child: SettingsSliderRow(label: 'RSSI Filter', value: _rssi + 127, min: 0, max: 127, suffix: '${_rssi.round()}dBm', onChanged: (v) => setState(() => _rssi = v - 127))),
          SettingsCard(child: SettingsLabelRow(label: 'Filter Relationship', child: BlueValueButton(text: Lw010OptionLists.filterRelationship[_relationshipIndex], onTap: () async {
            final i = await showBottomPicker(context: context, options: Lw010OptionLists.filterRelationship, selectedIndex: _relationshipIndex);
            if (i != null) setState(() => _relationshipIndex = i);
          }))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by MAC', onTap: () => pushDetailPage(context, FilterMacPage(session: widget.session)))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by ADV Name', onTap: () => pushDetailPage(context, FilterAdvNamePage(session: widget.session)))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by Raw Data', onTap: () => pushDetailPage(context, FilterRawDataPage(session: widget.session)))),
        ],
      ),
    );
  }
}
