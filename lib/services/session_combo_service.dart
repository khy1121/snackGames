import 'package:shared_preferences/shared_preferences.dart';
import 'game_data_service.dart';

/// 세션 콤보 단계
class ComboReward {
  final int gamesNeeded;
  final int points;
  final String title;
  final String emoji;

  const ComboReward({
    required this.gamesNeeded,
    required this.points,
    required this.title,
    required this.emoji,
  });
}

/// 세션 콤보 서비스 - 하루에 여러 게임 플레이 시 보너스
class SessionComboService {
  static const String _keyPlayedGames = 'combo_played_games';
  static const String _keyPlayedDate = 'combo_played_date';
  static const String _keyClaimedLevel = 'combo_claimed_level';

  static SharedPreferences? _prefs;

  /// 콤보 보상 단계
  static const List<ComboReward> comboRewards = [
    ComboReward(gamesNeeded: 2, points: 50, title: '듀오 플레이어', emoji: '✌️'),
    ComboReward(gamesNeeded: 3, points: 150, title: '트리플 스타', emoji: '⭐'),
    ComboReward(gamesNeeded: 5, points: 500, title: '올 클리어!', emoji: '🏆'),
  ];

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  static SharedPreferences get prefs => _prefs!;

  /// 게임 플레이 기록
  static void recordGamePlayed(String gameId) {
    _checkAndResetDaily();
    final played = getPlayedGames();
    if (!played.contains(gameId)) {
      played.add(gameId);
      prefs.setStringList(_keyPlayedGames, played);
    }
  }

  /// 오늘 플레이한 게임 목록
  static List<String> getPlayedGames() {
    _checkAndResetDaily();
    return prefs.getStringList(_keyPlayedGames) ?? [];
  }

  /// 오늘 플레이한 게임 수
  static int getPlayedCount() {
    return getPlayedGames().length;
  }

  /// 현재 달성 가능한 콤보 레벨 (0 = 아직 없음, 1~3)
  static int getCurrentComboLevel() {
    final count = getPlayedCount();
    int level = 0;
    for (int i = 0; i < comboRewards.length; i++) {
      if (count >= comboRewards[i].gamesNeeded) {
        level = i + 1;
      }
    }
    return level;
  }

  /// 수령한 콤보 레벨
  static int getClaimedLevel() {
    _checkAndResetDaily();
    return prefs.getInt(_keyClaimedLevel) ?? 0;
  }

  /// 수령 가능한 보상이 있는지
  static bool hasUnclaimedReward() {
    return getCurrentComboLevel() > getClaimedLevel();
  }

  /// 보상 수령 → 포인트 지급, 수령 레벨 업데이트
  static ComboReward? claimReward() {
    if (!hasUnclaimedReward()) return null;

    final level = getCurrentComboLevel();
    final claimed = getClaimedLevel();

    // 아직 수령하지 않은 보상 중 가장 높은 것 지급
    int totalPoints = 0;
    ComboReward? lastReward;
    for (int i = claimed; i < level; i++) {
      totalPoints += comboRewards[i].points;
      lastReward = comboRewards[i];
    }

    GameDataService.addPoints(totalPoints);
    prefs.setInt(_keyClaimedLevel, level);

    return lastReward;
  }

  /// 다음 콤보까지 남은 게임 수
  static int? gamesUntilNextCombo() {
    final count = getPlayedCount();
    for (final reward in comboRewards) {
      if (count < reward.gamesNeeded) {
        return reward.gamesNeeded - count;
      }
    }
    return null; // 모든 콤보 달성
  }

  /// 날짜 변경 시 리셋
  static void _checkAndResetDaily() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString(_keyPlayedDate);
    if (savedDate != today) {
      prefs.setString(_keyPlayedDate, today);
      prefs.setStringList(_keyPlayedGames, []);
      prefs.setInt(_keyClaimedLevel, 0);
    }
  }

  /// 전체 게임 ID 목록
  static const List<String> allGameIds = [
    '2048', 'dice', 'slotball', 'blockpuzzle', 'microgame_rush'
  ];
}
