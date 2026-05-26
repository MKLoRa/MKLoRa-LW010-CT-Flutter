import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ble_device_info.dart';
import '../../ble/lw010.dart';
import '../../ui/pages/about_page.dart';
import '../../ui/pages/device_detail_page.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/device_detail_theme.dart';
import '../../ui/widgets/ble_filter_dialog.dart';
import '../../ui/widgets/ble_password_dialog.dart';
import '../../ui/widgets/ble_loading_overlay.dart';
import '../../ui/widgets/common_confirm_dialog.dart';
import '../../ui/widgets/device_item.dart';
import '../../viewmodels/ble_scan_view_model.dart';

class BleScanPage extends StatefulWidget {
  const BleScanPage({super.key});

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final BleScanViewModel _vm;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm = BleScanViewModel();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _vm.addListener(_onVmChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.init(context);
    });
  }

  void _onVmChanged() {
    if (_vm.isScanning) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
      _rotationController.value = 0;
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _vm.onAppResumed(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _exitApp() async {
    final shouldQuit = await showCommonConfirmDialog(
      context: context,
      message: 'Are you sure you want to quit?',
      actionColor: BleScanViewModel.titleBarColor,
      barrierDismissible: false,
    );
    if (shouldQuit) {
      SystemNavigator.pop();
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showBleFilterDialog(
      context: context,
      initialKeyword: _vm.filterKeyword,
      initialRssiDbm: _vm.filterRssiDbm,
    );
    if (!mounted) {
      return;
    }
    if (result == null) {
      return;
    }
    await _vm.applyFilter(
      context: context,
      keyword: result.keyword,
      rssiDbm: result.rssiDbm,
    );
  }

  void _showAbout() {
    Navigator.of(context).push(
      AppTheme.slidePageRoute<void>(const AboutPage()),
    );
  }

  Future<void> _onConnect(BleDeviceInfo device) async {
    String? password;
    if (device.passwordEnabled) {
      password = await showBlePasswordDialog(context: context);
      if (!mounted || password == null) {
        return;
      }
    }

    showBleLoading(context);
    try {
      final session = await _vm.connectDevice(
        context: context,
        device: device,
        password: password,
      );
      if (!mounted) {
        forceHideBleLoading();
        return;
      }
      await Navigator.of(context).push<bool>(
        AppTheme.slidePageRoute(
          DeviceDetailPage(
            session: session,
            onInitialLoadComplete: () => hideBleLoading(context),
          ),
        ),
      );
      forceHideBleLoading();
      if (!mounted) {
        return;
      }
      await _vm.onReturnedFromDetail(context);
    } on Lw010ProtocolException catch (error) {
      forceHideBleLoading();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      await _vm.startScan(context: context, clearDevices: false);
    } catch (error) {
      forceHideBleLoading();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $error')),
      );
      await _vm.startScan(context: context, clearDevices: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = _vm.filteredDevices;
    final filterText = _vm.filterSummary();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _exitApp();
      },
      child: Scaffold(
        backgroundColor: BleScanViewModel.titleBarColor,
        appBar: AppBar(
          toolbarHeight: 55,
          backgroundColor: BleScanViewModel.titleBarColor,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _exitApp,
            tooltip: 'Back',
          ),
          title: Text(
            'DEVICE(${devices.length})',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: _showAbout,
              tooltip: 'About',
            ),
          ],
        ),
        body: ColoredBox(
          color: DeviceDetailTheme.background,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _showFilterDialog,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _vm.hasFilter ? filterText : 'Edit Filter',
                                style: TextStyle(
                                  color: _vm.hasFilter
                                      ? const Color(0xFF424242)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            if (_vm.hasFilter)
                              InkResponse(
                                onTap: () => _vm.clearFilterAndRescan(context),
                                radius: 18,
                                child: const Icon(
                                  Icons.cancel,
                                  color: Color(0xFFBDBDBD),
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkResponse(
                    onTap: () => _vm.isScanning
                        ? _vm.stopScan()
                        : _vm.startScan(context: context, clearDevices: false),
                    radius: 24,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: RotationTransition(
                          turns: _rotationController,
                          child: const Icon(
                            Icons.refresh,
                            color: BleScanViewModel.titleBarColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_vm.lastError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Scan error: ${_vm.lastError}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Text(
                        _vm.isScanning
                            ? 'Scanning for BLE devices...'
                            : 'Tap refresh to start scanning',
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: devices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 0),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return DeviceItem(
                          device: device,
                          onConnect: () => _onConnect(device),
                        );
                      },
                    ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
