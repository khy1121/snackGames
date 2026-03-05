class PWAInstallService {
  static void initialize() {}
  static bool isPWAInstallable() => false;
  static Future<bool> installPWA() async => false;
  static bool isRunningAsApp() => false;
  static bool isIOS() => false;
  static bool shouldShowInstallButton() => false;
  static bool get isInstallable => false;
  static bool get isInstalled => false;
}
