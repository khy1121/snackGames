import 'package:shared_preferences/shared_preferences.dart';

/// 업그레이드 타입
enum UpgradeType {
  scoreMultiplier,    // 점수 배율 증가
  luckyDice,          // 높은 숫자 주사위 출현율 증가
  magicChance,        // 매직 다이스 생성 확률 증가
  pointsBoost,        // 포인트 획득 배율 증가
  startingBonus,      // 시작 보너스 점수
  extraLives,         // 추가 생명 (실수 1회 되돌리기)
}

/// 업그레이드 정보
class UpgradeInfo {
  final UpgradeType type;
  final String id;
  final String name;
  final String description;
  final String icon;
  final int maxLevel;
  final int baseCost;
  final double costMultiplier;
  final List<String> effects; // 레벨별 효과 설명
  final int requiredLevel; // 해금에 필요한 레벨

  const UpgradeInfo({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.maxLevel,
    required this.baseCost,
    this.costMultiplier = 1.5,
    required this.effects,
    this.requiredLevel = 1, // 기본값: 레벨 1부터 사용 가능
  });

  /// 특정 레벨의 비용 계산
  int getCostForLevel(int level) {
    if (level >= maxLevel) return 0;
    return (baseCost * (costMultiplier * level)).round();
  }

  /// 특정 레벨의 효과 설명
  String getEffectDescription(int level) {
    if (level == 0) return 'Not purchased';
    if (level > effects.length) return effects.last;
    return effects[level - 1];
  }
}

/// 업그레이드 서비스
class UpgradeService {
  static const String _keyPrefix = 'upgrade_';
  static SharedPreferences? _prefs;

  /// 업그레이드 목록
  static final List<UpgradeInfo> upgrades = [
    UpgradeInfo(
      type: UpgradeType.scoreMultiplier,
      id: 'score_multiplier',
      name: '점수 배율 증가',
      description: '획득하는 점수가 증가합니다',
      icon: '💎',
      maxLevel: 10,
      baseCost: 100,
      costMultiplier: 1.6,
      requiredLevel: 1, // 레벨 1부터 사용 가능
      effects: [
        '+10% 점수',
        '+20% 점수',
        '+30% 점수',
        '+40% 점수',
        '+50% 점수',
        '+60% 점수',
        '+75% 점수',
        '+90% 점수',
        '+110% 점수',
        '+150% 점수',
      ],
    ),
    UpgradeInfo(
      type: UpgradeType.luckyDice,
      id: 'lucky_dice',
      name: '행운의 주사위',
      description: '높은 숫자가 더 자주 나옵니다',
      icon: '🍀',
      maxLevel: 5,
      baseCost: 200,
      costMultiplier: 2.0,
      requiredLevel: 3, // 레벨 3부터 해금
      effects: [
        '높은 숫자 +10%',
        '높은 숫자 +20%',
        '높은 숫자 +30%',
        '높은 숫자 +40%',
        '높은 숫자 +50%',
      ],
    ),
    UpgradeInfo(
      type: UpgradeType.magicChance,
      id: 'magic_chance',
      name: '매직 마스터',
      description: '6이 더 자주 나와 매직 생성 확률 증가',
      icon: '✨',
      maxLevel: 5,
      baseCost: 300,
      costMultiplier: 2.2,
      requiredLevel: 5, // 레벨 5부터 해금
      effects: [
        '6 출현율 +5%',
        '6 출현율 +10%',
        '6 출현율 +15%',
        '6 출현율 +20%',
        '6 출현율 +30%',
      ],
    ),
    UpgradeInfo(
      type: UpgradeType.pointsBoost,
      id: 'points_boost',
      name: '포인트 부스터',
      description: '게임 종료 시 획득 포인트 증가',
      icon: '💰',
      maxLevel: 8,
      baseCost: 150,
      costMultiplier: 1.7,
      requiredLevel: 2, // 레벨 2부터 해금
      effects: [
        '+20% 포인트',
        '+40% 포인트',
        '+60% 포인트',
        '+80% 포인트',
        '+100% 포인트',
        '+125% 포인트',
        '+150% 포인트',
        '+200% 포인트',
      ],
    ),
    UpgradeInfo(
      type: UpgradeType.startingBonus,
      id: 'starting_bonus',
      name: '시작 보너스',
      description: '게임 시작 시 보너스 점수',
      icon: '🎁',
      maxLevel: 5,
      baseCost: 250,
      costMultiplier: 2.0,
      requiredLevel: 4, // 레벨 4부터 해금
      effects: [
        '시작 점수 +50',
        '시작 점수 +150',
        '시작 점수 +300',
        '시작 점수 +500',
        '시작 점수 +1000',
      ],
    ),
    UpgradeInfo(
      type: UpgradeType.extraLives,
      id: 'extra_lives',
      name: '재도전 기회',
      description: '게임당 실수 되돌리기 기회',
      icon: '💚',
      maxLevel: 3,
      baseCost: 500,
      costMultiplier: 3.0,
      requiredLevel: 7, // 레벨 7부터 해금 (고급 기능)
      effects: [
        '1회 되돌리기',
        '2회 되돌리기',
        '3회 되돌리기',
      ],
    ),
  ];

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('UpgradeService not initialized');
    }
    return _prefs!;
  }

  /// 업그레이드 레벨 가져오기
  static int getUpgradeLevel(String upgradeId) {
    return prefs.getInt('$_keyPrefix$upgradeId') ?? 0;
  }

  /// 업그레이드 구매 (non-blocking)
  static bool purchaseUpgrade(String upgradeId, int cost) {
    final upgrade = upgrades.firstWhere((u) => u.id == upgradeId);
    final currentLevel = getUpgradeLevel(upgradeId);

    if (currentLevel >= upgrade.maxLevel) return false;

    // 포인트 확인 및 차감은 GameDataService에서 처리
    // 여기서는 레벨만 증가
    prefs.setInt('$_keyPrefix$upgradeId', currentLevel + 1);
    return true;
  }

  /// 점수 배율 계산
  static double getScoreMultiplier() {
    final level = getUpgradeLevel('score_multiplier');
    return 1.0 + (level * 0.1) + (level > 5 ? (level - 5) * 0.05 : 0);
  }

  /// 행운의 주사위 보너스 (0.0 ~ 1.0)
  static double getLuckyDiceBonus() {
    final level = getUpgradeLevel('lucky_dice');
    return level * 0.1;
  }

  /// 매직 확률 증가 (0.0 ~ 1.0)
  static double getMagicChanceBonus() {
    final level = getUpgradeLevel('magic_chance');
    return level * 0.05;
  }

  /// 포인트 배율
  static double getPointsMultiplier() {
    final level = getUpgradeLevel('points_boost');
    if (level == 0) return 1.0;
    if (level <= 5) return 1.0 + (level * 0.2);
    return 1.0 + (level * 0.25);
  }

  /// 시작 보너스 점수
  static int getStartingBonus() {
    final level = getUpgradeLevel('starting_bonus');
    return [0, 50, 150, 300, 500, 1000][level.clamp(0, 5)];
  }

  /// 재도전 기회 횟수
  static int getExtraLives() {
    return getUpgradeLevel('extra_lives');
  }

  /// 모든 업그레이드 정보 (레벨 포함)
  static List<UpgradeStatus> getAllUpgradeStatus(int userLevel) {
    return upgrades.map((upgrade) {
      final level = getUpgradeLevel(upgrade.id);
      return UpgradeStatus(
        info: upgrade,
        currentLevel: level,
        nextCost: upgrade.getCostForLevel(level),
        userLevel: userLevel,
      );
    }).toList();
  }

  /// 총 투자 포인트 계산
  static int getTotalInvestedPoints() {
    int total = 0;
    for (final upgrade in upgrades) {
      final level = getUpgradeLevel(upgrade.id);
      for (int i = 0; i < level; i++) {
        total += upgrade.getCostForLevel(i);
      }
    }
    return total;
  }
}

/// 업그레이드 상태
class UpgradeStatus {
  final UpgradeInfo info;
  final int currentLevel;
  final int nextCost;
  final int userLevel; // 사용자 현재 레벨

  UpgradeStatus({
    required this.info,
    required this.currentLevel,
    required this.nextCost,
    required this.userLevel,
  });

  bool get isMaxLevel => currentLevel >= info.maxLevel;
  bool get isLocked => userLevel < info.requiredLevel; // 레벨 잠금 여부
  String get currentEffect => info.getEffectDescription(currentLevel);
  String get nextEffect => info.getEffectDescription(currentLevel + 1);
}
