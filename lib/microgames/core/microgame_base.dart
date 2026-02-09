import 'package:flutter/material.dart';

/// 미니게임 결과
enum MicroGameResult {
  success,
  failure,
  timeout,
}

/// 미니게임 난이도
enum MicroGameDifficulty {
  easy,   // 10초
  medium, // 7초
  hard,   // 5초
  extreme, // 3초
}

/// 미니게임 설정
class MicroGameConfig {
  final MicroGameDifficulty difficulty;
  final Duration timeLimit;
  final String instruction; // "터치하세요!", "기울이세요!" 등
  
  const MicroGameConfig({
    required this.difficulty,
    required this.timeLimit,
    required this.instruction,
  });
  
  /// 난이도에 따른 기본 설정
  factory MicroGameConfig.fromDifficulty(MicroGameDifficulty difficulty, String instruction) {
    Duration timeLimit;
    switch (difficulty) {
      case MicroGameDifficulty.easy:
        timeLimit = const Duration(seconds: 10);
        break;
      case MicroGameDifficulty.medium:
        timeLimit = const Duration(seconds: 7);
        break;
      case MicroGameDifficulty.hard:
        timeLimit = const Duration(seconds: 5);
        break;
      case MicroGameDifficulty.extreme:
        timeLimit = const Duration(seconds: 3);
        break;
    }
    
    return MicroGameConfig(
      difficulty: difficulty,
      timeLimit: timeLimit,
      instruction: instruction,
    );
  }
}

/// 미니게임 추상 베이스 클래스
abstract class MicroGame extends StatefulWidget {
  final MicroGameConfig config;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;
  final VoidCallback onTimeout;
  
  const MicroGame({
    super.key,
    required this.config,
    required this.onSuccess,
    required this.onFailure,
    required this.onTimeout,
  });
  
  /// 게임 제목 (예: "날아오는 파리!")
  String get title;
  
  /// 게임 설명 (예: "파리를 잡아라!")
  String get description;
  
  /// 게임 아이콘 이모지
  String get emoji;
}

/// 미니게임 상태 베이스 클래스
abstract class MicroGameState<T extends MicroGame> extends State<T> {
  bool _isCompleted = false;
  
  /// 게임 성공 처리
  void markSuccess() {
    if (_isCompleted) return;
    _isCompleted = true;
    widget.onSuccess();
  }
  
  /// 게임 실패 처리
  void markFailure() {
    if (_isCompleted) return;
    _isCompleted = true;
    widget.onFailure();
  }
  
  /// 시간 초과 처리
  void markTimeout() {
    if (_isCompleted) return;
    _isCompleted = true;
    widget.onTimeout();
  }
  
  /// 게임이 완료되었는지 확인
  bool get isCompleted => _isCompleted;
}
