class Lw010OptionLists {
  Lw010OptionLists._();

  static const posStrategy4 = ['BLE', 'GPS', 'BLE+GPS', 'BLE*GPS'];
  static const posStrategy5 = [...posStrategy4, 'BLE&GPS'];

  static const loraUploadMode = ['ABP', 'OTAA'];
  static const loraRegions = [
    'AS923',
    'AU915',
    'EU868',
    'KR920',
    'IN865',
    'US915',
    'RU864',
    'AS923-1',
    'AS923-2',
    'AS923-3',
    'AS923-4',
  ];

  static const deviceModes = [
    'Standby Mode',
    'Periodic Mode',
    'Timing Mode',
    'Motion Mode',
    'Time-Segmented Mode',
  ];

  static const buzzerSounds = ['No', 'Alarm', 'Normal'];
  static const lowPowerPercents = ['10%', '20%', '30%', '40%', '50%', '60%'];

  static const alarmTypes = ['NO', 'Alert', 'SOS'];
  static const payloadTypes = ['Unconfirmed', 'Confirmed'];
  static const retransmissionTimes = ['0', '1', '2', '3'];

  static const bleFixMechanism = ['Time Priority', 'RSSI Priority'];
  static const filterRelationship = [
    'Null',
    'Only MAC',
    'Only ADV Name',
    'Only Raw Data',
    'ADV Name&Raw Data',
    'MAC&ADV Name&Raw Data',
    'ADV Name | Raw Data',
  ];

  static const alertTriggerModes = [
    'Single Click',
    'Double Click',
    'Long Press 1s',
    'Long Press 2s',
    'Long Press 3s',
  ];

  static const sosTriggerModes = [
    'Double Click',
    'Triple Click',
    'Long Press 1s',
    'Long Press 2s',
    'Long Press 3s',
  ];

  static const txPowerLevels = [-40, -20, -16, -12, -8, -4, 0, 3, 4];

  static List<String> timeZones() {
    final zones = <String>[];
    for (var i = -24; i <= 28; i++) {
      if (i < 0) {
        if (i % 2 == 0) {
          zones.add('UTC${i ~/ 2}');
        } else {
          zones.add(i < -1 ? 'UTC${(i + 1) ~/ 2}:30' : 'UTC-0:30');
        }
      } else if (i == 0) {
        zones.add('UTC');
      } else if (i % 2 == 0) {
        zones.add('UTC+${i ~/ 2}');
      } else {
        zones.add('UTC+${(i - 1) ~/ 2}:30');
      }
    }
    return zones;
  }

  static int regionPickerToDevice(int index) {
    return index > 1 ? index + 3 : index;
  }

  static int regionDeviceToPicker(int value) {
    return value > 2 ? value - 3 : value;
  }
}
