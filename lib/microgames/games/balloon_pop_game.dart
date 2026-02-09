import 'dart:async';
import 'package:flutter/material.dart';
import '../core/microgame_base.dart';
import '../core/microgame_theme.dart';

/// 풍선 터뜨리기 게임
class BalloonPopGame extends MicroGame {
  const BalloonPopGame({
    super.key,
    required super.config,
    required super.onSuccess,
    required super.onFailure,
    required super.onTimeout,
  });

  @override
  String get title => '풍선 터뜨리기!';

  @override
  String get description => '적당한 크기에 터뜨려라!';

  @override
  String get emoji => '🎈';

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

class _BalloonPopGameState extends MicroGameState<BalloonPopGame> {
  double _balloonScale = 0.5;
  Timer? _inflateTimer;
  Timer? _gameTimer;
  bool _isPopped = false;

  final double _minScale = 0.5;
  final double _maxScale = 2.5;
  final double _goodMinScale = 1.5;
  final double _goodMaxScale = 2.0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    // 풍선 부풀리기 애니메이션
    _inflateTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted && !_isPopped) {
        setState(() {
          _balloonScale += 0.05;

          // 너무 커지면 터짐 (실패)
          if (_balloonScale >= _maxScale) {
            _isPopped = true;
            _autoPop();
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

  void _popBalloon() {
    if (_isPopped || isCompleted) return;

    _isPopped = true;
    _inflateTimer?.cancel();

    // 적정 크기에 터뜨렸는지 확인
    if (_balloonScale >= _goodMinScale && _balloonScale <= _goodMaxScale) {
      markSuccess();
    } else {
      markFailure();
    }
  }

  void _autoPop() {
    // 너무 커져서 자동으로 터짐 (실패)
    _inflateTimer?.cancel();
    if (!isCompleted) {
      markFailure();
    }
  }

  @override
  void dispose() {
    _inflateTimer?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGoodSize = _balloonScale >= _goodMinScale && _balloonScale <= _goodMaxScale;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE5E5), Color(0xFFFFF5E5)],
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
              child: MicroGameWidgets.buildInstruction('적당한 크기에 터치!'),
            ),
          ),

          // 크기 안내 (초록색 구간)
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                isGoodSize ? '지금 터뜨려!' : '조금 더...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isGoodSize ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ),

          // 풍선
          Center(
            child: GestureDetector(
              onTap: _popBalloon,
              child: AnimatedScale(
                scale: _isPopped ? 0.0 : _balloonScale,
                duration: _isPopped
                    ? const Duration(milliseconds: 200)
                    : const Duration(milliseconds: 50),
                curve: Curves.easeOut,
                child: Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isGoodSize
                        ? Colors.greenAccent.withOpacity(0.3)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🎈',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 완료 메시지
          if (isCompleted)
            Center(
              child: AnimatedOpacity(
                opacity: isCompleted ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: MicroGameWidgets.buildResultBadge(
                  isSuccess: _balloonScale >= _goodMinScale && _balloonScale <= _goodMaxScale,
                  text: _balloonScale >= _goodMinScale && _balloonScale <= _goodMaxScale
                      ? '완벽!'
                      : '실패!',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
