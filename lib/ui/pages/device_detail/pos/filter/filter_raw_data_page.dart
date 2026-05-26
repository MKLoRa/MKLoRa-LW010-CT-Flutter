import 'package:flutter/material.dart';

import '../../../../../../ble/lw010_device_session.dart';
import '../../../../../../ble/lw010_protocol_named_api.dart';
import '../../../../../../ui/widgets/ble_loading_overlay.dart';
import '../../../../../../ui/widgets/device_detail/settings_widgets.dart';
import '../../device_detail_utils.dart';
import 'filter_bxp_button_page.dart';
import 'filter_bxp_ibeacon_page.dart';
import 'filter_bxp_tag_page.dart';
import 'filter_ibeacon_page.dart';
import 'filter_mk_pir_page.dart';
import 'filter_mk_tof_page.dart';
import 'filter_other_page.dart';
import 'filter_tlm_page.dart';
import 'filter_uid_page.dart';
import 'filter_url_page.dart';

class FilterRawDataPage extends StatefulWidget {
  const FilterRawDataPage({super.key, required this.session});
  final Lw010DeviceSession session;

  @override
  State<FilterRawDataPage> createState() => _FilterRawDataPageState();
}

class _FilterRawDataPageState extends State<FilterRawDataPage> {
  bool _other = false;
  bool _ibeacon = false;
  bool _uid = false;
  bool _url = false;
  bool _tlm = false;
  bool _bxpAcc = false;
  bool _bxpTh = false;
  bool _bxpTag = false;
  bool _bxpDevice = false;
  bool _bxpButton = false;
  bool _pir = false;
  bool _tof = false;
  bool _bxpIbeacon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await runWithBleLoading(context, () async {
      final data = (await widget.session.protocol.readFilterRawData()).data;
      if (!mounted || data.length < 13) return;
      setState(() {
        _other = data[0] == 1;
        _ibeacon = data[1] == 1;
        _uid = data[2] == 1;
        _url = data[3] == 1;
        _tlm = data[4] == 1;
        _bxpAcc = data[5] == 1;
        _bxpTh = data[6] == 1;
        _bxpTag = data[7] == 1;
        _bxpDevice = data[8] == 1;
        _bxpButton = data[9] == 1;
        _pir = data[10] == 1;
        _tof = data[11] == 1;
        _bxpIbeacon = data[12] == 1;
      });
    });
  }

  Future<void> _openSubPage(Widget page) async {
    await pushDetailPage(context, page);
    if (mounted) await _load();
  }

  Future<void> _toggleBxp({
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

  String _onOff(bool value) => value ? 'ON' : 'OFF';

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return DetailScaffold(
      title: 'Filter by Raw Data',
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          SettingsCard(child: SettingsNavRow(title: 'Filter by Other', trailing: _onOff(_other), onTap: () => _openSubPage(FilterOtherPage(session: session)))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by iBeacon', trailing: _onOff(_ibeacon), onTap: () => _openSubPage(FilterIbeaconPage(session: session)))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by UID', trailing: _onOff(_uid), onTap: () => _openSubPage(FilterUidPage(session: session)))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by URL', trailing: _onOff(_url), onTap: () => _openSubPage(FilterUrlPage(session: session)))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by TLM', trailing: _onOff(_tlm), onTap: () => _openSubPage(FilterTlmPage(session: session)))),
          SettingsCard(child: SettingsSwitchRow(label: 'Filter by BXP Acc', value: _bxpAcc, onChanged: (_) => _toggleBxp(current: _bxpAcc, write: (v) => session.protocol.writeFilterBxpAcc([v]), setLocal: (v) => _bxpAcc = v))),
          SettingsCard(child: SettingsSwitchRow(label: 'Filter by BXP TH', value: _bxpTh, onChanged: (_) => _toggleBxp(current: _bxpTh, write: (v) => session.protocol.writeFilterBxpTh([v]), setLocal: (v) => _bxpTh = v))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by BXP Tag', trailing: _onOff(_bxpTag), onTap: () => _openSubPage(FilterBxpTagPage(session: session)))),
          SettingsCard(child: SettingsSwitchRow(label: 'Filter by BXP Device', value: _bxpDevice, onChanged: (_) => _toggleBxp(current: _bxpDevice, write: (v) => session.protocol.writeFilterBxpDevice([v]), setLocal: (v) => _bxpDevice = v))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by BXP Button', trailing: _onOff(_bxpButton), onTap: () => _openSubPage(FilterBxpButtonPage(session: session)))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by MK PIR', trailing: _onOff(_pir), onTap: () => _openSubPage(FilterMkPirPage(session: session)))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by MK TOF', trailing: _onOff(_tof), onTap: () => _openSubPage(FilterMkTofPage(session: session)))),
          SettingsCard(child: SettingsNavRow(title: 'Filter by BXP iBeacon', trailing: _onOff(_bxpIbeacon), onTap: () => _openSubPage(FilterBxpIbeaconPage(session: session)))),
        ],
      ),
    );
  }
}
