import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dice_board.dart';
import 'dice_widget.dart';
import 'dice_theme.dart';
import 'dice_effects.dart'; // Import VFX
import '../services/game_data_service.dart';
import '../services/challenge_service.dart';
import '../services/settings_service.dart';
import '../services/upgrade_service.dart';
import '../widgets/challenge_toast.dart';
import '../widgets/theme_shop_dialog.dart';
import '../widgets/animated_counter.dart';
import '../widgets/particle_effect.dart';

/// 주사위 머지 게임 페이지
class DiceGamePage extends StatefulWidget {
  const DiceGamePage({super.key});

  @override
  State<DiceGamePage> createState() => _DiceGamePageState();
}

class _DiceGamePageState extends State<DiceGamePage>
    with TickerProviderStateMixin {
  @override
  void dispose() {
    _eventController.close();
    if (_startTime != null) {
      final elapsedMinutes = DateTime.now().difference(_startTime!).inMinutes;
      if (elapsedMinutes > 0) {
        GameDataService.addPlayTime(elapsedMinutes);
      }
    }
    super.dispose();
  }

  late DiceMergeBoard _board;
  Set<(int, int)> _newDice = {};
  Set<(int, int)> _mergingDice = {};
  bool _isProcessing = false;
  late DiceThemeData _theme;

  // VFX State
  final StreamController<EffectEvent> _eventController = StreamController<EffectEvent>.broadcast();
  final GlobalKey _boardKey = GlobalKey(); // To get board position
  final GlobalKey<ScreenShakeState> _shakeKey = GlobalKey();
  
  int _comboStreak = 0; // Track consecutive merges for Lightning effect

  DateTime? _startTime;

  // 연속 플레이 보너스
  int _consecutiveGamesPlayed = 0;
  double _consecutiveBonusMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _board = DiceMergeBoard();
    _startTime = DateTime.now();
    _loadTheme();
  }
  
  void _loadTheme() {
    final themeId = GameDataService.getSelectedTheme();
    setState(() {
      _theme = DiceTheme.getTheme(themeId)
          .copyWith(enableShadows: false, blurRadius: 0);
    });
  }

  void _startNewGame() {
    setState(() {
      _board = DiceMergeBoard(bestScore: _board.bestScore);
      _newDice = {};
      _mergingDice = {};
      // _effectEvents = []; // Controller persists, no clear needed, stream handles it
      _isProcessing = false;
      _isProcessing = false;
      _startTime = DateTime.now();
      
      // 연속 플레이 보너스 증가
      _consecutiveGamesPlayed++;
      _updateConsecutiveBonus();
    });
  }

  void _updateConsecutiveBonus() {
    // 연속 플레이 횟수에 따라 점수 배율 증가
    if (_consecutiveGamesPlayed >= 10) {
      _consecutiveBonusMultiplier = 3.0; // 10회 이상: 3배
    } else if (_consecutiveGamesPlayed >= 7) {
      _consecutiveBonusMultiplier = 2.5; // 7-9회: 2.5배
    } else if (_consecutiveGamesPlayed >= 5) {
      _consecutiveBonusMultiplier = 2.0; // 5-6회: 2배
    } else if (_consecutiveGamesPlayed >= 3) {
      _consecutiveBonusMultiplier = 1.5; // 3-4회: 1.5배
    } else {
      _consecutiveBonusMultiplier = 1.0; // 1-2회: 보너스 없음
    }
  }

  void _onColumnTap(int col) {
    if (_isProcessing || _board.isGameOver) return;
    _startTime ??= DateTime.now();

    // Pre-compute result before any setState
    final result = _board.dropDice(col);

    if (result == null) {
      // No valid move, ignore
      return;
    }

    // Single setState with all state changes
    setState(() {
      _isProcessing = true;
      _newDice = {result.droppedAt};
      _mergingDice = {};
      for (final merge in result.merges) {
        _mergingDice.add(merge.resultPosition);
      }
    });

    // Trigger VFX after UI update
    _triggerVFX(result);

    // Single delayed cleanup
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      
      setState(() {
        _isProcessing = false;
        _newDice = {};
        _mergingDice = {};
      });

      if (_board.isGameOver) {
        _showGameOverDialog();
      }
    });
  }

  void _triggerVFX(DropResult result) {
    bool hasMerge = result.merges.isNotEmpty;

    if (hasMerge) {
      _comboStreak++;
      
      // Every merge triggers a small shake
      // _shakeKey.currentState?.shake(); (Disabled for emulator performance)
      
      // Every 10th combo triggers LIGHTNING
      if (_comboStreak > 0 && _comboStreak % 10 == 0) {
        _eventController.add(LightningEvent());
        // HapticFeedback.heavyImpact(); (Disabled for Emulator Performance)
      } else {
         if (SettingsService.vibrationEnabled.value) {
            // HapticFeedback.lightImpact(); (Disabled for Emulator Performance)
         }
      }
    } else {
      // No merge, reset streak? 
      // User said "10 combo", typically means consecutive. 
      // But in this game, it's hard to strict-combo. 
      // Let's keep it as "Cumulative Merge Counter" for now to make it fun, 
      // or reset if they want strict combo.
      // Let's reset to make it a "Streak".
      _comboStreak = 0;
    }



    // 1. Calculate Combo / Score Text
    if (result.scoreGained > 0) {
       Offset centerPos = _getBoardCenter();
       centerPos = _getCellPosition(result.droppedAt.$1, result.droppedAt.$2) ?? centerPos;

       final isMagic = result.merges.any((m) => m.isMagicClear);
       final isBigCombo = result.scoreGained > 200;

       final msg = isMagic 
          ? 'MAGIC! +${result.scoreGained}'
          : result.scoreGained > 100 
             ? 'COMBO! +${result.scoreGained}' 
             : '+${result.scoreGained}';
       
       final color = isMagic
          ? Colors.amber
          : Colors.white;

        _eventController.add(TextPopupEvent(
          msg,
          centerPos,
          color,
          fontSize: result.scoreGained > 500 ? 32 : 20,
        ));
        
        // Trigger Shockwave for Big Combo
        if (isBigCombo || isMagic) {
          _eventController.add(ShockwaveEvent(centerPos, isMagic ? Colors.amber : Colors.cyanAccent));
        }
    }

    // 2. Trigger Explosions for Merges (Optimized)
    for (final merge in result.merges) {
        // Trigger main explosion at center
        final centerPos = _getCellPosition(merge.resultPosition.$1, merge.resultPosition.$2);
        if (centerPos != null) {
           _eventController.add(ExplosionEvent(centerPos, Colors.purpleAccent, isMagic: merge.isMagicClear));
        }

        // Limit small explosions to max 4 per merge to reduce overhead
        final positions = merge.explodedPositions.take(4);
        for (final pos in positions) {
           final p = _getCellPosition(pos.$1, pos.$2);
           if (p != null) {
              _eventController.add(ExplosionEvent(p, Colors.orangeAccent.withValues(alpha: 0.5)));
           }
        }
    }
  }

  
  // Helper to find screen coordinates of a cell
  Offset? _getCellPosition(int row, int col) {
    // This is tricky because Board is dynamic. 
    // We will use a rough approximation based on BoardKey, 
    // OR just pass relative coordinates and let Overlay handle it within the board stack.
    // Better strategy: Put Overlay INSIDE the Board Widget? 
    // No, Board Widget is stateless/rebuilt.
    // Let's rely on RenderBox.
    
    final RenderBox? box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    
    final size = box.size;
    final cellWidth = (size.width - 16) / DiceMergeBoard.cols;
    final cellHeight = (size.height - 16) / DiceMergeBoard.rows;
    
    // Center of cell
    final dx = 8 + col * cellWidth + cellWidth / 2;
    final dy = 8 + row * cellHeight + cellHeight / 2;
    
    // Local to Board. We need to convert if Overlay is Global.
    // But we will put Overlay INSIDE the Board Stack.
    return Offset(dx, dy);
  }

  Offset _getBoardCenter() {
     final RenderBox? box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
     if (box == null) return const Offset(150, 300);
     return Offset(box.size.width / 2, box.size.height / 2);
  }

  Future<void> _checkAndShowChallengeToasts() async {
    final gamesPlayed = GameDataService.getTotalGamesPlayed();
    final bestScore = GameDataService.getBestScore('dice');
    
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
    // 업그레이드 배율 가져오기
    final scoreMultiplier = UpgradeService.getScoreMultiplier();
    final pointsMultiplier = UpgradeService.getPointsMultiplier();
    
    // 연속 플레이 보너스 적용
    final totalScoreMultiplier = scoreMultiplier * _consecutiveBonusMultiplier;
    final totalPointsMultiplier = pointsMultiplier * _consecutiveBonusMultiplier;
    
    // 적용된 최종 점수 (배율 적용)
    final finalScore = (_board.score * totalScoreMultiplier).round();
    
    // 점수 기록
    GameDataService.recordScore('dice', finalScore);

    // 플레이 타임 계산
    final duration = DateTime.now().difference(_startTime ?? DateTime.now());
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final playTimeStr = '$minutes:$seconds';
    
    // 리워드 계산 (예: 100점당 1P) + 포인트 배율
    final baseReward = (finalScore / 100).floor();
    final finalReward = (baseReward * totalPointsMultiplier).round();
    
    // XP 계산 (기본 10 + 점수/100)
    final xpGain = 10 + (finalScore ~/ 100);
    
    // 포인트 지급
    GameDataService.addPoints(finalReward);
    
    // XP 지급
    ChallengeService.addXP(xpGain);
    
    // 도전과제 진행도 업데이트 및 토스트 표시
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
              // 배경 블러 처리 (선택 사항)
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
                          color: const Color(0xFF1E1E2E), // Dark background
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6D28D9).withValues(alpha: 0.3),
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
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Score Display with multiplier
                            Column(
                              children: [
                                Text(
                                  '$finalScore',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFD700), // Gold
                                    height: 1.0,
                                  ),
                                ),
                                if (scoreMultiplier > 1.0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '×${scoreMultiplier.toStringAsFixed(1)} boost!',
                                    style: TextStyle(
                                      color: Colors.amber.shade300,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
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
                                  colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
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
                                            if (totalPointsMultiplier > 1.0) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '(×${totalPointsMultiplier.toStringAsFixed(1)})',
                                                style: TextStyle(
                                                  color: Colors.amber.shade300,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
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
                                      color: Colors.white.withValues( alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.card_giftcard, color: Colors.white, size: 24),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // 연속 플레이 보너스 표시
                            if (_consecutiveBonusMultiplier > 1.0)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '연속 플레이 보너스: ${_consecutiveGamesPlayed}회 (×${_consecutiveBonusMultiplier.toStringAsFixed(1)})',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 16),
                            
                            // Stats Row
                            Row(
                              children: [
                                // Merged Dice
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
                                          'MERGED DICE',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_board.totalMerges}',
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
                                // Play Time
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
                                          'PLAY TIME',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.5),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          playTimeStr,
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
                                      backgroundColor: const Color(0xFF8E2DE2),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 5,
                                      shadowColor: const Color(0xFF8E2DE2).withValues(alpha: 0.5),
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
                                      Navigator.pop(context); // Close dialog
                                      Navigator.pop(context); // Go back home
                                    },
                                    icon: const Icon(Icons.home, color: Colors.white),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Share Button
                            TextButton.icon(
                              onPressed: () {
                                // Share logic here
                              },
                              icon: const Icon(Icons.share, size: 16, color: Colors.grey),
                              label: const Text(
                                'SHARE MY SCORE',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.getTextTheme(_theme.fontHandle, Theme.of(context).textTheme),
      ),
      child: ScreenShake(
        key: _shakeKey,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: _theme.backgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildScoreAndNextDice(),
                  const SizedBox(height: 8),
                  
                  // Game Board Area with VFX Overlay
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: RepaintBoundary(
                        child: Stack(
                          children: [
                             // Actual Board
                             DiceBoardWidget(
                               key: _boardKey,
                               board: _board,
                               newDice: _newDice,
                               mergingDice: _mergingDice,
                               onColumnTap: _onColumnTap,
                               theme: _theme,
                             ),
                             
                              // VFX Overlay
                             // Position.fill ensures it matches Board size
                             Positioned.fill(
                               child: DiceEffectsOverlay(
                                 eventStream: _eventController.stream,
                               ),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Tap column to drop • Match 3 to merge • 6+6+6 = ✨Magic!',
                      style: TextStyle(
                        color: _theme.textColor.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (rest of methods: _buildScoreAndNextDice, _buildHeader, etc.) ...


  Widget _buildScoreAndNextDice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreBox('SCORE', _board.score, const Color(0xFF00B894)),
          if (_board.nextDice != null)
            Column(
              children: [
                Text(
                  'NEXT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                DiceWidget(
                  dice: _board.nextDice!,
                  size: 40,
                  theme: _theme, // Pass Theme
                ),
              ],
            ),
          _buildScoreBox('BEST', _board.bestScore, const Color(0xFFE17055)),
          // 연속 플레이 보너스 표시
          if (_consecutiveBonusMultiplier > 1.0)
            Column(
              children: [
                Text(
                  'STREAK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _theme.textColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'x${_consecutiveBonusMultiplier.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }



// ... (inside class)

  void _showThemeShop() {
    showDialog(
      context: context,
      builder: (context) => const ThemeShopDialog(),
    ).then((_) {
      _loadTheme(); // Refresh theme after shop closes
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // 뒤로가기
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: _theme.textColor, size: 20),
          ),

          Expanded(
            child: Text(
              '🎲 Dice Merge',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // 테마 상점
          IconButton(
            onPressed: _showThemeShop,
            icon: Icon(Icons.palette, color: _theme.textColor, size: 20),
          ),

          // 새 게임
          IconButton(
            onPressed: _startNewGame,
            icon: Icon(Icons.refresh, color: _theme.textColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedCounter(
            value: value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _theme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Google Fonts Shim (Mock for now, replace real Google Fonts later if needed)
class GoogleFonts {
  static TextTheme getTextTheme(String fontName, TextTheme base) {
    // Just return base for now, can implement real logic if package added
    return base;
  }
}
