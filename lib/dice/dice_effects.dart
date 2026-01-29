import 'dart:math';
import 'package:flutter/material.dart';

class DiceEffectsOverlay extends StatefulWidget {
  final List<EffectEvent> events;
  final VoidCallback onClearEvents;

  const DiceEffectsOverlay({
    super.key,
    required this.events,
    required this.onClearEvents,
  });

  @override
  State<DiceEffectsOverlay> createState() => _DiceEffectsOverlayState();
}

class _DiceEffectsOverlayState extends State<DiceEffectsOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<Widget> _activeEffects = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
      setState(() {});
    });
    _controller.repeat(); // Keep running for particle updates
  }

  @override
  void didUpdateWidget(DiceEffectsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events.isNotEmpty) {
      _processEvents();
      widget.onClearEvents();
    }
  }

  void _processEvents() {
    for (final event in widget.events) {
      if (event is ExplosionEvent) {
        _addExplosion(event);
      } else if (event is TextPopupEvent) {
        _addTextPopup(event);
      }
    }
  }

  void _addExplosion(ExplosionEvent event) {
    final key = UniqueKey();
    // Simple particle system
    final particles = List.generate(20, (i) {
      final random = Random();
      final angle = random.nextDouble() * 2 * pi;
      final speed = random.nextDouble() * 100 + 50;
      return _Particle(
        position: event.position,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: event.color,
        size: random.nextDouble() * 8 + 4,
      );
    });

    _activeEffects.add(
      _ParticleEffectWidget(
        key: key,
        particles: particles,
        duration: const Duration(milliseconds: 800),
        onFinished: () {
          setState(() {
            _activeEffects.removeWhere((w) => w.key == key);
          });
        },
      ),
    );
  }

  void _addTextPopup(TextPopupEvent event) {
    final key = UniqueKey();
    _activeEffects.add(
      _TextPopupWidget(
        key: key,
        text: event.text,
        position: event.position,
        color: event.color,
        fontSize: event.fontSize,
        onFinished: () {
          setState(() {
            _activeEffects.removeWhere((w) => w.key == key);
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: _activeEffects,
      ),
    );
  }
}

// --- Event Classes ---

abstract class EffectEvent {}

class ExplosionEvent extends EffectEvent {
  final Offset position;
  final Color color;
  ExplosionEvent(this.position, this.color);
}

class TextPopupEvent extends EffectEvent {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  TextPopupEvent(this.text, this.position, this.color, {this.fontSize = 24});
}

// --- Internal Widgets ---

class _Particle {
  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double life = 1.0;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
  });

  void update(double dt) {
    position += velocity * dt;
    velocity += Offset(0, 200 * dt); // Gravity
    life -= dt * 1.5; // Decay
  }
}

class _ParticleEffectWidget extends StatefulWidget {
  final List<_Particle> particles;
  final Duration duration;
  final VoidCallback onFinished;

  const _ParticleEffectWidget({
    super.key,
    required this.particles,
    required this.duration,
    required this.onFinished,
  });

  @override
  State<_ParticleEffectWidget> createState() => _ParticleEffectWidgetState();
}

class _ParticleEffectWidgetState extends State<_ParticleEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _lastFrameTime = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _controller.forward().whenComplete(widget.onFinished);
    _controller.addListener(_updateParticles);
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
  }

  void _updateParticles() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = (now - _lastFrameTime) / 1000.0;
    _lastFrameTime = now;

    if (dt > 0.1) return; // Prevent huge jumps

    setState(() {
      for (var p in widget.particles) {
        p.update(dt);
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
    return CustomPaint(
      painter: _ParticlePainter(widget.particles),
      size: Size.infinite,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      if (p.life <= 0) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.size * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

class _TextPopupWidget extends StatefulWidget {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  final VoidCallback onFinished;

  const _TextPopupWidget({
    super.key,
    required this.text,
    required this.position,
    required this.color,
    this.fontSize = 24,
    required this.onFinished,
  });

  @override
  State<_TextPopupWidget> createState() => _TextPopupWidgetState();
}

class _TextPopupWidgetState extends State<_TextPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _offset = Tween<Offset>(
            begin: widget.position, end: widget.position - const Offset(0, 100))
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
    
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
    ]).animate(_controller);

    _controller.forward().whenComplete(widget.onFinished);
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
          left: _offset.value.dx - 100, // Center approx
          top: _offset.value.dy,
          width: 200,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w900,
                    color: widget.color,
                    shadows: [
                      Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(2, 2),
                          blurRadius: 4),
                      Shadow(
                          color: widget.color.withValues(alpha: 0.8),
                          blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
