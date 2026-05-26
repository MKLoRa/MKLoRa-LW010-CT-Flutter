import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Global loading visibility controller.
/// Uses an app-level overlay instead of [showDialog], so page navigation
/// cannot leave a stale dialog route on the navigator stack.
final class BleLoadingController {
  BleLoadingController._();

  static final instance = BleLoadingController._();

  final ValueNotifier<int> depth = ValueNotifier(0);

  bool get isVisible => depth.value > 0;

  void show() {
    depth.value = depth.value + 1;
  }

  void hide() {
    if (depth.value <= 0) {
      return;
    }
    depth.value = depth.value - 1;
  }

  void forceHide() {
    depth.value = 0;
  }
}

/// Wraps the app content and paints the shared loading overlay on top.
class BleLoadingHost extends StatelessWidget {
  const BleLoadingHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        ValueListenableBuilder<int>(
          valueListenable: BleLoadingController.instance.depth,
          builder: (context, depth, _) {
            if (depth <= 0) {
              return const SizedBox.shrink();
            }
            return AbsorbPointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const CupertinoActivityIndicator(radius: 14),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Shows the shared loading overlay.
void showBleLoading(BuildContext context) {
  BleLoadingController.instance.show();
}

void hideBleLoading(BuildContext context) {
  BleLoadingController.instance.hide();
}

void forceHideBleLoading() {
  BleLoadingController.instance.forceHide();
}

/// Runs [task] while the loading overlay is visible.
Future<T> runWithBleLoading<T>(
  BuildContext context,
  Future<T> Function() task, {
  bool showOverlay = true,
}) async {
  if (showOverlay) {
    showBleLoading(context);
  }
  try {
    return await task();
  } finally {
    if (showOverlay) {
      hideBleLoading(context);
    }
  }
}
