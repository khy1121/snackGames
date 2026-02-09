import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/microgame_base.dart';
import 'core/microgame_controller.dart';
import 'core/microgame_theme.dart';
import 'core/microgame_effects.dart';
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
  intro,
  countdown,
  transition, // 게임 전환 애니메이션 (NEW)
  playing,
  result,
  gameOver,
}

class _MicroGameRushPageState extends State<MicroGameRushPage>
    with TickerProviderStateMixin {
  final MicroGameController _controller = MicroGameController();
  GameState _gameState = GameState.intro;
  MicroGame? _currentGame;
  int _countdown = 3;
  Timer? _timer;

  // 이펙트 상태
  bool _showConfetti = false;
  bool _triggerShake = false;
  bool _showScorePopup = false;

  // 게임 내 타이머 바
  Timer? _timerBarTimer;
  double _timerProgress = 1.0;

  // 인트로 애니메이션
  late final AnimationController _introAnimController;
  late final Animation<double> _introFadeIn;
  late final Animation<double> _introBounce;

  @override
  void initState() {
    super.initState();
    _registerGames();

    _introAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _introFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introAnimController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _introBounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _introAnimController,
      curve: Curves.easeOut,
    ));
    _introAnimController.forward();
  }

  void _registerGames() {
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
      _showConfetti = false;
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
        _showTransitionThenGame();
      }
    });
  }

  /// 게임 전환 애니메이션 후 게임 시작
  void _showTransitionThenGame() {
    final game = _controller.getRandomGame(
      onSuccess: _onGameSuccess,
      onFailure: _onGameFailure,
      onTimeout: _onGameTimeout,
    );

    setState(() {
      _currentGame = game;
      _gameState = GameState.transition;
    });

    // 전환 애니메이션 후 플레이 시작 (1초)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _startPlaying();
      }
    });
  }

  void _startPlaying() {
    setState(() {
      _gameState = GameState.playing;
      _timerProgress = 1.0;
    });
    _startTimerBar();
  }

  /// 타이머 바 업데이트
  void _startTimerBar() {
    _timerBarTimer?.cancel();
    final totalMs = _currentGame?.config.timeLimit.inMilliseconds ?? 10000;
    const tickMs = 50;
    _timerBarTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (!mounted || _gameState != GameState.playing) {
        timer.cancel();
        return;
      }
      setState(() {
        _timerProgress -= tickMs / totalMs;
        if (_timerProgress < 0) _timerProgress = 0;
      });
    });
  }

  void _onGameSuccess() {
    _timerBarTimer?.cancel();
    VibrationService.medium();
    _controller.recordSuccess();
    setState(() {
      _showConfetti = true;
      _showScorePopup = true;
    });
    _showResult(MicroGameResult.success);
  }

  void _onGameFailure() {
    _timerBarTimer?.cancel();
    VibrationService.heavy();
    _controller.recordFailure();
    setState(() {
      _triggerShake = true;
      _showScorePopup = false;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _triggerShake = false);
    });
    _showResult(MicroGameResult.failure);
  }

  void _onGameTimeout() {
    _timerBarTimer?.cancel();
    VibrationService.heavy();
    _controller.recordFailure();
    setState(() {
      _triggerShake = true;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _triggerShake = false);
    });
    _showResult(MicroGameResult.timeout);
  }

  void _showResult(MicroGameResult result) {
    setState(() {
      _gameState = GameState.result;
    });

    if (_controller.isGameOver) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _showGameOver();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _showConfetti = false;
            _showScorePopup = false;
          });
          _showTransitionThenGame();
        }
      });
    }
  }

  void _showGameOver() {
    GameDataService.setMicroGameRushScore(_controller.score);
    GameDataService.incrementGamesPlayed('microgame_rush');

    setState(() {
      _gameState = GameState.gameOver;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerBarTimer?.cancel();
    _introAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScreenShake(
          trigger: _triggerShake,
          intensity: 10.0,
          child: Stack(
            children: [
              // 게임 화면
              _buildGameScreen(),

              // 상단 HUD
              if (_gameState == GameState.playing) _buildHUD(),

              // 타이머 바 (게임중에만)
              if (_gameState == GameState.playing)
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: MicroGameWidgets.buildTimerBar(_timerProgress),
                ),

              // 점수 팝업
              if (_showScorePopup && _controller.lastScoreGain > 0)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.35,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ScorePopup(
                      key: ValueKey(_controller.currentRound),
                      score: _controller.lastScoreGain,
                      isCombo: _controller.comboCount > 1,
                      comboCount: _controller.comboCount,
                    ),
                  ),
                ),

              // 컨페티 이펙트
              ConfettiEffect(trigger: _showConfetti),

              // 뒤로가기 버튼
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
      ),
    );
  }

  Widget _buildGameScreen() {
    switch (_gameState) {
      case GameState.intro:
        return _buildIntro();
      case GameState.countdown:
        return _buildCountdown();
      case GameState.transition:
        return _buildTransition();
      case GameState.playing:
        return _currentGame ?? const SizedBox.shrink();
      case GameState.result:
        return Stack(
          children: [
            _currentGame ?? const SizedBox.shrink(),
          ],
        );
      case GameState.gameOver:
        return _buildGameOver();
    }
  }

  Widget _buildTransition() {
    final game = _currentGame;
    if (game == null) return const SizedBox.shrink();

    return GameTransition(
      key: ValueKey(_controller.currentRound),
      gameEmoji: game.emoji,
      gameTitle: game.title,
      child: game,
    );
  }

  Widget _buildIntro() {
    return Container(
      decoration: const BoxDecoration(
        gradient: MicroGameTheme.backgroundGradient,
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _introAnimController,
          builder: (context, child) {
            return Opacity(
              opacity: _introFadeIn.value,
              child: Transform.scale(
                scale: _introBounce.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PulseGlow(
                glowColor: Color(0xFFFFE66D),
                maxRadius: 30,
                child: Text('⚡', style: TextStyle(fontSize: 100)),
              ),
              const SizedBox(height: 20),
              const Text(
                '미니게임 러시!',
                style: MicroGameTheme.titleStyle,
              ),
              const SizedBox(height: 12),
              const Text(
                '초단위 미션을 빠르게 클리어하세요!\n콤보와 속도 보너스로 고득점을 노려보세요 🔥',
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              _buildStartButton(),
              const SizedBox(height: 24),
              // 최고 기록 표시
              Builder(
                builder: (context) {
                  final best = GameDataService.getBestScore('microgame_rush');
                  if (best <= 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          '최고 기록: $best',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: const Color(0x33FF9800),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.05),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: MicroGameTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 12,
          shadowColor: const Color(0x60000000),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, size: 32),
            SizedBox(width: 8),
            Text(
              '시작하기',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_countdown),
          tween: Tween<double>(begin: 0.3, end: 1.2),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Text(
                  _countdown > 0 ? '$_countdown' : '시작!',
                  style: MicroGameTheme.countdownStyle,
                ),
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
      child: RepaintBoundary(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC000000),
                Color(0x00000000),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 체력 (하트 + 흔들림 효과)
              Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedScale(
                      scale: index < _controller.lives ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        index < _controller.lives ? '❤️' : '🖤',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ),

              // 점수 + 라운드
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_controller.score}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: MicroGameTheme.black54,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'ROUND ${_controller.currentRound + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: MicroGameTheme.white70,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),

              // 콤보 + 난이도
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ComboFireEffect(comboCount: _controller.comboCount),
                  const SizedBox(height: 4),
                  DifficultyBadge(
                    label: MicroGameTheme.difficultyLabel(_controller.currentDifficulty),
                    color: MicroGameTheme.difficultyColor(_controller.currentDifficulty),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOver() {
    final bestScore = GameDataService.getBestScore('microgame_rush');
    final isNewRecord = _controller.score >= bestScore && _controller.score > 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: MicroGameTheme.backgroundGradient,
      ),
      child: Stack(
        children: [
          // 신기록이면 컨페티
          if (isNewRecord) const ConfettiEffect(trigger: true, particleCount: 50),

          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isNewRecord ? '🎉 신기록! 🎉' : '게임 오버!',
                    style: MicroGameTheme.titleStyle.copyWith(
                      fontSize: isNewRecord ? 36 : 32,
                      color: isNewRecord ? const Color(0xFFFFD700) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 큰 점수 표시
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _controller.score.toDouble()),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOut,
                    builder: (context, value, _) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: MicroGameTheme.black38,
                                offset: Offset(3, 3), blurRadius: 8),
                          ],
                        ),
                      );
                    },
                  ),
                  const Text(
                    'SCORE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MicroGameTheme.white70,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 통계 카드
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MicroGameTheme.white24, width: 1),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow('✅ 성공', '${_controller.successCount}'),
                        _buildStatRow('❌ 실패', '${_controller.failureCount}'),
                        _buildStatRow('🔥 최대 콤보', '×${_controller.maxCombo}'),
                        _buildStatRow('⚡ 퍼펙트', '${_controller.perfectCount}'),
                        _buildStatRow('📊 라운드', '${_controller.currentRound}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 다시 도전 버튼
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '다시 도전',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, color: MicroGameTheme.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
