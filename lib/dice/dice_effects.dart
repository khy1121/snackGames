import 'dart:math';
import 'package:flutter/material.dart';

/// 화면 흔들림 효과 위젯
class ScreenShake extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double intensity;

  const ScreenShake({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.intensity = 5.0,
  });

  @override
  State<ScreenShake> createState() => ScreenShakeState();
}

class ScreenShakeState extends State<ScreenShake> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Random _random = Random();

  double _offsetX = 0;
  double _offsetY = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
        if (_controller.isAnimating) {
          setState(() {
            _offsetX = (_random.nextDouble() * 2 - 1) * widget.intensity * _animation.value;
            _offsetY = (_random.nextDouble() * 2 - 1) * widget.intensity * _animation.value;
          });
        } else {
          setState(() {
            _offsetX = 0;
            _offsetY = 0;
          });
        }
      });
  }

  void shake() {
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(_offsetX, _offsetY),
      child: widget.child,
    );
  }
}

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
      } else if (event is ShockwaveEvent) {
        _addShockwave(event);
      } else if (event is LightningEvent) {
        _addLightning(event);
      }
    }
  }

  void _addLightning(LightningEvent event) {
    final key = UniqueKey();
    _activeEffects.add(
      _LightningWidget(
        key: key,
        color: event.color,
        onFinished: () {
          setState(() {
            _activeEffects.removeWhere((w) => w.key == key);
          });
        },
      ),
    );
  }

  void _addShockwave(ShockwaveEvent event) {
    final key = UniqueKey();
    _activeEffects.add(
      _ShockwaveWidget(
        key: key,
        position: event.position,
        color: event.color,
        onFinished: () {
          setState(() {
            _activeEffects.removeWhere((w) => w.key == key);
          });
        },
      ),
    );
  }

  void _addExplosion(ExplosionEvent event) {
    final key = UniqueKey();
    // Simple particle system
    final count = event.isMagic ? 40 : 15;
    
    final particles = List.generate(count, (i) {
      final random = Random();
      final angle = random.nextDouble() * 2 * pi;
      // Magic explosions are faster and reach further
      final speed = random.nextDouble() * (event.isMagic ? 200 : 100) + 50; 
      
      return _Particle(
        position: event.position,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: event.isMagic 
            ? HSVColor.fromAHSV(1, (random.nextDouble() * 360), 1, 1).toColor() 
            : event.color,
        size: random.nextDouble() * (event.isMagic ? 12 : 6) + 3,
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
  final bool isMagic;
  
  ExplosionEvent(this.position, this.color, {this.isMagic = false});
}

class ShockwaveEvent extends EffectEvent {
  final Offset position;
  final Color color;
  
  ShockwaveEvent(this.position, this.color);
}

class LightningEvent extends EffectEvent {
  final Color color;
  LightningEvent({this.color = Colors.yellowAccent});
}

class TextPopupEvent extends EffectEvent {
  final String text;
  final Offset position;
  final Color color;
  final double fontSize;
  TextPopupEvent(this.text, this.position, this.color, {this.fontSize = 24});
}

// --- Internal Widgets ---

class _LightningWidget extends StatefulWidget {
  final Color color;
  final VoidCallback onFinished;

  const _LightningWidget({
    super.key,
    required this.color,
    required this.onFinished,
  });

  @override
  State<_LightningWidget> createState() => _LightningWidgetState();
}

class _LightningWidgetState extends State<_LightningWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
        return CustomPaint(
          size: Size.infinite,
          painter: _LightningPainter(widget.color, _controller.value),
        );
      },
    );
  }
}

class _LightningPainter extends CustomPainter {
  final Color color;
  final double progress;
  final Random _random = Random(123); // Consistent seed for jitter if needed, or variable

  _LightningPainter(this.color, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 1.0) return;
    
    final paint = Paint()
      ..color = color.withValues(alpha: 1.0 - progress) // Fade out
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Create detailed jagged lines
    // Top-Left to Bottom-Right
    _drawBolt(path, Offset.zero, Offset(size.width, size.height), 20);
    // Top-Right to Bottom-Left
    _drawBolt(path, Offset(size.width, 0), Offset(0, size.height), 20);
    
    canvas.drawPath(path, paint);
    
    // Flash effect
    if (progress < 0.2) {
      canvas.drawColor(Colors.white.withValues(alpha: (0.2 - progress) * 2), BlendMode.lighten);
    }
  }
  
  void _drawBolt(Path path, Offset start, Offset end, int segments) {
    path.moveTo(start.dx, start.dy);
    
    Offset current = start;
    final dx = (end.dx - start.dx) / segments;
    final dy = (end.dy - start.dy) / segments;
    
    // Re-seed for animation frame variance if desired, or keep consistent shape
    final random = Random(); 

    for (int i = 0; i < segments; i++) {
        final jitterX = (random.nextDouble() - 0.5) * 50;
        final jitterY = (random.nextDouble() - 0.5) * 50;
        
        final next = Offset(
           start.dx + dx * (i + 1) + jitterX,
           start.dy + dy * (i + 1) + jitterY
        );
        
        path.lineTo(next.dx, next.dy);
        current = next;
    }
    path.lineTo(end.dx, end.dy);
  }

  @override
  bool shouldRepaint(_LightningPainter oldDelegate) => true;
}


// --- Internal Widgets ---

class _ShockwaveWidget extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onFinished;

  const _ShockwaveWidget({
    super.key,
    required this.position,
    required this.color,
    required this.onFinished,
  });

  @override
  State<_ShockwaveWidget> createState() => _ShockwaveWidgetState();
}

class _ShockwaveWidgetState extends State<_ShockwaveWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radius;
  late Animation<double> _opacity;
  late Animation<double> _width;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    
    _radius = Tween<double>(begin: 0, end: 150).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    
    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _width = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

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
          left: widget.position.dx - _radius.value,
          top: widget.position.dy - _radius.value,
          width: _radius.value * 2,
          height: _radius.value * 2,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(alpha: _opacity.value),
                width: _width.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

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
