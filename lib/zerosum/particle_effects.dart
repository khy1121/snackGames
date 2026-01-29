import 'dart:math';
import 'package:flutter/material.dart';

/// 파티클 데이터
class Particle {
  Offset position;
  Offset velocity;
  double size;
  double life;
  Color color;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.life,
    required this.color,
  });
}

/// 폭발 파티클 시스템
class ExplosionParticles extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback? onComplete;
  
  const ExplosionParticles({
    super.key,
    required this.position,
    required this.color,
    this.onComplete,
  });
  
  @override
  State<ExplosionParticles> createState() => _ExplosionParticlesState();
}

class _ExplosionParticlesState extends State<ExplosionParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    _generateParticles();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _controller.addListener(() => setState(() {}));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    
    _controller.forward();
  }
  
  void _generateParticles() {
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi + _random.nextDouble() * 0.5;
      final speed = 80 + _random.nextDouble() * 60;
      
      _particles.add(Particle(
        position: widget.position,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        size: 4 + _random.nextDouble() * 4,
        life: 1.0,
        color: widget.color.withValues(alpha: 0.8 + _random.nextDouble() * 0.2),
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
    return CustomPaint(
      painter: _ParticlePainter(
        particles: _particles,
        progress: _controller.value,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  
  _ParticlePainter({required this.particles, required this.progress});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final currentPos = particle.position + particle.velocity * progress;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final currentSize = particle.size * (1.0 - progress * 0.5);
      
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(currentPos, currentSize, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// 글로우 이펙트
class GlowEffect extends StatefulWidget {
  final Offset center;
  final double size;
  final Color color;
  final VoidCallback? onComplete;
  
  const GlowEffect({
    super.key,
    required this.center,
    required this.size,
    required this.color,
    this.onComplete,
  });
  
  @override
  State<GlowEffect> createState() => _GlowEffectState();
}

class _GlowEffectState extends State<GlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    
    _controller.forward();
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
        final progress = _controller.value;
        final scale = 1.0 + progress * 0.8;
        final opacity = (1.0 - progress).clamp(0.0, 1.0);
        
        return CustomPaint(
          painter: _GlowPainter(
            center: widget.center,
            size: widget.size * scale,
            color: widget.color.withValues(alpha: opacity * 0.6),
          ),
        );
      },
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Offset center;
  final double size;
  final Color color;
  
  _GlowPainter({
    required this.center,
    required this.size,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: size));
    
    canvas.drawCircle(center, size, paint);
  }
  
  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => true;
}

/// 날아가는 점수 텍스트
class FlyingScoreText extends StatefulWidget {
  final int score;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback? onComplete;
  
  const FlyingScoreText({
    super.key,
    required this.score,
    required this.startPosition,
    required this.endPosition,
    this.onComplete,
  });
  
  @override
  State<FlyingScoreText> createState() => _FlyingScoreTextState();
}

class _FlyingScoreTextState extends State<FlyingScoreText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _positionAnimation = Tween<Offset>(
      begin: widget.startPosition,
      end: widget.endPosition,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.8), weight: 70),
    ]).animate(_controller);
    
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    
    _controller.forward();
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
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Text(
                '+${widget.score}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  shadows: [
                    Shadow(
                      color: Colors.orange.withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                    const Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 착지 리플 이펙트
class LandingRipple extends StatefulWidget {
  final Offset center;
  final double maxRadius;
  final Color color;
  final VoidCallback? onComplete;
  
  const LandingRipple({
    super.key,
    required this.center,
    required this.maxRadius,
    required this.color,
    this.onComplete,
  });
  
  @override
  State<LandingRipple> createState() => _LandingRippleState();
}

class _LandingRippleState extends State<LandingRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    
    _controller.forward();
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
        final progress = _controller.value;
        final radius = widget.maxRadius * progress;
        final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.5;
        
        return CustomPaint(
          painter: _RipplePainter(
            center: widget.center,
            radius: radius,
            color: widget.color.withValues(alpha: opacity),
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;
  
  _RipplePainter({
    required this.center,
    required this.radius,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(center, radius, paint);
  }
  
  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
}

/// 화면 흔들림 위젯
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  final double intensity;
  
  const ShakeWidget({
    super.key,
    required this.child,
    this.shake = false,
    this.intensity = 2.0,
  });
  
  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1, end: -1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -1, end: 0), weight: 25),
    ]).animate(_controller);
  }
  
  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
    }
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
          offset: Offset(_shakeAnimation.value * widget.intensity, 0),
          child: widget.child,
        );
      },
    );
  }
}
