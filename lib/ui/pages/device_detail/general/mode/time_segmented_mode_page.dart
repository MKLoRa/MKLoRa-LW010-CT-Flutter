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

class _PeriodEditor {
  _PeriodEditor(this.segment) : interval = TextEditingController(text: segment.reportInterval.toString());

  final Lw010TimeSegment segment;
  final TextEditingController interval;

  void dispose() => interval.dispose();
}

class TimeSegmentedModePage extends StatefulWidget {
  const TimeSegmentedModePage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<TimeSegmentedModePage> createState() => _TimeSegmentedModePageState();
}

class _TimeSegmentedModePageState extends State<TimeSegmentedModePage> {
  int _strategyIndex = 0;
  final List<_PeriodEditor> _periods = [];

  static List<String> _hours() => List.generate(25, (i) => i.toString().padLeft(2, '0'));
  static List<String> _mins() => List.generate(60, (i) => i.toString().padLeft(2, '0'));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _clearPeriods() {
    for (final period in _periods) {
      period.dispose();
    }
    _periods.clear();
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final results = await Future.wait([
        widget.session.protocol.readTimePeriodicModePosStrategy(),
        widget.session.protocol.readTimePeriodicModeReportTimePoint(),
      ]);
      if (!mounted) return;
      _strategyIndex = Lw010ParamHelpers.uint8(results[0].data).clamp(0, 4);
      _clearPeriods();
      for (final segment in Lw010DataCodec.decodeTimeSegments(results[1].data)) {
        _periods.add(_PeriodEditor(segment));
      }
      setState(() {});
    });
  }

  void _addPeriod() {
    if (_periods.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can set up to 3 time points!')));
      return;
    }
    setState(() => _periods.add(_PeriodEditor(Lw010TimeSegment(startHour: 0, startMinute: 0, endHour: 0, endMinute: 0, reportInterval: 600))));
  }

  void _removePeriod(int index) {
    setState(() {
      _periods.removeAt(index).dispose();
    });
  }

  Future<void> _pickHourMin(Lw010TimeSegment period, {required bool start, required bool hour}) async {
    final options = hour ? _hours() : _mins();
    final selected = hour ? (start ? period.startHour : period.endHour) : (start ? period.startMinute : period.endMinute);
    final index = await showBottomPicker(context: context, options: options, selectedIndex: selected.clamp(0, options.length - 1));
    if (index == null) return;
    setState(() {
      if (start && hour) period.startHour = index;
      if (start && !hour) period.startMinute = index;
      if (!start && hour) period.endHour = index;
      if (!start && !hour) period.endMinute = index;
    });
  }

  int? _validate() {
    for (final period in _periods) {
      final interval = int.tryParse(period.interval.text.trim());
      if (interval == null || interval < 30 || interval > 86400) return 1;
      period.segment.reportInterval = interval;
      final start = period.segment.startHour * 60 + period.segment.startMinute;
      final end = period.segment.endHour * 60 + period.segment.endMinute;
      if (start > 1440 || end > 1440) return 1;
      if (start >= end) return 2;
    }
    if (_periods.length > 1) {
      final aStart = _periods[0].segment.startHour * 60 + _periods[0].segment.startMinute;
      final aEnd = _periods[0].segment.endHour * 60 + _periods[0].segment.endMinute;
      final bStart = _periods[1].segment.startHour * 60 + _periods[1].segment.startMinute;
      final bEnd = _periods[1].segment.endHour * 60 + _periods[1].segment.endMinute;
      if (aStart < bEnd && bStart < aEnd) return 3;
    }
    if (_periods.length > 2) {
      final aStart = _periods[0].segment.startHour * 60 + _periods[0].segment.startMinute;
      final aEnd = _periods[0].segment.endHour * 60 + _periods[0].segment.endMinute;
      final cStart = _periods[2].segment.startHour * 60 + _periods[2].segment.startMinute;
      final cEnd = _periods[2].segment.endHour * 60 + _periods[2].segment.endMinute;
      final bStart = _periods[1].segment.startHour * 60 + _periods[1].segment.startMinute;
      final bEnd = _periods[1].segment.endHour * 60 + _periods[1].segment.endMinute;
      if (aStart < cEnd && cStart < aEnd) return 3;
      if (bStart < cEnd && cStart < bEnd) return 3;
    }
    return 0;
  }

  Future<void> _save() async {
    final code = _validate();
    if (code == 1) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para error!')));
      return;
    }
    if (code == 2) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The start time must be earlier than the end time!')));
      return;
    }
    if (code == 3) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Time ranges cannot overlap!')));
      return;
    }
    await runWithBleLoading(context, () async {
      final api = widget.session.protocol;
      final segments = _periods.map((p) => p.segment).toList();
      final ok = (await Future.wait([
        api.writeTimePeriodicModePosStrategy([_strategyIndex]),
        api.writeTimePeriodicModeReportTimePoint(Lw010DataCodec.encodeTimeSegments(segments)),
      ])).every((r) => r);
      if (mounted) await saveWithToast(context, () async => ok);
    });
  }

  @override
  void dispose() {
    _clearPeriods();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Time-Segmented Mode',
      showSave: true,
      onSave: _save,
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(
            child: SettingsLabelRow(
              label: 'Position Strategy',
              child: BlueValueButton(
                text: Lw010OptionLists.posStrategy5[_strategyIndex],
                onTap: () async {
                  final index = await showBottomPicker(context: context, options: Lw010OptionLists.posStrategy5, selectedIndex: _strategyIndex);
                  if (index != null) setState(() => _strategyIndex = index);
                },
              ),
            ),
          ),
          for (var i = 0; i < _periods.length; i++)
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Time Period ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removePeriod(i)),
                    ],
                  ),
                  SettingsLabelRow(
                    label: 'Start',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlueValueButton(text: _periods[i].segment.startHour.toString().padLeft(2, '0'), onTap: () => _pickHourMin(_periods[i].segment, start: true, hour: true)),
                        const Text(' : '),
                        BlueValueButton(text: _periods[i].segment.startMinute.toString().padLeft(2, '0'), onTap: () => _pickHourMin(_periods[i].segment, start: true, hour: false)),
                      ],
                    ),
                  ),
                  SettingsLabelRow(
                    label: 'End',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BlueValueButton(text: _periods[i].segment.endHour.toString().padLeft(2, '0'), onTap: () => _pickHourMin(_periods[i].segment, start: false, hour: true)),
                        const Text(' : '),
                        BlueValueButton(text: _periods[i].segment.endMinute.toString().padLeft(2, '0'), onTap: () => _pickHourMin(_periods[i].segment, start: false, hour: false)),
                      ],
                    ),
                  ),
                  SettingsLabelRow(
                    label: 'Report Interval',
                    child: SettingsTextField(controller: _periods[i].interval, hint: '30~86400', suffix: 's'),
                  ),
                ],
              ),
            ),
          SettingsCard(child: ElevatedButton(onPressed: _addPeriod, child: const Text('Add Time Period'))),
        ],
      ),
    );
  }
}
