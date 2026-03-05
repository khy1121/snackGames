import 'dart:html' as html;
import 'dart:js' as js;

class PWAInstallService {
  static bool _isInstallable = false;
  static bool _isInstalled = false;

  static void initialize() {
    html.window.addEventListener('pwa-installable', (event) {
      _isInstallable = true;
    });

    html.window.addEventListener('pwa-installed', (event) {
      _isInstalled = true;
      _isInstallable = false;
    });

    _isInstallable = isPWAInstallable();
  }

  static bool isPWAInstallable() {
    try {
      final result = js.context.callMethod('isPWAInstallable');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> installPWA() async {
    try {
      final promise = js.context.callMethod('installPWA');
      final result = await js.JsObject.fromBrowserObject(promise).callMethod('then', [
        (value) => value,
      ]);
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static bool isRunningAsApp() {
    try {
      final mediaQuery = html.window.matchMedia('(display-mode: standalone)');
      return mediaQuery.matches;
    } catch (e) {
      return false;
    }
  }

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

  static bool shouldShowInstallButton() {
    if (isIOS() && !isRunningAsApp()) {
      return true;
    }
    return _isInstallable && !isRunningAsApp();
  }

  static bool get isInstallable => _isInstallable;
  static bool get isInstalled => _isInstalled;
}
