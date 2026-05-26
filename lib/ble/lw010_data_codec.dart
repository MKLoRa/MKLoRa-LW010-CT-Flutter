import 'lw010_param_helpers.dart';

class Lw010PayloadConfig {
  const Lw010PayloadConfig({required this.confirmed, required this.retransIndex});

  final bool confirmed;
  final int retransIndex;

  static Lw010PayloadConfig fromBytes(List<int> data) {
    if (data.length < 2) {
      return const Lw010PayloadConfig(confirmed: false, retransIndex: 0);
    }
    return Lw010PayloadConfig(
      confirmed: data[0] == 1,
      retransIndex: (data[1] - 1).clamp(0, 3),
    );
  }

  List<int> toBytes() => [confirmed ? 1 : 0, retransIndex + 1];
}

class Lw010TimePoint {
  Lw010TimePoint({required this.hour, required this.minute});

  int hour;
  int minute;

  int toMinutes() => hour * 60 + minute;

  static Lw010TimePoint fromMinutes(int value) {
    if (value == 0) {
      return Lw010TimePoint(hour: 0, minute: 0);
    }
    final hour = value ~/ 60;
    final minute = value % 60;
    return Lw010TimePoint(hour: hour == 24 ? 0 : hour, minute: minute);
  }
}

class Lw010TimeSegment {
  Lw010TimeSegment({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.reportInterval,
  });

  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  int reportInterval;

  List<int> encode() {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    return [
      ...Lw010ParamHelpers.uint16Bytes(start),
      ...Lw010ParamHelpers.uint16Bytes(end),
      ...Lw010ParamHelpers.int32Bytes(reportInterval),
    ];
  }
}

class Lw010DataCodec {
  Lw010DataCodec._();

  static List<int> encodeTimePoints(List<Lw010TimePoint> points) {
    final bytes = <int>[];
    for (final point in points) {
      bytes.addAll(Lw010ParamHelpers.uint16Bytes(point.toMinutes()));
    }
    return bytes;
  }

  static List<Lw010TimePoint> decodeTimePoints(List<int> data) {
    final points = <Lw010TimePoint>[];
    for (var i = 0; i + 1 < data.length; i += 2) {
      final minutes = Lw010ParamHelpers.uint16(data.sublist(i, i + 2));
      points.add(Lw010TimePoint.fromMinutes(minutes));
    }
    return points;
  }

  static List<int> encodeTimeSegments(List<Lw010TimeSegment> segments) {
    final bytes = <int>[];
    for (final segment in segments) {
      bytes.addAll(segment.encode());
    }
    return bytes;
  }

  static List<Lw010TimeSegment> decodeTimeSegments(List<int> data) {
    final segments = <Lw010TimeSegment>[];
    for (var i = 0; i + 7 < data.length; i += 8) {
      final start = Lw010ParamHelpers.uint16(data.sublist(i, i + 2));
      final end = Lw010ParamHelpers.uint16(data.sublist(i + 2, i + 4));
      final interval = Lw010ParamHelpers.int32(data.sublist(i + 4, i + 8));
      final startPoint = Lw010TimePoint.fromMinutes(start);
      final endPoint = Lw010TimePoint.fromMinutes(end);
      segments.add(
        Lw010TimeSegment(
          startHour: startPoint.hour,
          startMinute: startPoint.minute,
          endHour: endPoint.hour,
          endMinute: endPoint.minute,
          reportInterval: interval,
        ),
      );
    }
    return segments;
  }

  static List<String> decodeMacRules(List<int> data) {
    final rules = <String>[];
    var index = 0;
    while (index < data.length) {
      final length = data[index];
      index++;
      if (index + length > data.length) break;
      rules.add(Lw010ParamHelpers.bytesToHex(data.sublist(index, index + length)));
      index += length;
    }
    return rules;
  }

  static List<int> encodeMacRules(List<String> macs) {
    final bytes = <int>[];
    for (final mac in macs) {
      final macBytes = Lw010ParamHelpers.hexToBytes(mac);
      if (macBytes.isEmpty) continue;
      bytes.add(macBytes.length);
      bytes.addAll(macBytes);
    }
    return bytes;
  }

  static List<String> decodeNameRules(List<int> data) {
    final rules = <String>[];
    var index = 0;
    while (index < data.length) {
      final length = data[index];
      index++;
      if (index + length > data.length) break;
      rules.add(String.fromCharCodes(data.sublist(index, index + length)));
      index += length;
    }
    return rules;
  }

  static List<int> encodeNameRules(List<String> names) {
    final bytes = <int>[];
    for (final name in names) {
      final nameBytes = name.codeUnits;
      if (nameBytes.isEmpty) continue;
      bytes.add(nameBytes.length);
      bytes.addAll(nameBytes);
    }
    return bytes;
  }

  static int encodeIndicator({
    required bool deviceState,
    required int alarmState,
    required bool fix,
    required bool fixSuccess,
    required bool fixFail,
    required bool networkCheck,
    required bool fullCharge,
    required bool charging,
    required bool lowPower,
    required bool bleAdvCheck,
  }) {
    return (deviceState ? 1 : 0) |
        alarmState |
        (fix ? 4 : 0) |
        (fixSuccess ? 8 : 0) |
        (fixFail ? 16 : 0) |
        (networkCheck ? 32 : 0) |
        (fullCharge ? 64 : 0) |
        (charging ? 128 : 0) |
        (lowPower ? 256 : 0) |
        (bleAdvCheck ? 512 : 0);
  }

  static Map<String, bool> decodeIndicator(int value) {
    return {
      'deviceState': (value & 1) == 1,
      'alarmState': (value & 2) == 2,
      'fix': (value & 4) == 4,
      'fixSuccess': (value & 8) == 8,
      'fixFail': (value & 16) == 16,
      'networkCheck': (value & 32) == 32,
      'fullCharge': (value & 64) == 64,
      'charging': (value & 128) == 128,
      'lowPower': (value & 256) == 256,
      'bleAdvCheck': (value & 512) == 512,
    };
  }

  static List<int> encodeLoraUplinkStrategy({
    required bool adr,
    required int dr1,
    required int dr2,
  }) =>
      [adr ? 1 : 0, 1, dr1, dr2];

  static List<int> encodeAccCondition(int threshold, int duration) => [threshold, duration];

  static List<int> encodeTempEnable({required bool monitor, required bool alarm}) =>
      [(monitor ? 1 : 0) | (alarm ? 2 : 0)];

  static List<int> encodeTempThreshold(int min, int max) => [min, max];

  static List<int> encodeLightEnable({required bool monitor, required bool alarm}) =>
      [(monitor ? 1 : 0) | (alarm ? 2 : 0)];
}
