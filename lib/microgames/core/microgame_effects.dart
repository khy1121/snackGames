import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// 점수 팝업 애니메이션 위젯
class ScorePopup extends StatefulWidget {
  final int score;
  final bool isCombo;
  final int comboCount;
  final VoidCallback? onComplete;

  const ScorePopup({
    super.key,
    required this.score,
    this.isCombo = false,
    this.comboCount = 0,
    this.onComplete,
  });

  @override
  State<ScorePopup> createState() => _ScorePopupState();
}

class _ScorePopupState extends State<ScorePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -60),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnim.value,
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+${widget.score}',
            style: TextStyle(
              fontSize: widget.isCombo ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: widget.isCombo ? const Color(0xFFFFD700) : Colors.white,
              shadows: const [
                Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
              ],
            ),
          ),
          if (widget.isCombo && widget.comboCount > 1)
            Text(
              '🔥 COMBO ×${widget.comboCount}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B00),
                shadows: [
                  Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 파티클 이펙트 (성공 시 빵빠레)
class ConfettiEffect extends StatefulWidget {
  final bool trigger;
  final int particleCount;

  const ConfettiEffect({
    super.key,
    required this.trigger,
    this.particleCount = 30,
  });

  @override
  State<ConfettiEffect> createState() => _ConfettiEffectState();
}

class _ConfettiEffectState extends State<ConfettiEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(ConfettiEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _spawnParticles();
      _controller.forward(from: 0);
    }
  }

  void _spawnParticles() {
    _particles.clear();
    const colors = [
      Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF51CF66),
      Color(0xFF339AF0), Color(0xFFCC5DE8), Color(0xFFFF922B),
    ];

    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        x: 0.5, // center
        y: 0.5,
        vx: (_random.nextDouble() - 0.5) * 4,
        vy: -_random.nextDouble() * 5 - 2,
        color: colors[_random.nextInt(colors.length)],
        size: _random.nextDouble() * 8 + 4,
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.trigger && _particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x, y, vx, vy;
  final Color color;
  final double size;
  double rotation;
  final double rotationSpeed;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gravity = 9.8;
    final t = progress;

    for (final p in particles) {
      final currentX = (p.x + p.vx * t) * size.width;
      final currentY = (p.y + p.vy * t + 0.5 * gravity * t * t) * size.height * 0.3;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final rotation = p.rotation + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 화면 흔들림 효과
class ScreenShake extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final double intensity;

  const ScreenShake({
    super.key,
    required this.child,
    required this.trigger,
    this.intensity = 8.0,
  });

  @override
  State<ScreenShake> createState() => _ScreenShakeState();
}

class _ScreenShakeState extends State<ScreenShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controller.addListener(_updateShake);
  }

  @override
  void didUpdateWidget(ScreenShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  void _updateShake() {
    if (_controller.isAnimating) {
      final decay = 1.0 - _controller.value;
      setState(() {
        _offset = Offset(
          (_random.nextDouble() - 0.5) * 2 * widget.intensity * decay,
          (_random.nextDouble() - 0.5) * 2 * widget.intensity * decay,
        );
      });
    } else {
      if (_offset != Offset.zero) {
        setState(() {
          _offset = Offset.zero;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateShake);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _offset,
      child: widget.child,
    );
  }
}

/// 게임 전환 애니메이션 (슬라이드 인)
class GameTransition extends StatefulWidget {
  final Widget child;
  final String gameEmoji;
  final String gameTitle;

  const GameTransition({
    super.key,
    required this.child,
    required this.gameEmoji,
    required this.gameTitle,
  });

  @override
  State<GameTransition> createState() => _GameTransitionState();
}

class _GameTransitionState extends State<GameTransition>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _gameController;
  late final Animation<double> _introScale;
  late final Animation<double> _introFade;
  late final Animation<double> _gameSlide;
  bool _showGame = false;

  @override
  void initState() {
    super.initState();

    // 인트로 애니메이션 (이모지 + 제목 표시)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _introScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _introController, curve: Curves.easeOut));

    _introFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeIn),
    );

    // 게임 등장 애니메이션
    _gameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _gameSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _gameController, curve: Curves.easeOutCubic),
    );

    // 시퀀스: 인트로 → 딜레이 → 게임
    _introController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() => _showGame = true);
          _gameController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showGame) {
      return AnimatedBuilder(
        animation: _gameController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              MediaQuery.of(context).size.width * _gameSlide.value,
              0,
            ),
            child: child,
          );
        },
        child: widget.child,
      );
    }

    // 인트로 화면
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _introController,
          builder: (context, child) {
            return Opacity(
              opacity: _introFade.value,
              child: Transform.scale(
                scale: _introScale.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.gameEmoji,
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),
              Text(
                widget.gameTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      offset: Offset(2, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 콤보 화염 이펙트 (HUD 옆에 표시)
class ComboFireEffect extends StatelessWidget {
  final int comboCount;

  const ComboFireEffect({super.key, required this.comboCount});

  @override
  Widget build(BuildContext context) {
    if (comboCount < 2) return const SizedBox.shrink();

    final fireSize = (comboCount * 4.0).clamp(16.0, 40.0);
    final fireEmoji = comboCount >= 10
        ? '🌋'
        : comboCount >= 7
            ? '💥'
            : comboCount >= 4
                ? '🔥'
                : '✨';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(fireEmoji, style: TextStyle(fontSize: fireSize)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: comboCount >= 7
                    ? [const Color(0xFFFF0000), const Color(0xFFFF6B00)]
                    : comboCount >= 4
                        ? [const Color(0xFFFF6B00), const Color(0xFFFFD700)]
                        : [const Color(0xFFFFD700), const Color(0xFFFFF176)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              '×$comboCount',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 난이도 표시 위젯
class DifficultyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const DifficultyBadge({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// 펄스 글로우 효과 (버튼 등에 사용)
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxRadius;

  const PulseGlow({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFFFD700),
    this.maxRadius = 20,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.3 + _controller.value * 0.4),
                blurRadius: widget.maxRadius * _controller.value,
                spreadRadius: widget.maxRadius * 0.3 * _controller.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
