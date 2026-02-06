/// Vibration Service Stub (for conditional imports)
/// Import: vibration_service_mobile.dart (native) or vibration_service_web.dart (web)
class VibrationService {
  static Future<void> init(dynamic prefs) async {}
  static bool get isEnabled => false;
  static Future<void> setEnabled(bool enabled) async {}
  static Future<void> light() async {}
  static Future<void> medium() async {}
  static Future<void> heavy() async {}
  static Future<void> success() async {}
  static Future<void> error() async {}
  static Future<void> combo() async {}
  static Future<void> explosion() async {}
  static Future<void> cancel() async {}
}
