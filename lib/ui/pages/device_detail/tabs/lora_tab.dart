import 'package:flutter/material.dart';

import '../../../../../ble/lw010.dart';
import '../../../../../ble/lw010_device_session.dart';
import '../../../../../ble/lw010_param_helpers.dart';
import '../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../ui/theme/device_detail_theme.dart';
import '../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../lora/lora_app_setting_page.dart';
import '../lora/lora_conn_setting_page.dart';
import '../pos/pos_ble_and_gps_page.dart';
import '../pos/pos_ble_fix_page.dart';
import '../pos/pos_gps_l76c_fix_page.dart';

class LoRaTab extends StatefulWidget {
  const LoRaTab({super.key, required this.session});

  final Lw010DeviceSession session;

  @override
  State<LoRaTab> createState() => LoRaTabState();
}

class LoRaTabState extends State<LoRaTab> {
  String _status = '-';
  String _summary = '-';

  Future<void> load({bool showOverlay = true}) async {
    await runWithBleLoading(
      context,
      () async {
        final api = widget.session.protocol;
        final region = await api.readLoraRegion();
        final mode = await api.readLoraMode();
        final status = await api.readLoraNetworkStatus();
        if (!mounted) return;
        setState(() {
          _status = Lw010ParamHelpers.uint8(status.data) == 1 ? 'Connected' : 'Connecting';
          final regionIndex =
              Lw010OptionLists.regionDeviceToPicker(Lw010ParamHelpers.uint8(region.data));
          final modeIndex = Lw010ParamHelpers.uint8(mode.data) - 1;
          final regionLabel = regionIndex >= 0 && regionIndex < Lw010OptionLists.loraRegions.length
              ? Lw010OptionLists.loraRegions[regionIndex]
              : 'EU868';
          final modeLabel = modeIndex >= 0 && modeIndex < Lw010OptionLists.loraUploadMode.length
              ? Lw010OptionLists.loraUploadMode[modeIndex]
              : 'OTAA';
          _summary = '$modeLabel/$regionLabel/ClassA';
        });
      },
      showOverlay: showOverlay,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SettingsCard(
          margin: EdgeInsets.zero,
          child: SettingsLabelRow(
            label: 'LoRaWAN Status',
            child: Text(
              _status,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DeviceDetailTheme.textPrimary,
              ),
            ),
          ),
        ),
        const SettingsDivider(),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Connection Setting',
            trailing: _summary,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LoRaConnSettingPage(session: widget.session),
                ),
              );
              if (mounted) await load();
            },
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'Application Setting',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LoRaAppSettingPage(session: widget.session),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PositionTab extends StatefulWidget {
  const PositionTab({super.key, required this.session});

  final Lw010DeviceSession session;

  @override
  State<PositionTab> createState() => PositionTabState();
}

class PositionTabState extends State<PositionTab> {
  bool _gpsExtremeMode = false;
  bool _voltageReport = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(showOverlay: false));
  }

  Future<void> _load({bool showOverlay = true}) async {
    await runWithBleLoading(
      context,
      () async {
        final api = widget.session.protocol;
        final extreme = await api.readGpsExtremeModeL76C();
        final voltage = await api.readVoltageReportEnable();
        if (!mounted) return;
        setState(() {
          _gpsExtremeMode = Lw010ParamHelpers.uint8(extreme.data) == 1;
          _voltageReport = Lw010ParamHelpers.uint8(voltage.data) == 1;
        });
      },
      showOverlay: showOverlay,
    );
  }

  Future<void> _toggleExtreme(bool value) async {
    await runWithBleLoading(context, () async {
      await widget.session.protocol.writeGpsExtremeModeL76C([value ? 1 : 0]);
      await _load();
    });
  }

  Future<void> _toggleVoltage(bool value) async {
    await runWithBleLoading(context, () async {
      await widget.session.protocol.writeVoltageReportEnable([value ? 1 : 0]);
      await _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SettingsCard(
          child: SettingsNavRow(
            title: 'Bluetooth Fix',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PosBleFixPage(session: widget.session),
              ),
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'GPS Fix',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PosGpsL76CFixPage(session: widget.session),
              ),
            ),
          ),
        ),
        SettingsCard(
          child: SettingsNavRow(
            title: 'BLE&GPS',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PosBleAndGpsPage(session: widget.session),
              ),
            ),
          ),
        ),
        SettingsCard(
          child: SettingsSwitchRow(
            label: 'GPS Extreme Mode',
            value: _gpsExtremeMode,
            onChanged: _toggleExtreme,
          ),
        ),
        SettingsCard(
          child: SettingsSwitchRow(
            label: 'Beacon Voltage Report in Bluetooth Fix',
            value: _voltageReport,
            onChanged: _toggleVoltage,
          ),
        ),
      ],
    );
  }
}
