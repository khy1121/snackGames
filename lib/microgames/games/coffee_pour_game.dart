import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 커피 따르기 게임 (기울이기)
class CoffeePourGame extends MicroGame {
  const CoffeePourGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '커피 따르기!';

  @override
  String get description => '기울여서 따라라!';

  @override
  String get emoji => '☕';

  @override
  State<CoffeePourGame> createState() => _CoffeePourGameState();
}

class _CoffeePourGameState extends MicroGameState<CoffeePourGame> {
  Timer? _gameTimer;
  StreamSubscription? _accelerometerSubscription;
  double _coffeeLevel = 0.0; // 0.0 ~ 1.0
  double _tiltAngle = 0.0; // 기울기 각도

  final double _targetMin = 0.7; // 70%
  final double _targetMax = 0.9; // 90%

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
        _checkResult();
      }
    });
  }

  void _handleAccelerometer(AccelerometerEvent event) {
    // x축 기울기를 사용 (좌우 기울이기)
    final tilt = event.x;

    setState(() {
      _tiltAngle = tilt;

      // 기울기에 따라 커피 레벨 증가/감소
      if (tilt > 2.0) {
        // 오른쪽으로 기울임 → 커피가 흐름
        _coffeeLevel += 0.01;
      } else if (tilt < -2.0) {
        // 왼쪽으로 기울임 → 천천히 줄어듦
        _coffeeLevel -= 0.005;
      }

      _coffeeLevel = _coffeeLevel.clamp(0.0, 1.0);

      // 넘치면 실패
      if (_coffeeLevel >= 1.0) {
        markFailure();
      }
    });
  }

  void _checkResult() {
    if (_coffeeLevel >= _targetMin && _coffeeLevel <= _targetMax) {
      markSuccess();
    } else {
      markTimeout();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGoodLevel = _coffeeLevel >= _targetMin && _coffeeLevel <= _targetMax;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFFBCAAA4)],
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
              child: MicroGameWidgets.buildInstruction('기기를 기울여 따르세요!'),
            ),
          ),

          // 목표 범위 안내
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                isGoodLevel ? '완벽! 멈춰!' : '${(_coffeeLevel * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isGoodLevel ? Colors.green : Colors.white,
                ),
              ),
            ),
          ),

          // 커피 포트와 컵
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 커피 포트 (기울어짐)
                Transform.rotate(
                  angle: _tiltAngle * 0.1,
                  child: const Text(
                    '☕',
                    style: TextStyle(fontSize: 80),
                  ),
                ),
                const SizedBox(width: 40),
                // 컵 (커피가 차오름)
                _buildCup(),
              ],
            ),
          ),

          // 완료 메시지
          if (isCompleted)
            Center(
              child: MicroGameWidgets.buildResultBadge(
                isSuccess: isGoodLevel || _coffeeLevel >= _targetMin && _coffeeLevel <= _targetMax,
                text: isGoodLevel || (_coffeeLevel >= _targetMin && _coffeeLevel <= _targetMax)
                    ? '완벽!'
                    : _coffeeLevel >= 1.0
                        ? '넘쳤어요!'
                        : '부족해요!',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCup() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // 컵 외곽
        Container(
          width: 100,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.brown, width: 4),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
        ),
        // 커피 채워짐
        Container(
          width: 92,
          height: 116 * _coffeeLevel,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6F4E37), Color(0xFF8B4513)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: const Radius.circular(6),
              bottomRight: const Radius.circular(6),
              topLeft: _coffeeLevel < 0.95 ? Radius.zero : const Radius.circular(6),
              topRight: _coffeeLevel < 0.95 ? Radius.zero : const Radius.circular(6),
            ),
          ),
        ),
        // 목표 범위 표시
        Positioned(
          bottom: 116 * _targetMin,
          child: Container(
            width: 100,
            height: 2,
            color: Colors.greenAccent,
          ),
        ),
        Positioned(
          bottom: 116 * _targetMax,
          child: Container(
            width: 100,
            height: 2,
            color: Colors.greenAccent,
          ),
        ),
      ],
    );
  }
}
