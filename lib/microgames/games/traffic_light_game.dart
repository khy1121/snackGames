import 'dart:async';
import 'package:flutter/material.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 신호등 건너기 게임
class TrafficLightGame extends MicroGame {
  const TrafficLightGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '신호등 건너기!';

  @override
  String get description => '초록불에만 터치!';

  @override
  String get emoji => '🚦';

  @override
  State<TrafficLightGame> createState() => _TrafficLightGameState();
}

enum LightColor { red, yellow, green }

class _TrafficLightGameState extends MicroGameState<TrafficLightGame> {
  LightColor _currentLight = LightColor.red;
  Timer? _lightTimer;
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // 신호등 사이클 (빨강 → 노랑 → 초록 → 빨강...)
    _lightTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (mounted && !isCompleted) {
        setState(() {
          switch (_currentLight) {
            case LightColor.red:
              _currentLight = LightColor.yellow;
              break;
            case LightColor.yellow:
              _currentLight = LightColor.green;
              break;
            case LightColor.green:
              _currentLight = LightColor.red;
              break;
          }
        });
      }
    });

    // 게임 타임아웃
    _gameTimer = Timer(widget.config.timeLimit, () {
      if (!isCompleted && mounted) {
        markTimeout();
      }
    });
  }

  void _onTapped() {
    if (isCompleted) return;

    if (_currentLight == LightColor.green) {
      // 초록불에 터치 → 성공!
      markSuccess();
    } else {
      // 빨강/노랑에 터치 → 실패
      markFailure();
    }
  }

  @override
  void dispose() {
    _lightTimer?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTapped,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF37474F), Color(0xFF546E7A)],
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
                child: MicroGameWidgets.buildInstruction('초록불에 터치!'),
              ),
            ),

            // 안내 문구
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _currentLight == LightColor.green ? '지금!' : '기다려...',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _currentLight == LightColor.green
                        ? Colors.greenAccent
                        : Colors.white70,
                  ),
                ),
              ),
            ),

            // 신호등
            Center(
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLight(LightColor.red),
                    const SizedBox(height: 16),
                    _buildLight(LightColor.yellow),
                    const SizedBox(height: 16),
                    _buildLight(LightColor.green),
                  ],
                ),
              ),
            ),

            // 완료 메시지
            if (isCompleted)
              Center(
                child: MicroGameWidgets.buildResultBadge(
                  isSuccess: _currentLight == LightColor.green,
                  text: _currentLight == LightColor.green ? '성공!' : '실패!',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLight(LightColor color) {
    final isActive = _currentLight == color;
    Color lightColor;

    switch (color) {
      case LightColor.red:
        lightColor = isActive ? Colors.red : const Color(0x33F44336);
        break;
      case LightColor.yellow:
        lightColor = isActive ? Colors.yellow : const Color(0x33FFEB3B);
        break;
      case LightColor.green:
        lightColor = isActive ? Colors.green : const Color(0x334CAF50);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lightColor,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: lightColor.withValues(alpha: 0.8),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : [],
      ),
    );
  }
}
