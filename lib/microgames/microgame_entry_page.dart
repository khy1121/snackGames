import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'swipe_brick_breaker_page.dart';

/// MicroGame Rush 진입 래퍼 - 이제는 벽돌 깨기로 바로 연결됩니다.
class MicroGameEntryPage extends StatefulWidget {
  const MicroGameEntryPage({super.key});

  @override
  State<MicroGameEntryPage> createState() => _MicroGameEntryPageState();
}

class _MicroGameEntryPageState extends State<MicroGameEntryPage> {
  @override
  Widget build(BuildContext context) {
    return const SwipeBrickBreakerPage();
  }
}

/// 튜토리얼 리셋 유틸리티 (설정에서 사용 - 현재는 안씀)
class MicroGameTutorialHelper {
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('microgame_tutorial_completed', false);
  }
  
  static Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('microgame_tutorial_completed') ?? false;
  }
}
