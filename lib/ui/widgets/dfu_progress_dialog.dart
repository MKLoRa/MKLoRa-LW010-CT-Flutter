import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DfuProgressHandle {
  DfuProgressHandle(this._update);

  final ValueNotifier<String> _update;

  void update(String message) {
    _update.value = message;
  }
}

Future<DfuProgressHandle> showDfuProgressDialog(BuildContext context) async {
  final notifier = ValueNotifier<String>('Waiting...');

  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: ValueListenableBuilder<String>(
              valueListenable: notifier,
              builder: (context, message, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CupertinoActivityIndicator(radius: 14),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ),
  );

  return DfuProgressHandle(notifier);
}

void closeDfuProgressDialog(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}
