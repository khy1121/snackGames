import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'core/microgame_effects.dart';
import '../services/vibration_service.dart';
import '../services/game_data_service.dart';

class SwipeBrickBreakerPage extends StatefulWidget {
  const SwipeBrickBreakerPage({super.key});

  @override
  State<SwipeBrickBreakerPage> createState() => _SwipeBrickBreakerPageState();
}

enum GameState { idle, aiming, playing, gameOver }

class Brick {
  Rect rect;
  int health;
  final int initialHealth;
  final Color color;

  Brick({
    required this.rect,
    required this.health,
    required this.initialHealth,
    required this.color,
  });
}

class Ball {
  Offset position;
  Offset velocity;
  bool active;
  bool isRecovered;

  Ball({
    required this.position,
    required this.velocity,
    this.active = false,
    this.isRecovered = false,
  });
}

class _SwipeBrickBreakerPageState extends State<SwipeBrickBreakerPage>
    with TickerProviderStateMixin {
  
  // Game Configuration
  static const int columns = 7;
  static const double brickSpacing = 4.0;
  static const double ballRadius = 6.0;
  static const double ballSpeedFactor = 15.0; // Higher = faster
  
  // Current State
  GameState _gameState = GameState.idle;
  int _score = 0;
  int _bestScore = 0;
  int _round = 1;
  int _ballsCount = 1;
  int _recoveredBalls = 0;
  
  // Physics and Objects
  List<Brick> _bricks = [];
  List<Ball> _balls = [];
  Offset _launcherPos = Offset.zero;
  Offset? _firstRecoveredPos;
  
  // Interaction
  Offset? _dragStart;
  Offset? _dragCurrent;
  
  // Dimensions
  Size _gameAreaSize = Size.zero;
  double _brickWidth = 0;
  double _brickHeight = 0;

  // Effects
  bool _shakeTrigger = false;
  final List<ParticleData> _particles = [];
  
  // Loop
  late AnimationController _ticker;
  double _lastTime = 0.0;
  int _ballsFired = 0;
  double _fireTimer = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    
    _loadBestScore();
  }
  
  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final best = GameDataService.getBestScore('microgame_rush'); // Repurposing microgame_rush key
    setState(() {
      _bestScore = best;
    });
  }

  void _saveBestScore() {
    if (_score > _bestScore) {
      _bestScore = _score;
      GameDataService.setMicroGameRushScore(_score);
    }
  }

  void _initializeGame(Size size) {
    if (_gameState != GameState.idle && _gameState != GameState.gameOver) return;
    
    _gameAreaSize = size;
    _brickWidth = (size.width - (brickSpacing * (columns + 1))) / columns;
    _brickHeight = _brickWidth * 0.8;
    
    _launcherPos = Offset(size.width / 2, size.height - ballRadius - 10);
    
    _score = 0;
    _round = 1;
    _ballsCount = 1;
    _bricks.clear();
    _balls.clear();
    _particles.clear();
    
    _spawnRow();
    setState(() {
      _gameState = GameState.idle;
    });
  }

  void _spawnRow() {
    final yPos = brickSpacing;
    final random = math.Random();
    
    // Add 1 ball powerup logic if needed, simplify by giving 1 ball per round automatically
    _ballsCount++;
    
    for (int c = 0; c < columns; c++) {
      // 50% chance to spawn a brick
      if (random.nextDouble() > 0.5) {
        final xPos = brickSpacing + c * (_brickWidth + brickSpacing);
        final health = _round + (random.nextDouble() * 2).toInt();
        
        // Pick color based on health
        final hue = (health * 15) % 360.0;
        final color = HSLColor.fromAHSL(1.0, hue, 0.8, 0.6).toColor();
        
        _bricks.add(Brick(
          rect: Rect.fromLTWH(xPos, yPos, _brickWidth, _brickHeight),
          health: health,
          initialHealth: health,
          color: color,
        ));
      }
    }
  }

  void _handlePanStart(DragDownDetails details) {
    if (_gameState != GameState.idle) return;
    final pos = details.localPosition;
    
    // Allow dragging anywhere on screen
    setState(() {
      _gameState = GameState.aiming;
      _dragStart = pos;
      _dragCurrent = pos;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_gameState != GameState.aiming) return;
    setState(() {
      _dragCurrent = details.localPosition;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_gameState != GameState.aiming) return;
    
    if (_dragStart != null && _dragCurrent != null) {
      final  delta = _dragCurrent! - _dragStart!;
      if (delta.distance > 20 && delta.dy > 0) {
        // Shoot! The balls go OPPOSITE of the drag (drag down = shoot up)
        _shoot(-delta);
        return;
      }
    }
    
    setState(() {
      _gameState = GameState.idle;
    });
  }

  void _shoot(Offset direction) {
    final norm = direction / direction.distance;
    final velocity = norm * ballSpeedFactor;
    
    _balls = List.generate(_ballsCount, (i) => Ball(
      position: _launcherPos,
      velocity: velocity,
      active: false,
    ));
    
    _ballsFired = 0;
    _fireTimer = 0.0;
    _lastTime = 0.0;
    _firstRecoveredPos = null;
    _recoveredBalls = 0;
    
    setState(() {
      _gameState = GameState.playing;
    });
    
    _ticker.repeat();
  }

  void _updatePhysics() {
    final dt = _ticker.value - _lastTime;
    _lastTime = _ticker.value;
    
    // The physics step. For very high speeds, step smaller increments to prevent passing through bricks
    const int physicsSteps = 4;
    final stepDt = 0.016 / physicsSteps; // Approx standard frame time
    
    setState(() {
      // Manage firing
      _fireTimer += 0.016;
      if (_ballsFired < _ballsCount && _fireTimer > 0.05) {
        _balls[_ballsFired].active = true;
        _ballsFired++;
        _fireTimer = 0.0;
        VibrationService.light(); // Small tick when firing
      }

      bool blockHitThisFrame = false;

      // Update balls
      for (var ball in _balls) {
        if (!ball.active || ball.isRecovered) continue;
        
        for (int step = 0; step < physicsSteps; step++) {
          ball.position += ball.velocity * stepDt;
          
          // Wall Collisions
          if (ball.position.dx <= ballRadius) {
            ball.position = Offset(ballRadius, ball.position.dy);
            ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
          } else if (ball.position.dx >= _gameAreaSize.width - ballRadius) {
            ball.position = Offset(_gameAreaSize.width - ballRadius, ball.position.dy);
            ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
          }
          
          if (ball.position.dy <= ballRadius) {
            ball.position = Offset(ball.position.dx, ballRadius);
            ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
          }
          
          // Bottom Collision (Recover)
          if (ball.position.dy >= _gameAreaSize.height - ballRadius) {
            ball.isRecovered = true;
            _firstRecoveredPos ??= Offset(ball.position.dx.clamp(ballRadius, _gameAreaSize.width - ballRadius), _gameAreaSize.height - ballRadius - 10);
            _recoveredBalls++;
            break; // Stop stepping this ball
          }
          
          // Brick Collisions
          bool bounced = false;
          for (int i = 0; i < _bricks.length; i++) {
            final brick = _bricks[i];
            if (brick.health > 0) {
              final hit = _checkCollision(ball, brick.rect);
              if (hit != null) {
                ball.velocity = _reflect(ball.velocity, hit);
                brick.health--;
                _score++;
                bounced = true;
                blockHitThisFrame = true;
                
                if (brick.health <= 0) {
                  _spawnParticles(brick.rect.center, brick.color);
                  VibrationService.medium();
                }
              }
            }
          }
          if (bounced) break; // Only bounce once per substep
        }
      }
      
      if (blockHitThisFrame) {
        _triggerShake();
        if (_score % 10 != 0) { // Throttle heavy vibration
           // VibrationService.light();
        }
      }

      // Remove dead bricks
      _bricks.removeWhere((b) => b.health <= 0);
      
      // Update particles
      _particles.removeWhere((p) {
        p.update(0.016);
        return p.life <= 0;
      });

      // Check Turn Over
      if (_recoveredBalls == _ballsCount) {
        _endTurn();
      }
    });
  }

  void _triggerShake() {
    _shakeTrigger = true;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _shakeTrigger = false);
    });
  }

  void _spawnParticles(Offset pos, Color color) {
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = random.nextDouble() * 150 + 50;
      _particles.add(ParticleData(
        position: pos,
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        color: color,
        life: 0.5 + random.nextDouble() * 0.5,
        maxLife: 1.0,
      ));
    }
  }

  Offset? _checkCollision(Ball ball, Rect rect) {
    // Closest point on rect
    final testX = ball.position.dx.clamp(rect.left, rect.right);
    final testY = ball.position.dy.clamp(rect.top, rect.bottom);
    
    final distSq = math.pow(ball.position.dx - testX, 2) + math.pow(ball.position.dy - testY, 2);
    
    if (distSq <= ballRadius * ballRadius) {
      // Collision normal
      if (testX == rect.left || testX == rect.right) {
        return Offset(ball.position.dx > rect.center.dx ? 1 : -1, 0); // Horizontal normal
      } else {
        return Offset(0, ball.position.dy > rect.center.dy ? 1 : -1); // Vertical normal
      }
    }
    return null;
  }

  Offset _reflect(Offset velocity, Offset normal) {
    final dot = velocity.dx * normal.dx + velocity.dy * normal.dy;
    return Offset(
      velocity.dx - 2 * dot * normal.dx,
      velocity.dy - 2 * dot * normal.dy,
    );
  }

  void _endTurn() {
    _ticker.stop();
    _launcherPos = _firstRecoveredPos ?? _launcherPos;
    _round++;
    
    // Move bricks down
    bool gameOver = false;
    for (var brick in _bricks) {
      brick.rect = brick.rect.translate(0, _brickHeight + brickSpacing);
      if (brick.rect.bottom >= _gameAreaSize.height - ballRadius * 2 - 20) {
        gameOver = true;
      }
    }
    
    if (gameOver) {
      _saveBestScore();
      VibrationService.heavy();
      _gameState = GameState.gameOver;
    } else {
      _spawnRow();
      _gameState = GameState.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: GestureDetector(
                onPanDown: (d) => _handlePanStart(d),
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3D),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (_gameAreaSize != Size(constraints.maxWidth, constraints.maxHeight)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _initializeGame(Size(constraints.maxWidth, constraints.maxHeight));
                          });
                        }
                        return Stack(
                          children: [
                            CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: BrickBreakerPainter(
                                bricks: _bricks,
                                balls: _balls,
                                gameState: _gameState,
                                dragStart: _dragStart,
                                dragCurrent: _dragCurrent,
                                launcherPos: _launcherPos,
                                ballRadius: ballRadius,
                                particles: _particles,
                                ballsAtLauncher: _ballsCount - _recoveredBalls,
                              ),
                            ),
                            if (_gameState == GameState.gameOver) _buildGameOverOverlay(),
                            if (_shakeTrigger)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 1.0, end: 0.0),
                                    duration: const Duration(milliseconds: 100),
                                    builder: (context, value, child) {
                                      final dx = (math.Random().nextDouble() - 0.5) * 8 * value;
                                      final dy = (math.Random().nextDouble() - 0.5) * 8 * value;
                                      return Transform.translate(
                                        offset: Offset(dx, dy),
                                        child: Container(), // Empty, but triggers rebuild
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              const Text('SCORE', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$_score', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('BEST', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$_bestScore', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('GAME OVER', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 4)),
            const SizedBox(height: 20),
            Text('Score: $_score', style: const TextStyle(color: Colors.white70, fontSize: 20)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _initializeGame(_gameAreaSize),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('RETRY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class BrickBreakerPainter extends CustomPainter {
  final List<Brick> bricks;
  final List<Ball> balls;
  final GameState gameState;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final Offset launcherPos;
  final double ballRadius;
  final List<ParticleData> particles;
  final int ballsAtLauncher;

  BrickBreakerPainter({
    required this.bricks,
    required this.balls,
    required this.gameState,
    this.dragStart,
    this.dragCurrent,
    required this.launcherPos,
    required this.ballRadius,
    required this.particles,
    required this.ballsAtLauncher,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Aiming Line
    if (gameState == GameState.aiming && dragStart != null && dragCurrent != null) {
      final delta = dragCurrent! - dragStart!;
      if (delta.distance > 10 && delta.dy > 0) {
        final direction = -delta / delta.distance;
        
        final paint = Paint()
          ..color = Colors.white24
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
          
        var p1 = launcherPos;
        for (int i=0; i<15; i++) {
          var p2 = p1 + direction * 20;
          canvas.drawLine(p1, p1 + direction * 10, paint);
          p1 = p2;
        }
      }
    }

    // 2. Draw Bricks
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (var brick in bricks) {
      // Shadows
      final rRect = RRect.fromRectAndRadius(brick.rect, const Radius.circular(8));
      canvas.drawRRect(rRect, Paint()..color = brick.color.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      
      // Main Brick
      canvas.drawRRect(rRect, Paint()..color = brick.color);
      
      // Inner highlight
      canvas.drawRRect(
        RRect.fromRectAndRadius(brick.rect.deflate(2), const Radius.circular(6)),
        Paint()..style = PaintingStyle.stroke..color = Colors.white.withValues(alpha: 0.3)..strokeWidth = 1,
      );

      // Value Text
      textPainter.text = TextSpan(
        text: '${brick.health}',
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(brick.rect.center.dx - textPainter.width / 2, brick.rect.center.dy - textPainter.height / 2),
      );
    }

    // 3. Draw Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      particlePaint.color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0));
      canvas.drawCircle(p.position, 3.0 * (p.life / p.maxLife), particlePaint);
    }

    // 4. Draw Balls
    final ballPaint = Paint()..color = const Color(0xFF00D2D3);
    final glowPaint = Paint()
      ..color = const Color(0xFF00D2D3).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    if (gameState == GameState.playing) {
      for (var ball in balls) {
        if (ball.active && !ball.isRecovered) {
          canvas.drawCircle(ball.position, ballRadius + 2, glowPaint);
          canvas.drawCircle(ball.position, ballRadius, ballPaint);
        }
      }
    }

    // 5. Draw Launcher (Remaining Balls)
    if (gameState == GameState.idle || gameState == GameState.aiming || ballsAtLauncher > 0) {
      canvas.drawCircle(launcherPos, ballRadius + 2, glowPaint);
      canvas.drawCircle(launcherPos, ballRadius, ballPaint);
      
      textPainter.text = TextSpan(
        text: 'x$ballsAtLauncher',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(launcherPos.dx - textPainter.width / 2, launcherPos.dy + ballRadius + 4));
    }
  }

  @override
  bool shouldRepaint(covariant BrickBreakerPainter oldDelegate) => true;
}

class ParticleData {
  Offset position;
  Offset velocity;
  Color color;
  double life;
  double maxLife;

  ParticleData({
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
    required this.maxLife,
  });

  void update(double dt) {
    position += velocity * dt;
    life -= dt;
  }
}
