import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../ble/lw010_device_session.dart';
import '../../../../ble/lw010_param_helpers.dart';
import '../../../../ble/lw010_protocol_named_api.dart';
import '../../../../dfu/lw010_dfu_coordinator.dart';
import '../../../../dfu/lw010_dfu_service.dart';
import '../../../../ui/theme/device_detail_theme.dart';
import '../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../ui/widgets/common_confirm_dialog.dart';
import '../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../../../ui/widgets/dfu_progress_dialog.dart';
import '../../../../viewmodels/ble_scan_view_model.dart';

enum SystemInfoDfuResult {
  success,
  failed,
}

class SystemInfoPage extends StatefulWidget {
  const SystemInfoPage({super.key, required this.session});

  final Lw010DeviceSession session;

  @override
  State<SystemInfoPage> createState() => _SystemInfoPageState();
}

class _SystemInfoPageState extends State<SystemInfoPage> {
  String _manufacturer = '-';
  String _firmware = '-';
  String _hardware = '-';
  String _demand = '-';
  String _model = '-';
  String _mac = '-';
  String _battery = '-';
  var _dfuRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readManufacturer(),
        api.readFirmwareVersion(),
        api.readHardwareVersion(),
        api.readDemandVersion(),
        api.readProductModel(),
        api.readChipMac(),
        api.readBatteryPower(),
      ]);
      if (!mounted) return;
      setState(() {
        _manufacturer = _textOrDash(results[0].data);
        _firmware = _textOrDash(results[1].data);
        _hardware = _textOrDash(results[2].data);
        _demand = _textOrDash(results[3].data);
        _model = _textOrDash(results[4].data);
        _mac = Lw010ParamHelpers.formatMac(results[5].data);
        if (_mac.isEmpty) _mac = '-';
        if (results[6].data.length >= 2) {
          _battery = '${Lw010ParamHelpers.uint16(results[6].data)}mV';
        }
      });
    });
  }

  String _textOrDash(List<int> data) {
    final text = Lw010ParamHelpers.bytesToString(data);
    return text.isEmpty ? '-' : text;
  }

  Future<void> _updateFirmware() async {
    if (_dfuRunning || _mac == '-' || _mac.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Para error!')),
        );
      }
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
    );
    if (!mounted || picked == null) return;

    final path = picked.files.single.path;
    if (path == null) return;

    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0 || !path.toLowerCase().endsWith('.zip')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File error!')),
        );
      }
      return;
    }

    setState(() => _dfuRunning = true);
    DfuProgressHandle? progress;
    try {
      Lw010DfuCoordinator.begin(mac: _mac);
      await widget.session.disconnect();

      progress = await showDfuProgressDialog(context);
      await Lw010DfuService.start(
        address: _mac,
        filePath: path,
        onStatus: progress.update,
      );

      if (!mounted) return;
      closeDfuProgressDialog(context);
      await showCommonConfirmDialog(
        context: context,
        message: 'Update firmware successfully!\nPlease reconnect the device.',
        confirmText: 'OK',
        actionColor: BleScanViewModel.titleBarColor,
        barrierDismissible: false,
        showCancel: false,
      );
      if (mounted) {
        Navigator.of(context).pop(SystemInfoDfuResult.success);
      }
    } on Lw010DfuException catch (error) {
      if (mounted) {
        closeDfuProgressDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
        Navigator.of(context).pop(SystemInfoDfuResult.failed);
      }
    } catch (_) {
      if (mounted) {
        closeDfuProgressDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opps!DFU Failed. Please try again!')),
        );
        Navigator.of(context).pop(SystemInfoDfuResult.failed);
      }
    } finally {
      Lw010DfuCoordinator.end();
      if (mounted) {
        setState(() => _dfuRunning = false);
      }
    }
  }

  Widget _infoRow(String label, String value, {Widget? trailing}) {
    return SettingsCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DeviceDetailTheme.textPrimary,
              ),
            ),
          ),
          if (trailing == null)
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            )
          else ...[
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Device Information',
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          _infoRow('Manufacturer', _manufacturer),
          _infoRow(
            'Firmware Version',
            _firmware,
            trailing: SizedBox(
              width: 70,
              height: 40,
              child: ElevatedButton(
                onPressed: _dfuRunning ? null : _updateFirmware,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DeviceDetailTheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('DFU', style: TextStyle(fontSize: 15)),
              ),
            ),
          ),
          _infoRow('Hardware Version', _hardware),
          _infoRow('Demand Version', _demand),
          _infoRow('Product Model', _model),
          _infoRow('MAC Address', _mac),
          _infoRow('Battery', _battery),
        ],
      ),
    );
  }
}
