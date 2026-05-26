import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/pages/ble_scan_page.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LW010CT_Flutter',
      theme: AppTheme.materialTheme,
      builder: AppTheme.chromeBuilder,
      home: const BleScanPage(),
    );
  }
}
