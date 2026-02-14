import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home/home_page.dart';
import 'services/game_data_service.dart';
import 'services/daily_mission_service.dart';
import 'services/achievement_service.dart';
import 'services/challenge_service.dart';
import 'services/settings_service.dart';
import 'services/background_music_service.dart';
import 'services/vibration_service.dart';
import 'services/leaderboard_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // SharedPreferences 한 번만 로드 후 공유
  final prefs = await SharedPreferences.getInstance();
  
  // 독립적인 서비스들을 병렬 초기화 (순차 → 병렬로 ~3x 빠름)
  await Future.wait([
    GameDataService.init(),
    DailyMissionService.init(prefs),
    AchievementService.init(prefs),
    ChallengeService.init(prefs),
    SettingsService.init(),
    VibrationService.init(prefs),
    LeaderboardService.init(),
  ]);
  
  // 배경음악은 Settings 이후 초기화 (의존성)
  await BackgroundMusicService().initialize();
  
  // SystemChrome.setPreferredOrientations removed for Web compatibility
  runApp(const DiceMergeMasterApp());
}

/// 스낵게임즈 - 기다림을 게임으로 바꾸다
/// 짧게, 가볍게, 계속하게
class DiceMergeMasterApp extends StatelessWidget {
  const DiceMergeMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: SettingsService.textScale,
      builder: (context, scale, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: MaterialApp(
            title: '스낵게임즈',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E5940), // Forest Green
                primary: const Color(0xFF2E5940),
                secondary: const Color(0xFF8DA399), // Sage Green
                surface: const Color(0xFFF7F5EC), // Warm Beige
                background: const Color(0xFFF7F5EC),
              ),
              scaffoldBackgroundColor: const Color(0xFFF7F5EC),
              useMaterial3: true,
              // fontFamily: 'Pretendard', // Removed to use system font fallback
            ),
            home: const HomePage(),
          ),
        );
      },
    );
  }
}
