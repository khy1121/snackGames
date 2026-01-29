import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const SnackGamesApp());
}

/// 스낵게임즈 - 기다림을 게임으로 바꾸다
/// 짧게, 가볍게, 계속하게
class SnackGamesApp extends StatelessWidget {
  const SnackGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
