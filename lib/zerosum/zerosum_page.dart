import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'zerosum_board.dart';
import 'zerosum_theme.dart';
import 'block_widget.dart';
import 'particle_effects.dart';
import '../services/game_data_service.dart';

class ZeroSumPage extends StatefulWidget {
  const ZeroSumPage({super.key});

  @override
  State<ZeroSumPage> createState() => _ZeroSumPageState();
}

class _ZeroSumPageState extends State<ZeroSumPage> with TickerProviderStateMixin {
  late ZeroSumBoard _board;
  
  // Interaction State
  final List<BlockPosition> _currentPath = [];
  Offset? _currentDragPos;
  
  // Hints
  List<BlockPosition> _hintPath = [];
  Timer? _hintTimer;
  
  // Effects
  final List<Widget> _effectsLayer = [];
  
  // Layout
  final GlobalKey _gridKey = GlobalKey();
  double _blockSize = 0;
  Offset _gridOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _board = ZeroSumBoard.newGame();
    _restartHintTimer();
  }
  
  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  void _restartHintTimer() {
    _hintTimer?.cancel();
    _hintPath = [];
    _hintTimer = Timer(const Duration(seconds: 5), _showHint);
  }
  
  void _showHint() {
    if (!mounted || _board.isGameOver) return;
    
    final hint = _board.findHint();
    if (hint.isNotEmpty) {
      setState(() {
        _hintPath = hint;
      });
      // Bouncing effect or highlight? handled in Painter
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_board.isGameOver) return;
    _hintTimer?.cancel();
    setState(() => _hintPath = []); // Clear hint on interaction
    
    _currentDragPos = details.localPosition;
    _updatePath(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_board.isGameOver) return;
    
    setState(() {
      _currentDragPos = details.localPosition;
    });
    _updatePath(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_board.isGameOver) return;
    
    _processPath();
    setState(() {
      _currentPath.clear();
      _currentDragPos = null;
    });
    _restartHintTimer();
  }

  void _updatePath(Offset localPos) {
    // Convert localPos (stack coordinates) to Grid Position
    if (_blockSize == 0) return;

    // Grid starts relative to the GestureDetector, but we need to account for padding/centering?
    // Actually, GestureDetector wraps the Grid container directly.
    
    int col = (localPos.dx / _blockSize).floor();
    int row = (localPos.dy / _blockSize).floor();

    if (row >= 0 && row < ZeroSumBoard.rows && col >= 0 && col < ZeroSumBoard.columns) {
      final pos = BlockPosition(row, col);
      
      // Prevent adding empty blocks
      if (_board.grid[row][col] == null) return;

      if (_currentPath.isEmpty) {
        // Start Path
        setState(() {
          _currentPath.add(pos);
        });
        HapticFeedback.selectionClick();
      } else {
        final lastPos = _currentPath.last;
        
        // Backtracking (remove last if moving back)
        if (_currentPath.length > 1 && pos == _currentPath[_currentPath.length - 2]) {
           setState(() {
             _currentPath.removeLast();
           });
           HapticFeedback.selectionClick();
           return;
        }

        // Add if neighbor and not already in path
        if (pos != lastPos && lastPos.isNeighbor(pos) && !_currentPath.contains(pos)) {
           setState(() {
             _currentPath.add(pos);
           });
           HapticFeedback.lightImpact();
        }
      }
    }
  }

  void _processPath() {
    final result = _board.processPath(_currentPath);
    
    if (result.success) {
      HapticFeedback.heavyImpact();
      _spawnEffects(result.removedPositions, result.scoreGained);
    } else {
      // Invalid path feedback?
      if (_currentPath.length > 1) {
         HapticFeedback.vibrate();
      }
    }

    if (_board.isGameOver) {
      _showGameOverDialog();
    }
  }

  void _spawnEffects(List<BlockPosition> positions, int score) {
    for (final pos in positions) {
      final center = _getBlockCenter(pos);
      
      final pKey = UniqueKey();
      setState(() {
        _effectsLayer.add(ExplosionParticles(
          key: pKey,
          position: center,
          color: ZeroSumColors.pathValid,
          onComplete: () => _removeEffect(pKey),
        ));
      });
    }
    
    // Flying Text at last position
    if (positions.isNotEmpty) {
      final lastPos = positions.last;
      final center = _getBlockCenter(lastPos);
      final tKey = UniqueKey();
      setState(() {
        _effectsLayer.add(FlyingScoreText(
           key: tKey,
           score: score,
           startPosition: center,
           endPosition: Offset(center.dx, center.dy - 100),
           onComplete: () => _removeEffect(tKey),
        ));
      });
    }
  }

  void _removeEffect(Key key) {
    setState(() {
      _effectsLayer.removeWhere((element) => element.key == key);
    });
  }

  Offset _getBlockCenter(BlockPosition pos) {
    return Offset(
      (pos.col + 0.5) * _blockSize, 
      (pos.row + 0.5) * _blockSize
    );
  }

  int _calculateSum() {
    int sum = 0;
    for (var pos in _currentPath) {
      final val = _board.grid[pos.row][pos.col];
      if (val != null) sum += val.value;
    }
    return sum;
  }
  
  void _showGameOverDialog() {
    GameDataService.recordScore('zerosum_path', _board.score);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ZeroSumColors.boardBackground,
        title: Text(
           _board.isVictory ? 'MISSION COMPLETE' : 'SYSTEM FAILURE',
           style: TextStyle(
               color: _board.isVictory ? ZeroSumColors.pathActive : Colors.red,
               fontWeight: FontWeight.bold
           ),
        ),
        content: Text(
            'Final Score: ${_board.score}\nTarget: ${_board.targetScore}', 
            style: const TextStyle(color: Colors.white)
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                 _board = ZeroSumBoard.newGame();
                 _currentPath.clear();
                 _effectsLayer.clear();
                 _restartHintTimer();
              });
            },
            child: const Text('REBOOT SYSTEM'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final gridWidth = size.width - 32; // Margin 16
    _blockSize = gridWidth / ZeroSumBoard.columns;
    final gridHeight = _blockSize * ZeroSumBoard.rows;

    final currentSum = _calculateSum();
    final isZeroSum = _currentPath.length >= 2 && currentSum == 0;

    return Scaffold(
      backgroundColor: ZeroSumColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            _buildHeader(),
            
            // --- HUD ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHUDItem('MOVES', '${_board.movesLeft}'),
                  Expanded(child: _buildProgressBar()),
                ],
              ),
            ),

            const Spacer(),
            
            // --- GAME GRID ---
            Center(
               child: Container(
                 width: gridWidth,
                 height: gridHeight,
                 key: _gridKey,
                 decoration: BoxDecoration(
                   color: ZeroSumColors.boardBackground.withValues(alpha: 0.5),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: ZeroSumColors.gridLine),
                 ),
                 child: GestureDetector(
                   onPanStart: _onPanStart,
                   onPanUpdate: _onPanUpdate,
                   onPanEnd: _onPanEnd,
                   child: Stack(
                     children: [
                       // 1. Grid Blocks
                       ..._buildGridBlocks(),

                       // 2. Path Line
                       CustomPaint(
                         size: Size(gridWidth, gridHeight),
                         painter: ZeroSumPathPainter(
                            path: _currentPath,
                            hintPath: _hintPath,
                            blockSize: _blockSize,
                            isValid: isZeroSum,
                         ),
                       ),
                       
                       // 3. Effects Layer (Ignore Pointer)
                       IgnorePointer(
                         child: Stack(children: _effectsLayer),
                       ),
                       
                       // 4. Floating Sum Indicator
                       if (_currentPath.isNotEmpty && _currentDragPos != null)
                          Positioned(
                             left: _currentDragPos!.dx - 40,
                             top: _currentDragPos!.dy - 60,
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                 color: isZeroSum ? ZeroSumColors.pathValid.withValues(alpha: 0.9) 
                                                  : Colors.black.withValues(alpha: 0.7),
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(
                                     color: isZeroSum ? Colors.white : ZeroSumColors.gridLine
                                 ),
                                 boxShadow: [
                                   BoxShadow(
                                     color: isZeroSum ? ZeroSumColors.pathValid : Colors.transparent,
                                     blurRadius: 10,
                                   )
                                 ]
                               ),
                               child: Text(
                                 'SUM: $currentSum',
                                 style: const TextStyle(
                                   color: Colors.white,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 14,
                                 ),
                               ),
                             ),
                          ),
                     ],
                   ),
                 ),
               ),
            ),
            
            const Spacer(),

            // --- BOTTOM CONTROLS ---
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildCircleButton(Icons.lightbulb_outline, 'HINT', () {
                      _showHint();
                      HapticFeedback.lightImpact();
                   }),
                   _buildCircleButton(Icons.shuffle, 'SHUFFLE', () {
                      setState(() {
                         _board = ZeroSumBoard.newGame(moves: _board.movesLeft, target: _board.targetScore);
                         _restartHintTimer();
                      });
                   }),
                   _buildCircleButton(Icons.flash_on, 'BOMB', () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGridBlocks() {
    List<Widget> blocks = [];
    for (int r = 0; r < ZeroSumBoard.rows; r++) {
      for (int c = 0; c < ZeroSumBoard.columns; c++) {
        final block = _board.grid[r][c];
        if (block != null) {
          final pos = BlockPosition(r, c);
          final isSelected = _currentPath.contains(pos);
          bool isDimmed = (_currentPath.isNotEmpty && !isSelected);
          
          // Should not dim if hints are active and it's part of hint? 
          // Keep it simple for now. 
          
          blocks.add(Positioned(
            left: c * _blockSize,
            top: r * _blockSize,
            child: BlockWidget(
              value: block,
              size: _blockSize,
              isSelected: isSelected,
              isDimmed: isDimmed,
            ),
          ));
        }
      }
    }
    return blocks;
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: ZeroSumColors.textDim),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'ZERO SUM PATH',
            style: TextStyle(
              color: ZeroSumColors.pathActive,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              shadows: [Shadow(color: ZeroSumColors.pathActive, blurRadius: 10)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDItem(String label, String value) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(label, style: const TextStyle(color: ZeroSumColors.textDim, fontSize: 10, letterSpacing: 1.2)),
         Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300)),
       ],
     );
  }
  
  Widget _buildProgressBar() {
     final progress = (_board.score / _board.targetScore).clamp(0.0, 1.0);
     return Padding(
       padding: const EdgeInsets.only(left: 30, top: 10),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.end,
         children: [
            Text('TARGET SCORE', style: const TextStyle(color: ZeroSumColors.textDim, fontSize: 10)),
            const SizedBox(height: 4),
            Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: 6,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        color: ZeroSumColors.pathActive,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: const [BoxShadow(color: ZeroSumColors.pathActive, blurRadius: 6)]
                      ),
                    );
                  } 
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_board.score} / ${_board.targetScore}',
              style: const TextStyle(color: ZeroSumColors.pathActive, fontSize: 12, fontWeight: FontWeight.bold),
            ),
         ],
       ),
     );
  }

  Widget _buildCircleButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E293B),
              border: Border.all(color: ZeroSumColors.pathActive.withValues(alpha: 0.5)),
              boxShadow: const [
                 BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4))
              ]
            ),
            child: Icon(icon, color: ZeroSumColors.pathActive, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: ZeroSumColors.textDim, fontSize: 10)),
      ],
    );
  }
}

class ZeroSumPathPainter extends CustomPainter {
  final List<BlockPosition> path;
  final List<BlockPosition> hintPath;
  final double blockSize;
  final bool isValid;

  ZeroSumPathPainter({
    required this.path,
    this.hintPath = const [],
    required this.blockSize,
    required this.isValid,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Hint Path (if no active path)
    if (path.isEmpty && hintPath.isNotEmpty) {
      _drawPath(canvas, hintPath, Colors.white.withValues(alpha: 0.3), isHint: true);
    }

    // Draw Active Path
    if (path.isNotEmpty) {
        final color = isValid ? ZeroSumColors.pathValid : ZeroSumColors.pathActive;
        _drawPath(canvas, path, color, isHint: false);
    }
  }

  void _drawPath(Canvas canvas, List<BlockPosition> pList, Color color, {bool isHint = false}) {
    if (pList.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = isHint ? 4.0 : 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
      
    if (!isHint) {
       paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    }

    final pathObj = Path();
    final first = _getCenter(pList.first);
    pathObj.moveTo(first.dx, first.dy);

    for (int i = 1; i < pList.length; i++) {
       final p = _getCenter(pList[i]);
       pathObj.lineTo(p.dx, p.dy);
    }
    
    // Draw Glow (only for active path)
    if (!isHint) {
        canvas.drawPath(
            pathObj, 
            paint..color = color.withValues(alpha: 0.5)..strokeWidth = 12
        );
        // Core
        canvas.drawPath(
            pathObj, 
            paint..color = Colors.white..strokeWidth = 3..maskFilter = null
        );
    } else {
        // Dashed? or just transparent
        canvas.drawPath(pathObj, paint);
    }
  }

  Offset _getCenter(BlockPosition pos) {
    return Offset(
      (pos.col + 0.5) * blockSize,
      (pos.row + 0.5) * blockSize,
    );
  }

  @override
  bool shouldRepaint(covariant ZeroSumPathPainter oldDelegate) {
    return oldDelegate.path != path || 
           oldDelegate.isValid != isValid ||
           oldDelegate.hintPath != hintPath;
  }
}
