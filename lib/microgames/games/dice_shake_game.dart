import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 주사위 흔들기 게임
class DiceShakeGame extends MicroGame {
  const DiceShakeGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '주사위 흔들기!';

  @override
  String get description => '흔들어서 6을 만들어!';

  @override
  String get emoji => '🎲';

  @override
  State<DiceShakeGame> createState() => _DiceShakeGameState();
}

class _DiceShakeGameState extends MicroGameState<DiceShakeGame> {
  Timer? _gameTimer;
  StreamSubscription? _accelerometerSubscription;
  
  int _diceValue = 1;
  double _shakeIntensity = 0.0;
  final double _shakeThreshold = 15.0; // 흔들림 감지 임계값
  bool _isShaking = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // 가속도계 리스닝
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!isCompleted && mounted) {
        _handleAccelerometer(event);
      }
    });

    // 게임 타임아웃
    _gameTimer = Timer(widget.config.timeLimit, () {
      if (!isCompleted && mounted) {
        markTimeout();
      }
    });
  }

  void _handleAccelerometer(AccelerometerEvent event) {
    // 전체 가속도 크기 계산
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    setState(() {
      _shakeIntensity = magnitude;

      // 흔들림이 임계값을 넘으면 주사위 굴리기
      if (magnitude > _shakeThreshold && !_isShaking) {
        _isShaking = true;
        _rollDice();

        // 짧은 지연 후 다시 흔들기 가능
        Future.delayed(const Duration(milliseconds: 300), () {
          _isShaking = false;
        });
      }
    });
  }

  void _rollDice() {
    setState(() {
      _diceValue = _random.nextInt(6) + 1;
    });

    // 6이 나오면 성공!
    if (_diceValue == 6) {
      markSuccess();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  String _getDiceEmoji(int value) {
    switch (value) {
      case 1:
        return '⚀';
      case 2:
        return '⚁';
      case 3:
        return '⚂';
      case 4:
        return '⚃';
      case 5:
        return '⚄';
      case 6:
        return '⚅';
      default:
        return '🎲';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWinning = _diceValue == 6;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // 지시문
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: MicroGameWidgets.buildInstruction('기기를 흔들어주세요!'),
            ),
          ),

          // 목표 안내
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                isWinning ? '대박!' : '6을 만들어라!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isWinning ? Colors.yellow : Colors.white,
                ),
              ),
            ),
          ),

          // 주사위
          Center(
            child: AnimatedRotation(
              turns: _isShaking ? _random.nextDouble() : 0,
              duration: const Duration(milliseconds: 100),
              child: AnimatedScale(
                scale: _isShaking ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isWinning 
                            ? const Color(0x99FFEB3B)
                            : const Color(0x4D000000),
                        blurRadius: isWinning ? 30 : 20,
                        spreadRadius: isWinning ? 10 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _getDiceEmoji(_diceValue),
                      style: TextStyle(
                        fontSize: 100,
                        color: isWinning ? Colors.green : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 흔들림 인디케이터
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Text(
                    '흔들림: ${(_shakeIntensity).toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: (_shakeIntensity / 30).clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.yellow, Colors.red],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 완료 메시지
          if (isCompleted)
            Center(
              child: MicroGameWidgets.buildResultBadge(
                isSuccess: isWinning,
                text: isWinning ? '대박! 6!' : '실패!',
              ),
            ),
        ],
      ),
    );
  }
}
