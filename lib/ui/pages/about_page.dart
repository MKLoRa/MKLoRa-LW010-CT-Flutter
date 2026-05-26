import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_version.dart';
import '../../viewmodels/ble_scan_view_model.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _companyName = 'MOKO TECHNOLOGY LTD.';
  static const _companyWebsite = 'www.mokosmart.com';

  Future<void> _openCompanyWebsite(BuildContext context) async {
    final uri = Uri.parse('https://$_companyWebsite');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open website')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ABOUT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ColoredBox(
        color: Colors.white,
        child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/ic_about_bg.png',
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
          ),
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 45),
                Image.asset(
                  'assets/images/lw010_ic_logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 15),
                const Text(
                  'LW010-CT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'APP Version:V$appVersion',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFA8A8A8),
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'FW Version:V1.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFA8A8A8),
                    fontSize: 17,
                  ),
                ),
                const Spacer(),
                const Text(
                  _companyName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => _openCompanyWebsite(context),
                  child: const Text(
                    _companyWebsite,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF03BFEA),
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
