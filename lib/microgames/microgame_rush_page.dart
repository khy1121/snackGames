import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/microgame_base.dart';
import 'core/microgame_controller.dart';
import 'core/microgame_theme.dart';
import 'games/fly_catcher_game.dart';
import 'games/balloon_pop_game.dart';
import 'games/bubble_wrap_game.dart';
import 'games/traffic_light_game.dart';
import 'games/door_knock_game.dart';
import 'games/coffee_pour_game.dart';
import 'games/ball_roll_game.dart';
import 'games/dice_shake_game.dart';
import '../services/game_data_service.dart';
import '../services/vibration_service.dart';

/// 미니게임 러시 메인 페이지
class MicroGameRushPage extends StatefulWidget {
  const MicroGameRushPage({super.key});

  @override
  State<MicroGameRushPage> createState() => _MicroGameRushPageState();
}

enum GameState {
  intro,      // 시작 화면
  countdown,  // 3-2-1 카운트다운
  playing,    // 게임 플레이 중
  result,     // 게임 결과 (성공/실패)
  gameOver,   // 전체 게임 오버
}

class _MicroGameRushPageState extends State<MicroGameRushPage> {
  final MicroGameController _controller = MicroGameController();
  GameState _gameState = GameState.intro;
  MicroGame? _currentGame;
  int _countdown = 3;
  MicroGameResult? _lastResult;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _registerGames();
  }

  /// 모든 게임 등록
  void _registerGames() {
    // 터치 게임
    _controller.registerGame((config, onSuccess, onFailure, onTimeout) =>
        FlyCatcherGame(
            config: config,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onTimeout: onTimeout));

    _controller.registerGame((config, onSuccess, onFailure, onTimeout) =>
        BalloonPopGame(
            config: config,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onTimeout: onTimeout));

    _controller.registerGame((config, onSuccess, onFailure, onTimeout) =>
        BubbleWrapGame(
            config: config,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onTimeout: onTimeout));

    _controller.registerGame((config, onSuccess, onFailure, onTimeout) =>
        TrafficLightGame(
            config: config,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onTimeout: onTimeout));

    _controller.registerGame((config, onSuccess, onFailure, onTimeout) =>
        DoorKnockGame(
            config: config,
            onSuccess: onSuccess,
            onFailure: onFailure,
            onTimeout: onTimeout));

    // 센서 게임 (모바일에서만)
    if (!kIsWeb) {
      _controller.registerGame((config, onSuccess, onFailure, onTimeout) =>
          CoffeePourGame(
              config: config,
              onSuccess: onSuccess,
              onFailure: onFailure,
              onTimeout: onTimeout));

      _controller.registerGame((config, onSuccess, onFailure, onTimeout) =>
          BallRollGame(
              config: config,
              onSuccess: onSuccess,
              onFailure: onFailure,
              onTimeout: onTimeout));

      _controller.registerGame((config, onSuccess, onFailure, onTimeout) =>
          DiceShakeGame(
              config: config,
              onSuccess: onSuccess,
              onFailure: onFailure,
              onTimeout: onTimeout));
    }
  }

  void _startGame() {
    _controller.reset();
    setState(() {
      _gameState = GameState.countdown;
      _countdown = 3;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        _startNextGame();
      }
    });
  }

  void _startNextGame() {
    setState(() {
      _currentGame = _controller.getRandomGame(
        onSuccess: _onGameSuccess,
        onFailure: _onGameFailure,
        onTimeout: _onGameTimeout,
      );
      _gameState = GameState.playing;
    });
  }

  void _onGameSuccess() {
    VibrationService.medium();
    _controller.recordSuccess();
    _showResult(MicroGameResult.success);
  }

  void _onGameFailure() {
    VibrationService.heavy();
    _controller.recordFailure();
    _showResult(MicroGameResult.failure);
  }

  void _onGameTimeout() {
    VibrationService.heavy();
    _controller.recordFailure();
    _showResult(MicroGameResult.timeout);
  }

  void _showResult(MicroGameResult result) {
    setState(() {
      _lastResult = result;
      _gameState = GameState.result;
    });

    // 게임 오버 체크
    if (_controller.isGameOver) {
      Future.delayed(const Duration(seconds: 2), () {
        _showGameOver();
      });
    } else {
      // 다음 게임으로
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _startNextGame();
        }
      });
    }
  }

  void _showGameOver() {
    // 점수 저장
    GameDataService.setMicroGameRushScore(_controller.score);
    GameDataService.incrementGamesPlayed('microgame_rush');

    setState(() {
      _gameState = GameState.gameOver;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 게임 화면
            _buildGameScreen(),

            // 상단 HUD
            if (_gameState == GameState.playing) _buildHUD(),

            // 뒤로가기 버튼 (인트로/게임오버에만)
            if (_gameState == GameState.intro || _gameState == GameState.gameOver)
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    switch (_gameState) {
      case GameState.intro:
        return _buildIntro();
      case GameState.countdown:
        return _buildCountdown();
      case GameState.playing:
        return _currentGame ?? const SizedBox.shrink();
      case GameState.result:
        return Stack(
          children: [
            _currentGame ?? const SizedBox.shrink(),
            // 결과 오버레이는 게임 내부에서 표시됨
          ],
        );
      case GameState.gameOver:
        return _buildGameOver();
    }
  }

  Widget _buildIntro() {
    return Container(
      decoration: const BoxDecoration(
        gradient: MicroGameTheme.backgroundGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '⚡',
              style: TextStyle(fontSize: 100),
            ),
            const SizedBox(height: 20),
            const Text(
              '미니게임 러시!',
              style: MicroGameTheme.titleStyle,
            ),
            const SizedBox(height: 12),
            const Text(
              '초단위 미션을 빠르게 클리어하세요!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: MicroGameTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
              child: const Text(
                '시작하기',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: const Text(
                  '💡 센서 게임은 모바일 앱에서만 플레이할 수 있습니다',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      decoration: const BoxDecoration(
        gradient: MicroGameTheme.backgroundGradient,
      ),
      child: Center(
        child: TweenAnimationBuilder(
          key: ValueKey(_countdown),
          tween: Tween<double>(begin: 0.5, end: 1.2),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Text(
                _countdown > 0 ? '$_countdown' : '시작!',
                style: MicroGameTheme.countdownStyle,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHUD() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 체력
            Row(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    index < _controller.lives ? '❤️' : '🖤',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),

            // 점수
            Text(
              '${_controller.score}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),

            // 콤보
            if (_controller.comboCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '×${_controller.comboCount}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final bestScore = GameDataService.getBestScore('microgame_rush');

    return Container(
      decoration: const BoxDecoration(
        gradient: MicroGameTheme.backgroundGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '게임 오버!',
              style: MicroGameTheme.titleStyle,
            ),
            const SizedBox(height: 40),
            _buildStatRow('점수', '${_controller.score}'),
            _buildStatRow('성공', '${_controller.successCount}'),
            _buildStatRow('실패', '${_controller.failureCount}'),
            _buildStatRow('최대 콤보', '×${_controller.maxCombo}'),
            if (_controller.score > bestScore)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  '🎉 신기록! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
              ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: MicroGameTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                '다시 도전',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '홈으로',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 100,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
