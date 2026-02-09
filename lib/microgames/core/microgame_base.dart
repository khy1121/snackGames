import 'package:flutter/material.dart';

/// 미니게임 결과
enum MicroGameResult {
  success,
  failure,
  timeout,
}

/// 미니게임 난이도 (WarioWare 스타일: 빠른 템포)
enum MicroGameDifficulty {
  easy,    // 5초 (입문)
  medium,  // 4초 (보통)
  hard,    // 3초 (빠름)
  extreme, // 2.5초 (초고속)
}

/// 미니게임 설정
class MicroGameConfig {
  final MicroGameDifficulty difficulty;
  final Duration timeLimit;
  final String instruction;
  final double speedMultiplier; // 속도 배율 (낮을수록 빠름)
  final bool isBoss; // 보스 스테이지 여부
  
  const MicroGameConfig({
    required this.difficulty,
    required this.timeLimit,
    required this.instruction,
    this.speedMultiplier = 1.0,
    this.isBoss = false,
  });
  
  /// 난이도에 따른 기본 설정 (WarioWare 스타일 타이밍)
  factory MicroGameConfig.fromDifficulty(
    MicroGameDifficulty difficulty,
    String instruction, {
    double speedMultiplier = 1.0,
    bool isBoss = false,
  }) {
    int baseMs;
    switch (difficulty) {
      case MicroGameDifficulty.easy:
        baseMs = 5000;
        break;
      case MicroGameDifficulty.medium:
        baseMs = 4000;
        break;
      case MicroGameDifficulty.hard:
        baseMs = 3000;
        break;
      case MicroGameDifficulty.extreme:
        baseMs = 2500;
        break;
    }
    
    // 보스 스테이지는 시간 2배
    if (isBoss) baseMs = (baseMs * 2.5).toInt();
    
    // 속도 배율 적용 (점진적으로 빨라짐)
    final adjustedMs = (baseMs * speedMultiplier).toInt().clamp(1500, 15000);
    
    return MicroGameConfig(
      difficulty: difficulty,
      timeLimit: Duration(milliseconds: adjustedMs),
      instruction: instruction,
      speedMultiplier: speedMultiplier,
      isBoss: isBoss,
    );
  }

  /// 난이도 레벨 (0~3)
  int get difficultyLevel {
    switch (difficulty) {
      case MicroGameDifficulty.easy: return 0;
      case MicroGameDifficulty.medium: return 1;
      case MicroGameDifficulty.hard: return 2;
      case MicroGameDifficulty.extreme: return 3;
    }
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
  
  /// 게임 지시문 — WarioWare 스타일 한마디 명령 (예: "잡아!", "터뜨려!")
  String get instruction;
  
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
