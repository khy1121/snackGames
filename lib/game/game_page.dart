import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_board.dart';
import 'game_theme.dart';
import 'tile_widget.dart';
import '../services/game_data_service.dart';
import '../services/challenge_service.dart';
import '../services/upgrade_service.dart';
import '../services/achievement_service.dart';
import '../services/vibration_service.dart';
import '../widgets/challenge_toast.dart';
import '../services/sfx_service_stub.dart'
    if (dart.library.html) '../services/sfx_service.dart';

/// 점수 팝업 데이터
class _ScorePopup {
  double relX, relY;
  final String text;
  final bool isCombo;
  double life = 1.0;
  _ScorePopup({
    required this.relX,
    required this.relY,
    required this.text,
    this.isCombo = false,
  });

}

/// 2048 게임 메인 페이지
class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
    bool _resumeDialogShown = false;
  // Versions (label + grid size)
  final List<Map<String, dynamic>> _versions = [
    {'label': 'Classic 4×4', 'size': 4},
    {'label': 'Small 3×3', 'size': 3},
    {'label': 'Big 5×5', 'size': 5},
    {'label': 'Huge 6×6', 'size': 6},
  ];
  int _selectedVersionIndex = 0;
  late GameBoard _board;
  Set<(int, int)> _newTiles = {};
  Set<(int, int)> _mergedTiles = {};

  // 스와이프 감지
  Offset? _dragStart;
  bool _isProcessing = false;

  // 플레이 시간 측정
  DateTime? _startTime;

  // ===== 재미 요소 =====
  final List<_ScorePopup> _popups = [];
  int _comboStreak = 0;
  final Set<int> _shownMilestones = {};
  String? _milestoneText;
  double _milestoneLife = 0;
  late AnimationController _animTicker;
  double _cachedBoardSize = 300;

  static const List<int> _milestoneValues = [128, 256, 512, 1024, 2048, 4096];
  static const Map<int, String> _milestoneEmoji = {
    128: '🌟', 256: '⚡', 512: '🔥', 1024: '💎', 2048: '👑', 4096: '🏆',
  };

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    final savedBest = GameDataService.getBestScore('2048');
    final resumeJson = GameDataService.load2048Resume();
    if (resumeJson != null && !_resumeDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResumeDialog(resumeJson, savedBest);
      });
      _resumeDialogShown = true;
    } else {
      final size = _versions[_selectedVersionIndex]['size'] as int;
      _board = GameBoard.newGame(size: size, bestScore: savedBest);
      _board.score += UpgradeService.getStartingBonus();
    }
    _animTicker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_tickAnimations);
    _animTicker.repeat();
    GameDataService.setLastPlayedGame('2048');
  }

  void _showResumeDialog(Map<String, dynamic> resumeJson, int bestScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text('이어하기/새로하기'),
          content: Text('저장된 게임 데이터가 있습니다. 이어서 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _board = GameBoard.fromJson(resumeJson);
                  final s = resumeJson['size'] ?? _board.size;
                  final idx = _versions.indexWhere((v) => v['size'] == s);
                  if (idx >= 0) _selectedVersionIndex = idx;
                });
                Navigator.of(ctx).pop();
              },
              child: Text('이어하기'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final s = resumeJson['size'] ?? (_versions[_selectedVersionIndex]['size'] as int);
                  _board = GameBoard.newGame(size: s, bestScore: bestScore);
                  _board.score += UpgradeService.getStartingBonus();
                  GameDataService.clear2048Resume();
                });
                Navigator.of(ctx).pop();
              },
              child: Text('새로하기'),
            ),
          ],
        );
      },
    );
  }
  

  @override
  void dispose() {
    _animTicker.dispose();
    if (_startTime != null) {
      final elapsedMinutes = DateTime.now().difference(_startTime!).inMinutes;
      if (elapsedMinutes > 0) {
        GameDataService.addPlayTime(elapsedMinutes);
      }
    }
    super.dispose();
  }

  void _tickAnimations() {
    bool dirty = false;
    if (_popups.isNotEmpty) {
      for (final p in _popups) {
        p.life -= 0.022;
        p.relY -= 0.004;
      }
      _popups.removeWhere((p) => p.life <= 0);
      dirty = true;
    }
    if (_milestoneLife > 0) {
      _milestoneLife -= 0.012;
      if (_milestoneLife <= 0) _milestoneText = null;
      dirty = true;
    }
    if (dirty) setState(() {});
  }

  void _startNewGame() {
    final prevBest = _board.bestScore;
    setState(() {
      _board = GameBoard.newGame(bestScore: prevBest);
      _newTiles = {};
      _mergedTiles = {};
      _popups.clear();
      _comboStreak = 0;
      _milestoneText = null;
      _milestoneLife = 0;
      _shownMilestones.clear();
      _board.score += UpgradeService.getStartingBonus();
    });
  }

  void _undo() {
    if (!_board.canUndo) return;
    setState(() {
      _board.undo();
      _newTiles = {};
      _mergedTiles = {};
      _comboStreak = 0;
    });
    VibrationService.light();
  }

  void _onSwipe(Direction direction) {
      _saveResume();
    if (_isProcessing || _board.isGameOver) return;

    setState(() {
      _isProcessing = true;
      _newTiles = {};
      _mergedTiles = {};
    });

    final oldTiles = _board.tiles.map((r) => List<int>.from(r)).toList();
    final oldHighest = _board.highestTile;
    final result = _board.move(direction);

    if (result.moved) {
      // 진동 피드백
      if (result.merges.isNotEmpty) {
        final maxMergeValue = result.merges.map((m) => m.$3).reduce((a, b) => a > b ? a : b);
        if (maxMergeValue >= 512) {
          VibrationService.heavy();
        } else {
          VibrationService.medium();
        }
      } else {
        VibrationService.light();
      }

      // 병합 타일 추적
      for (final merge in result.merges) {
        _mergedTiles.add((merge.$1, merge.$2));
      }

      // 새 타일 추적
      final gridSize = _board.size;
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          if (oldTiles[r][c] == 0 && _board.tiles[r][c] != 0) {
            _newTiles.add((r, c));
          }
        }
      }

      // ===== 점수 팝업 =====
      if (result.merges.isNotEmpty) {
        _comboStreak++;
        for (final merge in result.merges) {
          _popups.add(_ScorePopup(
              relX: (merge.$2 + 0.5) / gridSize.toDouble(),
              relY: (merge.$1 + 0.5) / gridSize.toDouble(),
            text: '+${merge.$3}',
          ));
        }
        // 콤보 보너스 (연속 병합 스와이프)
        if (_comboStreak >= 2) {
          final bonus = _comboStreak * 5;
          _board.score += bonus;
          _popups.add(_ScorePopup(
            relX: 0.5, relY: 0.12,
            text: '🔥 COMBO ×$_comboStreak! +$bonus',
            isCombo: true,
          ));
        }
        // 다중 병합 (한 스와이프에 3+ 병합)
        if (result.merges.length >= 3) {
          _popups.add(_ScorePopup(
            relX: 0.5, relY: 0.04,
            text: '⚡ MULTI MERGE!',
            isCombo: true,
          ));
        }
      } else {
        _comboStreak = 0;
      }

      // ===== 마일스톤 체크 =====
      final newHighest = _board.highestTile;
      if (newHighest > oldHighest) {
        // milestone logic here
      }

      // Save resume state after move
      _saveResume();
    }

    setState(() {
      _isProcessing = false;
    });
  }

  void _saveResume() {
    GameDataService.save2048Resume(_board.toJson());
  }

  Future<void> _checkAndShowChallengeToasts() async {
    final gamesPlayed = GameDataService.getTotalGamesPlayed();
    final bestScore = GameDataService.getBestScore('2048');

    final playIds = ['play_1', 'play_3', 'play_5', 'play_10', 'play_15', 'play_20', 'play_30', 'play_40', 'play_50', 'play_75'];
    for (final id in playIds) {
      final completed = await ChallengeService.updateProgressAndGetCompleted(id, gamesPlayed);
      for (final desc in completed) {
        if (mounted) ChallengeToast.show(context, desc);
      }
    }

    final scoreIds = ['score_300', 'score_500', 'score_1000', 'score_1500', 'score_2000', 'score_3000', 'score_4000', 'score_5000', 'score_7500'];
    for (final id in scoreIds) {
      final completed = await ChallengeService.updateProgressAndGetCompleted(id, bestScore);
      for (final desc in completed) {
        if (mounted) ChallengeToast.show(context, desc);
      }
    }
  }

  void _showGameOverDialog() {
    final scoreMultiplier = UpgradeService.getScoreMultiplier();
    final pointsMultiplier = UpgradeService.getPointsMultiplier();
    final finalScore = (_board.score * scoreMultiplier).round();

    GameDataService.recordScore('2048', finalScore);

    final baseReward = (finalScore / 200).floor();
    final finalReward = (baseReward * pointsMultiplier).round();
    final xpGain = 10 + (finalScore ~/ 200);

    GameDataService.addPoints(finalReward);
    ChallengeService.addXP(xpGain);
    AchievementService.syncFromGameData(GameDataService.getTotalGamesPlayed());

    final maxTile = _board.highestTile;
    if (maxTile >= 256) AchievementService.updateProgress('2048_256', 256);
    if (maxTile >= 512) AchievementService.updateProgress('2048_512', 512);
    if (maxTile >= 1024) AchievementService.updateProgress('2048_1024', 1024);
    if (maxTile >= 2048) AchievementService.updateProgress('2048_2048', 2048);

    _checkAndShowChallengeToasts();

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
                            Text(
                              '$finalScore',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFFD700),
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (finalScore >= _board.bestScore && finalScore > 0)
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
                                              '+${finalReward}P',
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

                            // Stats Row (3 columns: Max Tile, Best Score, Moves)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatBox('MAX TILE', '$maxTile'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatBox('BEST', '${_board.bestScore}'),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatBox('MOVES', '${_board.moveCount}'),
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

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
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
          '🎉 축하합니다! 🎉',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '2048을 달성했습니다!',
          style: TextStyle(fontSize: 18, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFEDC22E),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('계속하기'),
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
            child: const Text('새 게임'),
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
              _onSwipe(dx > 0 ? Direction.right : Direction.left);
            } else if (dy.abs() > dx.abs()) {
              _onSwipe(dy > 0 ? Direction.down : Direction.up);
            }
            _dragStart = null;
          },
          onPanUpdate: (details) {
            if (_dragStart == null) return;
            final delta = details.localPosition - _dragStart!;
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

                    // 게임 보드 + 팝업 오버레이
                    LayoutBuilder(
                      builder: (context, constraints) {
                        _cachedBoardSize = boardSize.clamp(280.0, 400.0);
                        return SizedBox(
                          width: _cachedBoardSize,
                          height: _cachedBoardSize,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              BoardWidget(
                                tiles: _board.tiles,
                                newTiles: _newTiles,
                                mergedTiles: _mergedTiles,
                                boardSize: _cachedBoardSize,
                              ),
                              // 점수 팝업 오버레이
                              if (_popups.isNotEmpty)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _PopupPainter(popups: _popups),
                                    ),
                                  ),
                                ),
                              // 마일스톤 배너
                              if (_milestoneText != null && _milestoneLife > 0)
                                Positioned(
                                  left: 0, right: 0, top: _cachedBoardSize * 0.35,
                                  child: IgnorePointer(
                                    child: Opacity(
                                      opacity: _milestoneLife.clamp(0.0, 1.0),
                                      child: Transform.scale(
                                        scale: 0.8 + 0.2 * _milestoneLife.clamp(0.0, 1.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          margin: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFD700), Color(0xFFF39C12)],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                                blurRadius: 20,
                                                spreadRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            _milestoneText!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // 안내 텍스트
                    Text(
                      '스와이프하거나 방향키를 눌러 타일을 움직이세요',
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
        // 뒤로가기
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
        // Version selector
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: DropdownButton<int>(
            value: _versions[_selectedVersionIndex]['size'] as int,
            dropdownColor: GameColors.background,
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox.shrink(),
            items: _versions.map((v) {
              return DropdownMenuItem<int>(
                value: v['size'] as int,
                child: Text(v['label'] as String),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              final idx = _versions.indexWhere((v) => v['size'] == val);
              setState(() {
                _selectedVersionIndex = idx >= 0 ? idx : 0;
                _board = GameBoard.newGame(size: val, bestScore: _board.bestScore);
              });
            },
          ),
        ),

        // 되돌리기 버튼
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _board.canUndo ? _undo : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _board.canUndo
                    ? GameColors.buttonBackground.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.undo_rounded,
                    color: _board.canUndo
                        ? const Color(0xFF776E65)
                        : const Color(0xFFCDC1B4),
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '되돌리기',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _board.canUndo
                          ? const Color(0xFF776E65)
                          : const Color(0xFFCDC1B4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

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
        const SizedBox(width: 8),
        _buildScoreBox('BEST', _board.bestScore),
        const SizedBox(width: 8),
        _buildScoreBox('MOVES', _board.moveCount),
        if (_comboStreak >= 2) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF39C12), Color(0xFFE74C3C)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'COMBO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '×$_comboStreak',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreBox(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GameColors.boardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: GameColors.scoreLabel,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: GameColors.scoreValue,
            ),
          ),
        ],
      ),
    );
  }
}

/// 점수 팝업 페인터
class _PopupPainter extends CustomPainter {
  final List<_ScorePopup> popups;
  _PopupPainter({required this.popups});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in popups) {
      final alpha = p.life.clamp(0.0, 1.0);
      final px = p.relX * size.width;
      final py = p.relY * size.height;
      final scale = 0.7 + 0.3 * alpha;

      final style = TextStyle(
        color: p.isCombo
            ? Color.lerp(const Color(0xFFFFD700), const Color(0xFFFF6B6B), 0.3)!
                .withValues(alpha: alpha)
            : const Color(0xFF776E65).withValues(alpha: alpha),
        fontSize: (p.isCombo ? 18 : 16) * scale,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.white.withValues(alpha: alpha * 0.8),
            blurRadius: 6,
          ),
          if (p.isCombo)
            Shadow(
              color: const Color(0xFFFF6B6B).withValues(alpha: alpha * 0.5),
              blurRadius: 12,
            ),
        ],
      );

      final tp = TextPainter(
        text: TextSpan(text: p.text, style: style),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
