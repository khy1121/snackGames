import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'package:flutter/material.dart';



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

class MergeAnimationEvent extends EffectEvent {
  final List<Offset> fromPositions; // 합쳐지는 주사위들의 위치
  final Offset toPosition; // 합쳐지는 목표 위치
  final Color color;
  
  MergeAnimationEvent(this.fromPositions, this.toPosition, this.color);
}

class ScorePopupEvent extends EffectEvent {
  final int score;
  final Offset position;
  final bool isBig;
  
  ScorePopupEvent(this.score, this.position, {this.isBig = false});
}

class ComboIndicatorEvent extends EffectEvent {
  final int combo;
  final Offset position;
  
  ComboIndicatorEvent(this.combo, this.position);
}

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
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
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
    // Use AnimatedBuilder instead of setState for better performance
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!_controller.isAnimating) {
          return child!;
        }
        
        final intensity = widget.intensity * (1.0 - _controller.value);
        final offsetX = (_random.nextDouble() * 2 - 1) * intensity;
        final offsetY = (_random.nextDouble() * 2 - 1) * intensity;
        
        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class DiceEffectsOverlay extends StatefulWidget {
  final Stream<EffectEvent> eventStream;

  const DiceEffectsOverlay({
    super.key,
    required this.eventStream,
  });

  @override
  State<DiceEffectsOverlay> createState() => _DiceEffectsOverlayState();
}

class _DiceEffectsOverlayState extends State<DiceEffectsOverlay>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<_ActiveEffect> _activeEffects = [];
  Duration _lastElapsed = Duration.zero;
  late final StreamSubscription<EffectEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _subscription = widget.eventStream.listen(_addEffect);
  }

  @override
  void didUpdateWidget(DiceEffectsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventStream != widget.eventStream) {
      _subscription.cancel();
      _subscription = widget.eventStream.listen(_addEffect);
    }
  }

  void _addEffect(EffectEvent event) {
    if (event is ExplosionEvent) {
      _activeEffects.add(_ExplosionEffect(event.position, event.color, event.isMagic));
    } else if (event is TextPopupEvent) {
      _activeEffects.add(_TextPopupEffect(event.text, event.position, event.color, event.fontSize));
    } else if (event is ShockwaveEvent) {
      _activeEffects.add(_ShockwaveEffect(event.position, event.color));
    } else if (event is LightningEvent) {
      _activeEffects.add(_LightningEffect(event.color));
    } else if (event is MergeAnimationEvent) {
      _activeEffects.add(_MergeAnimationEffect(event.fromPositions, event.toPosition, event.color));
    } else if (event is ScorePopupEvent) {
      _activeEffects.add(_ScorePopupEffect(event.score, event.position, event.isBig));
    } else if (event is ComboIndicatorEvent) {
      _activeEffects.add(_ComboIndicatorEffect(event.combo, event.position));
    }
  }

  void _onTick(Duration elapsed) {
    if (_activeEffects.isEmpty) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Cap dt to prevent huge jumps (max 100ms)
    final safeDt = dt > 0.1 ? 0.1 : dt;

    // Throttle updates to 30fps for effects (every ~33ms)
    if (safeDt > 0 && safeDt >= 0.016) {
      setState(() {
        _activeEffects.removeWhere((effect) => !effect.update(safeDt));
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild when effects list changes
    if (_activeEffects.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          painter: _EffectsPainter(_activeEffects),
        ),
      ),
    );
  }
}

class _EffectsPainter extends CustomPainter {
  final List<_ActiveEffect> effects;

  _EffectsPainter(this.effects);

  @override
  void paint(Canvas canvas, Size size) {
    for (final effect in effects) {
      effect.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(_EffectsPainter oldDelegate) {
    // Only repaint if effects count changed or always repaint if effects exist
    return effects.isNotEmpty;
  }
}

// --- Active Effect Classes (Optimized) ---

abstract class _ActiveEffect {
  /// Updates state. Returns false if effect is finished.
  bool update(double dt);
  void draw(Canvas canvas, Size size);
}

class _ExplosionEffect extends _ActiveEffect {
  final List<_Particle> particles;
  
  _ExplosionEffect(Offset position, Color color, bool isMagic) 
      : particles = List.generate(isMagic ? 20 : 8, (_) {
          final random = Random();
          final angle = random.nextDouble() * 2 * pi;
          final speed = random.nextDouble() * (isMagic ? 200 : 100) + 50;
          final pColor = isMagic
              ? HSVColor.fromAHSV(1, (random.nextDouble() * 360), 1, 1).toColor()
              : color;
          return _Particle(
            position: position,
            velocity: Offset(cos(angle) * speed, sin(angle) * speed),
            color: pColor,
            size: random.nextDouble() * (isMagic ? 12 : 6) + 3,
            life: 1.0, 
          );
        });

  @override
  bool update(double dt) {
    bool anyAlive = false;
    for (final p in particles) {
      if (p.life > 0) {
        p.position += p.velocity * dt;
        p.velocity += Offset(0, 200 * dt); // Gravity
        p.life -= dt * 1.5; // Decay
        if (p.life > 0) anyAlive = true;
      }
    }
    return anyAlive;
  }

  @override
  void draw(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.size * p.life, paint);
    }
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double life;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.life,
  });
}

class _TextPopupEffect extends _ActiveEffect {
  final String text;
  final Offset startPos;
  final Color color;
  final double fontSize;
  double time = 0;
  final double duration = 0.8; // 짧게 조정
  
  // Cache the painter
  late final TextPainter _textPainter;

  _TextPopupEffect(this.text, this.startPos, this.color, this.fontSize) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: color,
        // Shadows removed for emulator performance
      ),
    );

    _textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    _textPainter.layout();
  }

  @override
  bool update(double dt) {
    time += dt;
    // Fade out color opacity in draw, not here
    return time < duration;
  }

  @override
  void draw(Canvas canvas, Size size) {
    final progress = time / duration;
    final opacity = ((progress > 0.5) ? (1.0 - progress) * 2 : 1.0).clamp(0.0, 1.0);
    
    // Scale effect
    final scale = (progress < 0.2) ? progress * 6 : (progress < 0.4 ? 1.2 : 1.0); 

    if (opacity <= 0) return;

    final offset = startPos - Offset(0, 100 * (1 - pow(1 - progress, 2).toDouble()));

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale, scale);
    
    // Use saveLayer with alpha for efficient fading without recreating TextPainter
    if (opacity < 1.0) {
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(255, 255, 255, opacity));
    }
    
    _textPainter.paint(canvas, Offset(-_textPainter.width / 2, -_textPainter.height / 2));
    
    if (opacity < 1.0) {
      canvas.restore();
    }

    canvas.restore();
  }
}

class _ShockwaveEffect extends _ActiveEffect {
  final Offset position;
  final Color color;
  double time = 0;
  final double duration = 0.5; // 빠르게

  _ShockwaveEffect(this.position, this.color);

  @override
  bool update(double dt) {
    time += dt;
    return time < duration;
  }

  @override
  void draw(Canvas canvas, Size size) {
    final progress = time / duration;
    final radius = 150 * pow(progress, 0.25).toDouble(); // easeOutQuart approx
    final opacity = (1.0 - progress).clamp(0.0, 1.0); // easeOut approx
    final width = 20 * (1.0 - progress);

    if (opacity <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    canvas.drawCircle(position, radius, paint);
  }
}

class _MergeAnimationEffect extends _ActiveEffect {
  final List<Offset> fromPositions;
  final Offset toPosition;
  final Color color;
  double time = 0;
  final double duration = 0.35; // 빠르게 빨려들어가기
  
  _MergeAnimationEffect(this.fromPositions, this.toPosition, this.color);
  
  @override
  bool update(double dt) {
    time += dt;
    return time < duration;
  }
  
  @override
  void draw(Canvas canvas, Size size) {
    final progress = (time / duration).clamp(0.0, 1.0);
    final easedProgress = Curves.easeInCubic.transform(progress);
    
    final paint = Paint()
      ..color = color.withValues(alpha: (1.0 - progress) * 0.6)
      ..style = PaintingStyle.fill;
    
    // 각 주사위가 목표 위치로 빨려들어가는 효과
    for (final from in fromPositions) {
      final currentX = from.dx + (toPosition.dx - from.dx) * easedProgress;
      final currentY = from.dy + (toPosition.dy - from.dy) * easedProgress;
      final size = 30 * (1.0 - easedProgress); // 작아지면서 이동
      
      canvas.drawCircle(Offset(currentX, currentY), size, paint);
      
      // 궤적 라인
      final linePaint = Paint()
        ..color = color.withValues(alpha: (1.0 - progress) * 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(from, Offset(currentX, currentY), linePaint);
    }
  }
}

class _ScorePopupEffect extends _ActiveEffect {
  final int score;
  final Offset position;
  final bool isBig;
  double time = 0;
  final double duration = 0.8; // 짧게
  
  _ScorePopupEffect(this.score, this.position, this.isBig);
  
  @override
  bool update(double dt) {
    time += dt;
    return time < duration;
  }
  
  @override
  void draw(Canvas canvas, Size size) {
    final progress = (time / duration).clamp(0.0, 1.0);
    final y = position.dy - (50 * progress); // 위로 떠오름
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final scale = 1.0 + (progress * 0.5); // 커지면서 사라짐
    
    final textStyle = TextStyle(
      color: Colors.yellow.withValues(alpha: opacity),
      fontSize: (isBig ? 36 : 24) * scale,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          blurRadius: 10,
          color: Colors.black.withValues(alpha: opacity * 0.5),
          offset: const Offset(2, 2),
        ),
      ],
    );
    
    final textSpan = TextSpan(
      text: '+$score',
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, y),
    );
  }
}

class _ComboIndicatorEffect extends _ActiveEffect {
  final int combo;
  final Offset position;
  double time = 0;
  final double duration = 0.7; // 빠르게
  
  _ComboIndicatorEffect(this.combo, this.position);
  
  @override
  bool update(double dt) {
    time += dt;
    return time < duration;
  }
  
  @override
  void draw(Canvas canvas, Size size) {
    final progress = (time / duration).clamp(0.0, 1.0);
    final opacity = progress < 0.2 
        ? progress / 0.2 
        : progress > 0.6 
            ? (1.0 - (progress - 0.6) / 0.4) 
            : 1.0;
    final scale = 0.5 + (progress < 0.2 ? progress / 0.2 * 0.5 : 0.5);
    
    // 콤보 배경
    final bgPaint = Paint()
      ..color = Colors.orange.withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: position,
          width: 120 * scale,
          height: 50 * scale,
        ),
        const Radius.circular(25),
      ),
      bgPaint,
    );
    
    // 콤보 텍스트
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: opacity),
      fontSize: 24 * scale,
      fontWeight: FontWeight.bold,
    );
    
    final textSpan = TextSpan(
      text: '${combo}x COMBO!',
      style: textStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }
}

class _LightningEffect extends _ActiveEffect {
  final Color color;
  double time = 0;
  final double duration = 0.35; // 빠르게
  final Random _random = Random();
  
  // Fix late initialization
  List<Offset>? _points1;
  List<Offset>? _points2;

  _LightningEffect(this.color);

  @override
  bool update(double dt) {
    time += dt;
    return time < duration;
  }

  // Pre-calculate bolts when needed (lazy init or in draw if null)
  List<Offset> _generateBolt(Offset start, Offset end, int segments) {
    final points = <Offset>[start];
    final dx = (end.dx - start.dx) / segments;
    final dy = (end.dy - start.dy) / segments;
    
    for (int i = 1; i < segments; i++) {
        final jitterX = (_random.nextDouble() - 0.5) * 50;
        final jitterY = (_random.nextDouble() - 0.5) * 50;
        points.add(Offset(
           start.dx + dx * i + jitterX,
           start.dy + dy * i + jitterY
        ));
    }
    points.add(end);
    return points;
  }

  @override
  void draw(Canvas canvas, Size size) {
    if (time >= duration) return;

    _points1 ??= _generateBolt(Offset.zero, Offset(size.width, size.height), 10);
    _points2 ??= _generateBolt(Offset(size.width, 0), Offset(0, size.height), 10);

    final progress = time / duration;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Path 1
    if (_points1 != null) {
      path.moveTo(_points1![0].dx, _points1![0].dy);
      for (int i=1; i<_points1!.length; i++) path.lineTo(_points1![i].dx, _points1![i].dy);
    }
    // Path 2
    if (_points2 != null) {
      path.moveTo(_points2![0].dx, _points2![0].dy);
      for (int i=1; i<_points2!.length; i++) path.lineTo(_points2![i].dx, _points2![i].dy);
    }
    
    canvas.drawPath(path, paint);
    
    // Flash background
    if (progress < 0.2) {
       canvas.drawColor(Colors.white.withValues(alpha: (0.2 - progress) * 2), BlendMode.srcOver);
    }
  }
}
