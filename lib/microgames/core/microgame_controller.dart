import 'dart:math';
import 'package:flutter/material.dart';
import 'microgame_base.dart';

/// 속도 업 이벤트 콜백
typedef SpeedUpCallback = void Function(MicroGameDifficulty newDifficulty);

/// 보스 스테이지 콜백
typedef BossStageCallback = void Function(int bossNumber);

/// 미니게임 컨트롤러 — WarioWare 스타일 게임 흐름 (4라이프, 보스, 속도업)
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
  int _lives = 4;             // WarioWare: 4 라이프
  int _lastScoreGain = 0;
  int _perfectCount = 0;
  int _bossesCleared = 0;     // 클리어한 보스 수
  
  // 속도 배율 (점진적으로 빨라짐, WarioWare 핵심 메카닉)
  double _speedMultiplier = 1.0;
  static const double _speedDecayPerRound = 0.012; // 라운드마다 1.2% 빨라짐
  static const double _minSpeedMultiplier = 0.55;   // 최소 55% (최대 속도)
  
  // 보스 스테이지 간격
  static const int _bossInterval = 10;
  
  // 이벤트 콜백
  SpeedUpCallback? onSpeedUp;
  BossStageCallback? onBossStage;

  // 게임 시작 시각 (속도 보너스 계산용)
  DateTime? _gameStartTime;

  final Random _random = Random();

  // 난이도 증가 설정
  MicroGameDifficulty _currentDifficulty = MicroGameDifficulty.easy;
  
  // 현재 보스 스테이지 여부
  bool _isCurrentBoss = false;

  MicroGameController();

  /// 게임 시작 시각 기록
  void markGameStart() {
    _gameStartTime = DateTime.now();
  }

  /// 게임 팩토리 등록
  void registerGame(MicroGame Function(MicroGameConfig, VoidCallback, VoidCallback, VoidCallback) factory) {
    _gameFactories.add(factory);
  }

  /// 보스 스테이지인지 확인
  bool get isCurrentBoss => _isCurrentBoss;
  
  /// 다음 라운드가 보스인지 미리 확인
  bool get isNextRoundBoss {
    final nextRound = _currentRound + 1;
    return nextRound > 0 && nextRound % _bossInterval == 0;
  }
  
  /// 현재 보스 번호 (1부터)
  int get currentBossNumber => (_currentRound ~/ _bossInterval) + 1;

  /// 랜덤 게임 선택 (연속 중복 방지, 보스/속도 배율 적용)
  MicroGame getRandomGame({
    required VoidCallback onSuccess,
    required VoidCallback onFailure,
    required VoidCallback onTimeout,
  }) {
    if (_gameFactories.isEmpty) {
      throw Exception('No games registered!');
    }

    // 보스 스테이지 체크
    _isCurrentBoss = _currentRound > 0 && _currentRound % _bossInterval == 0;

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
    final config = MicroGameConfig.fromDifficulty(
      _currentDifficulty,
      '빨리!',
      speedMultiplier: _speedMultiplier,
      isBoss: _isCurrentBoss,
    );

    markGameStart();
    return factory(config, onSuccess, onFailure, onTimeout);
  }

  /// 게임 성공 처리 (속도 보너스 + 콤보 보너스 + 보스 보너스)
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
      final timeLimitMs = MicroGameConfig.fromDifficulty(
        _currentDifficulty, '',
        speedMultiplier: _speedMultiplier,
      ).timeLimit.inMilliseconds;
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

    // 보스 클리어 보너스
    if (_isCurrentBoss) {
      baseScore += 300;
      _bossesCleared++;
      onBossStage?.call(_bossesCleared);
    }

    _lastScoreGain = baseScore;
    _score += baseScore;

    if (_comboCount > _maxCombo) {
      _maxCombo = _comboCount;
    }

    // 점진적 속도 증가 (매 라운드)
    _speedMultiplier = (_speedMultiplier - _speedDecayPerRound)
        .clamp(_minSpeedMultiplier, 1.0);

    // 난이도 증가 (5판마다) + SPEED UP 이벤트
    if (_currentRound % 5 == 0) {
      final oldDiff = _currentDifficulty;
      _increaseDifficulty();
      if (_currentDifficulty != oldDiff) {
        onSpeedUp?.call(_currentDifficulty);
      }
    }
  }

  /// 게임 실패 처리
  void recordFailure() {
    _failureCount++;
    _currentRound++;
    _comboCount = 0;
    _lives--;
    _lastScoreGain = 0;
    
    // 점진적 속도 증가는 실패해도 적용
    _speedMultiplier = (_speedMultiplier - _speedDecayPerRound * 0.5)
        .clamp(_minSpeedMultiplier, 1.0);
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
    _lives = 4;
    _lastScoreGain = 0;
    _perfectCount = 0;
    _bossesCleared = 0;
    _lastGameIndex = -1;
    _gameStartTime = null;
    _currentDifficulty = MicroGameDifficulty.easy;
    _speedMultiplier = 1.0;
    _isCurrentBoss = false;
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
  int get bossesCleared => _bossesCleared;
  double get speedMultiplier => _speedMultiplier;
  MicroGameDifficulty get currentDifficulty => _currentDifficulty;
}
