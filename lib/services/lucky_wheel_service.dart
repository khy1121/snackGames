import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class LuckyWheelService {
  static const String _lastSpinTimeKey = 'last_spin_time';
  static const String _totalSpinsKey = 'total_spins';
  static const int spinCost = 100; // 룰렛 한 번 돌리는데 필요한 포인트
  static const int cooldownHours = 0; // 쿨다운 시간 (0이면 쿨다운 없음)

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LuckyWheelService not initialized');
    }
    return _prefs!;
  }

  // 룰렛 돌리기
  static WheelReward spin() {
    final random = Random();
    final value = random.nextDouble() * 100;

    WheelReward reward;

    // 확률 기반 보상 (재조정)
    if (value < 0.5) { // 0.5% - 잭팟 (희귀)
      reward = WheelReward(
        type: RewardType.jackpot,
        points: 5000,
        exp: 500,
        description: '🎰 잭팟!',
      );
    } else if (value < 3) { // 2.5% - 큰 보상
      reward = WheelReward(
        type: RewardType.large,
        points: 1000,
        exp: 100,
        description: '🌟 대박!',
      );
    } else if (value < 13) { // 10% - 중간 보상
      reward = WheelReward(
        type: RewardType.medium,
        points: 500,
        exp: 50,
        description: '✨ 좋아요!',
      );
    } else if (value < 38) { // 25% - 작은 보상
      reward = WheelReward(
        type: RewardType.small,
        points: 250,
        exp: 25,
        description: '👍 괜찮아요!',
      );
    } else if (value < 73) { // 35% - 최소 보상
      reward = WheelReward(
        type: RewardType.minimal,
        points: 120,
        exp: 15,
        description: '😊 조금 아쉽지만!',
      );
    } else { // 27% - 손실 방지 (투자 금액 반환)
      reward = WheelReward(
        type: RewardType.nothing,
        points: spinCost,
        exp: 5,
        description: '😅 다음 기회에!',
      );
    }

    _recordSpin();
    return reward;
  }

  static void _recordSpin() {
    final now = DateTime.now().millisecondsSinceEpoch;
    prefs.setInt(_lastSpinTimeKey, now);
    
    final totalSpins = (prefs.getInt(_totalSpinsKey) ?? 0) + 1;
    prefs.setInt(_totalSpinsKey, totalSpins);
  }

  // 쿨다운 확인
  static bool canSpin() {
    if (cooldownHours == 0) return true;

    final lastSpinTime = prefs.getInt(_lastSpinTimeKey);
    if (lastSpinTime == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final cooldownMs = cooldownHours * 60 * 60 * 1000;

    return (now - lastSpinTime) >= cooldownMs;
  }

  // 남은 쿨다운 시간 (분 단위)
  static int getRemainingCooldownMinutes() {
    if (cooldownHours == 0) return 0;

    final lastSpinTime = prefs.getInt(_lastSpinTimeKey);
    if (lastSpinTime == null) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final cooldownMs = cooldownHours * 60 * 60 * 1000;
    final remaining = cooldownMs - (now - lastSpinTime);

    return remaining > 0 ? (remaining / 60000).ceil() : 0;
  }

  // 총 스핀 횟수
  static int getTotalSpins() {
    return prefs.getInt(_totalSpinsKey) ?? 0;
  }

  // 모든 가능한 보상 목록
  static List<WheelSlot> getWheelSlots() {
    return [
      WheelSlot(label: '120P', color: 0xFFFF6B6B, probability: 35),
      WheelSlot(label: '250P', color: 0xFFFFD93D, probability: 25),
      WheelSlot(label: '500P', color: 0xFF6BCF7F, probability: 10),
      WheelSlot(label: '1000P', color: 0xFF4ECDC4, probability: 3),
      WheelSlot(label: '잭팟!', color: 0xFFFF00FF, probability: 1),
      WheelSlot(label: '100P', color: 0xFFA8E6CF, probability: 27),
    ];
  }
}

enum RewardType {
  jackpot,
  large,
  medium,
  small,
  minimal,
  nothing,
}

class WheelReward {
  final RewardType type;
  final int points;
  final int exp;
  final String description;

  WheelReward({
    required this.type,
    required this.points,
    required this.exp,
    required this.description,
  });
}

class WheelSlot {
  final String label;
  final int color;
  final int probability;

  WheelSlot({
    required this.label,
    required this.color,
    required this.probability,
  });
}
