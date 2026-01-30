import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home/home_page.dart';
import 'services/game_data_service.dart';
import 'services/daily_mission_service.dart';
import 'services/achievement_service.dart';
import 'services/challenge_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 서비스 초기화
  final prefs = await SharedPreferences.getInstance();
  await GameDataService.init();
  await DailyMissionService.init(prefs);
  await AchievementService.init(prefs);
  await ChallengeService.init(prefs);
  await SettingsService.init();
  
  // SystemChrome.setPreferredOrientations removed for Web compatibility
  runApp(const SnackGamesApp());
}

/// 스낵게임즈 - 기다림을 게임으로 바꾸다
/// 짧게, 가볍게, 계속하게
class SnackGamesApp extends StatelessWidget {
  const SnackGamesApp({super.key});

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
                seedColor: const Color(0xFF6C5CE7),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),
            home: const HomePage(),
          ),
        );
      },
    );
  }
}
