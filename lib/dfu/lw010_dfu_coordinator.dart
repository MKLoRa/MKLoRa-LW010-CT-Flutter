/// Tracks an in-progress DFU so the detail page can ignore disconnect events.
class Lw010DfuCoordinator {
  Lw010DfuCoordinator._();

  static var isUpgrading = false;
  static String? deviceMac;

  static void begin({required String mac}) {
    isUpgrading = true;
    deviceMac = mac;
  }

  static void end() {
    isUpgrading = false;
    deviceMac = null;
  }
}
