import 'dart:async';
import 'package:flutter/material.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 뽁뽁이 터뜨리기 게임
class BubbleWrapGame extends MicroGame {
  const BubbleWrapGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '뽁뽁이!';

  @override
  String get instruction => '전부 터뜨려!';

  @override
  String get emoji => '⚪';

  @override
  State<BubbleWrapGame> createState() => _BubbleWrapGameState();
}

class _BubbleWrapGameState extends MicroGameState<BubbleWrapGame> {
  final List<bool> _popped = List.generate(16, (_) => false); // 4x4 grid
  Timer? _gameTimer;
  int _poppedCount = 0;
  final int _totalBubbles = 16;

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

  void _popBubble(int index) {
    if (_popped[index] || isCompleted) return;

    setState(() {
      _popped[index] = true;
      _poppedCount++;
    });

    // 모두 터뜨렸으면 성공
    if (_poppedCount >= _totalBubbles) {
      markSuccess();
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
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
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
              child: MicroGameWidgets.buildInstruction('모두 터뜨려!'),
            ),
          ),

          // 진행도
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '$_poppedCount / $_totalBubbles',
                style: MicroGameTheme.titleStyle.copyWith(color: Colors.black87),
              ),
            ),
          ),

          // 뽁뽁이 그리드
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _totalBubbles,
                itemBuilder: (context, index) {
                  return _buildBubble(index);
                },
              ),
            ),
          ),

          // 완료 메시지
          if (isCompleted)
            Center(
              child: MicroGameWidgets.buildResultBadge(
                isSuccess: _poppedCount >= _totalBubbles,
                text: _poppedCount >= _totalBubbles ? '완벽!' : '시간 초과!',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(int index) {
    final isPopped = _popped[index];

    return GestureDetector(
      onTap: () => _popBubble(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isPopped
              ? const LinearGradient(
                  colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: isPopped
              ? []
              : const [
                  BoxShadow(
                    color: Color(0x4D2196F3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              fontSize: isPopped ? 24 : 32,
              color: Colors.white,
            ),
            child: Text(isPopped ? '💨' : '⚪'),
          ),
        ),
      ),
    );
  }
}
