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
import 'games/color_match_game.dart';
import 'games/countdown_tap_game.dart';
import 'games/odd_one_out_game.dart';
import 'games/dont_touch_game.dart';
import '../services/game_data_service.dart';
import '../services/vibration_service.dart';

/// 미니게임 러시 — WarioWare: Touched! 오마주
class MicroGameRushPage extends StatefulWidget {
  const MicroGameRushPage({super.key});

  @override
  State<MicroGameRushPage> createState() => _MicroGameRushPageState();
}

enum GameState {
  intro,
  countdown,
  speedUp,      // "SPEED UP!" 연출
  transition,   // 게임 전환 (WarioWare 스타일 지시문)
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
  bool _triggerSuccessFlash = false;
  bool _triggerFailFlash = false;

  // 게임 내 타이머 바
  Timer? _timerBarTimer;
  double _timerProgress = 1.0;

  // 인트로 애니메이션
  late final AnimationController _introAnimController;
  late final Animation<double> _introFadeIn;
  late final Animation<double> _introBounce;

  // 결과 표시용
  MicroGameResult? _lastResult;
  
  // SPEED UP 표시 예약
  bool _pendingSpeedUp = false;

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
    // 터치 게임 (웹+모바일 — 9개)
    _controller.registerGame((config, s, f, t) =>
        FlyCatcherGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
    _controller.registerGame((config, s, f, t) =>
        BalloonPopGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
    _controller.registerGame((config, s, f, t) =>
        BubbleWrapGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
    _controller.registerGame((config, s, f, t) =>
        TrafficLightGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
    _controller.registerGame((config, s, f, t) =>
        DoorKnockGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
    _controller.registerGame((config, s, f, t) =>
        ColorMatchGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
    _controller.registerGame((config, s, f, t) =>
        CountdownTapGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
    _controller.registerGame((config, s, f, t) =>
        OddOneOutGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
    _controller.registerGame((config, s, f, t) =>
        DontTouchGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));

    // 센서 게임 (모바일만 — 3개)
    if (!kIsWeb) {
      _controller.registerGame((config, s, f, t) =>
          CoffeePourGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
      _controller.registerGame((config, s, f, t) =>
          BallRollGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
      _controller.registerGame((config, s, f, t) =>
          DiceShakeGame(config: config, onSuccess: s, onFailure: f, onTimeout: t));
    }
  }

  void _startGame() {
    _controller.reset();
    setState(() {
      _gameState = GameState.countdown;
      _countdown = 3;
      _showConfetti = false;
      _lastResult = null;
      _pendingSpeedUp = false;
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

  /// SPEED UP! 화면 → 다음 게임
  void _showSpeedUpThenGame() {
    setState(() {
      _gameState = GameState.speedUp;
      _pendingSpeedUp = false;
    });
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) _showTransitionThenGame();
    });
  }

  /// WarioWare 스타일 게임 전환 (지시문 → 게임)
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

    // 보스=1.8초, 일반=0.7초  (WarioWare 스냅 전환)
    final ms = _controller.isCurrentBoss ? 1800 : 700;
    Future.delayed(Duration(milliseconds: ms), () {
      if (mounted) _startPlaying();
    });
  }

  void _startPlaying() {
    setState(() {
      _gameState = GameState.playing;
      _timerProgress = 1.0;
    });
    _startTimerBar();
  }

  void _startTimerBar() {
    _timerBarTimer?.cancel();
    final totalMs = _currentGame?.config.timeLimit.inMilliseconds ?? 5000;
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

    final oldDiff = _controller.currentDifficulty;
    _controller.recordSuccess();
    final diffChanged = _controller.currentDifficulty != oldDiff;

    setState(() {
      _lastResult = MicroGameResult.success;
      _showConfetti = true;
      _showScorePopup = true;
      _triggerSuccessFlash = true;
      _pendingSpeedUp = diffChanged;
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _triggerSuccessFlash = false);
      }
    });
    _showResult(MicroGameResult.success);
  }

  void _onGameFailure() {
    _timerBarTimer?.cancel();
    VibrationService.heavy();
    _controller.recordFailure();
    setState(() {
      _lastResult = MicroGameResult.failure;
      _triggerShake = true;
      _triggerFailFlash = true;
      _showScorePopup = false;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _triggerShake = false;
          _triggerFailFlash = false;
        });
      }
    });
    _showResult(MicroGameResult.failure);
  }

  void _onGameTimeout() {
    _timerBarTimer?.cancel();
    VibrationService.heavy();
    _controller.recordFailure();
    setState(() {
      _lastResult = MicroGameResult.timeout;
      _triggerShake = true;
      _triggerFailFlash = true;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _triggerShake = false;
          _triggerFailFlash = false;
        });
      }
    });
    _showResult(MicroGameResult.timeout);
  }

  void _showResult(MicroGameResult result) {
    setState(() => _gameState = GameState.result);

    if (_controller.isGameOver) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _showGameOver();
      });
    } else {
      // WarioWare 템포: 결과 800ms
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _showConfetti = false;
            _showScorePopup = false;
          });
          if (_pendingSpeedUp) {
            _showSpeedUpThenGame();
          } else {
            _showTransitionThenGame();
          }
        }
      });
    }
  }

  void _showGameOver() {
    GameDataService.setMicroGameRushScore(_controller.score);
    GameDataService.incrementGamesPlayed('microgame_rush');
    setState(() => _gameState = GameState.gameOver);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerBarTimer?.cancel();
    _introAnimController.dispose();
    super.dispose();
  }

  // ───── BUILD ─────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ScreenShake(
          trigger: _triggerShake,
          intensity: 12.0,
          child: Stack(
            children: [
              _buildGameScreen(),

              // HUD
              if (_gameState == GameState.playing) _buildHUD(),

              // 타이머 바
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

              // 컨페티
              ConfettiEffect(trigger: _showConfetti),

              // 화면 플래시
              Positioned.fill(
                child: ScreenFlash(trigger: _triggerSuccessFlash, color: const Color(0xFF00FF00)),
              ),
              Positioned.fill(
                child: ScreenFlash(trigger: _triggerFailFlash, color: const Color(0xFFFF0000)),
              ),

              // 뒤로가기
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
      case GameState.speedUp:
        return _buildSpeedUp();
      case GameState.transition:
        return _buildTransition();
      case GameState.playing:
        return _currentGame ?? const SizedBox.shrink();
      case GameState.result:
        return Stack(
          children: [
            _currentGame ?? const SizedBox.shrink(),
            _buildResultOverlay(),
          ],
        );
      case GameState.gameOver:
        return _buildGameOver();
    }
  }

  // ───── SUB WIDGETS ─────

  Widget _buildResultOverlay() {
    if (_lastResult == null) return const SizedBox.shrink();
    final isSuccess = _lastResult == MicroGameResult.success;
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                gradient: isSuccess ? MicroGameTheme.successGradient : MicroGameTheme.failureGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isSuccess ? MicroGameTheme.successHalf : MicroGameTheme.failureHalf,
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                isSuccess ? '👍' : _lastResult == MicroGameResult.timeout ? '⏰' : '💥',
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedUp() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF0000), Color(0xFF990000)],
        ),
      ),
      child: Center(
        child: SpeedUpAnnounce(key: ValueKey(_controller.currentDifficulty)),
      ),
    );
  }

  Widget _buildTransition() {
    final game = _currentGame;
    if (game == null) return const SizedBox.shrink();
    return WarioTransition(
      key: ValueKey(_controller.currentRound),
      gameEmoji: game.emoji,
      instruction: game.instruction,
      isBoss: _controller.isCurrentBoss,
      bossNumber: _controller.currentBossNumber,
      child: game,
    );
  }

  Widget _buildIntro() {
    return Container(
      decoration: const BoxDecoration(gradient: MicroGameTheme.backgroundGradient),
      child: Center(
        child: AnimatedBuilder(
          animation: _introAnimController,
          builder: (context, child) {
            return Opacity(
              opacity: _introFadeIn.value,
              child: Transform.scale(scale: _introBounce.value, child: child),
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
              const Text('마이크로 러시!', style: MicroGameTheme.titleStyle),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x33000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'WarioWare Style',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: Color(0xCCFFFFFF), letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '초고속 미니게임을 연속 클리어!\n❤️×4 · 콤보 보너스 · BOSS 스테이지',
                  style: TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              _buildStartButton(),
              const SizedBox(height: 24),
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
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: const Color(0x33FF9800),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange, width: 1.5),
                  ),
                  child: const Text(
                    '💡 센서 게임은 모바일 앱에서만 플레이 가능',
                    style: TextStyle(color: Colors.white, fontSize: 13),
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
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: MicroGameTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 12,
          shadowColor: const Color(0x60000000),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, size: 32),
            SizedBox(width: 8),
            Text('START!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      decoration: const BoxDecoration(gradient: MicroGameTheme.backgroundGradient),
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
                  _countdown > 0 ? '$_countdown' : 'GO!',
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
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC000000), Color(0x00000000)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 4 라이프
              LivesDisplay(lives: _controller.lives, maxLives: 4),

              // 점수 + 스테이지 + 스피드미터
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_controller.score}',
                    style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
                      shadows: [Shadow(color: MicroGameTheme.black54, offset: Offset(2, 2), blurRadius: 4)],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _controller.isCurrentBoss ? '🔴 BOSS' : 'STAGE ${_controller.currentRound + 1}',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: _controller.isCurrentBoss ? const Color(0xFFFF4444) : MicroGameTheme.white70,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SpeedMeter(speedMultiplier: _controller.speedMultiplier),
                    ],
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
    final best = GameDataService.getBestScore('microgame_rush');
    final isNew = _controller.score >= best && _controller.score > 0;

    return Container(
      decoration: const BoxDecoration(gradient: MicroGameTheme.backgroundGradient),
      child: Stack(
        children: [
          if (isNew) const ConfettiEffect(trigger: true, particleCount: 50),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isNew ? '🎉 NEW RECORD! 🎉' : 'GAME OVER',
                    style: MicroGameTheme.titleStyle.copyWith(
                      fontSize: isNew ? 34 : 32,
                      color: isNew ? const Color(0xFFFFD700) : Colors.white,
                      letterSpacing: isNew ? 2 : 4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _controller.score.toDouble()),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOut,
                    builder: (context, v, _) {
                      return Text(
                        '${v.toInt()}',
                        style: const TextStyle(
                          fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white,
                          shadows: [Shadow(color: MicroGameTheme.black38, offset: Offset(3, 3), blurRadius: 8)],
                        ),
                      );
                    },
                  ),
                  const Text(
                    'SCORE',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: MicroGameTheme.white70, letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 28),
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
                        _stat('✅ 성공', '${_controller.successCount}'),
                        _stat('❌ 실패', '${_controller.failureCount}'),
                        _stat('🔥 최대 콤보', '×${_controller.maxCombo}'),
                        _stat('⚡ 퍼펙트', '${_controller.perfectCount}'),
                        _stat('👑 보스 클리어', '${_controller.bossesCleared}'),
                        _stat('📊 스테이지', '${_controller.currentRound}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: MicroGameTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 24),
                        SizedBox(width: 8),
                        Text('RETRY', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('홈으로', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: MicroGameTheme.white70)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
