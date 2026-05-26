import 'package:flutter/material.dart';

import '../../../../../ble/lw010.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';

class PosBleAndGpsPage extends StatefulWidget {
  const PosBleAndGpsPage({super.key, required this.session});
  final Lw010DeviceSession session;
  @override
  State<PosBleAndGpsPage> createState() => _PosBleAndGpsPageState();
}

class _PosBleAndGpsPageState extends State<PosBleAndGpsPage> {
  final _bleInterval = TextEditingController();
  final _gpsInterval = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ble = await api.readOutdoorBleReportInterval();
      final gps = await api.readOutdoorGpsReportInterval();
      if (!mounted) return;
      _bleInterval.text = Lw010ParamHelpers.uint8(ble.data).toString();
      _gpsInterval.text = Lw010ParamHelpers.uint16(gps.data).toString();
    });
  }

  Future<void> _save() async {
    final ble = int.tryParse(_bleInterval.text.trim());
    final gps = int.tryParse(_gpsInterval.text.trim());
    if (ble == null || ble < 1 || ble > 100 || gps == null || gps < 1 || gps > 14400) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = (await Future.wait([
        api.writeOutdoorBleReportInterval([ble]),
        api.writeOutdoorGpsReportInterval(Lw010ParamHelpers.uint16Bytes(gps)),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _bleInterval.dispose();
    _gpsInterval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'BLE&GPS',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsLabelRow(label: 'Outdoor BLE Report Interval', child: SettingsTextField(controller: _bleInterval, hint: '1~100', suffix: 'mins'))),
          SettingsCard(child: SettingsLabelRow(label: 'Outdoor GPS Report Interval', child: SettingsTextField(controller: _gpsInterval, hint: '1~14400', suffix: 's'))),
        ],
      ),
    );
  }
}
