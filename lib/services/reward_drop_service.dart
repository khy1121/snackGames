import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_data_service.dart';
import 'challenge_service.dart';

/// 보상 드롭 종류
enum DropType {
  points,
  xp,
}

/// 드롭 보상 결과
class DropReward {
  final DropType type;
  final int amount;
  final String emoji;
  final String description;

  const DropReward({
    required this.type,
    required this.amount,
    required this.emoji,
    required this.description,
  });
}

/// 게임 후 랜덤 보상 서비스
class RewardDropService {
  static const String _keyTodayDrops = 'drop_today_count';
  static const String _keyTodayDropDate = 'drop_today_date';
  static const String _keyTotalDrops = 'drop_total_count';

  static SharedPreferences? _prefs;
  static final _random = Random();

  /// 기본 드롭 확률 30%
  static const double _baseDropRate = 0.30;
  /// 연속 미드롭 시 증가량 5%씩
  static const double _pityIncrease = 0.05;
  /// 최대 확률 50%
  static const double _maxDropRate = 0.50;
  /// 하루 최대 드롭 횟수
  static const int _maxDailyDrops = 3;

  static int _consecutiveMisses = 0;

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  static SharedPreferences get prefs => _prefs!;

  /// 게임 종료 후 보상 드롭 시도
  /// null이면 드롭 없음, DropReward면 당첨
  static DropReward? tryDrop() {
    _checkAndResetDaily();

    // 하루 최대 횟수 체크
    final todayDrops = prefs.getInt(_keyTodayDrops) ?? 0;
    if (todayDrops >= _maxDailyDrops) return null;

    // 확률 계산 (피티 시스템)
    final dropRate = (_baseDropRate + (_consecutiveMisses * _pityIncrease))
        .clamp(0.0, _maxDropRate);

    if (_random.nextDouble() > dropRate) {
      _consecutiveMisses++;
      return null;
    }

    // 당첨!
    _consecutiveMisses = 0;
    prefs.setInt(_keyTodayDrops, todayDrops + 1);
    prefs.setInt(_keyTotalDrops, (prefs.getInt(_keyTotalDrops) ?? 0) + 1);

    return _generateReward();
  }

  /// 보상 생성
  static DropReward _generateReward() {
    final roll = _random.nextDouble();

    if (roll < 0.55) {
      // 55% - 포인트 보상
      final points = _randomRange(30, 150);
      GameDataService.addPoints(points);
      return DropReward(
        type: DropType.points,
        amount: points,
        emoji: '💰',
        description: '보너스 포인트 ${points}P!',
      );
    } else {
      // 45% - XP 보상
      final xp = _randomRange(10, 40);
      ChallengeService.addXP(xp);
      return DropReward(
        type: DropType.xp,
        amount: xp,
        emoji: '✨',
        description: '보너스 경험치 ${xp}XP!',
      );
    }
  }

  /// min~max 사이 10 단위 랜덤
  static int _randomRange(int min, int max) {
    final steps = ((max - min) ~/ 10) + 1;
    return min + (_random.nextInt(steps) * 10);
  }

  /// 오늘 총 드롭 횟수
  static int getTodayDropCount() {
    _checkAndResetDaily();
    return prefs.getInt(_keyTodayDrops) ?? 0;
  }

  /// 누적 총 드롭 횟수
  static int getTotalDropCount() {
    return prefs.getInt(_keyTotalDrops) ?? 0;
  }

  /// 날짜 변경 시 리셋
  static void _checkAndResetDaily() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString(_keyTodayDropDate);
    if (savedDate != today) {
      prefs.setString(_keyTodayDropDate, today);
      prefs.setInt(_keyTodayDrops, 0);
    }
  }
}
