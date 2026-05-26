import 'package:flutter/foundation.dart';

import 'lw010_constants.dart';
import 'lw010_param_key.dart';
import 'lw010_protocol_codec.dart';

/// Debug-only protocol logger for Flutter console output.
class Lw010ProtocolLogger {
  Lw010ProtocolLogger._();

  static bool enabled = true;

  static final Map<int, String> _paramNames = {
    for (final key in Lw010ParamKey.values) key.key: key.name,
  };

  static void logTx({
    required String channel,
    required int cmd,
    required int subCmd,
    required List<int> payload,
  }) {
    if (!_shouldLog) return;

    final param = _paramLabel(cmd, subCmd);
    final operation = _operationFromPayload(payload, cmd, subCmd);
    final writeData = _writeDataFromPayload(payload);
    debugPrint(
      '[LW010 TX] $channel | $operation $param | frame=${_formatHex(payload)}'
      '${writeData == null ? '' : ' | writeData=${_formatHex(writeData)}'}',
    );
  }

  static void logRx({
    required String channel,
    required List<int> payload,
    bool partialPacket = false,
  }) {
    if (!_shouldLog) return;

    final parsed = Lw010ProtocolCodec.parseReadResponse(payload);
    final cmd = parsed?.cmd ?? (payload.length > 3 ? payload[2] : null);
    final subCmd = parsed?.subCmd ?? (payload.length > 3 ? payload[3] : null);
    final param = cmd == null || subCmd == null ? 'unknown' : _paramLabel(cmd, subCmd);
    final suffix = partialPacket ? ' (packet chunk)' : '';
    final parsedData = parsed?.data;
    final writeOk = cmd != null &&
        subCmd != null &&
        Lw010ProtocolCodec.isWriteSuccess(payload, cmd, subCmd);

    debugPrint(
      '[LW010 RX] $channel | $param$suffix | frame=${_formatHex(payload)}'
      '${parsedData == null ? '' : ' | data=${_formatHex(parsedData)}'}'
      '${writeOk ? ' | result=OK' : ''}',
    );
  }

  static void logGattRead({
    required String name,
    required List<int> value,
  }) {
    if (!_shouldLog) return;
    final text = String.fromCharCodes(value.where((b) => b != 0)).trim();
    debugPrint(
      '[LW010 GATT READ] $name | raw=${_formatHex(value)} | text="$text"',
    );
  }

  static void logDisconnectNotify(List<int> value) {
    if (!_shouldLog) return;
    debugPrint('[LW010 NOTIFY] disconnect | raw=${_formatHex(value)}');
  }

  static void logError(String message) {
    if (!_shouldLog) return;
    debugPrint('[LW010 ERROR] $message');
  }

  static bool get _shouldLog => kDebugMode && enabled;

  static String _paramLabel(int cmd, int subCmd) {
    final key = ((cmd & 0xFF) << 8) | (subCmd & 0xFF);
    final name = _paramNames[key];
    return name == null
        ? '0x${cmd.toRadixString(16).padLeft(2, '0')}${subCmd.toRadixString(16).padLeft(2, '0')}'
        : '$name (0x${cmd.toRadixString(16).padLeft(2, '0')}${subCmd.toRadixString(16).padLeft(2, '0')})';
  }

  static String _operationFromPayload(List<int> payload, int cmd, int subCmd) {
    if (payload.length < 2) {
      return 'UNKNOWN';
    }
    if (cmd == Lw010ProtocolConstants.passwordCmd &&
        subCmd == Lw010ProtocolConstants.passwordSubCmd) {
      return 'PASSWORD';
    }
    return payload[1] == Lw010ProtocolConstants.flagRead ? 'READ' : 'WRITE';
  }

  static List<int>? _writeDataFromPayload(List<int> payload) {
    if (payload.length < 5) {
      return null;
    }
    if (payload[1] != Lw010ProtocolConstants.flagWrite) {
      return null;
    }
    if (payload[0] == Lw010ProtocolConstants.headPacket) {
      if (payload.length < 7) {
        return null;
      }
      final length = payload[6];
      if (payload.length < 7 + length) {
        return null;
      }
      return payload.sublist(7, 7 + length);
    }
    final length = payload[4];
    if (payload.length < 5 + length) {
      return null;
    }
    final data = payload.sublist(5, 5 + length);
    if (payload[2] == Lw010ProtocolConstants.passwordCmd &&
        payload[3] == Lw010ProtocolConstants.passwordSubCmd) {
      return List<int>.filled(data.length, 0x2A);
    }
    return data;
  }

  static String _formatHex(List<int> bytes) {
    if (bytes.isEmpty) {
      return '(empty)';
    }
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }
}
