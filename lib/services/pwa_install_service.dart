import 'dart:html' as html;
import 'dart:js' as js;

class PWAInstallService {
  static bool _isInstallable = false;
  static bool _isInstalled = false;

  /// Initialize PWA install listeners
  static void initialize() {
    // Listen for PWA installable event
    html.window.addEventListener('pwa-installable', (event) {
      _isInstallable = true;
      print('PWA is installable');
    });

    // Listen for PWA installed event
    html.window.addEventListener('pwa-installed', (event) {
      _isInstalled = true;
      _isInstallable = false;
      print('PWA was installed');
    });

    // Check initial state
    _isInstallable = isPWAInstallable();
  }

  /// Check if PWA can be installed
  static bool isPWAInstallable() {
    try {
      final result = js.context.callMethod('isPWAInstallable');
      return result == true;
    } catch (e) {
      print('Error checking PWA installability: $e');
      return false;
    }
  }

  /// Trigger PWA installation prompt
  static Future<bool> installPWA() async {
    try {
      final promise = js.context.callMethod('installPWA');
      // JavaScript Promise를 Future로 변환
      final result = await js.JsObject.fromBrowserObject(promise).callMethod('then', [
        (value) => value,
      ]);
      return result == true;
    } catch (e) {
      print('Error installing PWA: $e');
      return false;
    }
  }

  /// Check if app is running as installed PWA
  static bool isRunningAsApp() {
    try {
      // Check if running in standalone mode
      final mediaQuery = html.window.matchMedia('(display-mode: standalone)');
      return mediaQuery.matches;
    } catch (e) {
      return false;
    }
  }

  /// Check if device is iOS
  static bool isIOS() {
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('iphone') || 
             userAgent.contains('ipad') || 
             userAgent.contains('ipod');
    } catch (e) {
      return false;
    }
  }

  /// Check if should show install button (iOS manual or Chrome auto)
  static bool shouldShowInstallButton() {
    // iOS에서는 standalone이 아니면 항상 표시
    if (isIOS() && !isRunningAsApp()) {
      return true;
    }
    // 다른 브라우저는 installable일 때만 표시
    return _isInstallable && !isRunningAsApp();
  }

  /// Get current installability status
  static bool get isInstallable => _isInstallable;

  /// Get current installation status
  static bool get isInstalled => _isInstalled;
}
