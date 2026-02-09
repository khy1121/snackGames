import 'dart:math';
import 'package:flutter/material.dart';
import 'microgame_base.dart';

/// 미니게임 컨트롤러 - 게임 흐름 제어 (개선: 보너스, 속도 보너스, 퍼펙트 판정)
class MicroGameController {
  // 사용 가능한 모든 미니게임 생성자 목록
  final List<MicroGame Function(MicroGameConfig config, VoidCallback onSuccess, VoidCallback onFailure, VoidCallback onTimeout)> _gameFactories = [];

  // 최근에 플레이한 게임 인덱스 (연속 같은 게임 방지)
  int _lastGameIndex = -1;

  // 현재 게임 정보
  int _currentRound = 0;
  int _successCount = 0;
  int _failureCount = 0;
  int _comboCount = 0;
  int _maxCombo = 0;
  int _score = 0;
  int _lives = 3;
  int _lastScoreGain = 0; // 마지막 획득 점수 (팝업용)
  int _perfectCount = 0; // 빠르게 클리어한 횟수
  
  // 게임 시작 시각 (속도 보너스 계산용)
  DateTime? _gameStartTime;

  final Random _random = Random();

  // 난이도 증가 설정
  MicroGameDifficulty _currentDifficulty = MicroGameDifficulty.easy;

  MicroGameController();

  /// 게임 시작 시각 기록
  void markGameStart() {
    _gameStartTime = DateTime.now();
  }

  /// 게임 팩토리 등록
  void registerGame(MicroGame Function(MicroGameConfig, VoidCallback, VoidCallback, VoidCallback) factory) {
    _gameFactories.add(factory);
  }

  /// 모든 게임 등록
  void registerAllGames(List<MicroGame Function(MicroGameConfig, VoidCallback, VoidCallback, VoidCallback)> factories) {
    _gameFactories.addAll(factories);
  }

  /// 랜덤 게임 선택 (연속 중복 방지)
  MicroGame getRandomGame({
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
    required VoidCallback onTimeout,
  }) {
    if (_gameFactories.isEmpty) {
      throw Exception('No games registered!');
    }

    int index;
    if (_gameFactories.length == 1) {
      index = 0;
    } else {
      do {
        index = _random.nextInt(_gameFactories.length);
      } while (index == _lastGameIndex);
    }
    _lastGameIndex = index;

    final factory = _gameFactories[index];
    final config = MicroGameConfig.fromDifficulty(_currentDifficulty, '빨리!');

    markGameStart();
    return factory(config, onSuccess, onFailure, onTimeout);
  }

  /// 게임 성공 처리 (속도 보너스 + 콤보 보너스)
  void recordSuccess() {
    _successCount++;
    _comboCount++;
    _currentRound++;

    // 기본 점수 100
    int baseScore = 100;

    // 콤보 보너스 (콤보 3마다 배율 +1)
    final comboMultiplier = 1 + _comboCount ~/ 3;
    baseScore *= comboMultiplier;

    // 속도 보너스: 제한시간의 50% 이내에 클리어하면 추가 점수
    if (_gameStartTime != null) {
      final elapsed = DateTime.now().difference(_gameStartTime!);
      final timeLimitMs = MicroGameConfig.fromDifficulty(_currentDifficulty, '').timeLimit.inMilliseconds;
      final ratio = elapsed.inMilliseconds / timeLimitMs;
      if (ratio < 0.3) {
        baseScore += 80; // 초고속 보너스
        _perfectCount++;
      } else if (ratio < 0.5) {
        baseScore += 40; // 속도 보너스
      }
    }

    // 난이도 보너스
    switch (_currentDifficulty) {
      case MicroGameDifficulty.easy:
        break;
      case MicroGameDifficulty.medium:
        baseScore += 20;
        break;
      case MicroGameDifficulty.hard:
        baseScore += 50;
        break;
      case MicroGameDifficulty.extreme:
        baseScore += 100;
        break;
    }

    _lastScoreGain = baseScore;
    _score += baseScore;

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
    _comboCount = 0;
    _lives--;
    _lastScoreGain = 0;
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
    _lastScoreGain = 0;
    _perfectCount = 0;
    _lastGameIndex = -1;
    _gameStartTime = null;
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
  int get lastScoreGain => _lastScoreGain;
  int get perfectCount => _perfectCount;
  MicroGameDifficulty get currentDifficulty => _currentDifficulty;
}
