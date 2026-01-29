import 'package:shared_preferences/shared_preferences.dart';

/// 업적 모델
class Achievement {
  final String id;
  final String icon;
  final String title;
  final String description;
  final int targetValue;
  int currentValue;
  bool isUnlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
}

/// 랭크 정보
class RankInfo {
  final String name;
  final String icon;
  final int minPoints;
  final int maxPoints;

  const RankInfo({
    required this.name,
    required this.icon,
    required this.minPoints,
    required this.maxPoints,
  });
}

/// 업적 서비스
class AchievementService {
  static const String _keyPrefix = 'achievement_';
  static const String _keyPoints = 'total_points';

  static SharedPreferences? _prefs;
  static final Map<String, Achievement> _achievements = {};

  // 랭크 목록
  static const List<RankInfo> ranks = [
    RankInfo(name: 'Bronze', icon: '🥉', minPoints: 0, maxPoints: 499),
    RankInfo(name: 'Silver', icon: '🥈', minPoints: 500, maxPoints: 1499),
    RankInfo(name: 'Gold', icon: '🥇', minPoints: 1500, maxPoints: 3999),
    RankInfo(name: 'Platinum', icon: '💎', minPoints: 4000, maxPoints: 9999),
    RankInfo(name: 'Diamond', icon: '👑', minPoints: 10000, maxPoints: 999999),
  ];

  // 업적 정의
  static final List<Achievement> _achievementDefinitions = [
    // 첫 시작
    Achievement(
      id: 'first_game',
      icon: '🎮',
      title: '첫 발걸음',
      description: '첫 게임을 플레이하세요',
      targetValue: 1,
    ),
    Achievement(
      id: 'games_10',
      icon: '🔥',
      title: '열정 플레이어',
      description: '게임을 10번 플레이하세요',
      targetValue: 10,
    ),
    Achievement(
      id: 'games_50',
      icon: '⚡',
      title: '게임 마스터',
      description: '게임을 50번 플레이하세요',
      targetValue: 50,
    ),

    // 2048 업적
    Achievement(
      id: '2048_256',
      icon: '🔢',
      title: '256 달성',
      description: '2048에서 256 타일을 만드세요',
      targetValue: 256,
    ),
    Achievement(
      id: '2048_512',
      icon: '🏆',
      title: '512 달성',
      description: '2048에서 512 타일을 만드세요',
      targetValue: 512,
    ),
    Achievement(
      id: '2048_1024',
      icon: '👑',
      title: '1024 달성',
      description: '2048에서 1024 타일을 만드세요',
      targetValue: 1024,
    ),
    Achievement(
      id: '2048_2048',
      icon: '🌟',
      title: '2048 마스터',
      description: '2048에서 2048 타일을 만드세요',
      targetValue: 2048,
    ),

    // Dice 업적
    Achievement(
      id: 'dice_star',
      icon: '⭐',
      title: '첫 별',
      description: 'Dice Merge에서 ⭐ 주사위를 만드세요',
      targetValue: 1,
    ),
    Achievement(
      id: 'dice_5stars',
      icon: '🌟',
      title: '별 수집가',
      description: 'Dice Merge에서 ⭐ 주사위 5개를 만드세요',
      targetValue: 5,
    ),

    // Zero Sum 업적
    Achievement(
      id: 'zerosum_combo2',
      icon: '💥',
      title: '콤보 시작',
      description: 'Zero Sum에서 2콤보를 달성하세요',
      targetValue: 2,
    ),
    Achievement(
      id: 'zerosum_combo5',
      icon: '🔥',
      title: '콤보 마스터',
      description: 'Zero Sum에서 5콤보를 달성하세요',
      targetValue: 5,
    ),
  ];

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _loadAchievements();
  }

  static SharedPreferences get prefs => _prefs!;

  static void _loadAchievements() {
    for (final def in _achievementDefinitions) {
      final current = prefs.getInt('$_keyPrefix${def.id}_current') ?? 0;
      final unlocked = prefs.getBool('$_keyPrefix${def.id}_unlocked') ?? false;

      _achievements[def.id] = Achievement(
        id: def.id,
        icon: def.icon,
        title: def.title,
        description: def.description,
        targetValue: def.targetValue,
        currentValue: current,
        isUnlocked: unlocked,
      );
    }
  }

  /// 모든 업적 가져오기
  static List<Achievement> getAllAchievements() {
    return _achievements.values.toList();
  }

  /// 해금된 업적 수
  static int getUnlockedCount() {
    return _achievements.values.where((a) => a.isUnlocked).length;
  }

  /// 업적 진행도 업데이트
  static Future<bool> updateProgress(String achievementId, int value) async {
    final achievement = _achievements[achievementId];
    if (achievement == null || achievement.isUnlocked) return false;

    achievement.currentValue = value;
    await prefs.setInt('$_keyPrefix${achievementId}_current', value);

    if (value >= achievement.targetValue) {
      return await _unlockAchievement(achievementId);
    }
    return false;
  }

  /// 업적 해금
  static Future<bool> _unlockAchievement(String achievementId) async {
    final achievement = _achievements[achievementId];
    if (achievement == null || achievement.isUnlocked) return false;

    achievement.isUnlocked = true;
    achievement.unlockedAt = DateTime.now();
    await prefs.setBool('$_keyPrefix${achievementId}_unlocked', true);

    // 포인트 추가 (업적당 100점)
    await addPoints(100);

    return true;
  }

  // ========== 랭크 시스템 ==========

  /// 총 포인트
  static int getTotalPoints() {
    return _prefs?.getInt(_keyPoints) ?? 0;
  }

  /// 포인트 추가
  static Future<void> addPoints(int points) async {
    final current = getTotalPoints();
    await prefs.setInt(_keyPoints, current + points);
  }

  /// 현재 랭크 가져오기
  static RankInfo getCurrentRank() {
    final points = getTotalPoints();
    for (final rank in ranks.reversed) {
      if (points >= rank.minPoints) {
        return rank;
      }
    }
    return ranks.first;
  }

  /// 다음 랭크까지 남은 포인트
  static int getPointsToNextRank() {
    final points = getTotalPoints();
    final currentRank = getCurrentRank();
    final currentIndex = ranks.indexOf(currentRank);

    if (currentIndex >= ranks.length - 1) return 0;

    final nextRank = ranks[currentIndex + 1];
    return nextRank.minPoints - points;
  }
}
