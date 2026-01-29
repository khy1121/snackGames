import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_board.dart';
import 'game_theme.dart';
import 'tile_widget.dart';
import '../services/game_data_service.dart';
import '../services/challenge_service.dart';
import '../widgets/challenge_toast.dart';

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
    final savedBest = GameDataService.getBestScore('2048');
    _board = GameBoard.newGame(bestScore: savedBest);
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
  
  Future<void> _checkAndShowChallengeToasts() async {
    final gamesPlayed = GameDataService.getTotalGamesPlayed();
    final bestScore = GameDataService.getBestScore('2048');
    
    // 플레이 횟수 관련 도전과제 체크
    final playIds = ['play_1', 'play_3', 'play_5', 'play_10', 'play_15', 'play_20', 'play_30', 'play_40', 'play_50', 'play_75'];
    for (final id in playIds) {
      final completed = await ChallengeService.updateProgressAndGetCompleted(id, gamesPlayed);
      for (final desc in completed) {
        if (mounted) ChallengeToast.show(context, desc);
      }
    }
    
    // 점수 관련 도전과제 체크
    final scoreIds = ['score_300', 'score_500', 'score_1000', 'score_1500', 'score_2000', 'score_3000', 'score_4000', 'score_5000', 'score_7500'];
    for (final id in scoreIds) {
      final completed = await ChallengeService.updateProgressAndGetCompleted(id, bestScore);
      for (final desc in completed) {
        if (mounted) ChallengeToast.show(context, desc);
      }
    }
  }
  
  void _showGameOverDialog() {
    // 점수 기록
    GameDataService.recordScore('2048', _board.score);
    
    // 리워드 계산 (2048은 점수가 더 높으므로 200점당 1P)
    final reward = (_board.score / 200).floor();
    
    // XP 계산 (기본 10 + 점수/200)
    final xpGain = 10 + (_board.score ~/ 200);
    
    // 포인트 지급
    GameDataService.addPoints(reward);
    
    // XP 지급
    ChallengeService.addXP(xpGain);
    
    // 도전과제 진행도 업데이트 및 토스트 표시
    _checkAndShowChallengeToasts();
    
    // 최대 타일 표시
    final maxTile = _board.highestTile;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Game Over',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Container(color: Colors.black.withValues(alpha: 0.85)),
              
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 340,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF39C12).withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            const Text(
                              'GAME OVER',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Score
                            Text(
                              '${_board.score}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFD700),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // New Best Badge 
                            if (_board.score >= _board.bestScore && _board.score > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFFFD700)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emoji_events, size: 14, color: Color(0xFFFFD700)),
                                    SizedBox(width: 4),
                                    Text(
                                      'NEW BEST!',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                            const SizedBox(height: 30),
                            
                            // Reward Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF39C12), Color(0xFFE74C3C)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'REWARD EARNED',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '+${reward}P',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '+${xpGain}XP',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Stats Row
                            Row(
                              children: [
                                // Max Tile
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'MAX TILE',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$maxTile',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Best Score
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'BEST SCORE',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_board.bestScore}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _startNewGame();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF39C12),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 5,
                                      shadowColor: const Color(0xFFF39C12).withValues(alpha: 0.5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.refresh, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          '다시하기',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(Icons.home, color: Colors.white),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
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
      children: [
        // 뒤로가기 버튼
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF776E65)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        
        // 2048 로고
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEDC22E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '2048',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        
        const Spacer(),
        
        // 새 게임 버튼
        ElevatedButton.icon(
          onPressed: _startNewGame,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('New'),
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
