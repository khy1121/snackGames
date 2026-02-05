// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class VibrationService {
  static const String _keyEnabled = 'vibration_enabled';
  static bool _isEnabled = true;
  static bool _hasVibrator = false;

  /// 초기화 (웹 진동 API 지원 확인)
  static Future<void> init(dynamic prefs) async {
    _hasVibrator = _checkVibrationSupport();
    // SharedPreferences 없이 localStorage 사용 가능
    final stored = html.window.localStorage[_keyEnabled];
    if (stored != null) {
      _isEnabled = stored == 'true';
    }
  }

  static bool _checkVibrationSupport() {
    try {
      return html.window.navigator.vibrate != null;
    } catch (e) {
      return false;
    }
  }

  /// 진동 활성화 상태 확인
  static bool get isEnabled => _isEnabled && _hasVibrator;

  /// 진동 활성화/비활성화 설정
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    html.window.localStorage[_keyEnabled] = enabled.toString();
  }

  static void _vibrate(int duration) {
    if (!isEnabled) return;
    try {
      html.window.navigator.vibrate(duration);
    } catch (e) {
      // 지원하지 않는 브라우저
    }
  }

  static void _vibratePattern(List<int> pattern) {
    if (!isEnabled) return;
    try {
      html.window.navigator.vibrate(pattern);
    } catch (e) {
      // 지원하지 않는 브라우저
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
}
