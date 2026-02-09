import 'dart:math';

/// 블록 모양 정의
class BlockShape {
  final List<List<bool>> cells;
  final int colorIndex;

  const BlockShape({required this.cells, required this.colorIndex});

  int get width => cells.isEmpty ? 0 : cells[0].length;
  int get height => cells.length;
  int get cellCount {
    int count = 0;
    for (final row in cells) {
      for (final cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }
}

/// 점수 팝업
class ScorePopup {
  double x, y;
  final String text;
  final bool isCombo;
  double life;

  ScorePopup({
    required this.x,
    required this.y,
    required this.text,
    this.isCombo = false,
    this.life = 1.0,
  });
}

/// 블록 퍼즐 엔진
class BlockPuzzleEngine {
  static const int gridSize = 8;
  static const int shapesPerSet = 3;
  static const int colorCount = 8;

  // 그리드: -1 = 빈칸, 0~7 = 색상 인덱스
  List<List<int>> grid =
      List.generate(gridSize, (_) => List.filled(gridSize, -1));

  // 현재 3개 블록
  List<BlockShape?> currentShapes = [];

  // 게임 상태
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int totalLinesCleared = 0;
  bool isGameOver = false;

  // 클리어 애니메이션
  Set<int> clearedCellKeys = {}; // row * gridSize + col
  double clearAnimProgress = 0;
  bool isClearAnimating = false;

  // 팝업
  List<ScorePopup> popups = [];

  final Random _random = Random();

  // ========= 블록 모양 템플릿 =========
  static final List<List<List<bool>>> _shapeTemplates = [
    // === 1~2칸 (흔함) ===
    [[true]],
    [[true, true]],
    [[true], [true]],

    // === 3~4칸 ===
    [[true, true, true]],
    [[true], [true], [true]],
    [[true, true], [true, true]],

    // === 긴 블록 ===
    [[true, true, true, true]],
    [[true], [true], [true], [true]],
    [[true, true, true, true, true]],
    [[true], [true], [true], [true], [true]],

    // === L자 (4방향) ===
    [[true, false], [true, false], [true, true]],
    [[false, true], [false, true], [true, true]],
    [[true, true], [true, false], [true, false]],
    [[true, true], [false, true], [false, true]],

    // === T자 (4방향) ===
    [[true, true, true], [false, true, false]],
    [[false, true, false], [true, true, true]],
    [[true, false], [true, true], [true, false]],
    [[false, true], [true, true], [false, true]],

    // === S/Z자 ===
    [[true, true, false], [false, true, true]],
    [[false, true, true], [true, true, false]],

    // === 코너 (2x2에서 1칸 빠진) ===
    [[true, true], [true, false]],
    [[true, true], [false, true]],
    [[true, false], [true, true]],
    [[false, true], [true, true]],

    // === 3x3 (희귀) ===
    [[true, true, true], [true, true, true], [true, true, true]],
  ];

  // 가중치: 작은 블록이 더 자주 나옴
  static final List<int> _shapeWeights = [
    4, 3, 3, //  1~2칸 (3개)
    3, 3, 2, //  3~4칸 (3개)
    1, 1, 1, 1, // 긴 블록 (4개)
    1, 1, 1, 1, // L자    (4개)
    1, 1, 1, 1, // T자    (4개)
    1, 1, //       S/Z자  (2개)
    2, 2, 2, 2, // 코너   (4개)
    1, //          3x3    (1개)
  ];

  BlockPuzzleEngine();

  /// 새 게임
  void newGame() {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, -1));
    currentShapes = [];
    score = 0;
    combo = 0;
    maxCombo = 0;
    totalLinesCleared = 0;
    isGameOver = false;
    clearedCellKeys.clear();
    clearAnimProgress = 0;
    isClearAnimating = false;
    popups.clear();
    _generateNewShapes();
  }

  /// 가중치 기반 랜덤 블록 생성
  BlockShape _randomShape() {
    final totalWeight = _shapeWeights.reduce((a, b) => a + b);
    int roll = _random.nextInt(totalWeight);
    int idx = 0;
    for (int i = 0; i < _shapeWeights.length; i++) {
      roll -= _shapeWeights[i];
      if (roll < 0) {
        idx = i;
        break;
      }
    }
    return BlockShape(
      cells: _shapeTemplates[idx],
      colorIndex: _random.nextInt(colorCount),
    );
  }

  void _generateNewShapes() {
    currentShapes = List.generate(shapesPerSet, (_) => _randomShape());
  }

  /// 배치 가능 여부
  bool canPlaceShape(BlockShape shape, int gridX, int gridY) {
    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (!shape.cells[r][c]) continue;
        final gx = gridX + c;
        final gy = gridY + r;
        if (gx < 0 || gx >= gridSize || gy < 0 || gy >= gridSize) {
          return false;
        }
        if (grid[gy][gx] != -1) return false;
      }
    }
    return true;
  }

  /// 어딘가에 놓을 수 있는지
  bool canPlaceAnywhere(BlockShape shape) {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (canPlaceShape(shape, x, y)) return true;
      }
    }
    return false;
  }

  /// 블록 배치 → 라인 클리어 → 점수
  /// Returns total lines cleared
  int placeShape(int shapeIndex, int gridX, int gridY) {
    if (shapeIndex < 0 || shapeIndex >= currentShapes.length) return 0;
    final shape = currentShapes[shapeIndex];
    if (shape == null) return 0;
    if (!canPlaceShape(shape, gridX, gridY)) return 0;

    // 배치
    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (!shape.cells[r][c]) continue;
        grid[gridY + r][gridX + c] = shape.colorIndex;
      }
    }
    score += shape.cellCount;

    // 사용 처리
    currentShapes[shapeIndex] = null;

    // 완성된 줄 찾기
    final clearedRows = <int>[];
    final clearedCols = <int>[];

    for (int r = 0; r < gridSize; r++) {
      if (grid[r].every((c) => c != -1)) clearedRows.add(r);
    }
    for (int c = 0; c < gridSize; c++) {
      bool full = true;
      for (int r = 0; r < gridSize; r++) {
        if (grid[r][c] == -1) {
          full = false;
          break;
        }
      }
      if (full) clearedCols.add(c);
    }

    final totalCleared = clearedRows.length + clearedCols.length;

    if (totalCleared > 0) {
      combo++;
      if (combo > maxCombo) maxCombo = combo;

      // 점수: 줄당 10점 × 콤보 배수
      final linePoints = totalCleared * 10 * combo;
      score += linePoints;
      totalLinesCleared += totalCleared;

      // 클리어 애니메이션 셀 저장
      clearedCellKeys.clear();
      for (final r in clearedRows) {
        for (int c = 0; c < gridSize; c++) {
          clearedCellKeys.add(r * gridSize + c);
        }
      }
      for (final c in clearedCols) {
        for (int r = 0; r < gridSize; r++) {
          clearedCellKeys.add(r * gridSize + c);
        }
      }
      isClearAnimating = true;
      clearAnimProgress = 0;

      // 실제 클리어
      for (final r in clearedRows) {
        for (int c = 0; c < gridSize; c++) {
          grid[r][c] = -1;
        }
      }
      for (final c in clearedCols) {
        for (int r = 0; r < gridSize; r++) {
          grid[r][c] = -1;
        }
      }

      // 팝업
      if (totalCleared >= 4) {
        popups.add(ScorePopup(
            x: 0.5,
            y: 0.25,
            text: '🔥 MEGA! +$linePoints',
            isCombo: true));
      } else if (totalCleared >= 3) {
        popups.add(ScorePopup(
            x: 0.5,
            y: 0.25,
            text: '⚡ TRIPLE! +$linePoints',
            isCombo: true));
      } else if (totalCleared >= 2) {
        popups.add(ScorePopup(
            x: 0.5,
            y: 0.25,
            text: '✨ DOUBLE! +$linePoints',
            isCombo: true));
      } else {
        popups.add(ScorePopup(x: 0.5, y: 0.25, text: '+$linePoints'));
      }

      if (combo > 1) {
        popups.add(ScorePopup(
            x: 0.5,
            y: 0.32,
            text: '🎯 COMBO ×$combo',
            isCombo: true));
      }

      // 퍼펙트 클리어 (보드 전체 비움)
      if (grid.every((row) => row.every((c) => c == -1))) {
        score += 100;
        popups.add(ScorePopup(
            x: 0.5,
            y: 0.18,
            text: '💎 PERFECT CLEAR! +100',
            isCombo: true));
      }
    } else {
      combo = 0;
    }

    // 3개 다 사용 → 새 세트
    if (currentShapes.every((s) => s == null)) {
      _generateNewShapes();
    }

    // 게임 오버 체크
    _checkGameOver();

    return totalCleared;
  }

  void _checkGameOver() {
    for (final shape in currentShapes) {
      if (shape == null) continue;
      if (canPlaceAnywhere(shape)) return;
    }
    if (currentShapes.any((s) => s != null)) {
      isGameOver = true;
    }
  }

  /// 애니메이션 업데이트 (매 프레임)
  void updateAnimations() {
    if (isClearAnimating) {
      clearAnimProgress += 0.06;
      if (clearAnimProgress >= 1.0) {
        isClearAnimating = false;
        clearedCellKeys.clear();
        clearAnimProgress = 0;
      }
    }

    for (final p in popups) {
      p.life -= 0.018;
      p.y -= 0.002;
    }
    popups.removeWhere((p) => p.life <= 0);
  }

  int get filledCells {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell != -1) count++;
      }
    }
    return count;
  }
}
