import 'package:flutter/material.dart';

import '../../../../../ble/lw010.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';

class PosGpsL76CFixPage extends StatefulWidget {
  const PosGpsL76CFixPage({super.key, required this.session});
  final Lw010DeviceSession session;
  @override
  State<PosGpsL76CFixPage> createState() => _PosGpsL76CFixPageState();
}

class _PosGpsL76CFixPageState extends State<PosGpsL76CFixPage> {
  final _timeout = TextEditingController();
  final _pdop = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final timeout = await api.readGpsPosTimeoutL76C();
      final pdop = await api.readGpsPdopLimitL76C();
      if (!mounted) return;
      _timeout.text = Lw010ParamHelpers.uint16(timeout.data).toString();
      _pdop.text = Lw010ParamHelpers.uint16(pdop.data).toString();
    });
  }

  Future<void> _save() async {
    final timeout = int.tryParse(_timeout.text.trim());
    final pdop = int.tryParse(_pdop.text.trim());
    if (timeout == null || timeout < 30 || timeout > 600 || pdop == null || pdop < 25 || pdop > 100) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = (await Future.wait([
        api.writeGpsPosTimeoutL76C(Lw010ParamHelpers.uint16Bytes(timeout)),
        api.writeGpsPdopLimitL76C(Lw010ParamHelpers.uint16Bytes(pdop)),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _timeout.dispose();
    _pdop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'GPS Fix',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsLabelRow(label: 'Position Timeout', child: SettingsTextField(controller: _timeout, hint: '30~600', suffix: 's'))),
          SettingsCard(child: SettingsLabelRow(label: 'PDOP Limit', child: SettingsTextField(controller: _pdop, hint: '25~100'))),
        ],
      ),
    );
  }
}
