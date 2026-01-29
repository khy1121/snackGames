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

/// 블록 위치 (Hex Grid)
class BlockPosition {
  final int row;
  final int col;

  const BlockPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is BlockPosition && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  /// Hex Grid 6방향 이웃
  /// 짝수 행(Even Rows)  vs 홀수 행(Odd Rows) 오프셋 고려
  /// Even Row (0, 2...): (r-1, c-1), (r-1, c), (r, c-1), (r, c+1), (r+1, c-1), (r+1, c)
  /// Odd Row (1, 3...):  (r-1, c), (r-1, c+1), (r, c-1), (r, c+1), (r+1, c), (r+1, c+1)
  List<BlockPosition> get neighbors {
    // 공통: 좌우
    final list = [
      BlockPosition(row, col - 1),
      BlockPosition(row, col + 1),
    ];

    if (row.isEven) {
      // 짝수 행: 위/아래의 왼쪽 & 중앙
      list.add(BlockPosition(row - 1, col - 1));
      list.add(BlockPosition(row - 1, col));
      list.add(BlockPosition(row + 1, col - 1));
      list.add(BlockPosition(row + 1, col));
    } else {
      // 홀수 행: 위/아래의 중앙 & 오른쪽
      list.add(BlockPosition(row - 1, col));
      list.add(BlockPosition(row - 1, col + 1));
      list.add(BlockPosition(row + 1, col));
      list.add(BlockPosition(row + 1, col + 1));
    }
    return list;
  }
}

/// 제로섬 폭발 결과
class ExplosionResult {
  final Map<BlockPosition, BlockValue> explodedBlocks;
  final int scoreGained;
  final int comboLevel;

  ExplosionResult({
    required this.explodedBlocks,
    required this.scoreGained,
    required this.comboLevel,
  });

  bool get hasExplosion => explodedBlocks.isNotEmpty;
}

/// 제로섬 게임 보드 (Hex Ver.)
class ZeroSumBoard {
  static const int columns = 8; // 버블 슈터는 보통 가로가 넓음 (또는 8개)
  static const int rows = 12; // 세로 높이

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
  void generateNextBlock() {
    nextBlock = BlockValue.random();
  }

  /// 특정 위치에 블록 배치 (슈팅 후 착지)
  /// 반환: 성공 여부
  bool placeBlock(int row, int col, BlockValue value) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) return false;
    
    // 홀수 행은 마지막 컬럼을 쓰지 않는 경우도 있지만 (7개 vs 8개)
    // 여기서는 8x12 그리드를 꽉 채우되 시각적으로만 오프셋 처리
    
    if (grid[row][col] != null) return false;

    grid[row][col] = value;

    // 게임 오버 체크: 최하단 행에 블록이 생기면?
    // 보통 슈팅 게임은 바닥 라인(데드라인)을 넘으면 게임 오버
    if (row >= rows - 1) {
      isGameOver = true;
    }

    return true;
  }
  
  /// 주변(연결된) 모든 빈 공간이 아닌 블록들을 반환 (Floating Cluster Check용)
  Set<BlockPosition> _findConnectedCluster(BlockPosition start) {
      if (grid[start.row][start.col] == null) return {};
      
      final cluster = <BlockPosition>{};
      final queue = [start];
      cluster.add(start);
      
      while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          
          for (final neighbor in current.neighbors) {
              if (_isValid(neighbor) && 
                  grid[neighbor.row][neighbor.col] != null && 
                  !cluster.contains(neighbor)) {
                  cluster.add(neighbor);
                  queue.add(neighbor);
              }
          }
      }
      return cluster;
  }
  
  /// 천장에 붙어있는(혹은 천장과 연결된) 모든 블록의 클러스터를 찾습니다.
  Set<BlockPosition> findAllCeilingConnectedBlocks() {
      final connected = <BlockPosition>{};
      // Row 0의 모든 블록 확인
      for (int c = 0; c < columns; c++) {
          if (grid[0][c] != null) {
             connected.addAll(_findConnectedCluster(BlockPosition(0, c)));
          }
      }
      return connected;
  }

  /// 공중에 뜬 블록(Cluster) 제거
  Set<BlockPosition> removeFloatingBlocks() {
      final ceilingConnected = findAllCeilingConnectedBlocks();
      final floating = <BlockPosition>{};
      
      for (int r = 0; r < rows; r++) {
          for (int c = 0; c < columns; c++) {
              if (grid[r][c] != null) {
                  final pos = BlockPosition(r, c);
                  if (!ceilingConnected.contains(pos)) {
                      floating.add(pos);
                  }
              }
          }
      }
      
      for (final pos in floating) {
          grid[pos.row][pos.col] = null;
          // 공중 부양 블록 제거 점수 (보너스)
          score += 100; 
      }
      
      return floating;
  }

  ExplosionResult checkAndExplode() {
    Map<BlockPosition, BlockValue> allExploded = {};
    int totalScore = 0;
    int combo = 0;

    // 반복적으로 체크 (연쇄 폭발)
    while (true) {
      final groups = _findZeroSumGroups();
      if (groups.isEmpty) break;

      combo++;
      for (final group in groups) {
        for (final pos in group) {
           if (grid[pos.row][pos.col] != null) {
               allExploded[pos] = grid[pos.row][pos.col]!;
           }
        }
        // 점수: (블록 수) * 20 * 콤보 배수
        totalScore += group.length * 20 * combo;
      }

      // 블록 제거
      for (final pos in allExploded.keys) {
        grid[pos.row][pos.col] = null;
      }
    }
    
    // Floating 제거는 한 번만 수행 (옵션)
    final floating = removeFloatingBlocks();
    // allExploded.addAll(floating); // Type Mismatch (Set vs Map) -> Disabled

    score += totalScore;
    if (score > bestScore) bestScore = score;

    return ExplosionResult(
      explodedBlocks: allExploded,
      scoreGained: totalScore,
      comboLevel: combo,
    );
  }

  /// 합이 0이 되는 인접 그룹 찾기 (Hex Neighbor Logic)
  List<Set<BlockPosition>> _findZeroSumGroups() {
    List<Set<BlockPosition>> groups = [];
    Set<BlockPosition> visited = {}; // 중복 그룹 방지 (메인 블록 기준)

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        final pos = BlockPosition(r, c);
        final val = grid[r][c];
        if (val == null) continue;

        // 주변 6방향 확인
        for (final n in pos.neighbors) {
          if (!_isValid(n)) continue;
          final nVal = grid[n.row][n.col];
          if (nVal == null) continue;

          // 두 블록의 합이 0이면 그룹화
          if (val.value + nVal.value == 0) {
            // 이미 처리된 쌍인지 확인은 어렵지만, Set으로 결과 관리하면 됨
            // 여기서는 단순하게 "현재 블록 + 이웃 블록"을 하나의 그룹으로 간주
            // 만약 A(-1)가 B(+1), C(+1)과 모두 0이면?
            // A, B, C 모두 터져야 함.
            
            // 더 나은 로직: 
            // "나와 합쳐서 0이 되는 모든 이웃"을 찾아서 한 번에 터트림
          }
        }
      }
    }
    
    // 개선된 로직: 모든 유효한 블록에 대해, "나 + 이웃 == 0"인 경우들을 수집
    Set<BlockPosition> toExplode = {};
    
    for (int r = 0; r < rows; r++) {
        for (int c = 0; c < columns; c++) {
            final pos = BlockPosition(r, c);
            final val = grid[r][c];
            if (val == null) continue;
            
            for (final n in pos.neighbors) {
                if (!_isValid(n)) continue;
                final nVal = grid[n.row][n.col];
                if (nVal != null && val.value + nVal.value == 0) {
                    toExplode.add(pos);
                    toExplode.add(n);
                }
            }
        }
    }
    
    if (toExplode.isNotEmpty) {
        groups.add(toExplode);
    }

    return groups;
  }

  bool _isValid(BlockPosition pos) {
    return pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < columns;
  }
}
