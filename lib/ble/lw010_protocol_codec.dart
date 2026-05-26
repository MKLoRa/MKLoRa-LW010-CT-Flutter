import 'dart:convert';
import 'dart:typed_data';

import 'lw010_constants.dart';

class Lw010ProtocolCodec {
  Lw010ProtocolCodec._();

  static List<int> buildReadFrame({
    required int cmd,
    required int subCmd,
    bool packet = false,
  }) {
    if (packet) {
      return [
        Lw010ProtocolConstants.headPacket,
        Lw010ProtocolConstants.flagRead,
        cmd,
        subCmd,
        0x00,
      ];
    }
    return [
      Lw010ProtocolConstants.headSingle,
      Lw010ProtocolConstants.flagRead,
      cmd,
      subCmd,
      0x00,
    ];
  }

  static List<int> buildWriteFrame({
    required int cmd,
    required int subCmd,
    required List<int> data,
    bool packet = false,
  }) {
    if (packet) {
      return [
        Lw010ProtocolConstants.headPacket,
        Lw010ProtocolConstants.flagWrite,
        cmd,
        subCmd,
        0x01,
        0x00,
        data.length,
        ...data,
      ];
    }
    return [
      Lw010ProtocolConstants.headSingle,
      Lw010ProtocolConstants.flagWrite,
      cmd,
      subCmd,
      data.length,
      ...data,
    ];
  }

  static List<int> buildPasswordFrame(String password) {
    final passwordBytes = utf8.encode(password);
    return [
      Lw010ProtocolConstants.headSingle,
      Lw010ProtocolConstants.flagWrite,
      Lw010ProtocolConstants.passwordCmd,
      Lw010ProtocolConstants.passwordSubCmd,
      passwordBytes.length,
      ...passwordBytes,
    ];
  }

  static bool isPasswordSuccess(List<int> value) {
    if (value.length < 6) {
      return false;
    }
    final header = value[0];
    final flag = value[1];
    final cmd = _toInt16(value, 2);
    final length = value[4];
    if (header != Lw010ProtocolConstants.headSingle ||
        flag != Lw010ProtocolConstants.flagWrite ||
        cmd != 0x0001 ||
        length != 0x01) {
      return false;
    }
    return value[5] == 0x01;
  }

  static bool isWriteSuccess(List<int> value, int cmd, int subCmd) {
    if (value.length < 6) {
      return false;
    }
    if (value[0] != Lw010ProtocolConstants.headSingle ||
        value[1] != Lw010ProtocolConstants.flagWrite) {
      return false;
    }
    if (_toInt16(value, 2) != _combine(cmd, subCmd)) {
      return false;
    }
    final length = value[4];
    return length == 0x01 && value[5] == 0x01;
  }

  static Lw010ParsedFrame? parseReadResponse(List<int> value) {
    if (value.isEmpty) {
      return null;
    }
    final header = value[0];
    if (header == Lw010ProtocolConstants.headSingle) {
      if (value.length < 5) {
        return null;
      }
      final cmd = _toInt16(value, 2);
      final length = value[4];
      if (value.length < 5 + length) {
        return null;
      }
      return Lw010ParsedFrame(
        cmd: (cmd >> 8) & 0xFF,
        subCmd: cmd & 0xFF,
        data: value.sublist(5, 5 + length),
      );
    }
    if (header == Lw010ProtocolConstants.headPacket) {
      if (value.length < 7) {
        return null;
      }
      final cmd = _toInt16(value, 2);
      final length = value[6];
      if (value.length < 7 + length) {
        return null;
      }
      return Lw010ParsedFrame(
        cmd: (cmd >> 8) & 0xFF,
        subCmd: cmd & 0xFF,
        data: value.sublist(7, 7 + length),
        packetIndex: value[5],
        packetCount: value[4],
      );
    }
    return null;
  }

  static List<int> reassemblePacketResponses(List<List<int>> packets) {
    if (packets.isEmpty) {
      return const [];
    }
    final first = packets.first;
    if (first.isEmpty || first[0] != Lw010ProtocolConstants.headPacket) {
      return const [];
    }
    final buffer = BytesBuilder();
    for (final packet in packets) {
      if (packet.length < 7) {
        continue;
      }
      final length = packet[6];
      buffer.add(packet.sublist(7, 7 + length));
    }
    final data = buffer.toBytes();
    final cmd = _toInt16(first, 2);
    return [
      Lw010ProtocolConstants.headSingle,
      Lw010ProtocolConstants.flagRead,
      (cmd >> 8) & 0xFF,
      cmd & 0xFF,
      data.length,
      ...data,
    ];
  }

  static int _combine(int cmd, int subCmd) => ((cmd & 0xFF) << 8) | (subCmd & 0xFF);

  static int _toInt16(List<int> value, int offset) {
    return ((value[offset] & 0xFF) << 8) | (value[offset + 1] & 0xFF);
  }
}

class Lw010ParsedFrame {
  const Lw010ParsedFrame({
    required this.cmd,
    required this.subCmd,
    required this.data,
    this.packetIndex,
    this.packetCount,
  });

  final int cmd;
  final int subCmd;
  final List<int> data;
  final int? packetIndex;
  final int? packetCount;

  int get key => ((cmd & 0xFF) << 8) | (subCmd & 0xFF);
}
