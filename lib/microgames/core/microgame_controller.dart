import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'microgame_base.dart';

/// 미니게임 컨트롤러 - 게임 흐름 제어
class MicroGameController {
  // 사용 가능한 모든 미니게임 생성자 목록
  final List<MicroGame Function(MicroGameConfig config, VoidCallback onSuccess, VoidCallback onFailure, VoidCallback onTimeout)> _gameFactories = [];
  
  // 현재 게임 정보
  int _currentRound = 0;
  int _successCount = 0;
  int _failureCount = 0;
  int _comboCount = 0;
  int _maxCombo = 0;
  int _score = 0;
  int _lives = 3; // 체력
  
  final Random _random = Random();
  
  // 난이도 증가 설정
  MicroGameDifficulty _currentDifficulty = MicroGameDifficulty.easy;
  
  MicroGameController();
  
  /// 게임 팩토리 등록
  void registerGame(MicroGame Function(MicroGameConfig, VoidCallback, VoidCallback, VoidCallback) factory) {
    _gameFactories.add(factory);
  }
  
  /// 모든 게임 등록 (사용 예시)
  void registerAllGames(List<MicroGame Function(MicroGameConfig, VoidCallback, VoidCallback, VoidCallback)> factories) {
    _gameFactories.addAll(factories);
  }
  
  /// 랜덤 게임 선택
  MicroGame getRandomGame({
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
    required VoidCallback onTimeout,
  }) {
    if (_gameFactories.isEmpty) {
      throw Exception('No games registered!');
    }
    
    // 랜덤 게임 선택
    final factory = _gameFactories[_random.nextInt(_gameFactories.length)];
    
    // 현재 난이도로 설정 생성
    final config = MicroGameConfig.fromDifficulty(_currentDifficulty, '빨리!');
    
    return factory(config, onSuccess, onFailure, onTimeout);
  }
  
  /// 게임 성공 처리
  void recordSuccess() {
    _successCount++;
    _comboCount++;
    _currentRound++;
    
    // 콤보 점수 계산
    _score += 100 * (1 + _comboCount ~/ 3);
    
    if (_comboCount > _maxCombo) {
      _maxCombo = _comboCount;
    }
    
    // 난이도 증가 (5판마다)
    if (_currentRound % 5 == 0) {
      _increaseDifficulty();
    }
  }
  
  /// 게임 실패 처리
  void recordFailure() {
    _failureCount++;
    _currentRound++;
    _comboCount = 0; // 콤보 초기화
    _lives--; // 체력 감소
  }
  
  /// 게임 오버 확인
  bool get isGameOver => _lives <= 0;
  
  /// 난이도 증가
  void _increaseDifficulty() {
    switch (_currentDifficulty) {
      case MicroGameDifficulty.easy:
        _currentDifficulty = MicroGameDifficulty.medium;
        break;
      case MicroGameDifficulty.medium:
        _currentDifficulty = MicroGameDifficulty.hard;
        break;
      case MicroGameDifficulty.hard:
        _currentDifficulty = MicroGameDifficulty.extreme;
        break;
      case MicroGameDifficulty.extreme:
        // 최대 난이도 유지
        break;
    }
  }
  
  /// 게임 리셋
  void reset() {
    _currentRound = 0;
    _successCount = 0;
    _failureCount = 0;
    _comboCount = 0;
    _maxCombo = 0;
    _score = 0;
    _lives = 3;
    _currentDifficulty = MicroGameDifficulty.easy;
  }
  
  // Getters
  int get currentRound => _currentRound;
  int get successCount => _successCount;
  int get failureCount => _failureCount;
  int get comboCount => _comboCount;
  int get maxCombo => _maxCombo;
  int get score => _score;
  int get lives => _lives;
  MicroGameDifficulty get currentDifficulty => _currentDifficulty;
}
