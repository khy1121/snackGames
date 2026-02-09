import 'dart:async';
import 'package:flutter/material.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// "만지지 마!" 게임 (WarioWare 명물: 아무것도 하지 않으면 성공)
class DontTouchGame extends MicroGame {
  const DontTouchGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '만지지 마!';

  @override
  String get instruction => '참아!';

  @override
  String get emoji => '🚫';

  @override
  State<DontTouchGame> createState() => _DontTouchGameState();
}

class _DontTouchGameState extends MicroGameState<DontTouchGame> {
  Timer? _gameTimer;
  Timer? _temptTimer;
  bool _showTemptation = false;
  int _temptPhase = 0;

  // 유혹 메시지 (누르고 싶게 만드는 것들)
  static const List<String> _temptations = [
    '👇 여기 눌러!',
    '🎁 선물이다!',
    '💰 터치하면 보너스!',
    '⬇️ 빨리 눌러!',
    '🍰 맛있는 케이크!',
    '✨ 반짝반짝!',
  ];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // 유혹 타이머: 화면에 유혹적인 것이 나타남
    _temptTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!mounted || isCompleted) {
        timer.cancel();
        return;
      }
      setState(() {
        _showTemptation = !_showTemptation;
        if (_showTemptation) _temptPhase++;
      });
    });

    // 시간이 다 되면 성공! (아무것도 안 했으므로)
    _gameTimer = Timer(widget.config.timeLimit, () {
      if (!isCompleted && mounted) {
        markSuccess(); // 참았으니 성공!
      }
    });
  }

  void _onTouched() {
    if (isCompleted) return;
    markFailure(); // 만졌으니 실패!
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _temptTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temptText = _temptations[_temptPhase % _temptations.length];
    final screenH = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: _onTouched,
      onPanDown: (_) => _onTouched(), // 어떤 터치도 감지
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF212121), Color(0xFF424242)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // 경고 아이콘
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: MicroGameWidgets.buildInstruction('❌ 만지지 마! ❌'),
              ),
            ),

            // 큰 금지 아이콘
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: _showTemptation ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Text(
                      '🚫',
                      style: TextStyle(fontSize: 120),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: _showTemptation ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: _showTemptation
                          ? const Color(0xFFFF4444)
                          : const Color(0xB3FFFFFF),
                    ),
                    child: const Text('참아! 참아!'),
                  ),
                ],
              ),
            ),

            // 유혹 (번쩍번쩍 나타났다 사라짐)
            if (_showTemptation)
              Positioned(
                bottom: screenH * 0.15,
                left: 30,
                right: 30,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, child) {
                    return Opacity(opacity: value, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFFD93D)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x80FFD93D),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        temptText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 완료 메시지
            if (isCompleted)
              Center(
                child: MicroGameWidgets.buildResultBadge(
                  isSuccess: true,
                  text: '잘 참았어!',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
