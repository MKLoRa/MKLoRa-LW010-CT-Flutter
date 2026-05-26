import 'dart:async';

import 'package:nordic_dfu/nordic_dfu.dart';

class Lw010DfuException implements Exception {
  Lw010DfuException(this.message);

  final String message;

  @override
  String toString() => message;
}

class Lw010DfuService {
  Lw010DfuService._();

  static Future<void> start({
    required String address,
    required String filePath,
    void Function(String status)? onStatus,
    void Function(int percent)? onProgress,
  }) async {
    final completer = Completer<void>();
    var connectAttempts = 0;
    var finished = false;

    void finishError(Object error) {
      if (finished) return;
      finished = true;
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    void finishSuccess() {
      if (finished) return;
      finished = true;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    onStatus?.call('Waiting...');

    NordicDfu()
        .startDfu(
          address,
          filePath,
          androidParameters: const AndroidParameters(
            keepBond: false,
            disableNotification: true,
            startAsForegroundService: false,
          ),
          dfuEventHandler: DfuEventHandler(
            onDeviceConnecting: (_) {
              connectAttempts++;
              onStatus?.call('Connecting...');
              if (connectAttempts > 3) {
                onStatus?.call('Error:DFU Failed');
                NordicDfu().abortDfu();
                finishError(Lw010DfuException('Error:DFU Failed'));
              }
            },
            onDfuProcessStarting: (_) => onStatus?.call('DfuProcessStarting...'),
            onEnablingDfuMode: (_) => onStatus?.call('EnablingDfuMode...'),
            onFirmwareValidating: (_) => onStatus?.call('FirmwareValidating...'),
            onProgressChanged: (_, percent, __, ___, ____, _____) {
              onProgress?.call(percent);
              onStatus?.call('Progress:$percent%');
            },
            onDfuAborted: (_) {
              onStatus?.call('DfuAborted...');
              finishError(Lw010DfuException('DfuAborted'));
            },
            onError: (_, __, ___, message) {
              finishError(
                Lw010DfuException(
                  message.isEmpty ? 'Opps!DFU Failed. Please try again!' : message,
                ),
              );
            },
            onDfuCompleted: (_) => finishSuccess(),
          ),
        )
        .then((_) => finishSuccess())
        .catchError((Object error) {
      if (error is Lw010DfuException) {
        finishError(error);
      } else {
        finishError(Lw010DfuException('Opps!DFU Failed. Please try again!'));
      }
    });

    return completer.future;
  }
}
