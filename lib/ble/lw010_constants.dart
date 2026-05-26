class Lw010Uuids {
  Lw010Uuids._();

  static const deviceInfoService = '0000180a-0000-1000-8000-00805f9b34fb';
  static const customService = '0000aa00-0000-1000-8000-00805f9b34fb';

  static const modelNumber = '00002a24-0000-1000-8000-00805f9b34fb';
  static const serialNumber = '00002a25-0000-1000-8000-00805f9b34fb';
  static const firmwareRevision = '00002a26-0000-1000-8000-00805f9b34fb';
  static const hardwareRevision = '00002a27-0000-1000-8000-00805f9b34fb';
  static const softwareRevision = '00002a28-0000-1000-8000-00805f9b34fb';
  static const manufacturerName = '00002a29-0000-1000-8000-00805f9b34fb';

  static const password = '0000aa00-0000-1000-8000-00805f9b34fb';
  static const disconnectNotify = '0000aa01-0000-1000-8000-00805f9b34fb';
  static const params = '0000aa02-0000-1000-8000-00805f9b34fb';
  static const defaultParams = '0000aa03-0000-1000-8000-00805f9b34fb';
  static const logNotify = '0000aa04-0000-1000-8000-00805f9b34fb';
  static const productionTest = '0000aa06-0000-1000-8000-00805f9b34fb';
}

class Lw010ProtocolConstants {
  Lw010ProtocolConstants._();

  static const headSingle = 0xED;
  static const headPacket = 0xEE;
  static const flagRead = 0x00;
  static const flagWrite = 0x01;
  static const flagNotify = 0x02;

  static const passwordCmd = 0x00;
  static const passwordSubCmd = 0x01;

  static const productionTestCmd = 0x0A;
  static const productionTestStatusSubCmd = 0x02;

  static const connectMaxAttempts = 5;
  static const connectRetryDelayMs = 200;
  static const connectTotalTimeout = Duration(seconds: 50);
  static const requestTimeout = Duration(seconds: 10);
  static const packetDataMaxLength = 176;
}
