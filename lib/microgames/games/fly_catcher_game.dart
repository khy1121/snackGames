import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 날아오는 파리 잡기 게임
class FlyCatcherGame extends MicroGame {
  const FlyCatcherGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '날아오는 파리!';

  @override
  String get description => '파리를 잡아라!';

  @override
  String get emoji => '🪰';

  @override
  State<FlyCatcherGame> createState() => _FlyCatcherGameState();
}

class _FlyCatcherGameState extends MicroGameState<FlyCatcherGame> {
  final List<Fly> _flies = [];
  final Random _random = Random();
  Timer? _gameTimer;
  Timer? _movementTimer;
  int _caughtCount = 0;
  final int _targetCount = 3; // 3마리 잡으면 성공

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // 3마리의 파리 생성
    for (int i = 0; i < _targetCount; i++) {
      _flies.add(Fly(
        id: i,
        x: _random.nextDouble() * 0.8 + 0.1,
        y: _random.nextDouble() * 0.6 + 0.2,
      ));
    }

    // 파리 움직임 타이머
    _movementTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          for (var fly in _flies) {
            if (!fly.isCaught) {
              fly.move(_random);
            }
          }
        });
      }
    });

    // 게임 타임아웃 타이머
    _gameTimer = Timer(widget.config.timeLimit, () {
      if (!isCompleted && mounted) {
        markTimeout();
      }
    });
  }

  void _catchFly(Fly fly) {
    if (fly.isCaught || isCompleted) return;

    setState(() {
      fly.isCaught = true;
      _caughtCount++;
    });

    // 모두 잡았으면 성공
    if (_caughtCount >= _targetCount) {
      markSuccess();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _movementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF87CEEB), Color(0xFFE0F6FF)],
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
              child: MicroGameWidgets.buildInstruction(widget.config.instruction),
            ),
          ),

          // 잡은 개수 표시
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '$_caughtCount / $_targetCount',
                style: MicroGameTheme.titleStyle.copyWith(color: Colors.black87),
              ),
            ),
          ),

          // 파리들
          ..._flies.map((fly) => _buildFly(fly, size)),

          // 완료 메시지
          if (isCompleted)
            Center(
              child: MicroGameWidgets.buildResultBadge(
                isSuccess: _caughtCount >= _targetCount,
                text: _caughtCount >= _targetCount ? '성공!' : '실패!',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFly(Fly fly, Size screenSize) {
    if (fly.isCaught) return const SizedBox.shrink();

    return Positioned(
      left: fly.x * screenSize.width - 30,
      top: fly.y * screenSize.height - 30,
      child: GestureDetector(
        onTap: () => _catchFly(fly),
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1A000000),
                ),
                child: const Center(
                  child: Text(
                    '🪰',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 파리 데이터 클래스
class Fly {
  final int id;
  double x;
  double y;
  bool isCaught = false;

  Fly({
    required this.id,
    required this.x,
    required this.y,
  });

  /// 랜덤 이동
  void move(Random random) {
    // 0.1~0.2 범위 내에서 이동
    x = (x + (random.nextDouble() - 0.5) * 0.2).clamp(0.1, 0.9);
    y = (y + (random.nextDouble() - 0.5) * 0.2).clamp(0.2, 0.8);
  }
}
