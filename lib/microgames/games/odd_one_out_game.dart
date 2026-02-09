import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 다른 그림 찾기 게임 (하나만 다른 이모지!)
class OddOneOutGame extends MicroGame {
  const OddOneOutGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '다른 그림 찾기!';

  @override
  String get instruction => '다른 걸 찾아!';

  @override
  String get emoji => '🔍';

  @override
  State<OddOneOutGame> createState() => _OddOneOutGameState();
}

class _OddOneOutGameState extends MicroGameState<OddOneOutGame> {
  Timer? _gameTimer;
  final Random _random = Random();

  // 이모지 세트 (일반, 다른 것)
  static const List<List<String>> _emojiPairs = [
    ['😀', '😃'],
    ['🍎', '🍏'],
    ['🐱', '🐶'],
    ['⭐', '🌟'],
    ['🔵', '🟣'],
    ['🌸', '🌺'],
    ['🐤', '🐥'],
    ['♠️', '♣️'],
    ['🎵', '🎶'],
    ['🔴', '🟠'],
    ['💚', '💙'],
    ['🍕', '🍔'],
  ];

  late String _normalEmoji;
  late String _oddEmoji;
  late int _oddIndex;
  late int _gridSize; // 그리드 총 아이템 수

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
    _startGame();
  }

  void _generatePuzzle() {
    // 난이도에 따른 그리드 크기
    switch (widget.config.difficulty) {
      case MicroGameDifficulty.easy:
        _gridSize = 9; // 3×3
        break;
      case MicroGameDifficulty.medium:
        _gridSize = 12; // 3×4
        break;
      case MicroGameDifficulty.hard:
        _gridSize = 16; // 4×4
        break;
      case MicroGameDifficulty.extreme:
        _gridSize = 20; // 4×5
        break;
    }

    final pair = _emojiPairs[_random.nextInt(_emojiPairs.length)];
    _normalEmoji = pair[0];
    _oddEmoji = pair[1];
    _oddIndex = _random.nextInt(_gridSize);
  }

  void _startGame() {
    _gameTimer = Timer(widget.config.timeLimit, () {
      if (!isCompleted && mounted) markTimeout();
    });
  }

  void _onTap(int index) {
    if (isCompleted) return;
    if (index == _oddIndex) {
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

  int get _crossAxisCount {
    if (_gridSize <= 9) return 3;
    if (_gridSize <= 12) return 3;
    if (_gridSize <= 16) return 4;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
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
              child: MicroGameWidgets.buildInstruction('다른 하나를 찾아!'),
            ),
          ),

          // 그리드
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _gridSize,
                itemBuilder: (context, index) {
                  final isOdd = index == _oddIndex;
                  return GestureDetector(
                    onTap: () => _onTap(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isOdd ? _oddEmoji : _normalEmoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 완료 메시지
          if (isCompleted)
            Center(
              child: MicroGameWidgets.buildResultBadge(
                isSuccess: true,
                text: '발견!',
              ),
            ),
        ],
      ),
    );
  }
}
