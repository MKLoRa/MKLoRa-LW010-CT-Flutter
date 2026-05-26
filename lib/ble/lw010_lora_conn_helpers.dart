import 'lw010_option_lists.dart';

class Lw010LoraConnState {
  int region = 3;
  int ch1 = 0;
  int ch2 = 2;
  int dr = 0;
  int dr1 = 0;
  int dr2 = 0;
  int maxCh = 2;
  int maxDr = 5;
  int minDr = 0;
  bool showCh = false;
  bool showDr = false;
  bool showDutyCycle = false;
}

class Lw010LoraConnHelpers {
  Lw010LoraConnHelpers._();

  static String regionLabel(int region) {
    final picker = Lw010OptionLists.regionDeviceToPicker(region);
    if (picker < 0 || picker >= Lw010OptionLists.loraRegions.length) {
      return 'EU868';
    }
    return Lw010OptionLists.loraRegions[picker];
  }

  static int regionFromPicker(int pickerIndex) {
    return Lw010OptionLists.regionPickerToDevice(pickerIndex);
  }

  static int pickerFromRegion(int region) {
    return Lw010OptionLists.regionDeviceToPicker(region);
  }

  static void applyRegion(Lw010LoraConnState state, int region, {bool resetValues = false}) {
    state.region = region;
    _initRanges(state);
    if (resetValues) {
      _resetChDr(state);
    }
    _initDutyCycle(state);
  }

  static void _initRanges(Lw010LoraConnState state) {
    switch (state.region) {
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
        state.maxCh = 2;
        state.maxDr = 5;
        state.minDr = 0;
        state.showCh = false;
        state.showDr = true;
        break;
      case 1:
        state.maxCh = 63;
        state.maxDr = 6;
        state.minDr = 0;
        state.showCh = true;
        state.showDr = false;
        break;
      case 2:
        state.maxCh = 95;
        state.maxDr = 5;
        state.minDr = 0;
        state.showCh = true;
        state.showDr = true;
        break;
      case 8:
        state.maxCh = 63;
        state.maxDr = 4;
        state.minDr = 0;
        state.showCh = true;
        state.showDr = false;
        break;
      default:
        state.maxCh = 1;
        state.maxDr = 5;
        state.minDr = _as923Family(state.region) ? 2 : 0;
        state.showCh = false;
        state.showDr = false;
    }
  }

  static void _resetChDr(Lw010LoraConnState state) {
    switch (state.region) {
      case 1:
      case 8:
        state.ch1 = 8;
        state.ch2 = 15;
        state.dr = 0;
        break;
      case 2:
        state.ch1 = 0;
        state.ch2 = 7;
        state.dr = 0;
        break;
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
        state.ch1 = 0;
        state.ch2 = 2;
        state.dr = 0;
        break;
      default:
        state.ch1 = 0;
        state.ch2 = 1;
        state.dr = 0;
    }
    if (_as923Family(state.region)) {
      state.dr1 = 2;
      state.dr2 = 2;
    } else {
      state.dr1 = 0;
      state.dr2 = 0;
    }
  }

  static void _initDutyCycle(Lw010LoraConnState state) {
    state.showDutyCycle =
        state.region == 3 || state.region == 4 || state.region == 5 || state.region == 9;
  }

  static bool _as923Family(int region) =>
      region == 0 || region == 1 || region == 10 || region == 11 || region == 12 || region == 13;

  static List<String> chOptions(Lw010LoraConnState state) =>
      List.generate(state.maxCh + 1, (i) => '$i');

  static List<String> drOptions(Lw010LoraConnState state) =>
      List.generate(state.maxDr - state.minDr + 1, (i) => '${state.minDr + i}');

  static bool shouldWriteCh(int region) => region == 1 || region == 2 || region == 8;

  static bool shouldWriteDr(int region) =>
      region == 2 ||
      region == 3 ||
      region == 4 ||
      region == 5 ||
      region == 6 ||
      region == 7 ||
      region == 9;

  static bool shouldWriteDutyCycle(int region) =>
      region == 3 || region == 4 || region == 5 || region == 9;
}
