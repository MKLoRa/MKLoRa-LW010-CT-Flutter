import 'dart:convert';
import 'dart:typed_data';

import 'lw010_protocol_api.dart';

class Lw010ParamHelpers {
  Lw010ParamHelpers._();

  static int byte0(List<int> data, {int defaultValue = 0}) {
    if (data.isEmpty) {
      return defaultValue;
    }
    var value = data[0];
    if (value > 127) {
      value -= 256;
    }
    return value;
  }

  static int uint8(List<int> data, {int defaultValue = 0}) {
    return data.isEmpty ? defaultValue : data[0];
  }

  static int uint16(List<int> data, {int defaultValue = 0, int offset = 0}) {
    if (data.length < offset + 2) {
      return defaultValue;
    }
    return (data[offset] << 8) | data[offset + 1];
  }

  static int int32(List<int> data, {int defaultValue = 0}) {
    if (data.length < 4) {
      return defaultValue;
    }
    return ByteData.sublistView(Uint8List.fromList(data.sublist(0, 4))).getInt32(0);
  }

  static List<int> single(int value) => [value & 0xFF];

  static List<int> uint16Bytes(int value) => [(value >> 8) & 0xFF, value & 0xFF];

  static List<int> int32Bytes(int value) {
    final bytes = ByteData(4);
    bytes.setInt32(0, value);
    return bytes.buffer.asUint8List();
  }

  static String bytesToString(List<int> data) {
    if (data.isEmpty) {
      return '';
    }
    return utf8.decode(data, allowMalformed: true).trim();
  }

  static String formatMac(List<int> data) {
    if (data.isEmpty) {
      return '';
    }
    final hex = data
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();
    final buffer = StringBuffer();
    for (var i = 0; i < hex.length; i += 2) {
      if (buffer.isNotEmpty) {
        buffer.write(':');
      }
      buffer.write(hex.substring(i, i + 2));
    }
    return buffer.toString();
  }

  static int timeZoneIndexFromBytes(List<int> data) {
    return byte0(data) + 24;
  }

  static List<int> timeZoneBytesFromIndex(int pickerIndex) {
    return single(pickerIndex - 24);
  }

  static String bytesToHex(List<int> data) {
    return data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
  }

  static List<int> hexToBytes(String hex) {
    final cleaned = hex.replaceAll(':', '').replaceAll(' ', '');
    if (cleaned.isEmpty) {
      return const [];
    }
    final bytes = <int>[];
    for (var i = 0; i < cleaned.length; i += 2) {
      bytes.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}

extension Lw010ProtocolApiBatch on Lw010ProtocolApi {
  Future<void> syncTime() async {
    final now = DateTime.now().toUtc();
    final seconds = now.millisecondsSinceEpoch ~/ 1000;
    final bytes = ByteData(4);
    bytes.setInt32(0, seconds, Endian.big);
    await client.writeParam(
      cmd: 0x00,
      subCmd: 0x20,
      data: bytes.buffer.asUint8List(),
    );
  }
}
