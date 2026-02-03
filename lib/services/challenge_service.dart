import 'package:shared_preferences/shared_preferences.dart';

/// 도전과제 모델
class Challenge {
  final String id;
  final String description;
  final int targetValue;
  int currentValue;
  bool isCompleted;

  Challenge({
    required this.id,
    required this.description,
    required this.targetValue,
    this.currentValue = 0,
    this.isCompleted = false,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
}

/// 레벨 정의
class LevelData {
  final int level;
  final String name;
  final int xpRequired;
  final List<Challenge> challenges;
  final int reward; // 포인트 보상

  const LevelData({
    required this.level,
    required this.name,
    required this.xpRequired,
    required this.challenges,
    required this.reward,
  });
}

/// 도전과제 레벨 서비스
class ChallengeService {
  static const String _keyLevel = 'user_level';
  static const String _keyXP = 'user_xp';
  static const String _keyChallengeProgress = 'challenge_progress_';

  static SharedPreferences? _prefs;

  // 레벨 데이터 정의 (1~15 레벨)
  static List<LevelData> get levels => [
    LevelData(
      level: 1,
      name: '초보자',
      xpRequired: 0,
      challenges: [
        Challenge(id: 'play_1', description: '게임 1회 플레이', targetValue: 1),
      ],
      reward: 50,
    ),
    LevelData(
      level: 2,
      name: '입문자',
      xpRequired: 100,
      challenges: [
        Challenge(id: 'play_3', description: '게임 3회 플레이', targetValue: 3),
        Challenge(id: 'score_300', description: '300점 달성', targetValue: 300),
      ],
      reward: 100,
    ),
    LevelData(
      level: 3,
      name: '도전자',
      xpRequired: 300,
      challenges: [
        Challenge(id: 'play_5', description: '게임 5회 플레이', targetValue: 5),
        Challenge(id: 'score_500', description: '500점 달성', targetValue: 500),
      ],
      reward: 150,
    ),
    LevelData(
      level: 4,
      name: '수련생',
      xpRequired: 600,
      challenges: [
        Challenge(id: 'play_10', description: '게임 10회 플레이', targetValue: 10),
        Challenge(id: 'score_1000', description: '1000점 달성', targetValue: 1000),
      ],
      reward: 200,
    ),
    LevelData(
      level: 5,
      name: '숙련자',
      xpRequired: 1000,
      challenges: [
        Challenge(id: 'play_15', description: '게임 15회 플레이', targetValue: 15),
        Challenge(id: 'score_1500', description: '1500점 달성', targetValue: 1500),
      ],
      reward: 300,
    ),
    LevelData(
      level: 6,
      name: '전문가',
      xpRequired: 1500,
      challenges: [
        Challenge(id: 'play_20', description: '게임 20회 플레이', targetValue: 20),
        Challenge(id: 'score_2000', description: '2000점 달성', targetValue: 2000),
      ],
      reward: 400,
    ),
    LevelData(
      level: 7,
      name: '마스터',
      xpRequired: 2200,
      challenges: [
        Challenge(id: 'play_30', description: '게임 30회 플레이', targetValue: 30),
        Challenge(id: 'score_3000', description: '3000점 달성', targetValue: 3000),
      ],
      reward: 500,
    ),
    LevelData(
      level: 8,
      name: '그랜드마스터',
      xpRequired: 3000,
      challenges: [
        Challenge(id: 'play_40', description: '게임 40회 플레이', targetValue: 40),
        Challenge(id: 'score_4000', description: '4000점 달성', targetValue: 4000),
      ],
      reward: 600,
    ),
    LevelData(
      level: 9,
      name: '챔피언',
      xpRequired: 4000,
      challenges: [
        Challenge(id: 'play_50', description: '게임 50회 플레이', targetValue: 50),
        Challenge(id: 'score_5000', description: '5000점 달성', targetValue: 5000),
      ],
      reward: 800,
    ),
    LevelData(
      level: 10,
      name: '레전드',
      xpRequired: 5500,
      challenges: [
        Challenge(id: 'play_75', description: '게임 75회 플레이', targetValue: 75),
        Challenge(id: 'score_7500', description: '7500점 달성', targetValue: 7500),
      ],
      reward: 1000,
    ),
  ];

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    _loadProgress();
  }

  static SharedPreferences get prefs => _prefs!;

  /// 현재 레벨
  static int getCurrentLevel() {
    return prefs.getInt(_keyLevel) ?? 1;
  }

  /// 현재 XP
  static int getCurrentXP() {
    return prefs.getInt(_keyXP) ?? 0;
  }

  /// 현재 레벨 데이터
  static LevelData getCurrentLevelData() {
    final level = getCurrentLevel();
    return levels.firstWhere(
      (l) => l.level == level,
      orElse: () => levels.last,
    );
  }

  /// 다음 레벨 데이터
  static LevelData? getNextLevelData() {
    final level = getCurrentLevel();
    final nextLevel = level + 1;
    try {
      return levels.firstWhere((l) => l.level == nextLevel);
    } catch (_) {
      return null; // 최대 레벨
    }
  }

  /// XP 추가 (non-blocking)
  static void addXP(int amount) {
    final current = getCurrentXP();
    prefs.setInt(_keyXP, current + amount);
  }

  /// 게임 완료 시 XP 계산 및 추가 (non-blocking)
  static void onGameComplete(int score) {
    // XP = 기본 10 + 점수/100
    final xpGain = 10 + (score ~/ 100);
    addXP(xpGain);
  }

  /// 도전과제 진행도 업데이트 및 새로 완료된 도전과제 반환 (non-blocking but returns sync result)
  static Future<List<String>> updateProgressAndGetCompleted(String type, int value) async {
    final oldValue = prefs.getInt('$_keyChallengeProgress$type') ?? 0;
    prefs.setInt('$_keyChallengeProgress$type', value); // Non-blocking
    
    // 현재 레벨의 도전과제 중 새로 완료된 것 찾기
    final completedChallenges = <String>[];
    final levelData = getCurrentLevelData();
    
    for (final c in levelData.challenges) {
      if (c.id == type || c.id.startsWith(type.split('_')[0])) {
        // 이전에는 미완료였고, 지금은 완료된 경우
        if (oldValue < c.targetValue && value >= c.targetValue) {
          completedChallenges.add(c.description);
        }
      }
    }
    
    return completedChallenges;
  }

  /// 도전과제 진행도 업데이트 (기존 호환성, non-blocking)
  static void updateProgress(String type, int value) {
    prefs.setInt('$_keyChallengeProgress$type', value);
  }

  /// 도전과제 진행도 가져오기
  static int getProgress(String type) {
    return prefs.getInt('$_keyChallengeProgress$type') ?? 0;
  }

  /// 현재 레벨 도전과제 목록 (진행도 포함)
  static List<Challenge> getCurrentChallenges() {
    final levelData = getCurrentLevelData();
    final challenges = <Challenge>[];

    for (final c in levelData.challenges) {
      final progress = getProgress(c.id);
      challenges.add(Challenge(
        id: c.id,
        description: c.description,
        targetValue: c.targetValue,
        currentValue: progress,
        isCompleted: progress >= c.targetValue,
      ));
    }

    return challenges;
  }

  /// 레벨업 가능 여부
  static bool canLevelUp() {
    final nextLevel = getNextLevelData();
    if (nextLevel == null) return false; // 최대 레벨

    // XP 조건 확인
    if (getCurrentXP() < nextLevel.xpRequired) return false;

    // 현재 레벨 도전과제 모두 완료했는지 확인
    final challenges = getCurrentChallenges();
    return challenges.every((c) => c.isCompleted);
  }

  /// 레벨업 실행
  static Future<int> levelUp() async {
    if (!canLevelUp()) return 0;

    final currentLevel = getCurrentLevel();
    final levelData = getCurrentLevelData();

    // 레벨 증가
    await prefs.setInt(_keyLevel, currentLevel + 1);

    // 보상 반환
    return levelData.reward;
  }

  /// XP 진행률 (다음 레벨까지)
  static double getXPProgress() {
    final nextLevel = getNextLevelData();
    if (nextLevel == null) return 1.0; // 최대 레벨

    final currentXP = getCurrentXP();
    final currentLevelXP = getCurrentLevelData().xpRequired;
    final nextLevelXP = nextLevel.xpRequired;

    final progress = (currentXP - currentLevelXP) / (nextLevelXP - currentLevelXP);
    return progress.clamp(0.0, 1.0);
  }

  /// 외부 데이터(GameDataService)와 동기화
  static void syncFromGameData(int totalGames, int bestScore2048, int bestScoreDice) {
    // 플레이 횟수 관련 도전과제 동기화
    final playIds = ['play_1', 'play_3', 'play_5', 'play_10', 'play_15', 'play_20', 'play_30', 'play_40', 'play_50', 'play_75'];
    for (final id in playIds) {
      updateProgress(id, totalGames);
    }
    
    // 점수 관련 도전과제 동기화 (두 게임 중 최고 점수 사용)
    final bestScore = bestScore2048 > bestScoreDice ? bestScore2048 : bestScoreDice;
    final scoreIds = ['score_300', 'score_500', 'score_1000', 'score_1500', 'score_2000', 'score_3000', 'score_4000', 'score_5000', 'score_7500'];
    for (final id in scoreIds) {
      updateProgress(id, bestScore);
    }
  }

  static void _loadProgress() {
    // 초기화 시 필요한 로직
  }
}
