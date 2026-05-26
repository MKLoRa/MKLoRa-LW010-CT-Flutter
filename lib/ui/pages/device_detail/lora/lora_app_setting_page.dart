import 'package:flutter/material.dart';

import '../../../../../ble/lw010.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';
import 'message_type_settings_page.dart';

class LoRaAppSettingPage extends StatefulWidget {
  const LoRaAppSettingPage({super.key, required this.session});
  final Lw010DeviceSession session;
  @override
  State<LoRaAppSettingPage> createState() => _LoRaAppSettingPageState();
}

class _LoRaAppSettingPageState extends State<LoRaAppSettingPage> {
  final _syncInterval = TextEditingController();
  final _networkCheck = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final sync = await api.readLoraTimeSyncInterval();
      final network = await api.readLoraNetworkCheckInterval();
      if (!mounted) return;
      _syncInterval.text = Lw010ParamHelpers.uint8(sync.data).toString();
      _networkCheck.text = Lw010ParamHelpers.uint8(network.data).toString();
    });
  }

  Future<void> _save() async {
    final sync = int.tryParse(_syncInterval.text.trim());
    final network = int.tryParse(_networkCheck.text.trim());
    if (sync == null || sync > 255 || network == null || network > 255) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = (await Future.wait([
        api.writeLoraTimeSyncInterval([sync]),
        api.writeLoraNetworkCheckInterval([network]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _syncInterval.dispose();
    _networkCheck.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Application Setting',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsLabelRow(label: 'Time Sync Interval', child: SettingsTextField(controller: _syncInterval, hint: '0~255', maxLength: 3, suffix: 'x30mins'))),
          SettingsCard(child: SettingsLabelRow(label: 'Network Check Interval', child: SettingsTextField(controller: _networkCheck, hint: '0~255', maxLength: 3, suffix: 'x30mins'))),
          SettingsCard(child: SettingsNavRow(title: 'Message Type Settings', onTap: () => pushDetailPage(context, MessageTypeSettingsPage(session: widget.session)))),
        ],
      ),
    );
  }
}
