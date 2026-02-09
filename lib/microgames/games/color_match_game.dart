import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 색깔 맞추기 게임 (스트룹 테스트 — 글자 색과 뜻이 다름!)
class ColorMatchGame extends MicroGame {
  const ColorMatchGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '색깔 맞추기!';

  @override
  String get instruction => '글자 색을 골라!';

  @override
  String get emoji => '🎨';

  @override
  State<ColorMatchGame> createState() => _ColorMatchGameState();
}

class _ColorMatchData {
  final String name;
  final Color color;
  const _ColorMatchData(this.name, this.color);
}

class _ColorMatchGameState extends MicroGameState<ColorMatchGame> {
  Timer? _gameTimer;
  final Random _random = Random();

  // 색상 풀
  static const List<_ColorMatchData> _colorPool = [
    _ColorMatchData('빨강', Color(0xFFFF0000)),
    _ColorMatchData('파랑', Color(0xFF2196F3)),
    _ColorMatchData('초록', Color(0xFF4CAF50)),
    _ColorMatchData('노랑', Color(0xFFFFEB3B)),
    _ColorMatchData('보라', Color(0xFF9C27B0)),
    _ColorMatchData('주황', Color(0xFFFF9800)),
  ];

  // 문제: 글자의 텍스트와 색이 다름
  late String _displayText;     // 표시되는 문자 (예: "빨강")
  late Color _displayColor;     // 표시되는 색 (예: 파란색)
  late int _correctAnswerIndex; // 정답 인덱스 (_displayColor와 매칭되는 것)
  late List<_ColorMatchData> _choices; // 2~3개 선택지

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
    _startGame();
  }

  void _generatePuzzle() {
    // 난이도에 따라 선택지 수 결정
    final numChoices = widget.config.difficultyLevel >= 2 ? 4 : 3;

    // 글자 텍스트 (이름)와 표시 색상(다른 색)을 랜덤 선택
    final textIndex = _random.nextInt(_colorPool.length);
    int colorIndex;
    do {
      colorIndex = _random.nextInt(_colorPool.length);
    } while (colorIndex == textIndex);

    _displayText = _colorPool[textIndex].name;
    _displayColor = _colorPool[colorIndex].color;

    // 정답은 _displayColor에 해당하는 색 이름
    final correctColor = _colorPool[colorIndex];

    // 선택지 생성 (정답 포함)
    final choiceSet = <_ColorMatchData>{correctColor};
    while (choiceSet.length < numChoices) {
      choiceSet.add(_colorPool[_random.nextInt(_colorPool.length)]);
    }
    _choices = choiceSet.toList()..shuffle(_random);
    _correctAnswerIndex = _choices.indexOf(correctColor);
  }

  void _startGame() {
    _gameTimer = Timer(widget.config.timeLimit, () {
      if (!isCompleted && mounted) markTimeout();
    });
  }

  void _onChoice(int index) {
    if (isCompleted) return;
    if (index == _correctAnswerIndex) {
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
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
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
              child: MicroGameWidgets.buildInstruction('이 글자의 "색깔"은?'),
            ),
          ),

          // 스트룹 글자 (텍스트와 색이 다름!)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _displayText,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: _displayColor,
                  shadows: const [
                    Shadow(color: Color(0x80000000), offset: Offset(3, 3), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ),

          // 선택지 버튼들
          Positioned(
            bottom: 80,
            left: 20,
            right: 20,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_choices.length, (i) {
                return GestureDetector(
                  onTap: () => _onChoice(i),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _choices[i].color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _choices[i].color.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _choices[i].name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Color(0x80000000), offset: Offset(1, 1), blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 완료 메시지
          if (isCompleted)
            Center(
              child: MicroGameWidgets.buildResultBadge(
                isSuccess: true,
                text: '정답!',
              ),
            ),
        ],
      ),
    );
  }
}
