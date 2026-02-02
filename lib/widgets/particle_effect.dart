import 'dart:math';
import 'package:flutter/material.dart';

/// 파티클 효과를 위한 위젯
class ParticleEffect extends StatefulWidget {
  final int particleCount;
  final Color color;
  final Duration duration;
  final double spread;

  const ParticleEffect({
    super.key,
    this.particleCount = 20,
    this.color = Colors.yellow,
    this.duration = const Duration(milliseconds: 1000),
    this.spread = 100,
  });

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _particles = List.generate(widget.particleCount, (index) {
      final angle = (_random.nextDouble() * 2 * pi);
      final velocity = _random.nextDouble() * widget.spread;
      return Particle(
        angle: angle,
        velocity: velocity,
        size: _random.nextDouble() * 4 + 2,
        color: widget.color,
      );
    });

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    });
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
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  final double angle;
  final double velocity;
  final double size;
  final Color color;

  Particle({
    required this.angle,
    required this.velocity,
    required this.size,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final distance = particle.velocity * progress;
      final x = center.dx + cos(particle.angle) * distance;
      final y = center.dy + sin(particle.angle) * distance;

      final opacity = 1.0 - progress;
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particle.size * (1 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 간단한 파티클 오버레이
class ParticleOverlay extends StatelessWidget {
  final Widget child;
  final bool showParticles;
  final Color particleColor;

  const ParticleOverlay({
    super.key,
    required this.child,
    this.showParticles = false,
    this.particleColor = Colors.yellow,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showParticles)
          Positioned.fill(
            child: IgnorePointer(
              child: ParticleEffect(
                color: particleColor,
                particleCount: 30,
                spread: 150,
              ),
            ),
          ),
      ],
    );
  }
}
