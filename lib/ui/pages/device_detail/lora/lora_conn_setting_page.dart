import 'package:flutter/material.dart';

import '../../../../../ble/lw010.dart';
import '../../../../../ble/lw010_data_codec.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_lora_conn_helpers.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../device_detail_utils.dart';

class LoRaConnSettingPage extends StatefulWidget {
  const LoRaConnSettingPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<LoRaConnSettingPage> createState() => _LoRaConnSettingPageState();
}

class _LoRaConnSettingPageState extends State<LoRaConnSettingPage> {
  final _state = Lw010LoraConnState();
  final _devEui = TextEditingController();
  final _appEui = TextEditingController();
  final _appKey = TextEditingController();
  final _devAddr = TextEditingController();
  final _appSkey = TextEditingController();
  final _nwkSkey = TextEditingController();
  final _adrAckLimit = TextEditingController();
  final _adrAckDelay = TextEditingController();

  int _modeIndex = 1;
  int _regionPicker = 2;
  bool _advanced = false;
  bool _adr = true;
  bool _dutyCycle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readLoraMode(),
        api.readLoraDevEui(),
        api.readLoraAppEui(),
        api.readLoraAppKey(),
        api.readLoraDevAddr(),
        api.readLoraAppSkey(),
        api.readLoraNwkSkey(),
        api.readLoraRegion(),
        api.readLoraCh(),
        api.readLoraDutycycle(),
        api.readLoraDr(),
        api.readLoraAdrAckLimit(),
        api.readLoraAdrAckDelay(),
        api.readLoraUplinkStrategy(),
      ]);
      if (!mounted) return;
      final mode = Lw010ParamHelpers.uint8(results[0].data);
      _modeIndex = (mode - 1).clamp(0, 1);
      _devEui.text = Lw010ParamHelpers.bytesToHex(results[1].data);
      _appEui.text = Lw010ParamHelpers.bytesToHex(results[2].data);
      _appKey.text = Lw010ParamHelpers.bytesToHex(results[3].data);
      _devAddr.text = Lw010ParamHelpers.bytesToHex(results[4].data);
      _appSkey.text = Lw010ParamHelpers.bytesToHex(results[5].data);
      _nwkSkey.text = Lw010ParamHelpers.bytesToHex(results[6].data);
      final region = Lw010ParamHelpers.uint8(results[7].data);
      _regionPicker = Lw010LoraConnHelpers.pickerFromRegion(region);
      Lw010LoraConnHelpers.applyRegion(_state, region);
      final ch = results[8].data;
      if (ch.length >= 2) {
        _state.ch1 = ch[0];
        _state.ch2 = ch[1];
      }
      _dutyCycle = Lw010ParamHelpers.uint8(results[9].data) == 1;
      _state.dr = Lw010ParamHelpers.uint8(results[10].data);
      _adrAckLimit.text = Lw010ParamHelpers.uint8(results[11].data).toString();
      _adrAckDelay.text = Lw010ParamHelpers.uint8(results[12].data).toString();
      final strategy = results[13].data;
      if (strategy.isNotEmpty) {
        _adr = Lw010ParamHelpers.uint8(strategy) == 1;
        if (strategy.length >= 4) {
          _state.dr1 = strategy[2];
          _state.dr2 = strategy[3];
        }
      }
      setState(() {});
    });
  }

  Future<void> _pickMode() async {
    final index = await showBottomPicker(
      context: context,
      options: Lw010OptionLists.loraUploadMode,
      selectedIndex: _modeIndex,
    );
    if (index != null) setState(() => _modeIndex = index);
  }

  Future<void> _pickRegion() async {
    final index = await showBottomPicker(
      context: context,
      options: Lw010OptionLists.loraRegions,
      selectedIndex: _regionPicker,
    );
    if (index == null) return;
    final region = Lw010LoraConnHelpers.regionFromPicker(index);
    setState(() {
      _regionPicker = index;
      _adr = true;
      Lw010LoraConnHelpers.applyRegion(_state, region, resetValues: true);
    });
  }

  Future<void> _pickCh1() async {
    final options = Lw010LoraConnHelpers.chOptions(_state);
    final index = await showBottomPicker(context: context, options: options, selectedIndex: _state.ch1);
    if (index == null) return;
    setState(() {
      _state.ch1 = index;
      if (_state.ch2 < _state.ch1) _state.ch2 = _state.ch1;
    });
  }

  Future<void> _pickCh2() async {
    final options = List.generate(_state.maxCh - _state.ch1 + 1, (i) => '${_state.ch1 + i}');
    final index = await showBottomPicker(context: context, options: options, selectedIndex: _state.ch2 - _state.ch1);
    if (index == null) return;
    setState(() => _state.ch2 = _state.ch1 + index);
  }

  Future<void> _pickDr() async {
    final options = Lw010LoraConnHelpers.drOptions(_state);
    final selected = _state.dr - _state.minDr;
    final index = await showBottomPicker(context: context, options: options, selectedIndex: selected.clamp(0, options.length - 1));
    if (index == null) return;
    setState(() => _state.dr = _state.minDr + index);
  }

  Future<void> _pickDr1() async {
    final options = Lw010LoraConnHelpers.drOptions(_state);
    final selected = _state.dr1 - _state.minDr;
    final index = await showBottomPicker(context: context, options: options, selectedIndex: selected.clamp(0, options.length - 1));
    if (index == null) return;
    setState(() {
      _state.dr1 = _state.minDr + index;
      if (_state.dr2 < _state.dr1) _state.dr2 = _state.dr1;
    });
  }

  Future<void> _pickDr2() async {
    final options = List.generate(_state.maxDr - _state.dr1 + 1, (i) => '${_state.dr1 + i}');
    final index = await showBottomPicker(context: context, options: options, selectedIndex: _state.dr2 - _state.dr1);
    if (index == null) return;
    setState(() => _state.dr2 = _state.dr1 + index);
  }

  bool _validate() {
    final limit = int.tryParse(_adrAckLimit.text.trim());
    final delay = int.tryParse(_adrAckDelay.text.trim());
    if (limit == null || limit < 1 || limit > 255 || delay == null || delay < 1 || delay > 255) return false;
    if (_devEui.text.length != 16 || _appEui.text.length != 16) return false;
    if (_modeIndex == 0) {
      return _devAddr.text.length == 8 && _appSkey.text.length == 32 && _nwkSkey.text.length == 32;
    }
    return _appKey.text.length == 32;
  }

  Future<void> _save() async {
    if (!_validate()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final region = _state.region;
      final writes = <Future<bool>>[
        api.writeLoraDevEui(Lw010ParamHelpers.hexToBytes(_devEui.text)),
        api.writeLoraAppEui(Lw010ParamHelpers.hexToBytes(_appEui.text)),
        if (_modeIndex == 0) ...[
          api.writeLoraDevAddr(Lw010ParamHelpers.hexToBytes(_devAddr.text)),
          api.writeLoraAppSkey(Lw010ParamHelpers.hexToBytes(_appSkey.text)),
          api.writeLoraNwkSkey(Lw010ParamHelpers.hexToBytes(_nwkSkey.text)),
        ] else
          api.writeLoraAppKey(Lw010ParamHelpers.hexToBytes(_appKey.text)),
        api.writeLoraMode([_modeIndex + 1]),
        api.writeLoraRegion([region]),
      ];
      if (Lw010LoraConnHelpers.shouldWriteCh(region)) {
        writes.add(api.writeLoraCh([_state.ch1, _state.ch2]));
      }
      if (Lw010LoraConnHelpers.shouldWriteDutyCycle(region)) {
        writes.add(api.writeLoraDutycycle([_dutyCycle ? 1 : 0]));
      }
      if (Lw010LoraConnHelpers.shouldWriteDr(region)) {
        writes.add(api.writeLoraDr([_state.dr]));
      }
      writes.addAll([
        api.writeLoraAdrAckLimit([int.parse(_adrAckLimit.text)]),
        api.writeLoraAdrAckDelay([int.parse(_adrAckDelay.text)]),
        api.writeLoraUplinkStrategy(Lw010DataCodec.encodeLoraUplinkStrategy(adr: _adr, dr1: _state.dr1, dr2: _state.dr2)),
      ]);
      final ok = (await Future.wait(writes)).every((r) => r);
      if (ok) await api.writeRebootEmpty();
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _devEui.dispose();
    _appEui.dispose();
    _appKey.dispose();
    _devAddr.dispose();
    _appSkey.dispose();
    _nwkSkey.dispose();
    _adrAckLimit.dispose();
    _adrAckDelay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Connection Setting',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsLabelRow(label: 'Upload Mode', child: BlueValueButton(text: Lw010OptionLists.loraUploadMode[_modeIndex], onTap: _pickMode))),
          SettingsCard(child: SettingsLabelRow(label: 'DevEUI', child: Expanded(child: SettingsHexField(controller: _devEui, hint: '16 hex chars', maxLength: 16)))),
          SettingsCard(child: SettingsLabelRow(label: 'AppEUI', child: Expanded(child: SettingsHexField(controller: _appEui, hint: '16 hex chars', maxLength: 16)))),
          if (_modeIndex == 0) ...[
            SettingsCard(child: SettingsLabelRow(label: 'DevAddr', child: Expanded(child: SettingsHexField(controller: _devAddr, hint: '8 hex chars', maxLength: 8)))),
            SettingsCard(child: SettingsLabelRow(label: 'AppSKey', child: Expanded(child: SettingsHexField(controller: _appSkey, hint: '32 hex chars', maxLength: 32)))),
            SettingsCard(child: SettingsLabelRow(label: 'NwkSKey', child: Expanded(child: SettingsHexField(controller: _nwkSkey, hint: '32 hex chars', maxLength: 32)))),
          ] else
            SettingsCard(child: SettingsLabelRow(label: 'AppKey', child: Expanded(child: SettingsHexField(controller: _appKey, hint: '32 hex chars', maxLength: 32)))),
          SettingsCard(child: SettingsLabelRow(label: 'Region', child: BlueValueButton(text: Lw010OptionLists.loraRegions[_regionPicker], onTap: _pickRegion))),
          SettingsCard(child: SettingsSwitchRow(label: 'Advanced Setting', value: _advanced, onChanged: (v) => setState(() => _advanced = v))),
          if (_advanced) ...[
            if (_state.showCh) ...[
              SettingsCard(child: SettingsLabelRow(label: 'CH1', child: BlueValueButton(text: '${_state.ch1}', onTap: _pickCh1))),
              SettingsCard(child: SettingsLabelRow(label: 'CH2', child: BlueValueButton(text: '${_state.ch2}', onTap: _pickCh2))),
            ],
            if (_state.showDr)
              SettingsCard(child: SettingsLabelRow(label: 'DR (Join)', child: BlueValueButton(text: '${_state.dr}', onTap: _pickDr))),
            SettingsCard(child: SettingsSwitchRow(label: 'ADR', value: _adr, onChanged: (v) => setState(() => _adr = v))),
            if (!_adr) ...[
              SettingsCard(child: SettingsLabelRow(label: 'DR1', child: BlueValueButton(text: '${_state.dr1}', onTap: _pickDr1))),
              SettingsCard(child: SettingsLabelRow(label: 'DR2', child: BlueValueButton(text: '${_state.dr2}', onTap: _pickDr2))),
            ],
            if (_state.showDutyCycle)
              SettingsCard(child: SettingsSwitchRow(label: 'Duty Cycle', value: _dutyCycle, onChanged: (v) => setState(() => _dutyCycle = v))),
            SettingsCard(child: SettingsLabelRow(label: 'ADR ACK Limit', child: SettingsTextField(controller: _adrAckLimit, hint: '1~255', maxLength: 3))),
            SettingsCard(child: SettingsLabelRow(label: 'ADR ACK Delay', child: SettingsTextField(controller: _adrAckDelay, hint: '1~255', maxLength: 3))),
          ],
        ],
      ),
    );
  }
}
