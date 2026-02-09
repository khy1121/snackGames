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

/// 물리 파티클 (줄 클리어 폭발)
class BlockParticle {
  double x, y;
  double vx, vy;
  double size;
  double life;
  double rotation;
  double rotSpeed;
  final int colorIndex;

  BlockParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.colorIndex,
    this.life = 1.0,
    this.rotation = 0,
    this.rotSpeed = 0,
  });
}

/// 배치 착지 바운스
class PlaceBounce {
  final int row, col;
  final int colorIndex;
  double progress; // 0→1

  PlaceBounce({
    required this.row,
    required this.col,
    required this.colorIndex,
    this.progress = 0.0,
  });
}

/// 블록 퍼즐 엔진
class BlockPuzzleEngine {
  static const int gridSize = 8;
  static const int shapesPerSet = 3;
  static const int colorCount = 8;

  List<List<int>> grid =
      List.generate(gridSize, (_) => List.filled(gridSize, -1));

  List<BlockShape?> currentShapes = [];

  // 게임 상태
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int totalLinesCleared = 0;
  bool isGameOver = false;
  int placementStreak = 0;

  // 클리어 애니메이션
  Set<int> clearedCellKeys = {};
  double clearAnimProgress = 0;
  bool isClearAnimating = false;

  // 줄 완성 미리보기
  Set<int> previewHighlightKeys = {};

  // 파티클 물리
  List<BlockParticle> particles = [];
  static const double particleGravity = 0.25;
  static const double particleFriction = 0.98;

  // 배치 바운스
  List<PlaceBounce> placeBounces = [];

  // 화면 흔들림
  double shakeIntensity = 0;
  double shakeOffsetX = 0;
  double shakeOffsetY = 0;

  // 위기 모드
  bool isDangerMode = false;
  double dangerPulse = 0;

  List<ScorePopup> popups = [];

  final Random _random = Random();

  // ========= 블록 모양 템플릿 =========
  static final List<List<List<bool>>> _shapeTemplates = [
    [[true]],
    [[true, true]],
    [[true], [true]],
    [[true, true, true]],
    [[true], [true], [true]],
    [[true, true], [true, true]],
    [[true, true, true, true]],
    [[true], [true], [true], [true]],
    [[true, true, true, true, true]],
    [[true], [true], [true], [true], [true]],
    [[true, false], [true, false], [true, true]],
    [[false, true], [false, true], [true, true]],
    [[true, true], [true, false], [true, false]],
    [[true, true], [false, true], [false, true]],
    [[true, true, true], [false, true, false]],
    [[false, true, false], [true, true, true]],
    [[true, false], [true, true], [true, false]],
    [[false, true], [true, true], [false, true]],
    [[true, true, false], [false, true, true]],
    [[false, true, true], [true, true, false]],
    [[true, true], [true, false]],
    [[true, true], [false, true]],
    [[true, false], [true, true]],
    [[false, true], [true, true]],
    [[true, true, true], [true, true, true], [true, true, true]],
  ];

  static final List<int> _shapeWeights = [
    4, 3, 3, 3, 3, 2,
    1, 1, 1, 1,
    1, 1, 1, 1,
    1, 1, 1, 1,
    1, 1,
    2, 2, 2, 2,
    1,
  ];

  BlockPuzzleEngine();

  void newGame() {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, -1));
    currentShapes = [];
    score = 0;
    combo = 0;
    maxCombo = 0;
    totalLinesCleared = 0;
    isGameOver = false;
    placementStreak = 0;
    clearedCellKeys.clear();
    previewHighlightKeys.clear();
    clearAnimProgress = 0;
    isClearAnimating = false;
    particles.clear();
    placeBounces.clear();
    popups.clear();
    shakeIntensity = 0;
    shakeOffsetX = 0;
    shakeOffsetY = 0;
    isDangerMode = false;
    dangerPulse = 0;
    _generateNewShapes();
  }

  BlockShape _randomShape() {
    final totalWeight = _shapeWeights.reduce((a, b) => a + b);
    int roll = _random.nextInt(totalWeight);
    int idx = 0;
    for (int i = 0; i < _shapeWeights.length; i++) {
      roll -= _shapeWeights[i];
      if (roll < 0) { idx = i; break; }
    }
    return BlockShape(
      cells: _shapeTemplates[idx],
      colorIndex: _random.nextInt(colorCount),
    );
  }

  void _generateNewShapes() {
    currentShapes = List.generate(shapesPerSet, (_) => _randomShape());
  }

  bool canPlaceShape(BlockShape shape, int gridX, int gridY) {
    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (!shape.cells[r][c]) continue;
        final gx = gridX + c;
        final gy = gridY + r;
        if (gx < 0 || gx >= gridSize || gy < 0 || gy >= gridSize) return false;
        if (grid[gy][gx] != -1) return false;
      }
    }
    return true;
  }

  bool canPlaceAnywhere(BlockShape shape) {
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (canPlaceShape(shape, x, y)) return true;
      }
    }
    return false;
  }

  /// 고스트 위치에서 줄 완성 미리보기
  void updatePreviewHighlight(int shapeIndex, int gridX, int gridY) {
    previewHighlightKeys.clear();
    if (shapeIndex < 0 || shapeIndex >= currentShapes.length) return;
    final shape = currentShapes[shapeIndex];
    if (shape == null) return;
    if (!canPlaceShape(shape, gridX, gridY)) return;

    final tempGrid = List.generate(gridSize, (r) => List<int>.from(grid[r]));
    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (!shape.cells[r][c]) continue;
        tempGrid[gridY + r][gridX + c] = shape.colorIndex;
      }
    }

    for (int r = 0; r < gridSize; r++) {
      if (tempGrid[r].every((c) => c != -1)) {
        for (int c = 0; c < gridSize; c++) {
          previewHighlightKeys.add(r * gridSize + c);
        }
      }
    }
    for (int c = 0; c < gridSize; c++) {
      bool full = true;
      for (int r = 0; r < gridSize; r++) {
        if (tempGrid[r][c] == -1) { full = false; break; }
      }
      if (full) {
        for (int r = 0; r < gridSize; r++) {
          previewHighlightKeys.add(r * gridSize + c);
        }
      }
    }
  }

  void clearPreviewHighlight() {
    previewHighlightKeys.clear();
  }

  /// 블록 배치 → 라인 클리어 → 점수 → 파티클
  int placeShape(int shapeIndex, int gridX, int gridY, {double cellPx = 37}) {
    if (shapeIndex < 0 || shapeIndex >= currentShapes.length) return 0;
    final shape = currentShapes[shapeIndex];
    if (shape == null) return 0;
    if (!canPlaceShape(shape, gridX, gridY)) return 0;

    previewHighlightKeys.clear();

    // 배치 + 바운스
    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (!shape.cells[r][c]) continue;
        grid[gridY + r][gridX + c] = shape.colorIndex;
        placeBounces.add(PlaceBounce(
          row: gridY + r, col: gridX + c,
          colorIndex: shape.colorIndex,
        ));
      }
    }
    score += shape.cellCount;
    currentShapes[shapeIndex] = null;

    final clearedRows = <int>[];
    final clearedCols = <int>[];
    for (int r = 0; r < gridSize; r++) {
      if (grid[r].every((c) => c != -1)) clearedRows.add(r);
    }
    for (int c = 0; c < gridSize; c++) {
      bool full = true;
      for (int r = 0; r < gridSize; r++) {
        if (grid[r][c] == -1) { full = false; break; }
      }
      if (full) clearedCols.add(c);
    }

    final totalCleared = clearedRows.length + clearedCols.length;

    if (totalCleared > 0) {
      combo++;
      if (combo > maxCombo) maxCombo = combo;
      placementStreak = 0;

      final linePoints = totalCleared * 10 * combo;
      score += linePoints;
      totalLinesCleared += totalCleared;

      clearedCellKeys.clear();
      for (final r in clearedRows) {
        for (int c = 0; c < gridSize; c++) {
          clearedCellKeys.add(r * gridSize + c);
          _spawnParticles(c, r, grid[r][c], cellPx);
        }
      }
      for (final cc in clearedCols) {
        for (int r = 0; r < gridSize; r++) {
          final key = r * gridSize + cc;
          clearedCellKeys.add(key);
          if (!clearedRows.contains(r)) {
            _spawnParticles(cc, r, grid[r][cc], cellPx);
          }
        }
      }
      isClearAnimating = true;
      clearAnimProgress = 0;

      for (final r in clearedRows) {
        for (int c = 0; c < gridSize; c++) grid[r][c] = -1;
      }
      for (final cc in clearedCols) {
        for (int r = 0; r < gridSize; r++) grid[r][cc] = -1;
      }

      // 화면 흔들림
      if (totalCleared >= 4) {
        shakeIntensity = 12;
      } else if (totalCleared >= 2) {
        shakeIntensity = 7;
      } else if (combo > 1) {
        shakeIntensity = 5;
      } else {
        shakeIntensity = 3;
      }

      // 팝업
      if (totalCleared >= 4) {
        popups.add(ScorePopup(x: 0.5, y: 0.22, text: '🔥 MEGA! +$linePoints', isCombo: true));
      } else if (totalCleared >= 3) {
        popups.add(ScorePopup(x: 0.5, y: 0.22, text: '⚡ TRIPLE! +$linePoints', isCombo: true));
      } else if (totalCleared >= 2) {
        popups.add(ScorePopup(x: 0.5, y: 0.22, text: '✨ DOUBLE! +$linePoints', isCombo: true));
      } else {
        popups.add(ScorePopup(x: 0.5, y: 0.22, text: '+$linePoints'));
      }

      if (combo > 1) {
        popups.add(ScorePopup(x: 0.5, y: 0.29, text: '🎯 COMBO ×$combo', isCombo: true));
      }

      // 퍼펙트 클리어
      if (grid.every((row) => row.every((c) => c == -1))) {
        score += 100;
        shakeIntensity = 15;
        popups.add(ScorePopup(x: 0.5, y: 0.15, text: '💎 PERFECT CLEAR! +100', isCombo: true));
        for (int i = 0; i < 30; i++) {
          particles.add(BlockParticle(
            x: 150, y: 120,
            vx: (_random.nextDouble() - 0.5) * 15,
            vy: -_random.nextDouble() * 12 - 3,
            size: _random.nextDouble() * 6 + 3,
            colorIndex: _random.nextInt(colorCount),
            rotation: _random.nextDouble() * 6.28,
            rotSpeed: (_random.nextDouble() - 0.5) * 0.3,
          ));
        }
      }
    } else {
      combo = 0;
      placementStreak++;
      if (placementStreak >= 3 && placementStreak % 3 == 0) {
        final streakBonus = (placementStreak ~/ 3) * 5;
        score += streakBonus;
        popups.add(ScorePopup(x: 0.5, y: 0.25, text: '🧱 STREAK ×${placementStreak ~/ 3}! +$streakBonus', isCombo: true));
        shakeIntensity = 2;
      }
    }

    _updateDangerMode();

    if (currentShapes.every((s) => s == null)) {
      _generateNewShapes();
    }

    _checkGameOver();
    return totalCleared;
  }

  void _spawnParticles(int col, int row, int colorIdx, double cellPx) {
    final cx = (col + 0.5) * cellPx;
    final cy = (row + 0.5) * cellPx;
    final count = 2 + _random.nextInt(3);
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 6 + 2;
      particles.add(BlockParticle(
        x: cx, y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 3,
        size: _random.nextDouble() * 5 + 2,
        colorIndex: colorIdx >= 0 ? colorIdx : _random.nextInt(colorCount),
        rotation: _random.nextDouble() * 6.28,
        rotSpeed: (_random.nextDouble() - 0.5) * 0.2,
      ));
    }
  }

  void _updateDangerMode() {
    isDangerMode = filledCells >= (gridSize * gridSize * 0.65);
  }

  void _checkGameOver() {
    for (final shape in currentShapes) {
      if (shape == null) continue;
      if (canPlaceAnywhere(shape)) return;
    }
    if (currentShapes.any((s) => s != null)) {
      isGameOver = true;
      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          if (grid[r][c] != -1) {
            final cx = (c + 0.5) * 37.0;
            final cy = (r + 0.5) * 37.0;
            particles.add(BlockParticle(
              x: cx, y: cy,
              vx: (_random.nextDouble() - 0.5) * 8,
              vy: -_random.nextDouble() * 6 - 2,
              size: _random.nextDouble() * 5 + 3,
              colorIndex: grid[r][c],
              rotation: _random.nextDouble() * 6.28,
              rotSpeed: (_random.nextDouble() - 0.5) * 0.15,
            ));
          }
        }
      }
      shakeIntensity = 10;
    }
  }

  void updateAnimations() {
    if (isClearAnimating) {
      clearAnimProgress += 0.06;
      if (clearAnimProgress >= 1.0) {
        isClearAnimating = false;
        clearedCellKeys.clear();
        clearAnimProgress = 0;
      }
    }

    for (final p in particles) {
      p.vy += particleGravity;
      p.vx *= particleFriction;
      p.vy *= particleFriction;
      p.x += p.vx;
      p.y += p.vy;
      p.rotation += p.rotSpeed;
      p.life -= 0.02;
    }
    particles.removeWhere((p) => p.life <= 0 || p.y > 800);

    for (final b in placeBounces) {
      b.progress += 0.08;
    }
    placeBounces.removeWhere((b) => b.progress >= 1.0);

    if (shakeIntensity > 0) {
      shakeOffsetX = (_random.nextDouble() - 0.5) * 2 * shakeIntensity;
      shakeOffsetY = (_random.nextDouble() - 0.5) * 2 * shakeIntensity;
      shakeIntensity *= 0.88;
      if (shakeIntensity < 0.3) {
        shakeIntensity = 0;
        shakeOffsetX = 0;
        shakeOffsetY = 0;
      }
    }

    if (isDangerMode) {
      dangerPulse += 0.08;
      if (dangerPulse > 2 * pi) dangerPulse -= 2 * pi;
    }

    for (final p in popups) {
      p.life -= 0.016;
      p.y -= 0.0015;
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

  double get fillRatio => filledCells / (gridSize * gridSize);
}
