import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'zerosum_board.dart';
import 'zerosum_theme.dart';
import 'block_widget.dart';
import 'particle_effects.dart';
import '../services/game_data_service.dart';

/// 발사체 클래스
class Projectile {
  Offset position;
  Offset velocity;
  final BlockValue value;
  final double radius;

  Projectile({
    required this.position,
    required this.velocity,
    required this.value,
    required this.radius,
  });

  void update(double dt) {
    position += velocity * dt;
  }
}

/// Zero Sum 게임 메인 페이지 (Puzzle Bobble Style)
class ZeroSumPage extends StatefulWidget {
  const ZeroSumPage({super.key});

  @override
  State<ZeroSumPage> createState() => _ZeroSumPageState();
}

class _ZeroSumPageState extends State<ZeroSumPage>
    with TickerProviderStateMixin {
  late ZeroSumBoard _board;
  late Ticker _ticker;

  // 게임 상태
  Projectile? _projectile;
  double _aimAngle = -math.pi / 2; // -90도 (위쪽)
  bool _isAiming = false;
  
  // 이펙트 레이어
  final List<Widget> _effectsLayer = [];
  Map<BlockPosition, BlockValue> _explodingBlocks = {};

  // 보드 크기 계산용
  double _bubbleSize = 0;
  double _boardWidth = 0;
  double _boardHeight = 0;
  final double _bottomPanelHeight = 120.0;

  @override
  void initState() {
    super.initState();
    _board = ZeroSumBoard.newGame();
    _ticker = createTicker(_gameLoop);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _gameLoop(Duration elapsed) {
    if (_projectile == null) return;

    // 대략적인 델타 타임
    const dt = 0.016; 
    _projectile!.update(dt);

    if (_checkCollision()) {
      _handleCollision();
    } else {
      setState(() {}); // 발사체 위치 갱신
    }
  }

  bool _checkCollision() {
    if (_projectile == null) return false;

    final pos = _projectile!.position;
    final r = _projectile!.radius;

    // 1. 벽 충돌 (좌우)
    if (pos.dx - r < 0) {
      _projectile!.position = Offset(r, pos.dy);
      _projectile!.velocity = Offset(-_projectile!.velocity.dx, _projectile!.velocity.dy);
    } else if (pos.dx + r > _boardWidth) {
      _projectile!.position = Offset(_boardWidth - r, pos.dy);
      _projectile!.velocity = Offset(-_projectile!.velocity.dx, _projectile!.velocity.dy);
    }

    // 2. 천장 충돌
    if (pos.dy - r < 0) {
      return true;
    }

    // 3. 버블 충돌
    for (int rIdx = 0; rIdx < ZeroSumBoard.rows; rIdx++) {
      for (int cIdx = 0; cIdx < ZeroSumBoard.columns; cIdx++) {
        if (_board.grid[rIdx][cIdx] != null) {
          final bubbleCenter = _getBubbleCenter(rIdx, cIdx);
          final distSq = (pos.dx - bubbleCenter.dx) * (pos.dx - bubbleCenter.dx) +
                         (pos.dy - bubbleCenter.dy) * (pos.dy - bubbleCenter.dy);
          // 충돌 거리: 2 * radius (약간 여유 둬서 1.8 정도)
          if (distSq < (2 * r - 5) * (2 * r - 5)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  void _handleCollision() {
    if (_projectile == null) return;

    // 가장 가까운 빈 그리드 찾기 (Snap)
    final snapPos = _findNearestEmptyGrid(_projectile!.position);
    
    if (snapPos != null) {
      final success = _board.placeBlock(snapPos.row, snapPos.col, _projectile!.value);
      if (success) {
        HapticFeedback.lightImpact();
        setState(() {
          _projectile = null;
        });

        // 폭발 체크
        _checkRules();
      } else {
        setState(() => _projectile = null);
      }
    } else {
       setState(() => _projectile = null);
    }
  }

  BlockPosition? _findNearestEmptyGrid(Offset p) {
    BlockPosition? bestPos;
    double minDesc = double.infinity;

    for (int r = 0; r < ZeroSumBoard.rows; r++) {
      for (int c = 0; c < ZeroSumBoard.columns; c++) {
        if (_board.grid[r][c] == null) {
          final center = _getBubbleCenter(r, c);
          final distSq = (p.dx - center.dx) * (p.dx - center.dx) +
                         (p.dy - center.dy) * (p.dy - center.dy);
          if (distSq < minDesc) {
            minDesc = distSq;
            bestPos = BlockPosition(r, c);
          }
        }
      }
    }
    return bestPos;
  }

  Offset _getBubbleCenter(int r, int c) {
    double x = c * _bubbleSize + _bubbleSize / 2;
    if (r % 2 == 1) x += _bubbleSize / 2;
    
    double y = r * _bubbleSize * 0.85 + _bubbleSize / 2;
    return Offset(x, y);
  }

  // 이펙트 관리
  void _addEffect(Widget effect) {
     _effectsLayer.add(effect);
  }

  void _removeEffect(Key key) {
     setState(() {
       _effectsLayer.removeWhere((w) => w.key == key);
     });
  }

  void _checkRules() {
    final prevScore = _board.score;
    final result = _board.checkAndExplode();
    
    if (result.hasExplosion) {
      HapticFeedback.mediumImpact();
      final scoreDiff = _board.score - prevScore;
      
      setState(() {
        _explodingBlocks = result.explodedBlocks;
        
        // 이펙트 추가
        for (final entry in result.explodedBlocks.entries) {
            final pos = entry.key;
            final val = entry.value;
            final center = _getBubbleCenter(pos.row, pos.col);
            
            final pKey = UniqueKey();
            final gKey = UniqueKey();

            _addEffect(
              ExplosionParticles(
                key: pKey,
                position: center,
                color: ZeroSumColors.getBlockColor(val),
                onComplete: () => _removeEffect(pKey),
              ),
            );
            
            _addEffect(
              GlowEffect(
                key: gKey,
                center: center,
                size: _bubbleSize * 1.5,
                color: ZeroSumColors.getBlockColor(val),
                onComplete: () => _removeEffect(gKey),
              ),
            );
        }
        
        if (scoreDiff > 0 && result.explodedBlocks.isNotEmpty) {
            final firstPos = result.explodedBlocks.keys.first;
            final center = _getBubbleCenter(firstPos.row, firstPos.col);
            final tKey = UniqueKey();
            
             _addEffect(
                FlyingScoreText(
                    key: tKey,
                    score: scoreDiff,
                    startPosition: center,
                    endPosition: Offset(center.dx, center.dy - 100),
                    onComplete: () => _removeEffect(tKey),
                )
             );
        }
      });
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _explodingBlocks = {};
          });
          
          if (_board.isGameOver) {
              _showGameOverDialog();
          }
        }
      });
    } else {
        if (_board.isGameOver) _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    GameDataService.recordScore('zerosum', _board.score);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ZeroSumColors.boardBackground,
        title: const Text('Game Over!', style: TextStyle(color: Colors.white)),
        content: Text('Score: ${_board.score}', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('New Game'),
          )
        ],
      ),
    );
  }

  void _startNewGame() {
    setState(() {
      _board = ZeroSumBoard.newGame(bestScore: _board.bestScore);
      _projectile = null;
      _isAiming = false;
      _explodingBlocks = {};
      _effectsLayer.clear();
    });
  }

  void _shoot() {
    if (_projectile != null || _board.isGameOver) return;
    
    final startPos = Offset(_boardWidth / 2, _boardHeight + 30); 
    final speed = 800.0; 
    final velocity = Offset(
      math.cos(_aimAngle) * speed,
      math.sin(_aimAngle) * speed,
    );
    
    setState(() {
      _projectile = Projectile(
        position: startPos,
        velocity: velocity,
        value: _board.nextBlock,
        radius: _bubbleSize / 2,
      );
      _board.generateNextBlock();
    });
    
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _boardWidth = size.width;
    _boardHeight = size.height - _bottomPanelHeight - 100;
    
    _bubbleSize = _boardWidth / (ZeroSumBoard.columns + 0.5);

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final localPos = renderBox.globalToLocal(details.globalPosition);
                  final shooterPos = Offset(_boardWidth / 2, _boardHeight + 50);
                  
                  final dx = localPos.dx - shooterPos.dx;
                  final dy = localPos.dy - shooterPos.dy;
                  
                  setState(() {
                    _aimAngle = math.atan2(dy, dx);
                    if (_aimAngle > -0.3) _aimAngle = -0.3;
                    if (_aimAngle < -2.8) _aimAngle = -2.8;
                  });
                },
                onPanEnd: (details) => _shoot(),
                child: Container(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      ..._buildGridBubbles(),
                      if (_projectile != null)
                        Positioned(
                          left: _projectile!.position.dx - _projectile!.radius,
                          top: _projectile!.position.dy - _projectile!.radius,
                          child: BlockWidget(
                            value: _projectile!.value,
                            size: _projectile!.radius * 2,
                          ),
                        ),
                      Positioned(
                        bottom: 20,
                        left: _boardWidth / 2 - _bubbleSize / 2,
                        child: Transform.rotate(
                          angle: _aimAngle + math.pi / 2,
                          child: const Icon(Icons.arrow_upward, color: Colors.white54, size: 40),
                        ),
                      ),
                       Positioned(
                        bottom: 20,
                        left: _boardWidth / 2 - _bubbleSize / 2,
                        child: BlockWidget(
                            value: _board.nextBlock,
                            size: _bubbleSize,
                        ),
                      ),
                      CustomPaint(
                        painter: _GuideLinePainter(
                          start: Offset(_boardWidth / 2, _boardHeight + 20),
                          angle: _aimAngle,
                        ),
                      ),
                      
                      // Effects Layer (Input Transparent)
                      IgnorePointer(
                        child: Stack(
                          children: _effectsLayer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Panel
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.black26,
              child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text('Score: ${_board.score}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                   IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _startNewGame),
                 ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGridBubbles() {
    List<Widget> bubbles = [];
    for (int r = 0; r < ZeroSumBoard.rows; r++) {
      for (int c = 0; c < ZeroSumBoard.columns; c++) {
        BlockValue? blockVal = _board.grid[r][c];
        
        final pos = BlockPosition(r, c);
        if (_explodingBlocks.containsKey(pos)) {
            blockVal = _explodingBlocks[pos];
        }

        if (blockVal != null) {
          final center = _getBubbleCenter(r, c);
          final isExploding = _explodingBlocks.containsKey(pos);
          
          if (isExploding) {
              // Shrinking & Fading Animation
              bubbles.add(Positioned(
                left: center.dx - _bubbleSize/2,
                top: center.dy - _bubbleSize/2,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInBack, // 약간 커졌다가 팍 터지는 느낌
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: BlockWidget(value: blockVal, size: _bubbleSize, isExploding: true),
                ),
              ));
          } else {
              bubbles.add(Positioned(
                left: center.dx - _bubbleSize/2,
                top: center.dy - _bubbleSize/2,
                child: BlockWidget(value: blockVal, size: _bubbleSize),
              ));
          }
        }
      }
    }
    return bubbles;
  }
  
  Widget _buildHeader() {
      return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
              children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                  ),
                  const Text('Zero Sum Bobble', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
          ),
      );
  }
}

class _GuideLinePainter extends CustomPainter {
    final Offset start;
    final double angle;
    
    _GuideLinePainter({required this.start, required this.angle});
    
    @override
    void paint(Canvas canvas, Size size) {
        final paint = Paint()
            ..color = Colors.white.withValues(alpha: 0.2)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
            
        final end = Offset(
            start.dx + math.cos(angle) * 200,
            start.dy + math.sin(angle) * 200,
        );
        
        double dashWidth = 5, dashSpace = 5, distance = 0;
        while (distance < 200) {
             canvas.drawLine(
                 Offset(start.dx + math.cos(angle) * distance, start.dy + math.sin(angle) * distance),
                 Offset(start.dx + math.cos(angle) * (distance + dashWidth), start.dy + math.sin(angle) * (distance + dashWidth)),
                 paint
             );
             distance += dashWidth + dashSpace;
        }
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
