import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_data_codec.dart';
import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_option_lists.dart';
import '../../../../../../ble/lw010_param_helpers.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/bottom_picker_dialog.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';

class TimingModePage extends StatefulWidget {
  const TimingModePage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<TimingModePage> createState() => _TimingModePageState();
}

class _TimingModePageState extends State<TimingModePage> {
  int _strategyIndex = 0;
  final List<Lw010TimePoint> _points = [];

  static List<String> _hours() => List.generate(24, (i) => i.toString().padLeft(2, '0'));
  static List<String> _mins() => List.generate(60, (i) => i.toString().padLeft(2, '0'));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final results = await Future.wait([
        widget.session.protocol.readTimeModePosStrategy(),
        widget.session.protocol.readTimeModeReportTimePoint(),
      ]);
      if (!mounted) return;
      _strategyIndex = Lw010ParamHelpers.uint8(results[0].data).clamp(0, 3);
      _points
        ..clear()
        ..addAll(Lw010DataCodec.decodeTimePoints(results[1].data));
      setState(() {});
    });
  }

  void _addPoint() {
    if (_points.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can set up to 10 time points!')));
      return;
    }
    setState(() => _points.add(Lw010TimePoint(hour: 0, minute: 0)));
  }

  void _removePoint(int index) {
    setState(() => _points.removeAt(index));
  }

  Future<void> _pickHour(int index) async {
    final selected = await showBottomPicker(context: context, options: _hours(), selectedIndex: _points[index].hour);
    if (selected != null) setState(() => _points[index].hour = selected);
  }

  Future<void> _pickMin(int index) async {
    final selected = await showBottomPicker(context: context, options: _mins(), selectedIndex: _points[index].minute);
    if (selected != null) setState(() => _points[index].minute = selected);
  }

  Future<void> _pickStrategy() async {
    final index = await showBottomPicker(context: context, options: Lw010OptionLists.posStrategy4, selectedIndex: _strategyIndex);
    if (index != null) setState(() => _strategyIndex = index);
  }

  List<int> _encodePoints() {
    final minutes = <int>[];
    for (final point in _points) {
      if (point.hour == 0 && point.minute == 0) {
        minutes.add(1440);
      } else {
        minutes.add(point.toMinutes());
      }
    }
    final bytes = <int>[];
    for (final value in minutes) {
      bytes.addAll(Lw010ParamHelpers.uint16Bytes(value));
    }
    return bytes;
  }

  Future<void> _save() async {
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final ok = (await Future.wait([
        api.writeTimeModePosStrategy([_strategyIndex]),
        api.writeTimeModeReportTimePoint(_encodePoints()),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Timing Mode',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Position Strategy',
              child: BlueValueButton(text: Lw010OptionLists.posStrategy4[_strategyIndex], onTap: _pickStrategy),
            ),
          ),
          for (var i = 0; i < _points.length; i++)
            SettingsCard(
              child: Column(
                children: [
                  SettingsLabelRow(
                    label: 'Time Point ${i + 1}',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlueValueButton(text: _points[i].hour.toString().padLeft(2, '0'), onTap: () => _pickHour(i)),
                        const Text(' : '),
                        BlueValueButton(text: _points[i].minute.toString().padLeft(2, '0'), onTap: () => _pickMin(i)),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removePoint(i)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SettingsCard(
            child: ElevatedButton(onPressed: _addPoint, child: const Text('Add Time Point')),
          ),
        ],
      ),
    );
  }
}
