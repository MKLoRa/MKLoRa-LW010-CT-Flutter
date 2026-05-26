import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/ble_loading_overlay.dart';

class AppTheme {
  AppTheme._();

  static const titleBarColor = Color(0xFF2F84D0);

  static const systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: titleBarColor,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static ThemeData get materialTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: titleBarColor),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: titleBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemOverlayStyle,
      ),
    );
  }

  static Widget chromeBuilder(BuildContext context, Widget? child) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: ColoredBox(
        color: titleBarColor,
        child: BleLoadingHost(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Slide-in route without parallax on the previous page.
  /// Default Material/Cupertino transitions shift the old page and expose
  /// the navigator background (white) under the status bar.
  static Route<T> slidePageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = animation.drive(
          Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        );
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
