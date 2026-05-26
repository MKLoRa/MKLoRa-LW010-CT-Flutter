import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_option_lists.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/ble_password_dialog.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';

class BleSettingsPage extends StatefulWidget {
  const BleSettingsPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<BleSettingsPage> createState() => _BleSettingsPageState();
}

class _BleSettingsPageState extends State<BleSettingsPage> {
  final _advName = TextEditingController();
  final _interval = TextEditingController();
  final _timeout = TextEditingController();
  bool _beaconMode = false;
  bool _passwordVerify = false;
  int _txPowerIndex = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readAdvName(),
        api.readAdvInterval(),
        api.readAdvTxPower(),
        api.readAdvTimeout(),
        api.readBeaconMode(),
        api.readPasswordVerifyEnable(),
      ]);
      if (!mounted) return;
      _advName.text = Lw010ParamHelpers.bytesToString(results[0].data);
      _interval.text = Lw010ParamHelpers.uint8(results[1].data).toString();
      final txPower = Lw010ParamHelpers.byte0(results[2].data);
      _txPowerIndex = Lw010OptionLists.txPowerLevels.indexOf(txPower);
      if (_txPowerIndex < 0) _txPowerIndex = 6;
      _timeout.text = Lw010ParamHelpers.uint8(results[3].data).toString();
      _beaconMode = Lw010ParamHelpers.uint8(results[4].data) == 1;
      _passwordVerify = Lw010ParamHelpers.uint8(results[5].data) == 1;
      setState(() {});
    });
  }

  bool _validate() {
    final interval = int.tryParse(_interval.text.trim());
    if (interval == null || interval < 1 || interval > 100) return false;
    if (_beaconMode) return true;
    final timeout = int.tryParse(_timeout.text.trim());
    return timeout != null && timeout >= 1 && timeout <= 60;
  }

  Future<void> _save() async {
    if (!_validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final interval = int.parse(_interval.text.trim());
      final writes = <Future<bool>>[
        api.writeAdvName(utf8.encode(_advName.text)),
        api.writeAdvInterval([interval]),
        api.writeAdvTxPower([Lw010OptionLists.txPowerLevels[_txPowerIndex]]),
        api.writeBeaconMode([_beaconMode ? 1 : 0]),
        api.writePasswordVerifyEnable([_passwordVerify ? 1 : 0]),
      ];
      if (!_beaconMode) {
        writes.add(api.writeAdvTimeout([int.parse(_timeout.text.trim())]));
      }
      final ok = (await Future.wait(writes)).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  Future<void> _changePassword() async {
    if (!_passwordVerify) return;
    final password = await showBlePasswordDialog(context: context);
    if (password == null || !mounted) return;
    await runWithBleLoading(context, () async {
      final ok = await widget.session.protocol.writePassword(utf8.encode(password));
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _advName.dispose();
    _interval.dispose();
    _timeout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'BLE Settings',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: SettingsLabelRow(
              label: 'ADV Name',
              child: Expanded(
                child: TextField(
                  controller: _advName,
                  maxLength: 16,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[ -~]'))],
                  decoration: const InputDecoration(counterText: '', border: UnderlineInputBorder(), isDense: true),
                ),
              ),
            ),
          ),
          SettingsCard(child: SettingsLabelRow(label: 'ADV Interval', child: SettingsTextField(controller: _interval, hint: '1~100', suffix: '100ms'))),
          if (!_beaconMode)
            SettingsCard(child: SettingsLabelRow(label: 'ADV Timeout', child: SettingsTextField(controller: _timeout, hint: '1~60', suffix: 's'))),
          SettingsCard(child: SettingsSwitchRow(label: 'Beacon Mode', value: _beaconMode, onChanged: (v) => setState(() => _beaconMode = v))),
          SettingsCard(
            child: SettingsSliderRow(
              label: 'TX Power',
              value: _txPowerIndex.toDouble(),
              min: 0,
              max: (Lw010OptionLists.txPowerLevels.length - 1).toDouble(),
              suffix: '${Lw010OptionLists.txPowerLevels[_txPowerIndex]}dBm',
              onChanged: (v) => setState(() => _txPowerIndex = v.round()),
            ),
          ),
          SettingsCard(child: SettingsSwitchRow(label: 'Password Verify', value: _passwordVerify, onChanged: (v) => setState(() => _passwordVerify = v))),
          if (_passwordVerify)
            SettingsCard(child: SettingsNavRow(title: 'Change Password', onTap: _changePassword)),
        ],
      ),
    );
  }
}
