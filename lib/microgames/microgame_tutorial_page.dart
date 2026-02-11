import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/microgame_base.dart';
import 'core/microgame_theme.dart';
import 'games/balloon_pop_game.dart';
import 'games/fly_catcher_game.dart';
import 'games/bubble_wrap_game.dart';
import 'games/traffic_light_game.dart';

/// MicroGame Rush 인터랙티브 튜토리얼
class MicroGameTutorialPage extends StatefulWidget {
  final VoidCallback onComplete;
  
  const MicroGameTutorialPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<MicroGameTutorialPage> createState() => _MicroGameTutorialPageState();
}

class _MicroGameTutorialPageState extends State<MicroGameTutorialPage>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _isPlaying = false;
  bool _showInstruction = true;
  int _lives = 4;
  int _combo = 0;
  int _score = 0;
  int _gamesPlayed = 0;
  double _speedMultiplier = 1.0;
  
  // 튜토리얼 단계별 게임
  MicroGame? _currentGame;
  
  // 애니메이션 컨트롤러
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // 타이머 진행률
  double _timerProgress = 1.0;
  Timer? _timerBarTimer;

  final List<TutorialStepData> _steps = [
    TutorialStepData(
      title: '기본 조작',
      instruction: '👆 화면을 터치해서\n풍선을 터뜨리세요!',
      tip: '시간 제한 없이 연습해보세요',
      gameType: TutorialGameType.balloon,
      hasTimeLimit: false,
    ),
    TutorialStepData(
      title: '타이밍',
      instruction: '⏱️ 제한 시간 안에\n파리를 잡으세요!',
      tip: '화면 상단의 타이머를 확인하세요',
      gameType: TutorialGameType.fly,
      hasTimeLimit: true,
      timeLimit: const Duration(seconds: 10),
    ),
    TutorialStepData(
      title: '라이프 & 콤보',
      instruction: '❤️ 4개의 라이프\n🔥 연속 성공 = 콤보!',
      tip: '실패하면 라이프가 줄어요',
      gameType: TutorialGameType.mixed,
      hasTimeLimit: true,
      timeLimit: const Duration(seconds: 8),
      gameCount: 3,
    ),
    TutorialStepData(
      title: '스피드 업!',
      instruction: '⚡ 점점 빨라져요!\n속도에 적응하세요!',
      tip: '실제 게임과 동일한 속도 증가',
      gameType: TutorialGameType.speedUp,
      hasTimeLimit: true,
      timeLimit: const Duration(seconds: 6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timerBarTimer?.cancel();
    super.dispose();
  }

  void _startStep() {
    setState(() {
      _showInstruction = false;
      _isPlaying = true;
    });
    _loadGame();
  }

  void _loadGame() {
    final step = _steps[_currentStep];
    
    MicroGameConfig config = MicroGameConfig(
      difficulty: MicroGameDifficulty.easy,
      instruction: step.instruction,
      timeLimit: step.hasTimeLimit 
          ? Duration(milliseconds: (step.timeLimit!.inMilliseconds / _speedMultiplier).round())
          : const Duration(seconds: 999),
    );
    
    setState(() {
      switch (step.gameType) {
        case TutorialGameType.balloon:
          _currentGame = BalloonPopGame(
            config: config,
            onSuccess: _onGameSuccess,
            onFailure: _onGameFailure,
            onTimeout: _onGameTimeout,
          );
          break;
        case TutorialGameType.fly:
          _currentGame = FlyCatcherGame(
            config: config,
            onSuccess: _onGameSuccess,
            onFailure: _onGameFailure,
            onTimeout: _onGameTimeout,
          );
          break;
        case TutorialGameType.mixed:
          // 혼합 게임: 랜덤 선택
          final games = [
            () => BubbleWrapGame(
              config: config,
              onSuccess: _onGameSuccess,
              onFailure: _onGameFailure,
              onTimeout: _onGameTimeout,
            ),
            () => TrafficLightGame(
              config: config,
              onSuccess: _onGameSuccess,
              onFailure: _onGameFailure,
              onTimeout: _onGameTimeout,
            ),
            () => BalloonPopGame(
              config: config,
              onSuccess: _onGameSuccess,
              onFailure: _onGameFailure,
              onTimeout: _onGameTimeout,
            ),
          ];
          _currentGame = games[_gamesPlayed % games.length]();
          break;
        case TutorialGameType.speedUp:
          _currentGame = FlyCatcherGame(
            config: config,
            onSuccess: _onGameSuccess,
            onFailure: _onGameFailure,
            onTimeout: _onGameTimeout,
          );
          break;
      }
    });
    
    // 타이머 시작
    if (step.hasTimeLimit) {
      _startTimerBar(step.timeLimit!);
    }
  }

  void _startTimerBar(Duration duration) {
    _timerProgress = 1.0;
    final adjustedDuration = Duration(
      milliseconds: (duration.inMilliseconds / _speedMultiplier).round(),
    );
    
    _timerBarTimer?.cancel();
    _timerBarTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _timerProgress -= 50 / adjustedDuration.inMilliseconds;
        if (_timerProgress <= 0) {
          _timerProgress = 0;
          timer.cancel();
        }
      });
    });
  }

  void _onGameSuccess() {
    _timerBarTimer?.cancel();
    
    setState(() {
      _combo++;
      _score += (100 * _combo * _speedMultiplier).round();
      _gamesPlayed++;
    });
    
    _showResultAndContinue(true);
  }

  void _onGameFailure() {
    _timerBarTimer?.cancel();
    
    setState(() {
      _lives--;
      _combo = 0;
      _gamesPlayed++;
    });
    
    _showResultAndContinue(false);
  }

  void _onGameTimeout() {
    _onGameFailure();
  }

  void _showResultAndContinue(bool success) {
    final step = _steps[_currentStep];
    
    // 결과 표시 후 다음 진행
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      
      // Step 3: 여러 게임 진행
      if (step.gameType == TutorialGameType.mixed && 
          step.gameCount != null && 
          _gamesPlayed < step.gameCount!) {
        _loadGame();
        return;
      }
      
      // Step 4: 스피드 업 (2회 진행)
      if (step.gameType == TutorialGameType.speedUp && _gamesPlayed < 2) {
        setState(() {
          _speedMultiplier = 0.7; // 속도 증가
        });
        _loadGame();
        return;
      }
      
      // 다음 단계로
      _proceedToNextStep();
    });
  }

  void _proceedToNextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _showInstruction = true;
        _isPlaying = false;
        _currentGame = null;
        _gamesPlayed = 0;
        
        // Step 3 이후 라이프/콤보 리셋
        if (_currentStep == 2) {
          _lives = 4;
          _combo = 0;
        }
      });
    } else {
      // 튜토리얼 완료
      _completeTutorial();
    }
  }

  Future<void> _completeTutorial() async {
    // 튜토리얼 완료 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('microgame_tutorial_completed', true);
    
    if (mounted) {
      widget.onComplete();
    }
  }

  void _skipTutorial() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('튜토리얼 건너뛰기', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말 건너뛰시겠습니까?\n나중에 설정에서 다시 볼 수 있습니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _completeTutorial();
            },
            child: const Text('건너뛰기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: MicroGameTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 게임 영역
              if (_currentGame != null && _isPlaying)
                Column(
                  children: [
                    // 상단 HUD
                    _buildHUD(),
                    
                    // 타이머 바
                    if (_steps[_currentStep].hasTimeLimit)
                      _buildTimerBar(),
                    
                    // 게임 영역
                    Expanded(child: _currentGame!),
                  ],
                ),
              
              // 설명 오버레이
              if (_showInstruction)
                _buildInstructionOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 라이프
          Row(
            children: List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                i < _lives ? Icons.favorite : Icons.favorite_border,
                color: i < _lives ? Colors.redAccent : Colors.grey,
                size: 24,
              ),
            )),
          ),
          
          // 콤보
          if (_combo > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '🔥 x$_combo',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // 점수
          Text(
            '$_score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _timerProgress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _timerProgress > 0.3
                  ? [const Color(0xFF00B894), const Color(0xFF00CEC9)]
                  : [Colors.red, Colors.orange],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionOverlay() {
    final step = _steps[_currentStep];
    
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 진행 상태
                Row(
                  children: List.generate(_steps.length, (i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: i == _currentStep ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i <= _currentStep 
                          ? const Color(0xFF00B894) 
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  )),
                ),
                
                // 스킵 버튼
                TextButton(
                  onPressed: _skipTutorial,
                  child: const Text(
                    '건너뛰기',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
          
          // 중앙 내용
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 단계 번호
                    Text(
                      'Step ${_currentStep + 1}/${_steps.length}',
                      style: TextStyle(
                        color: const Color(0xFF00B894),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 제목
                    Text(
                      step.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 설명
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF00B894).withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          step.instruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 팁
                    Text(
                      '💡 ${step.tip}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // 시작 버튼
                    FilledButton.icon(
                      onPressed: _startStep,
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '시작하기',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00B894),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 튜토리얼 단계 데이터
class TutorialStepData {
  final String title;
  final String instruction;
  final String tip;
  final TutorialGameType gameType;
  final bool hasTimeLimit;
  final Duration? timeLimit;
  final int? gameCount;

  const TutorialStepData({
    required this.title,
    required this.instruction,
    required this.tip,
    required this.gameType,
    this.hasTimeLimit = false,
    this.timeLimit,
    this.gameCount,
  });
}

enum TutorialGameType {
  balloon,
  fly,
  mixed,
  speedUp,
}
