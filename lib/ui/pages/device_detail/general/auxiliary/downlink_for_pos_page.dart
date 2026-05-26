import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_option_lists.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class DownlinkForPosPage extends StatefulWidget {
  const DownlinkForPosPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<DownlinkForPosPage> createState() => _DownlinkForPosPageState();
}

class _DownlinkForPosPageState extends State<DownlinkForPosPage> {
  int _strategyIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final result = await widget.session.protocol.readDownLinkPosStrategy();
      if (!mounted) return;
      setState(() => _strategyIndex = Lw010ParamHelpers.uint8(result.data).clamp(0, 4));
    });
  }

  Future<void> _pickStrategy() async {
    final index = await showBottomPicker(context: context, options: Lw010OptionLists.posStrategy5, selectedIndex: _strategyIndex);
    if (index == null || !mounted) return;
    setState(() => _strategyIndex = index);
    await runWithBleLoading(context, () async {
      final ok = await widget.session.protocol.writeDownLinkPosStrategy([index]);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Downlink for Position',
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Position Strategy',
              child: BlueValueButton(text: Lw010OptionLists.posStrategy5[_strategyIndex], onTap: _pickStrategy),
            ),
          ),
        ],
      ),
    );
  }
}
