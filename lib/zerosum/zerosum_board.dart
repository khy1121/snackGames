import 'dart:math';

/// 블록 값 (-2 ~ +2)
enum BlockValue {
  minusTwo(-2),
  minusOne(-1),
  zero(0),
  plusOne(1),
  plusTwo(2);

  final int value;
  const BlockValue(this.value);

  static BlockValue random() {
    final values = BlockValue.values;
    return values[Random().nextInt(values.length)];
  }

  static BlockValue? fromInt(int? v) {
    if (v == null) return null;
    return BlockValue.values.firstWhere((e) => e.value == v);
  }
}

/// 블록 위치
class BlockPosition {
  final int row;
  final int col;

  const BlockPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is BlockPosition && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  List<BlockPosition> get neighbors => [
        BlockPosition(row - 1, col), // 위
        BlockPosition(row + 1, col), // 아래
        BlockPosition(row, col - 1), // 왼쪽
        BlockPosition(row, col + 1), // 오른쪽
      ];
}

/// 제로섬 폭발 결과
class ExplosionResult {
  final Set<BlockPosition> explodedBlocks;
  final int scoreGained;
  final int comboLevel;

  ExplosionResult({
    required this.explodedBlocks,
    required this.scoreGained,
    required this.comboLevel,
  });

  bool get hasExplosion => explodedBlocks.isNotEmpty;
}

/// 제로섬 게임 보드
class ZeroSumBoard {
  static const int columns = 7;
  static const int rows = 12;

  late List<List<BlockValue?>> grid;
  BlockValue nextBlock;
  int score = 0;
  int bestScore = 0;
  bool isGameOver = false;



  ZeroSumBoard._internal({required this.nextBlock, this.bestScore = 0}) {
    grid = List.generate(rows, (_) => List.filled(columns, null));
  }

  factory ZeroSumBoard.newGame({int bestScore = 0}) {
    return ZeroSumBoard._internal(
      nextBlock: BlockValue.random(),
      bestScore: bestScore,
    );
  }

  /// 다음 블록 생성
  void _generateNextBlock() {
    nextBlock = BlockValue.random();
  }

  /// 특정 열에 블록 드롭
  /// 반환: 드롭된 위치 (null이면 열이 꽉 참)
  BlockPosition? dropBlock(int col) {
    if (col < 0 || col >= columns || isGameOver) return null;

    // 맨 위가 차있으면 드롭 불가
    if (grid[0][col] != null) return null;

    // 바닥부터 비어있는 위치 찾기
    int targetRow = rows - 1;
    for (int r = rows - 1; r >= 0; r--) {
      if (grid[r][col] == null) {
        targetRow = r;
        break;
      } else if (r < targetRow) {
        targetRow = r - 1;
      }
    }

    // 실제 빈 위치 찾기
    for (int r = rows - 1; r >= 0; r--) {
      if (grid[r][col] == null) {
        targetRow = r;
        break;
      }
    }

    grid[targetRow][col] = nextBlock;
    _generateNextBlock();

    // 게임 오버 체크
    _checkGameOver();

    return BlockPosition(targetRow, col);
  }

  /// 제로섬 조합 찾기 및 폭발 처리
  ExplosionResult checkAndExplode() {
    Set<BlockPosition> allExploded = {};
    int totalScore = 0;
    int combo = 0;

    while (true) {
      final groups = _findZeroSumGroups();
      if (groups.isEmpty) break;

      combo++;
      for (final group in groups) {
        allExploded.addAll(group);
        // 점수: (블록 수) * 10 * 콤보 배수
        totalScore += group.length * 10 * combo;
      }

      // 블록 제거
      for (final pos in allExploded) {
        grid[pos.row][pos.col] = null;
      }

      // 중력 적용
      _applyGravity();
    }

    score += totalScore;
    if (score > bestScore) {
      bestScore = score;
    }

    return ExplosionResult(
      explodedBlocks: allExploded,
      scoreGained: totalScore,
      comboLevel: combo,
    );
  }

  /// 제로섬이 되는 연결된 블록 그룹 찾기
  List<Set<BlockPosition>> _findZeroSumGroups() {
    List<Set<BlockPosition>> result = [];
    Set<BlockPosition> visited = {};

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        if (grid[r][c] == null) continue;

        final pos = BlockPosition(r, c);
        if (visited.contains(pos)) continue;

        // BFS/DFS로 연결된 블록 그룹 찾기
        final groups = _findConnectedZeroSumGroups(pos, visited);
        result.addAll(groups);
      }
    }

    return result;
  }

  /// 특정 위치에서 시작하여 제로섬 그룹 찾기
  List<Set<BlockPosition>> _findConnectedZeroSumGroups(
    BlockPosition start,
    Set<BlockPosition> globalVisited,
  ) {
    List<Set<BlockPosition>> result = [];

    // 모든 가능한 연결 조합 체크
    // 2개 이상의 인접 블록 조합 중 합이 0인 것 찾기
    final groups = _findAllZeroSumCombinations(start);

    for (final group in groups) {
      if (group.length >= 2) {
        result.add(group);
        globalVisited.addAll(group);
      }
    }

    return result;
  }

  /// 특정 위치에서 시작하여 합이 0이 되는 모든 조합 찾기
  List<Set<BlockPosition>> _findAllZeroSumCombinations(BlockPosition start) {
    List<Set<BlockPosition>> result = [];
    
    // BFS로 연결된 블록들 모두 찾기
    Set<BlockPosition> connected = {};
    List<BlockPosition> queue = [start];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (connected.contains(current)) continue;
      if (!_isValidPosition(current)) continue;
      if (grid[current.row][current.col] == null) continue;
      
      connected.add(current);
      
      for (final neighbor in current.neighbors) {
        if (!connected.contains(neighbor) && _isValidPosition(neighbor)) {
          if (grid[neighbor.row][neighbor.col] != null) {
            queue.add(neighbor);
          }
        }
      }
    }
    
    // 연결된 블록들 중 합이 0인 부분집합 찾기
    final connectedList = connected.toList();
    
    // 2개 이상의 조합 체크 (최대 6개까지만 체크하여 성능 유지)
    for (int size = 2; size <= min(6, connectedList.length); size++) {
      _findSubsetsWithZeroSum(connectedList, size, 0, {}, result);
    }
    
    return result;
  }

  void _findSubsetsWithZeroSum(
    List<BlockPosition> blocks,
    int targetSize,
    int startIdx,
    Set<BlockPosition> current,
    List<Set<BlockPosition>> result,
  ) {
    if (current.length == targetSize) {
      // 합이 0인지 체크
      int sum = 0;
      
      for (final pos in current) {
        final block = grid[pos.row][pos.col]!;
        sum += block.value;
      }
      
      // 0 블록이 있으면 조커 역할 - 나머지가 0이면 폭발
      // 또는 전체 합이 0이면 폭발
      if (sum == 0 && _isConnectedGroup(current)) {
        result.add(Set.from(current));
      }
      return;
    }
    
    for (int i = startIdx; i < blocks.length; i++) {
      current.add(blocks[i]);
      _findSubsetsWithZeroSum(blocks, targetSize, i + 1, current, result);
      current.remove(blocks[i]);
    }
  }

  /// 블록 그룹이 서로 연결되어 있는지 확인
  bool _isConnectedGroup(Set<BlockPosition> group) {
    if (group.length <= 1) return true;
    
    Set<BlockPosition> visited = {};
    List<BlockPosition> queue = [group.first];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current)) continue;
      if (!group.contains(current)) continue;
      
      visited.add(current);
      
      for (final neighbor in current.neighbors) {
        if (group.contains(neighbor) && !visited.contains(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    
    return visited.length == group.length;
  }

  bool _isValidPosition(BlockPosition pos) {
    return pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < columns;
  }

  /// 중력 적용 - 빈 공간 아래로 블록 떨어뜨리기
  void _applyGravity() {
    for (int c = 0; c < columns; c++) {
      // 각 열에서 빈 공간 없이 블록 정렬
      List<BlockValue> columnBlocks = [];
      for (int r = rows - 1; r >= 0; r--) {
        if (grid[r][c] != null) {
          columnBlocks.add(grid[r][c]!);
        }
      }
      
      // 아래부터 채우기
      for (int r = rows - 1; r >= 0; r--) {
        final idx = rows - 1 - r;
        grid[r][c] = idx < columnBlocks.length ? columnBlocks[idx] : null;
      }
    }
  }

  /// 게임 오버 체크
  void _checkGameOver() {
    // 모든 열의 맨 위가 차있으면 게임 오버
    for (int c = 0; c < columns; c++) {
      if (grid[0][c] != null) {
        isGameOver = true;
        return;
      }
    }
  }

  /// 특정 열의 높이 (쌓인 블록 수)
  int getColumnHeight(int col) {
    for (int r = 0; r < rows; r++) {
      if (grid[r][col] != null) {
        return rows - r;
      }
    }
    return 0;
  }
}
