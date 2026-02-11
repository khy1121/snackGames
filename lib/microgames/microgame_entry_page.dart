import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'microgame_rush_page.dart';
import 'microgame_tutorial_page.dart';

/// MicroGame Rush 진입 래퍼 - 첫 플레이 시 튜토리얼 표시
class MicroGameEntryPage extends StatefulWidget {
  const MicroGameEntryPage({super.key});

  @override
  State<MicroGameEntryPage> createState() => _MicroGameEntryPageState();
}

class _MicroGameEntryPageState extends State<MicroGameEntryPage> {
  bool _isLoading = true;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final tutorialCompleted = prefs.getBool('microgame_tutorial_completed') ?? false;
    
    if (mounted) {
      setState(() {
        _showTutorial = !tutorialCompleted;
        _isLoading = false;
      });
    }
  }

  void _onTutorialComplete() {
    setState(() {
      _showTutorial = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00B894)),
        ),
      );
    }

    if (_showTutorial) {
      return MicroGameTutorialPage(
        onComplete: _onTutorialComplete,
      );
    }

    return const MicroGameRushPage();
  }
}

/// 튜토리얼 리셋 유틸리티 (설정에서 사용)
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
