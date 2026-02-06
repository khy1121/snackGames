// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

/// Web용 진동 서비스 (Vibration API 사용)
class VibrationService {
  static const String _keyEnabled = 'vibration_enabled';
  static bool _isEnabled = true;
  static bool _hasVibrator = false;

  /// 초기화 (웹 진동 API 지원 확인)
  static Future<void> init(dynamic prefs) async {
    print('=== Web Vibration Service Init ===');
    _hasVibrator = _checkVibrationSupport();
    print('Web Vibration API supported: $_hasVibrator');
    
    // localStorage 사용
    final stored = html.window.localStorage[_keyEnabled];
    if (stored != null) {
      _isEnabled = stored == 'true';
    }
    print('Vibration enabled: $_isEnabled');
    print('=================================');
  }

  static bool _checkVibrationSupport() {
    try {
      // navigator.vibrate가 존재하는지 확인
      return js_util.hasProperty(html.window.navigator, 'vibrate');
    } catch (e) {
      print('Vibration check failed: $e');
      return false;
    }
  }

  /// 진동 활성화 상태 확인
  static bool get isEnabled => _isEnabled && _hasVibrator;

  /// 진동 활성화/비활성화 설정
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    html.window.localStorage[_keyEnabled] = enabled.toString();
    print('Vibration enabled: $enabled');
  }

  static void _vibrate(int duration) {
    if (!_isEnabled) return;
    if (!_hasVibrator) return;
    
    try {
      // navigator.vibrate() 호출
      js_util.callMethod(html.window.navigator, 'vibrate', [duration]);
      print('Vibrate: ${duration}ms');
    } catch (e) {
      print('Vibration failed: $e');
    }
  }

  static void _vibratePattern(List<int> pattern) {
    if (!_isEnabled) return;
    if (!_hasVibrator) return;
    
    try {
      // navigator.vibrate() 호출 (패턴)
      js_util.callMethod(html.window.navigator, 'vibrate', [
        js_util.jsify(pattern)
      ]);
      print('Vibrate pattern: $pattern');
    } catch (e) {
      print('Vibration pattern failed: $e');
    }
  }

  /// 짧은 진동 (버튼 탭)
  static Future<void> light() async {
    _vibrate(10);
  }

  /// 중간 진동 (타일 합체)
  static Future<void> medium() async {
    _vibrate(50);
  }

  /// 강한 진동 (큰 합체)
  static Future<void> heavy() async {
    _vibrate(100);
  }

  /// 성공 진동 패턴
  static Future<void> success() async {
    _vibratePattern([0, 50, 50, 50]);
  }

  /// 실패 진동 패턴
  static Future<void> error() async {
    _vibratePattern([0, 100, 100, 100]);
  }

  /// 연속 진동 (콤보)
  static Future<void> combo() async {
    _vibratePattern([0, 30, 30, 30, 30, 50]);
  }

  /// 폭발 진동 (매직 폭발)
  static Future<void> explosion() async {
    _vibratePattern([0, 100, 50, 100, 50, 200]);
  }

  /// 진동 취소
  static Future<void> cancel() async {
    if (!_hasVibrator) return;
    try {
      js_util.callMethod(html.window.navigator, 'vibrate', [0]);
    } catch (e) {
      // 무시
    }
  }
}

