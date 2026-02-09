import 'dart:async';
import 'package:flutter/material.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 문 두드리기 게임
class DoorKnockGame extends MicroGame {
  const DoorKnockGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '문 두드리기!';

  @override
  String get instruction => '똑똑똑!';

  @override
  String get emoji => '🚪';

  @override
  State<DoorKnockGame> createState() => _DoorKnockGameState();
}

class _DoorKnockGameState extends MicroGameState<DoorKnockGame> {
  Timer? _gameTimer;
  int _knockCount = 0;
  final int _targetKnocks = 3;
  final List<int> _knockTimestamps = [];
  final int _rhythmToleranceMs = 800; // 리듬 허용 오차 (ms)

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // 게임 타임아웃
    _gameTimer = Timer(widget.config.timeLimit, () {
      if (!isCompleted && mounted) {
        markTimeout();
      }
    });
  }

  void _knock() {
    if (isCompleted) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    _knockTimestamps.add(now);

    setState(() {
      _knockCount++;
    });

    // 3번 두드렸으면 리듬 체크
    if (_knockCount >= _targetKnocks) {
      _checkRhythm();
    }
  }

  void _checkRhythm() {
    // 간단한 리듬 체크: 일정한 간격으로 두드렸는지 확인
    if (_knockTimestamps.length < 3) {
      markFailure();
      return;
    }

    final interval1 = _knockTimestamps[1] - _knockTimestamps[0];
    final interval2 = _knockTimestamps[2] - _knockTimestamps[1];

    // 두 간격의 차이가 허용 오차 내면 성공
    final rhythmDiff = (interval1 - interval2).abs();

    if (rhythmDiff < _rhythmToleranceMs) {
      markSuccess();
    } else {
      markFailure();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
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
              child: MicroGameWidgets.buildInstruction('리듬에 맞춰 3번!'),
            ),
          ),

          // 리듬 안내
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '♪',
                      style: TextStyle(
                        fontSize: 40,
                        color: index < _knockCount
                            ? Colors.yellow
                            : const Color(0x4DFFFFFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 문 (터치 영역)
          Center(
            child: GestureDetector(
              onTap: _knock,
              child: AnimatedScale(
                scale: _knockCount > 0 ? 1.0 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: 200,
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D4C41),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4E342E),
                      width: 8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🚪',
                        style: TextStyle(fontSize: 100),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 카운트 표시
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '$_knockCount / $_targetKnocks',
                style: MicroGameTheme.titleStyle,
              ),
            ),
          ),

          // 완료 메시지
          if (isCompleted)
            Center(
              child: MicroGameWidgets.buildResultBadge(
                isSuccess: _knockCount >= _targetKnocks,
                text: _knockCount >= _targetKnocks ? '완벽한 리듬!' : '실패!',
              ),
            ),
        ],
      ),
    );
  }
}
