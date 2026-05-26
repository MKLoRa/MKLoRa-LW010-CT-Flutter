import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class FilterUrlPage extends StatefulWidget {
  const FilterUrlPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterUrlPage> createState() => _FilterUrlPageState();
}

class _FilterUrlPageState extends State<FilterUrlPage> {
  bool _enable = false;
  final _url = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final results = await Future.wait([
        api.readFilterEddystoneUrlEnable(),
        api.readFilterEddystoneUrl(),
      ]);
      if (!mounted) return;
      _enable = Lw010ParamHelpers.uint8(results[0].data) == 1;
      _url.text = Lw010ParamHelpers.bytesToString(results[1].data);
      setState(() {});
    });
  }

  Future<void> _save() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = (await Future.wait([
        api.writeFilterEddystoneUrl(_url.text.trim().codeUnits),
        api.writeFilterEddystoneUrlEnable([_enable ? 1 : 0]),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Filter by URL',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsSwitchRow(label: 'Enable', value: _enable, onChanged: (v) => setState(() => _enable = v))),
          SettingsCard(
            child: SettingsLabelRow(
              label: 'URL',
              child: Expanded(
                child: TextField(
                  controller: _url,
                  decoration: const InputDecoration(hintText: 'URL string', border: UnderlineInputBorder(), isDense: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
