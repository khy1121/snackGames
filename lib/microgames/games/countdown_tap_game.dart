import 'dart:async';
import 'package:flutter/material.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 카운트다운 정확히 멈추기 게임 (0.00에 터치!)
class CountdownTapGame extends MicroGame {
  const CountdownTapGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '타이밍 맞추기!';

  @override
  String get instruction => '0에 멈춰!';

  @override
  String get emoji => '⏱️';

  @override
  State<CountdownTapGame> createState() => _CountdownTapGameState();
}

class _CountdownTapGameState extends MicroGameState<CountdownTapGame> {
  Timer? _gameTimer;
  Timer? _countdownTimer;
  
  double _displayValue = 3.00; // 3초부터 카운트다운
  bool _hasTapped = false;
  
  // 난이도에 따른 허용 오차
  double get _tolerance {
    switch (widget.config.difficulty) {
      case MicroGameDifficulty.easy: return 0.50;
      case MicroGameDifficulty.medium: return 0.35;
      case MicroGameDifficulty.hard: return 0.25;
      case MicroGameDifficulty.extreme: return 0.20;
    }
  }

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // 빠르게 카운트다운 (50ms마다)
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_hasTapped || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _displayValue -= 0.05;
        // 0 이하로 내려가면 실패 (못 눌렀음)
        if (_displayValue <= -1.0) {
          timer.cancel();
          if (!isCompleted) markTimeout();
        }
      });
    });

    _gameTimer = Timer(widget.config.timeLimit, () {
      if (!isCompleted && mounted) markTimeout();
    });
  }

  void _onTap() {
    if (isCompleted || _hasTapped) return;
    _hasTapped = true;
    _countdownTimer?.cancel();

    // 0.00에 가까우면 성공
    if (_displayValue.abs() <= _tolerance) {
      markSuccess();
    } else {
      markFailure();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNearZero = _displayValue.abs() < _tolerance;
    final displayStr = _displayValue.toStringAsFixed(2);

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // 지시문
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: MicroGameWidgets.buildInstruction('0.00에 터치!'),
              ),
            ),

            // 큰 카운트다운 숫자
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 100),
                    style: TextStyle(
                      fontSize: isNearZero ? 96 : 80,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      color: _displayValue > 0.5
                          ? Colors.white
                          : isNearZero
                              ? const Color(0xFF00FF00)
                              : const Color(0xFFFF4444),
                      shadows: [
                        Shadow(
                          color: isNearZero
                              ? const Color(0x8000FF00)
                              : const Color(0x40FFFFFF),
                          blurRadius: isNearZero ? 30 : 10,
                        ),
                      ],
                    ),
                    child: Text(displayStr),
                  ),
                  const SizedBox(height: 20),
                  if (!_hasTapped)
                    Text(
                      isNearZero ? '지금!' : '기다려...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isNearZero
                            ? const Color(0xFF00FF00)
                            : const Color(0xB3FFFFFF),
                      ),
                    ),
                ],
              ),
            ),

            // 화면 아무곳이나 터치 안내
            if (!_hasTapped)
              const Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '화면을 터치하세요!',
                    style: TextStyle(fontSize: 16, color: Color(0x80FFFFFF)),
                  ),
                ),
              ),

            // 완료 메시지
            if (isCompleted)
              Center(
                child: MicroGameWidgets.buildResultBadge(
                  isSuccess: _displayValue.abs() <= _tolerance,
                  text: _displayValue.abs() <= _tolerance
                      ? '완벽! ${_displayValue.toStringAsFixed(2)}'
                      : '아쉽! ${_displayValue.toStringAsFixed(2)}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
