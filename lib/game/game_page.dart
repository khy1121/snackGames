import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_board.dart';
import 'game_theme.dart';
import 'tile_widget.dart';

/// 2048 게임 메인 페이지
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late GameBoard _board;
  Set<(int, int)> _newTiles = {};
  Set<(int, int)> _mergedTiles = {};
  
  // 스와이프 감지
  Offset? _dragStart;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _board = GameBoard.newGame();
  }
  
  void _startNewGame() {
    final prevBest = _board.bestScore;
    setState(() {
      _board = GameBoard.newGame(bestScore: prevBest);
      _newTiles = {};
      _mergedTiles = {};
    });
  }
  
  void _onSwipe(Direction direction) {
    if (_isProcessing || _board.isGameOver) return;
    
    setState(() {
      _isProcessing = true;
      _newTiles = {};
      _mergedTiles = {};
    });
    
    final oldTiles = _board.tiles.map((r) => List<int>.from(r)).toList();
    final result = _board.move(direction);
    
    if (result.moved) {
      HapticFeedback.lightImpact();
      
      // 병합된 타일 찾기
      for (final merge in result.merges) {
        _mergedTiles.add((merge.$1, merge.$2));
      }
      
      // 새로 생긴 타일 찾기
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          if (oldTiles[r][c] == 0 && _board.tiles[r][c] != 0) {
            _newTiles.add((r, c));
          }
        }
      }
      
      setState(() {});
      
      // 애니메이션 후 상태 리셋
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _newTiles = {};
            _mergedTiles = {};
          });
          
          // 게임 오버 또는 승리 체크
          if (_board.isGameOver) {
            _showGameOverDialog();
          } else if (_board.hasWon) {
            _showWinDialog();
          }
        }
      });
    } else {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: GameColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Game Over!',
          style: TextStyle(
            color: GameColors.headerText,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: ${_board.score}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: GameColors.headerText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Best: ${_board.bestScore}',
              style: TextStyle(
                fontSize: 18,
                color: GameColors.headerText.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            style: TextButton.styleFrom(
              backgroundColor: GameColors.buttonBackground,
              foregroundColor: GameColors.buttonText,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }
  
  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEDC22E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '🎉 You Win! 🎉',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'You reached 2048!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFEDC22E),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('New Game'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boardSize = (size.width < size.height ? size.width : size.height * 0.5) - 32;
    
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: GestureDetector(
          onPanStart: (details) {
            _dragStart = details.localPosition;
          },
          onPanEnd: (details) {
            if (_dragStart == null) return;
            
            final velocity = details.velocity.pixelsPerSecond;
            final dx = velocity.dx;
            final dy = velocity.dy;
            
            if (dx.abs() > dy.abs()) {
              // 수평 스와이프
              _onSwipe(dx > 0 ? Direction.right : Direction.left);
            } else if (dy.abs() > dx.abs()) {
              // 수직 스와이프
              _onSwipe(dy > 0 ? Direction.down : Direction.up);
            }
            
            _dragStart = null;
          },
          onPanUpdate: (details) {
            if (_dragStart == null) return;
            
            final delta = details.localPosition - _dragStart!;
            
            // 최소 이동 거리 체크
            if (delta.distance < 30) return;
            
            if (delta.dx.abs() > delta.dy.abs()) {
              _onSwipe(delta.dx > 0 ? Direction.right : Direction.left);
            } else {
              _onSwipe(delta.dy > 0 ? Direction.down : Direction.up);
            }
            
            _dragStart = null;
          },
          behavior: HitTestBehavior.opaque,
          child: KeyboardListener(
            focusNode: FocusNode()..requestFocus(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                switch (event.logicalKey) {
                  case LogicalKeyboardKey.arrowUp:
                    _onSwipe(Direction.up);
                  case LogicalKeyboardKey.arrowDown:
                    _onSwipe(Direction.down);
                  case LogicalKeyboardKey.arrowLeft:
                    _onSwipe(Direction.left);
                  case LogicalKeyboardKey.arrowRight:
                    _onSwipe(Direction.right);
                  default:
                    break;
                }
              }
            },
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 헤더
                    _buildHeader(),
                    const SizedBox(height: 24),
                    
                    // 점수판
                    _buildScoreBoard(),
                    const SizedBox(height: 24),
                    
                    // 게임 보드
                    BoardWidget(
                      tiles: _board.tiles,
                      newTiles: _newTiles,
                      mergedTiles: _mergedTiles,
                      boardSize: boardSize.clamp(280.0, 400.0),
                    ),
                    const SizedBox(height: 24),
                    
                    // 안내 텍스트
                    Text(
                      'Swipe or use arrow keys to move tiles',
                      style: TextStyle(
                        color: GameColors.headerText.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 2048 로고
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEDC22E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '2048',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        
        // 새 게임 버튼
        ElevatedButton.icon(
          onPressed: _startNewGame,
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('New Game'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.buttonBackground,
            foregroundColor: GameColors.buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildScoreBoard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildScoreBox('SCORE', _board.score),
        const SizedBox(width: 12),
        _buildScoreBox('BEST', _board.bestScore),
      ],
    );
  }
  
  Widget _buildScoreBox(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: GameColors.boardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: GameColors.scoreLabel,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: GameColors.scoreValue,
            ),
          ),
        ],
      ),
    );
  }
}
