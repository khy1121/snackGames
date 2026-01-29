import 'dart:math';

enum BlockValue {
  n9(-9), n8(-8), n7(-7), n6(-6), n5(-5), n4(-4), n3(-3), n2(-2), n1(-1),
  zero(0), // Special functionality? Or just 0.
  p1(1), p2(2), p3(3), p4(4), p5(5), p6(6), p7(7), p8(8), p9(9);

  final int value;
  const BlockValue(this.value);

  static BlockValue fromInt(int val) {
    return BlockValue.values.firstWhere((e) => e.value == val, orElse: () => p1);
  }
}

class BlockPosition {
  final int row;
  final int col;

  const BlockPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockPosition &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  /// 8-way adjacency check
  bool isNeighbor(BlockPosition other) {
    final dr = (row - other.row).abs();
    final dc = (col - other.col).abs();
    return (dr <= 1 && dc <= 1) && !(dr == 0 && dc == 0);
  }
  
  @override
  String toString() => '($row, $col)';
}

class PathResult {
  final bool success;
  final int scoreGained;
  final int combo;
  final List<BlockPosition> removedPositions;

  PathResult({
    required this.success,
    this.scoreGained = 0,
    this.combo = 0,
    this.removedPositions = const [],
  });
}

class ZeroSumBoard {
  static const int rows = 6;
  static const int columns = 5;

  List<List<BlockValue?>> grid;
  int score = 0;
  int movesLeft = 20; // Default moves
  int targetScore = 3000;

  final Random _random = Random();

  ZeroSumBoard({
    required this.grid,
    this.score = 0,
    this.movesLeft = 20,
    required this.targetScore,
  });

  factory ZeroSumBoard.newGame({int moves = 20, int target = 3000}) {
    final board = ZeroSumBoard(
      grid: List.generate(
        rows,
        (_) => List.filled(columns, null),
      ),
      movesLeft: moves,
      targetScore: target,
    );
    board._fillBoard();
    return board;
  }

  void _fillBoard() {
    for (int c = 0; c < columns; c++) {
      for (int r = rows - 1; r >= 0; r--) {
        if (grid[r][c] == null) {
          grid[r][c] = _generateRandomBlock();
        }
      }
    }
  }

  BlockValue _generateRandomBlock() {
    // Generate -9 to +9, excluding 0 mainly, or keeping probability balanced
    int val = 0;
    while (val == 0) {
      val = _random.nextInt(19) - 9; // -9 ~ 9
    }
    return BlockValue.fromInt(val);
  }

  /// Path Validation and Execution
  PathResult processPath(List<BlockPosition> path) {
    if (path.isEmpty) return PathResult(success: false);

    int sum = 0;
    for (final pos in path) {
      final block = grid[pos.row][pos.col];
      if (block != null) {
        sum += block.value;
      }
    }

    if (sum == 0 && path.length >= 2) {
      // Valid Zero Sum!
      movesLeft--;
      
      // Calculate Score
      // Base: 100 per block
      // Length Bonus: (Length - 2) * 50
      int pathScore = (path.length * 100) + ((path.length - 2) * 50);
      score += pathScore;

      // Remove blocks
      for (final pos in path) {
        grid[pos.row][pos.col] = null;
      }

      // Apply Gravity & Refill
      _applyGravity();
      _fillBoard();

      return PathResult(
        success: true,
        scoreGained: pathScore,
        removedPositions: path,
      );
    } else {
      // Invalid path, do nothing (or penalty?)
      // Usually in these games, invalid path just cancels.
      return PathResult(success: false);
    }
  }
  
  void _applyGravity() {
    for (int c = 0; c < columns; c++) {
      int writeRow = rows - 1;
      for (int readRow = rows - 1; readRow >= 0; readRow--) {
        if (grid[readRow][c] != null) {
          grid[writeRow][c] = grid[readRow][c];
          if (writeRow != readRow) {
            grid[readRow][c] = null;
          }
          writeRow--;
        }
      }
    }
  }

  bool get isGameOver => movesLeft <= 0 && score < targetScore;
  bool get isVictory => score >= targetScore;
}
