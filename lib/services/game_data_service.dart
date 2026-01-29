import 'package:shared_preferences/shared_preferences.dart';

/// 게임 데이터 서비스 - 점수 및 플레이 기록 관리
class GameDataService {
  static const String _keyBestScore = 'best_score_';
  static const String _keyTodayScore = 'today_score_';
  static const String _keyTodayDate = 'today_date';
  static const String _keyLastPlayed = 'last_played';
  static const String _keyTotalPlayTime = 'total_play_time';
  static const String _keyPoints = 'user_points';
  static const String _keyAdRemoved = 'ad_removed';
  static const String _keyOwnedThemes = 'owned_themes';
  static const String _keySelectedTheme = 'selected_theme';
  static const String _keyTotalGamesPlayed = 'total_games_played';

  static SharedPreferences? _prefs;

  // ... (previous static logic) ...

  // ========== 재화 및 상점 (Monetization) ==========

  /// 현재 보유 포인트
  static int getPoints() {
    return prefs.getInt(_keyPoints) ?? 0;
  }

  /// 포인트 추가/차감
  static Future<void> addPoints(int amount) async {
    final current = getPoints();
    await prefs.setInt(_keyPoints, current + amount);
  }

  /// 광고 제거 여부
  static bool isAdRemoved() {
    return prefs.getBool(_keyAdRemoved) ?? false;
  }

  /// 광고 제거 구매 처리
  static Future<void> removeAds() async {
    await prefs.setBool(_keyAdRemoved, true);
  }

  /// 보유 테마 목록 (ID 리스트)
  static List<String> getOwnedThemes() {
    return prefs.getStringList(_keyOwnedThemes) ?? ['cyberpunk']; // Default
  }

  /// 테마 구매/획득
  static Future<void> addTheme(String themeId) async {
    final themes = getOwnedThemes();
    if (!themes.contains(themeId)) {
      themes.add(themeId);
      await prefs.setStringList(_keyOwnedThemes, themes);
    }
  }

  /// 현재 적용된 테마
  static String getSelectedTheme() {
    return prefs.getString(_keySelectedTheme) ?? 'cyberpunk';
  }

  /// 테마 변경
  static Future<void> setTheme(String themeId) async {
    await prefs.setString(_keySelectedTheme, themeId);
  }
  // ... methods continuing ...

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _checkAndResetDailyScores();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('GameDataService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// 오늘 날짜 체크 및 일일 점수 리셋
  static void _checkAndResetDailyScores() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString(_keyTodayDate);

    if (savedDate != today) {
      // 새로운 날 - 일일 점수 리셋
      prefs.setString(_keyTodayDate, today);
      for (final gameId in ['2048', 'dice']) {
        prefs.remove('$_keyTodayScore$gameId');
      }
    }
  }

  // ========== 점수 관리 ==========

  /// 최고 점수 가져오기
  static int getBestScore(String gameId) {
    return prefs.getInt('$_keyBestScore$gameId') ?? 0;
  }

  /// 최고 점수 저장
  static Future<void> setBestScore(String gameId, int score) async {
    final current = getBestScore(gameId);
    if (score > current) {
      await prefs.setInt('$_keyBestScore$gameId', score);
    }
  }

  /// 오늘 점수 가져오기
  static int getTodayScore(String gameId) {
    _checkAndResetDailyScores();
    return prefs.getInt('$_keyTodayScore$gameId') ?? 0;
  }

  /// 오늘 점수 저장 (최고 기록만)
  static Future<void> setTodayScore(String gameId, int score) async {
    _checkAndResetDailyScores();
    final current = getTodayScore(gameId);
    if (score > current) {
      await prefs.setInt('$_keyTodayScore$gameId', score);
    }
  }

  /// 게임 점수 기록 (최고 점수 + 오늘 점수 동시 업데이트)
  static Future<void> recordScore(String gameId, int score) async {
    await setBestScore(gameId, score);
    await setTodayScore(gameId, score);
    await incrementGamesPlayed();
  }

  // ========== 플레이 기록 ==========

  /// 마지막 플레이한 게임 가져오기
  static String? getLastPlayedGame() {
    return prefs.getString(_keyLastPlayed);
  }

  /// 마지막 플레이한 게임 저장
  static Future<void> setLastPlayedGame(String gameId) async {
    await prefs.setString(_keyLastPlayed, gameId);
  }

  /// 총 플레이 시간 (분)
  static int getTotalPlayTime() {
    return prefs.getInt(_keyTotalPlayTime) ?? 0;
  }

  /// 플레이 시간 추가
  static Future<void> addPlayTime(int minutes) async {
    final current = getTotalPlayTime();
    await prefs.setInt(_keyTotalPlayTime, current + minutes);
  }

  /// 총 게임 플레이 횟수
  static int getTotalGamesPlayed() {
    return prefs.getInt(_keyTotalGamesPlayed) ?? 0;
  }

  /// 게임 플레이 횟수 증가
  static Future<void> incrementGamesPlayed() async {
    final current = getTotalGamesPlayed();
    await prefs.setInt(_keyTotalGamesPlayed, current + 1);
  }

  // ========== 게임 정보 ==========

  static String getGameName(String gameId) {
    switch (gameId) {
      case '2048':
        return '2048';
      case 'dice':
        return 'Dice Merge';

      default:
        return gameId;
    }
  }

  static String getGameIcon(String gameId) {
    switch (gameId) {
      case '2048':
        return '🔢';
      case 'dice':
        return '🎲';

      default:
        return '🎮';
    }
  }
}
