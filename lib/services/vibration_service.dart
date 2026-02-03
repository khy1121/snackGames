import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VibrationService {
  static const String _keyEnabled = 'vibration_enabled';
  static bool _isEnabled = true;
  static bool _hasVibrator = false;
  static SharedPreferences? _prefs;

  /// 초기화 (진동 지원 여부 확인)
  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _hasVibrator = await Vibration.hasVibrator() ?? false;
    _isEnabled = _prefs?.getBool(_keyEnabled) ?? true;
  }

  /// 진동 활성화 상태 확인
  static bool get isEnabled => _isEnabled && _hasVibrator;

  /// 진동 활성화/비활성화 설정
  static Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _prefs?.setBool(_keyEnabled, enabled);
  }

  /// 짧은 진동 (버튼 탭, 타일 이동)
  static Future<void> light() async {
    if (!isEnabled) return;
    try {
      await Vibration.vibrate(duration: 10);
    } catch (e) {
      // 웹이나 지원하지 않는 플랫폼에서는 무시
    }
  }

  /// 중간 진동 (타일 합체, 주사위 배치)
  static Future<void> medium() async {
    if (!isEnabled) return;
    try {
      await Vibration.vibrate(duration: 50);
    } catch (e) {
      // 웹이나 지원하지 않는 플랫폼에서는 무시
    }
  }

  /// 강한 진동 (게임 오버, 큰 합체)
  static Future<void> heavy() async {
    if (!isEnabled) return;
    try {
      await Vibration.vibrate(duration: 100);
    } catch (e) {
      // 웹이나 지원하지 않는 플랫폼에서는 무시
    }
  }

  /// 성공 진동 패턴 (레벨업, 미션 완료)
  static Future<void> success() async {
    if (!isEnabled) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 50, 50, 50],
        intensities: [0, 128, 0, 255],
      );
    } catch (e) {
      // 대체: 단순 진동
      await medium();
    }
  }

  /// 실패 진동 패턴 (게임 오버)
  static Future<void> error() async {
    if (!isEnabled) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 100, 100, 100],
        intensities: [0, 255, 0, 255],
      );
    } catch (e) {
      // 대체: 강한 진동
      await heavy();
    }
  }

  /// 연속 진동 (주사위 3개 합체)
  static Future<void> combo() async {
    if (!isEnabled) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 30, 30, 30, 30, 50],
        intensities: [0, 128, 0, 128, 0, 255],
      );
    } catch (e) {
      // 대체: 중간 진동
      await medium();
    }
  }

  /// 대폭발 진동 (⭐x3 → 💥)
  static Future<void> explosion() async {
    if (!isEnabled) return;
    try {
      await Vibration.vibrate(
        pattern: [0, 50, 30, 50, 30, 100],
        intensities: [0, 200, 0, 200, 0, 255],
      );
    } catch (e) {
      // 대체: 강한 진동
      await heavy();
    }
  }

  /// 진동 중지
  static Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      // 무시
    }
  }
}
