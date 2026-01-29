import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'zerosum_board.dart';
import 'zerosum_theme.dart';
import 'block_widget.dart';

/// Zero Sum 게임 메인 페이지
class ZeroSumPage extends StatefulWidget {
  const ZeroSumPage({super.key});

  @override
  State<ZeroSumPage> createState() => _ZeroSumPageState();
}

class _ZeroSumPageState extends State<ZeroSumPage>
    with TickerProviderStateMixin {
  late ZeroSumBoard _board;
  Set<BlockPosition> _newBlocks = {};
  Set<BlockPosition> _explodingBlocks = {};
  bool _isProcessing = false;
  int _lastCombo = 0;

  @override
  void initState() {
    super.initState();
    _board = ZeroSumBoard.newGame();
  }

  void _startNewGame() {
    final prevBest = _board.bestScore;
    setState(() {
      _board = ZeroSumBoard.newGame(bestScore: prevBest);
      _newBlocks = {};
      _explodingBlocks = {};
      _isProcessing = false;
      _lastCombo = 0;
    });
  }

  void _onColumnTap(int col) {
    if (_isProcessing || _board.isGameOver) return;

    setState(() {
      _isProcessing = true;
      _newBlocks = {};
      _explodingBlocks = {};
    });

    final droppedPos = _board.dropBlock(col);

    if (droppedPos != null) {
      HapticFeedback.lightImpact();
      _newBlocks.add(droppedPos);

      setState(() {});

      // 드롭 애니메이션 후 제로섬 체크
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _checkZeroSum();
      });
    } else {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _checkZeroSum() {
    final result = _board.checkAndExplode();

    if (result.hasExplosion) {
      HapticFeedback.mediumImpact();
      _lastCombo = result.comboLevel;

      setState(() {
        _explodingBlocks = result.explodedBlocks;
        _newBlocks = {};
      });

      // 폭발 애니메이션 후 상태 리셋
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;

        setState(() {
          _explodingBlocks = {};
        });

        // 연쇄 반응 체크
        final chainResult = _board.checkAndExplode();
        if (chainResult.hasExplosion) {
          _lastCombo = chainResult.comboLevel;
          setState(() {
            _explodingBlocks = chainResult.explodedBlocks;
          });

          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted) {
              _finishProcessing();
            }
          });
        } else {
          _finishProcessing();
        }
      });
    } else {
      _finishProcessing();
    }
  }

  void _finishProcessing() {
    setState(() {
      _isProcessing = false;
      _newBlocks = {};
      _explodingBlocks = {};
    });

    if (_board.isGameOver) {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ZeroSumColors.boardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Game Over!',
          style: TextStyle(
            color: ZeroSumColors.headerText,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚖️',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: ${_board.score}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ZeroSumColors.headerText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Best: ${_board.bestScore}',
              style: TextStyle(
                fontSize: 18,
                color: ZeroSumColors.headerText.withValues(alpha: 0.7),
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
              backgroundColor: ZeroSumColors.buttonBackground,
              foregroundColor: ZeroSumColors.buttonText,
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
    final size = MediaQuery.of(context).size;
    final boardWidth = (size.width - 32).clamp(280.0, 400.0);
    final cellSize = (boardWidth - 16) / ZeroSumBoard.columns - 4;

    return Scaffold(
      backgroundColor: ZeroSumColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 헤더
                _buildHeader(),
                const SizedBox(height: 20),

                // 점수/다음 블록
                _buildScoreAndPreview(),
                const SizedBox(height: 20),

                // 콤보 표시
                if (_lastCombo > 1)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: ZeroSumColors.explosion.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ZeroSumColors.explosion),
                    ),
                    child: Text(
                      '🔥 COMBO x$_lastCombo!',
                      style: const TextStyle(
                        color: ZeroSumColors.explosion,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                if (_lastCombo > 1) const SizedBox(height: 12),

                // 게임 보드
                _buildGameBoard(boardWidth, cellSize),
                const SizedBox(height: 20),

                // 안내 텍스트
                Text(
                  'Tap a column to drop the block',
                  style: TextStyle(
                    color: ZeroSumColors.headerText.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Make adjacent blocks sum to 0 💥',
                  style: TextStyle(
                    color: ZeroSumColors.headerText.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
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
        // 로고
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: ZeroSumCardColors.gradient,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⚖️',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 8),
              Text(
                'Zero Sum',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // 새 게임 버튼
        ElevatedButton.icon(
          onPressed: _startNewGame,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('New'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ZeroSumColors.buttonBackground,
            foregroundColor: ZeroSumColors.buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreAndPreview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildScoreBox('SCORE', _board.score),
        const SizedBox(width: 12),
        NextBlockPreview(value: _board.nextBlock),
        const SizedBox(width: 12),
        _buildScoreBox('BEST', _board.bestScore),
      ],
    );
  }

  Widget _buildScoreBox(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: ZeroSumColors.boardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: ZeroSumColors.scoreLabel,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ZeroSumColors.scoreValue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard(double boardWidth, double cellSize) {
    return Container(
      width: boardWidth,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ZeroSumColors.boardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 열 선택 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              ZeroSumBoard.columns,
              (col) => GestureDetector(
                onTap: () => _onColumnTap(col),
                child: Container(
                  width: cellSize,
                  height: 30,
                  decoration: BoxDecoration(
                    color: ZeroSumColors.cellBackground.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: ZeroSumColors.getBlockColor(_board.nextBlock)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 그리드
          ...List.generate(
            ZeroSumBoard.rows,
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  ZeroSumBoard.columns,
                  (col) => _buildCell(row, col, cellSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(int row, int col, double size) {
    final block = _board.grid[row][col];
    final pos = BlockPosition(row, col);
    final isNew = _newBlocks.contains(pos);
    final isExploding = _explodingBlocks.contains(pos);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ZeroSumColors.cellBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: block != null
          ? AnimatedBlockWidget(
              value: block,
              size: size - 4,
              isNew: isNew,
              isExploding: isExploding,
            )
          : null,
    );
  }
}
