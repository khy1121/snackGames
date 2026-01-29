import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dice_board.dart';
import 'dice_widget.dart';
import '../services/game_data_service.dart';

/// 주사위 머지 게임 페이지
class DiceGamePage extends StatefulWidget {
  const DiceGamePage({super.key});

  @override
  State<DiceGamePage> createState() => _DiceGamePageState();
}

class _DiceGamePageState extends State<DiceGamePage>
    with TickerProviderStateMixin {
  late DiceMergeBoard _board;
  Set<(int, int)> _newDice = {};
  Set<(int, int)> _mergingDice = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _board = DiceMergeBoard();
  }

  void _startNewGame() {
    setState(() {
      _board = DiceMergeBoard(bestScore: _board.bestScore);
      _newDice = {};
      _mergingDice = {};
      _isProcessing = false;
    });
  }

  void _onColumnTap(int col) {
    if (_isProcessing || _board.isGameOver) return;

    setState(() {
      _isProcessing = true;
      _newDice = {};
      _mergingDice = {};
    });

    final result = _board.dropDice(col);

    if (result != null) {
      HapticFeedback.lightImpact();

      // 드롭된 위치 표시
      _newDice.add(result.droppedAt);

      // 머지된 위치 표시
      for (final merge in result.merges) {
        _mergingDice.add(merge.resultPosition);
      }

      setState(() {});

      // 애니메이션 후 상태 리셋
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _newDice = {};
            _mergingDice = {};
          });

          if (_board.isGameOver) {
            _showGameOverDialog();
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
    // 점수 기록
    GameDataService.recordScore('dice', _board.score);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3436),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Game Over!',
          style: TextStyle(
            color: Colors.white,
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
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Best: ${_board.bestScore}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.7),
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
              backgroundColor: const Color(0xFF00B894),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              _buildHeader(),
              const SizedBox(height: 8),

              // 점수판 + 다음 주사위 (한 줄로)
              _buildScoreAndNextDice(),
              const SizedBox(height: 8),

              // 게임 보드
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DiceBoardWidget(
                    board: _board,
                    newDice: _newDice,
                    mergingDice: _mergingDice,
                    onColumnTap: _onColumnTap,
                  ),
                ),
              ),

              // 안내 텍스트
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Tap column to drop • Match 3 to merge • 6+6+6 = ✨Magic!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                DiceWidget(
                  dice: _board.nextDice!,
                  size: 40,
                ),
              ],
            ),
          _buildScoreBox('BEST', _board.bestScore, const Color(0xFFE17055)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // 뒤로가기
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),

          const Expanded(
            child: Text(
              '🎲 Dice Merge',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 새 게임
          IconButton(
            onPressed: _startNewGame,
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
