class Lw010DisconnectEvent {
  const Lw010DisconnectEvent({
    required this.type,
    required this.message,
    this.fromNotification = true,
  });

  /// 0x01 password timeout, 0x02 password changed, 0x03 no data timeout,
  /// 0x04 reboot, 0x05 factory reset, 0 = generic disconnect.
  final int type;
  final String message;
  final bool fromNotification;

  static Lw010DisconnectEvent? fromNotificationBytes(List<int> value) {
    if (value.length < 6) {
      return null;
    }
    final header = value[0];
    final flag = value[1];
    final cmd = ((value[2] & 0xFF) << 8) | (value[3] & 0xFF);
    final length = value[4];
    final type = value[5];
    if (header != 0xED || flag != 0x02 || cmd != 0x0001 || length != 0x01) {
      return null;
    }
    return Lw010DisconnectEvent(
      type: type,
      message: messageForType(type),
      fromNotification: true,
    );
  }

  static String messageForType(int type) {
    switch (type) {
      case 1:
        return 'The device is disconnected!';
      case 2:
        return 'Password changed successfully! Please reconnect the device.';
      case 3:
        return 'No data communication for 3 minutes, the device is disconnected.';
      case 4:
        return 'Reboot successfully!\nPlease reconnect the device.';
      case 5:
        return 'Factory reset successfully!\nPlease reconnect the device.';
      default:
        return 'The device disconnected!';
    }
  }

  static const generic = Lw010DisconnectEvent(
    type: 0,
    message: 'The device disconnected!',
    fromNotification: false,
  );
}
