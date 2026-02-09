import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 공 굴리기 게임 (기울이기)
class BallRollGame extends MicroGame {
  const BallRollGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '공 굴리기!';

  @override
  String get instruction => '굴려!';

  @override
  String get emoji => '⚽';

  @override
  State<BallRollGame> createState() => _BallRollGameState();
}

class _BallRollGameState extends MicroGameState<BallRollGame> {
  Timer? _gameTimer;
  StreamSubscription? _accelerometerSubscription;
  
  double _ballX = 0.5; // 0.0 ~ 1.0 (화면 중앙 시작)
  double _ballY = 0.5; // 0.0 ~ 1.0
  
  final double _goalX = 0.8;
  final double _goalY = 0.8;
  final double _goalRadius = 0.1;

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
    setState(() {
      // x축 기울기 → 좌우 이동
      _ballX += event.x * 0.005;
      _ballX = _ballX.clamp(0.1, 0.9);

      // y축 기울기 → 상하 이동
      _ballY += event.y * 0.005;
      _ballY = _ballY.clamp(0.1, 0.9);

      // 골인 체크
      final distance = _calculateDistance(_ballX, _ballY, _goalX, _goalY);
      if (distance < _goalRadius) {
        markSuccess();
      }
    });
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return (dx * dx + dy * dy);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
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
              child: MicroGameWidgets.buildInstruction('기기를 기울여 골인!'),
            ),
          ),

          // 게임 영역
          Center(
            child: Container(
              width: size.width * 0.9,
              height: size.height * 0.6,
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x4DFFFFFF), width: 3),
              ),
              child: Stack(
                children: [
                  // 골인 지점
                  Positioned(
                    left: (size.width * 0.9) * _goalX - 40,
                    top: (size.height * 0.6) * _goalY - 40,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Colors.greenAccent, Colors.green],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x994CAF50),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🏁',
                          style: TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                  ),

                  // 공
                  Positioned(
                    left: (size.width * 0.9) * _ballX - 25,
                    top: (size.height * 0.6) * _ballY - 25,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Colors.white, Colors.blueGrey],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4D000000),
                            blurRadius: 10,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '⚽',
                          style: TextStyle(fontSize: 30),
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
                isSuccess: true,
                text: '골인!',
              ),
            ),
        ],
      ),
    );
  }
}
