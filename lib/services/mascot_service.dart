import 'package:shared_preferences/shared_preferences.dart';
import 'challenge_service.dart';
import 'dart:math';

/// 마스코트 성장 단계
enum MascotStage {
  baby,    // 레벨 1~2: 아기 팝콘
  child,   // 레벨 3~4: 꼬마 팝콘
  teen,    // 레벨 5~6: 팝콘 소년
  hero,    // 레벨 7~8: 팝콘 히어로
  legend,  // 레벨 9~10: 레전드 팝콘
}

/// 마스코트 감정 상태
enum MascotMood {
  excited,  // 오늘 3게임+ 플레이
  happy,    // 오늘 접속함
  neutral,  // 1일 미접속
  sad,      // 2일 미접속
  crying,   // 3일+ 미접속
}

/// 마스코트 서비스 - 성장 & 감정 & 대사
class MascotService {
  static const String _keyLastVisit = 'mascot_last_visit';
  static const String _keyTodayGames = 'mascot_today_games';
  static const String _keyTodayGamesDate = 'mascot_today_games_date';

  static SharedPreferences? _prefs;

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  static SharedPreferences get prefs => _prefs!;

  // ========== 성장 단계 ==========

  /// 현재 성장 단계 (레벨 기반)
  static MascotStage getCurrentStage() {
    final level = ChallengeService.getCurrentLevel();
    if (level <= 2) return MascotStage.baby;
    if (level <= 4) return MascotStage.child;
    if (level <= 6) return MascotStage.teen;
    if (level <= 8) return MascotStage.hero;
    return MascotStage.legend;
  }

  /// 성장 단계별 이모지
  static String getStageEmoji() {
    switch (getCurrentStage()) {
      case MascotStage.baby:   return '🫛';
      case MascotStage.child:  return '🌽';
      case MascotStage.teen:   return '🍿';
      case MascotStage.hero:   return '⭐';
      case MascotStage.legend: return '👑';
    }
  }

  /// 성장 단계별 이름
  static String getStageName() {
    switch (getCurrentStage()) {
      case MascotStage.baby:   return '아기 팝콘';
      case MascotStage.child:  return '꼬마 팝콘';
      case MascotStage.teen:   return '팝콘 소년';
      case MascotStage.hero:   return '팝콘 히어로';
      case MascotStage.legend: return '레전드 팝콘';
    }
  }

  /// 성장 단계별 크기 (이모지 fontSize)
  static double getStageSize() {
    switch (getCurrentStage()) {
      case MascotStage.baby:   return 48;
      case MascotStage.child:  return 56;
      case MascotStage.teen:   return 64;
      case MascotStage.hero:   return 72;
      case MascotStage.legend: return 80;
    }
  }

  // ========== 감정 상태 ==========

  /// 현재 감정 상태 계산
  static MascotMood getCurrentMood() {
    final todayGames = getTodayGameCount();
    if (todayGames >= 3) return MascotMood.excited;

    final lastVisit = prefs.getString(_keyLastVisit);
    if (lastVisit == null) return MascotMood.happy; // 첫 방문

    final today = DateTime.now();
    final lastDate = DateTime.tryParse(lastVisit);
    if (lastDate == null) return MascotMood.happy;

    final daysDiff = today.difference(lastDate).inDays;

    if (daysDiff <= 0) return MascotMood.happy;
    if (daysDiff == 1) return MascotMood.neutral;
    if (daysDiff == 2) return MascotMood.sad;
    return MascotMood.crying;
  }

  /// 감정별 이모지
  static String getMoodEmoji() {
    switch (getCurrentMood()) {
      case MascotMood.excited: return '😆';
      case MascotMood.happy:   return '😊';
      case MascotMood.neutral: return '😐';
      case MascotMood.sad:     return '😢';
      case MascotMood.crying:  return '😭';
    }
  }

  // ========== 대사 시스템 ==========

  static final _random = Random();

  /// 현재 감정에 맞는 랜덤 대사
  static String getGreeting() {
    final mood = getCurrentMood();
    final lines = _greetings[mood]!;
    return lines[_random.nextInt(lines.length)];
  }

  static final Map<MascotMood, List<String>> _greetings = {
    MascotMood.excited: [
      '오늘 완전 불타오르잖아! 🔥',
      '멈출 수가 없어~! 💪',
      '이 기세 계속 가자! ⚡',
      '오늘 컨디션 최고다! 🌟',
    ],
    MascotMood.happy: [
      '만나서 반가워! 오늘도 화이팅! 😄',
      '좋은 하루 보내고 있어? 🌈',
      '어서와~ 같이 놀자! 🎮',
      '오늘은 어떤 게임 해볼까? 🤔',
    ],
    MascotMood.neutral: [
      '...보고싶었어 😶',
      '어제는 안 왔었네... 괜찮아? 🥺',
      '하루만 안 봐도 심심해지더라 📱',
      '다시 와줘서 고마워! 🙏',
    ],
    MascotMood.sad: [
      '나 잊은거 아니지...? 😢',
      '이틀이나... 너무 오래 기다렸어 💧',
      '혹시 다른 게임 하고 있었어? 😢',
      '다시 와줘서 정말 기뻐! 🥲',
    ],
    MascotMood.crying: [
      '드디어 왔구나!! 😭😭',
      '나 진짜 포기하려고 했어... 😭',
      '어디 갔었어?! 걱정했잖아! 😭',
      '다시는 이렇게 오래 안 올거지?! 🥹',
    ],
  };

  // ========== 접속 기록 ==========

  /// 접속 기록 업데이트
  static void recordVisit() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    prefs.setString(_keyLastVisit, today);
  }

  /// 오늘 게임 플레이 횟수 기록
  static void recordGamePlayed() {
    _checkAndResetDaily();
    final count = getTodayGameCount();
    prefs.setInt(_keyTodayGames, count + 1);
  }

  /// 오늘 플레이 횟수
  static int getTodayGameCount() {
    _checkAndResetDaily();
    return prefs.getInt(_keyTodayGames) ?? 0;
  }

  /// 날짜 변경 시 리셋
  static void _checkAndResetDaily() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString(_keyTodayGamesDate);
    if (savedDate != today) {
      prefs.setString(_keyTodayGamesDate, today);
      prefs.setInt(_keyTodayGames, 0);
    }
  }
}
