import 'dart:math';

/// 2048 게임 보드 모델
class GameBoard {
  final int size;

  List<List<int>> tiles;
  int score;
  int bestScore;
  bool isGameOver;
  bool hasWon;
  int moveCount;
  bool canUndo;
  List<List<int>>? _undoTiles;
  int _undoScore = 0;
  
  GameBoard({
    required this.size,
    List<List<int>>? tiles,
    this.score = 0,
    this.bestScore = 0,
    this.isGameOver = false,
    this.hasWon = false,
    this.moveCount = 0,
    this.canUndo = false,
  }) : tiles = tiles ?? List.generate(size, (_) => List.filled(size, 0));
  
  /// 새 게임 시작
  factory GameBoard.newGame({int size = 4, int bestScore = 0}) {
    final board = GameBoard(size: size, bestScore: bestScore);
    board._addRandomTile();
    board._addRandomTile();
    return board;
  }
  
  /// 보드 복사
  GameBoard copy() {
    return GameBoard(
      size: size,
      tiles: tiles.map((row) => List<int>.from(row)).toList(),
      score: score,
      bestScore: bestScore,
      isGameOver: isGameOver,
      hasWon: hasWon,
      moveCount: moveCount,
      canUndo: canUndo,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'tiles': tiles.map((row) => row).toList(),
      'score': score,
      'bestScore': bestScore,
      'isGameOver': isGameOver,
      'hasWon': hasWon,
      'moveCount': moveCount,
      'canUndo': canUndo,
    };
  }

  /// JSON에서 복원
  factory GameBoard.fromJson(Map<String, dynamic> json) {
    final tiles = (json['tiles'] as List)
        .map((row) => List<int>.from(row as List))
        .toList();
    final size = json['size'] ?? tiles.length;
    return GameBoard(
      size: size,
      tiles: tiles,
      score: json['score'] ?? 0,
      bestScore: json['bestScore'] ?? 0,
      isGameOver: json['isGameOver'] ?? false,
      hasWon: json['hasWon'] ?? false,
      moveCount: json['moveCount'] ?? 0,
      canUndo: json['canUndo'] ?? false,
    );
  }
  
  /// 특정 셀의 값 가져오기
  int getTile(int row, int col) => tiles[row][col];
  
  /// 빈 칸 목록
  List<(int, int)> get emptyCells {
    final empty = <(int, int)>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (tiles[r][c] == 0) empty.add((r, c));
      }
    }
    return empty;
  }
  
  /// 현재 보드에서 가장 큰 타일 값
  int get highestTile {
    int max = 0;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (tiles[r][c] > max) max = tiles[r][c];
      }
    }
    return max;
  }
  
  /// 랜덤 타일 추가 (90% 확률로 2, 10% 확률로 4)
  void _addRandomTile() {
    final empty = emptyCells;
    if (empty.isEmpty) return;
    
    final random = Random();
    final (r, c) = empty[random.nextInt(empty.length)];
    tiles[r][c] = random.nextDouble() < 0.9 ? 2 : 4;
  }
  
  /// 이동 가능 여부 확인
  bool canMove() {
    // 빈 칸이 있으면 이동 가능
    if (emptyCells.isNotEmpty) return true;
    
    // 인접한 같은 숫자가 있으면 이동 가능
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final value = tiles[r][c];
        if (r < size - 1 && tiles[r + 1][c] == value) return true;
        if (c < size - 1 && tiles[r][c + 1] == value) return true;
      }
    }
    return false;
  }
  
  /// 되돌리기 (직전 1회)
  bool undo() {
    if (!canUndo || _undoTiles == null) return false;
    tiles = _undoTiles!;
    score = _undoScore;
    isGameOver = false;
    canUndo = false;
    _undoTiles = null;
    if (moveCount > 0) moveCount--;
    return true;
  }
  
  /// 한 줄 압축 (왼쪽으로)
  (List<int>, int, List<MergeInfo>) _compressLine(List<int> line) {
    // 0이 아닌 숫자만 추출
    final filtered = line.where((v) => v != 0).toList();
    final result = List<int>.filled(size, 0);
    final merges = <MergeInfo>[];
    int addedScore = 0;
    int pos = 0;
    
    int i = 0;
    while (i < filtered.length) {
      if (i + 1 < filtered.length && filtered[i] == filtered[i + 1]) {
        // 병합
        final merged = filtered[i] * 2;
        result[pos] = merged;
        addedScore += merged;
        merges.add(MergeInfo(pos, merged));
        i += 2;
      } else {
        result[pos] = filtered[i];
        i++;
      }
      pos++;
    }
    
    return (result, addedScore, merges);
  }
  
  /// 이동 수행
  MoveResult move(Direction direction) {
    // 되돌리기를 위한 상태 저장
    _undoTiles = tiles.map((row) => List<int>.from(row)).toList();
    _undoScore = score;
    
    final oldTiles = _undoTiles!;
    int addedScore = 0;
    final allMerges = <(int, int, int)>[]; // row, col, value
    
    bool rotated = false;
    bool reversed = false;
    
    // 방향에 따라 보드 변환
    switch (direction) {
      case Direction.left:
        break;
      case Direction.right:
        _reverseRows();
        reversed = true;
      case Direction.up:
        _transpose();
        rotated = true;
      case Direction.down:
        _transpose();
        _reverseRows();
        rotated = true;
        reversed = true;
    }
    
    // 각 줄 압축
    for (int r = 0; r < size; r++) {
      final (newLine, lineScore, merges) = _compressLine(tiles[r]);
      tiles[r] = newLine;
      addedScore += lineScore;
      
      for (final merge in merges) {
        // 원래 좌표로 변환
        int mr = r, mc = merge.position;
        if (reversed) mc = size - 1 - mc;
        if (rotated) {
          final temp = mr;
          mr = mc;
          mc = temp;
        }
        allMerges.add((mr, mc, merge.value));
      }
    }
    
    // 보드 복원
    if (reversed) _reverseRows();
    if (rotated) _transpose();
    
    // 이동 여부 확인
    bool moved = false;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (oldTiles[r][c] != tiles[r][c]) {
          moved = true;
          break;
        }
      }
      if (moved) break;
    }
    
    if (moved) {
      score += addedScore;
      if (score > bestScore) bestScore = score;
      _addRandomTile();
      moveCount++;
      canUndo = true;
      
      // 2048 도달 확인
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          if (tiles[r][c] == 2048 && !hasWon) {
            hasWon = true;
          }
        }
      }
      
      // 게임 오버 확인
      if (!canMove()) {
        isGameOver = true;
      }
    }
    
    return MoveResult(
      moved: moved,
      addedScore: addedScore,
      merges: allMerges,
    );
  }
  
  void _transpose() {
    final newTiles = List.generate(size, (r) => 
      List.generate(size, (c) => tiles[c][r]));
    tiles = newTiles;
  }
  
  void _reverseRows() {
    for (int r = 0; r < size; r++) {
      tiles[r] = tiles[r].reversed.toList();
    }
  }
}

/// 이동 방향
enum Direction { up, down, left, right }

/// 병합 정보
class MergeInfo {
  final int position;
  final int value;
  
  MergeInfo(this.position, this.value);
}

/// 이동 결과
class MoveResult {
  final bool moved;
  final int addedScore;
  final List<(int, int, int)> merges; // row, col, value
  
  MoveResult({
    required this.moved,
    required this.addedScore,
    required this.merges,
  });
}
