import 'package:flutter/material.dart';

import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/common_confirm_dialog.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../../../../viewmodels/ble_scan_view_model.dart';
class OnOffSettingsPage extends StatefulWidget {
  const OnOffSettingsPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<OnOffSettingsPage> createState() => _OnOffSettingsPageState();
}

class _OnOffSettingsPageState extends State<OnOffSettingsPage> {
  bool _shutdownPayload = false;
  bool _offByButton = false;
  bool _autoPowerOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readShutdownPayloadEnable(),
        api.readOffByButton(),
        api.readAutoPowerOnEnable(),
      ]);
      if (!mounted) return;
      setState(() {
        _shutdownPayload = Lw010ParamHelpers.uint8(results[0].data) == 1;
        _offByButton = Lw010ParamHelpers.uint8(results[1].data) == 1;
        _autoPowerOn = Lw010ParamHelpers.uint8(results[2].data) == 1;
      });
    });
  }

  Future<void> _toggle({
    required bool current,
    required Future<bool> Function(int value) write,
    required void Function(bool value) setLocal,
  }) async {
    final next = !current;
    setState(() => setLocal(next));
    await runWithBleLoading(context, () async {
      final ok = await write(next ? 1 : 0);
      if (!mounted) return;
      if (!ok) {
        setState(() => setLocal(current));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opps！Save failed. Please check the input characters and try again.')),
        );
        return;
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save Successfully！')));
      }
    });
  }

  Future<void> _powerOff() async {
    final ok = await showCommonConfirmDialog(
      context: context,
      title: 'Warning!',
      message: 'Are you sure to turn off the device? Please make sure the device has a button to turn on!',
      confirmText: 'OK',
      actionColor: BleScanViewModel.titleBarColor,
    );
    if (!ok || !mounted) return;
    await runWithBleLoading(context, () => widget.session.protocol.writeCloseEmpty());
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.session.protocol;
    return DetailScaffold(
      title: 'On/Off Settings',
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Shutdown Payload', value: _shutdownPayload, onChanged: (_) => _toggle(current: _shutdownPayload, write: (v) => api.writeShutdownPayloadEnable([v]), setLocal: (v) => _shutdownPayload = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Off by Button', value: _offByButton, onChanged: (_) => _toggle(current: _offByButton, write: (v) => api.writeOffByButton([v]), setLocal: (v) => _offByButton = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Auto Power On', value: _autoPowerOn, onChanged: (_) => _toggle(current: _autoPowerOn, write: (v) => api.writeAutoPowerOnEnable([v]), setLocal: (v) => _autoPowerOn = v))),
          SettingsCard(child: SettingsNavRow(title: 'Power Off', onTap: _powerOff)),
        ],
      ),
    );
  }
}
