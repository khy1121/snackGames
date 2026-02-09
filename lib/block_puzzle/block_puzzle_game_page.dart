import 'dart:math';
import 'package:flutter/material.dart';
import 'block_puzzle_engine.dart';
import '../services/game_data_service.dart';
import '../services/vibration_service.dart';
import '../services/sfx_service_stub.dart'
    if (dart.library.html) '../services/sfx_service.dart';

/// 블록 블리츠 게임 페이지
class BlockPuzzleGamePage extends StatefulWidget {
  const BlockPuzzleGamePage({super.key});

  @override
  State<BlockPuzzleGamePage> createState() => _BlockPuzzleGamePageState();
}

class _BlockPuzzleGamePageState extends State<BlockPuzzleGamePage>
    with SingleTickerProviderStateMixin {
  final BlockPuzzleEngine _engine = BlockPuzzleEngine();
  late AnimationController _ticker;
  DateTime? _startTime;

  // 드래그 상태
  int? _draggingIndex;
  Offset? _dragPosition;
  int? _ghostX, _ghostY;
  bool _ghostValid = false;

  // 레이아웃 캐시
  double _gridLeft = 0;
  double _gridTop = 0;
  double _gridPixelSize = 0;
  double _cellSize = 0;
  double _trayTop = 0;
  double _trayHeight = 0;
  List<Rect> _shapeBounds = [];

  static const List<Color> blockColors = [
    Color(0xFFFF6B6B), Color(0xFFFECA57), Color(0xFF48DBFB), Color(0xFF00D2D3),
    Color(0xFFFF9FF3), Color(0xFF54A0FF), Color(0xFF5F27CD), Color(0xFF00B894),
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _engine.newGame();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_gameLoop);
    _ticker.repeat();
    GameDataService.setLastPlayedGame('blockpuzzle');
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (_startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!).inMinutes;
      if (elapsed > 0) GameDataService.addPlayTime(elapsed);
    }
    super.dispose();
  }

  void _gameLoop() {
    _engine.updateAnimations();
    setState(() {});
  }

  void _calculateLayout(double width, double height) {
    const padding = 8.0;
    _gridPixelSize = min(width - 2 * padding, height * 0.62);
    _cellSize = _gridPixelSize / BlockPuzzleEngine.gridSize;
    _gridLeft = (width - _gridPixelSize) / 2;
    _gridTop = 4;
    _trayTop = _gridTop + _gridPixelSize + 12;
    _trayHeight = height - _trayTop - 4;
    _shapeBounds = [];
    final trayWidth = width - 2 * padding;
    final shapeAreaWidth = trayWidth / 3;
    for (int i = 0; i < 3; i++) {
      _shapeBounds.add(Rect.fromLTWH(padding + i * shapeAreaWidth, _trayTop, shapeAreaWidth, _trayHeight));
    }
  }

  // ========= 드래그 핸들링 =========

  void _onPanStart(DragStartDetails details) {
    if (_engine.isGameOver || _engine.isClearAnimating) return;
    final pos = details.localPosition;
    for (int i = 0; i < _shapeBounds.length && i < _engine.currentShapes.length; i++) {
      if (_engine.currentShapes[i] == null) continue;
      if (_shapeBounds[i].contains(pos)) {
        _draggingIndex = i;
        _dragPosition = pos;
        _updateGhostPosition(pos);
        VibrationService.light();
        break;
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_draggingIndex == null) return;
    _dragPosition = details.localPosition;
    _updateGhostPosition(_dragPosition!);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (_draggingIndex == null) return;
    if (_ghostValid && _ghostX != null && _ghostY != null) {
      final cleared = _engine.placeShape(_draggingIndex!, _ghostX!, _ghostY!, cellPx: _cellSize);
      if (cleared > 0) {
        VibrationService.medium();
        SfxService().playButtonClick();
      } else {
        VibrationService.light();
        SfxService().playDropDice();
      }
      if (_engine.isGameOver) _onGameOver();
    }
    _draggingIndex = null;
    _dragPosition = null;
    _ghostX = null;
    _ghostY = null;
    _ghostValid = false;
    _engine.clearPreviewHighlight();
    setState(() {});
  }

  void _updateGhostPosition(Offset pos) {
    if (_draggingIndex == null) return;
    final shape = _engine.currentShapes[_draggingIndex!];
    if (shape == null) return;
    final visualY = pos.dy - 50;
    final gx = ((pos.dx - _gridLeft) / _cellSize - shape.width / 2).round();
    final gy = ((visualY - _gridTop) / _cellSize - shape.height / 2).round();
    _ghostX = gx;
    _ghostY = gy;
    _ghostValid = _engine.canPlaceShape(shape, gx, gy);
    if (_ghostValid) {
      _engine.updatePreviewHighlight(_draggingIndex!, gx, gy);
    } else {
      _engine.clearPreviewHighlight();
    }
  }

  // ========= 게임 오버 =========

  void _onGameOver() {
    final finalScore = _engine.score;
    GameDataService.recordScore('blockpuzzle', finalScore);
    final points = (finalScore * 0.5).round();
    GameDataService.addPoints(points);
    VibrationService.success();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _showGameOverDialog(finalScore, points);
    });
  }

  void _showGameOverDialog(int finalScore, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🧩 게임 종료!',
            style: TextStyle(color: Colors.white, fontSize: 22), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFE17055), Color(0xFFFF7675)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                const Text('최종 점수', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('$finalScore',
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 12),
            Text('🏆 최고 기록: ${GameDataService.getBestScore('blockpuzzle')}',
                style: const TextStyle(color: Color(0xFFFD79A8), fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('💰 +$points 포인트 획득!',
                  style: const TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildStatItem('줄 클리어', '${_engine.totalLinesCleared}줄', const Color(0xFF48DBFB)),
              _buildStatItem('최고 콤보', '×${_engine.maxCombo}', const Color(0xFFFECA57)),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('나가기', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _engine.newGame(); _startTime = DateTime.now(); });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE17055),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('다시 하기', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }

  void _showPauseMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('⏸️ 일시정지', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.play_arrow),
              label: const Text('이어하기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE17055),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: SizedBox(height: 48, child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(ctx); setState(() => _engine.newGame()); },
              icon: const Icon(Icons.refresh, size: 20), label: const Text('새 게임'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ))),
            const SizedBox(width: 12),
            Expanded(child: SizedBox(height: 48, child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              icon: const Icon(Icons.exit_to_app, size: 20), label: const Text('나가기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ))),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildScoreBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: LayoutBuilder(builder: (context, constraints) {
                _calculateLayout(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: BlockPuzzlePainter(
                      engine: _engine,
                      gridLeft: _gridLeft, gridTop: _gridTop,
                      gridPixelSize: _gridPixelSize, cellSize: _cellSize,
                      trayTop: _trayTop, trayHeight: _trayHeight,
                      shapeBounds: _shapeBounds,
                      draggingIndex: _draggingIndex, dragPosition: _dragPosition,
                      ghostX: _ghostX, ghostY: _ghostY, ghostValid: _ghostValid,
                      blockColors: blockColors,
                    ),
                  ),
                );
              }),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        const Expanded(
          child: Text('🧩 블록 블리츠',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center),
        ),
        IconButton(
          onPressed: _showPauseMenu,
          icon: const Icon(Icons.pause_circle_outline, color: Colors.white, size: 24),
        ),
      ]),
    );
  }

  Widget _buildScoreBar() {
    final dangerColor = _engine.isDangerMode
        ? Color.lerp(Colors.transparent, const Color(0xFFFF6B6B), (sin(_engine.dangerPulse) + 1) / 2 * 0.3)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          dangerColor ?? const Color(0xFF1A1A2E).withValues(alpha: 0.8),
          const Color(0xFF16213E).withValues(alpha: 0.8),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: _engine.isDangerMode
            ? Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.4), width: 1.5)
            : null,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildScoreColumn('점수', '${_engine.score}', const Color(0xFFE17055), 24),
        Container(width: 1, height: 30, color: Colors.white24),
        _buildScoreColumn('콤보', _engine.combo > 0 ? '×${_engine.combo}' : '-',
            _engine.combo > 0 ? const Color(0xFFFECA57) : Colors.white38, 20),
        Container(width: 1, height: 30, color: Colors.white24),
        _buildScoreColumn('줄', '${_engine.totalLinesCleared}', const Color(0xFF48DBFB), 20),
        Container(width: 1, height: 30, color: Colors.white24),
        _buildScoreColumn('최고', '${GameDataService.getBestScore('blockpuzzle')}',
            const Color(0xFFFD79A8), 18),
      ]),
    );
  }

  Widget _buildScoreColumn(String label, String value, Color color, double fontSize) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      Text(value, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
    ]);
  }
}

// ====================================================
// 블록 블리츠 커스텀 페인터
// ====================================================

class BlockPuzzlePainter extends CustomPainter {
  final BlockPuzzleEngine engine;
  final double gridLeft, gridTop, gridPixelSize, cellSize;
  final double trayTop, trayHeight;
  final List<Rect> shapeBounds;
  final int? draggingIndex;
  final Offset? dragPosition;
  final int? ghostX, ghostY;
  final bool ghostValid;
  final List<Color> blockColors;

  BlockPuzzlePainter({
    required this.engine,
    required this.gridLeft, required this.gridTop,
    required this.gridPixelSize, required this.cellSize,
    required this.trayTop, required this.trayHeight,
    required this.shapeBounds,
    this.draggingIndex, this.dragPosition,
    this.ghostX, this.ghostY,
    required this.ghostValid,
    required this.blockColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 화면 흔들림 적용
    canvas.save();
    canvas.translate(engine.shakeOffsetX, engine.shakeOffsetY);

    _drawGrid(canvas);
    _drawPreviewHighlight(canvas);
    _drawPlacedBlocks(canvas);
    _drawPlaceBounces(canvas);
    _drawClearAnimation(canvas);
    _drawGhostPreview(canvas);
    _drawDangerGlow(canvas);

    canvas.restore();

    // 파티클은 흔들림 적용 + 그리드 오프셋 적용
    canvas.save();
    canvas.translate(engine.shakeOffsetX + gridLeft, engine.shakeOffsetY + gridTop);
    _drawParticles(canvas);
    canvas.restore();

    // UI 요소 (흔들림 미적용)
    _drawShapeTray(canvas, size);
    _drawDraggingShape(canvas);
    _drawPopups(canvas, size);
  }

  // ---- 그리드 ----
  void _drawGrid(Canvas canvas) {
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(gridLeft - 2, gridTop - 2, gridPixelSize + 4, gridPixelSize + 4),
      const Radius.circular(8),
    );
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF141428));

    for (int r = 0; r < BlockPuzzleEngine.gridSize; r++) {
      for (int c = 0; c < BlockPuzzleEngine.gridSize; c++) {
        if ((r + c) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(gridLeft + c * cellSize, gridTop + r * cellSize, cellSize, cellSize),
            Paint()..color = Colors.white.withValues(alpha: 0.02),
          );
        }
      }
    }

    final linePaint = Paint()
      ..color = const Color(0xFF2D3436).withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= BlockPuzzleEngine.gridSize; i++) {
      final x = gridLeft + i * cellSize;
      final y = gridTop + i * cellSize;
      canvas.drawLine(Offset(x, gridTop), Offset(x, gridTop + gridPixelSize), linePaint);
      canvas.drawLine(Offset(gridLeft, y), Offset(gridLeft + gridPixelSize, y), linePaint);
    }

    canvas.drawRRect(bgRect, Paint()
      ..color = const Color(0xFFE17055).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  // ---- 줄 완성 미리보기 하이라이트 ----
  void _drawPreviewHighlight(Canvas canvas) {
    if (engine.previewHighlightKeys.isEmpty) return;
    final t = DateTime.now().millisecondsSinceEpoch % 800 / 800.0;
    final alpha = 0.08 + 0.12 * sin(t * 2 * pi);

    for (final key in engine.previewHighlightKeys) {
      final r = key ~/ BlockPuzzleEngine.gridSize;
      final c = key % BlockPuzzleEngine.gridSize;
      canvas.drawRect(
        Rect.fromLTWH(gridLeft + c * cellSize, gridTop + r * cellSize, cellSize, cellSize),
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  // ---- 배치된 블록 ----
  void _drawPlacedBlocks(Canvas canvas) {
    for (int r = 0; r < BlockPuzzleEngine.gridSize; r++) {
      for (int c = 0; c < BlockPuzzleEngine.gridSize; c++) {
        final colorIdx = engine.grid[r][c];
        if (colorIdx == -1) continue;
        _drawBlock(canvas, gridLeft + c * cellSize, gridTop + r * cellSize, cellSize, blockColors[colorIdx], 1.0);
      }
    }
  }

  // ---- 배치 바운스 ----
  void _drawPlaceBounces(Canvas canvas) {
    for (final bounce in engine.placeBounces) {
      final t = bounce.progress;
      // 바운스 이징: 떨어졌다 튕기는 느낌
      final bounceScale = 1.0 + 0.2 * sin(t * pi) * (1 - t);
      final x = gridLeft + bounce.col * cellSize;
      final y = gridTop + bounce.row * cellSize;
      final cx = x + cellSize / 2;
      final cy = y + cellSize / 2;
      final s = cellSize * bounceScale;

      // 글로우
      canvas.drawRect(
        Rect.fromCenter(center: Offset(cx, cy), width: s + 4, height: s + 4),
        Paint()..color = blockColors[bounce.colorIndex].withValues(alpha: 0.3 * (1 - t)),
      );
    }
  }

  // ---- 개별 블록 ----
  void _drawBlock(Canvas canvas, double x, double y, double size, Color color, double alpha) {
    const gap = 1.5;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x + gap, y + gap, size - 2 * gap, size - 2 * gap),
      const Radius.circular(4),
    );

    if (alpha > 0.5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + gap + 1, y + gap + 1, size - 2 * gap, size - 2 * gap),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.25 * alpha),
      );
    }

    // 그라디언트 본체
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.15)!.withValues(alpha: alpha),
          color.withValues(alpha: alpha),
          Color.lerp(color, Colors.black, 0.15)!.withValues(alpha: alpha),
        ],
      ).createShader(Rect.fromLTWH(x + gap, y + gap, size - 2 * gap, size - 2 * gap));
    canvas.drawRRect(rect, fillPaint);

    // 상단 하이라이트
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + gap, y + gap, size - 2 * gap, (size - 2 * gap) * 0.3),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.2 * alpha),
    );

    // 테두리
    canvas.drawRRect(rect, Paint()
      ..color = Colors.white.withValues(alpha: 0.15 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  // ---- 클리어 애니메이션 ----
  void _drawClearAnimation(Canvas canvas) {
    if (!engine.isClearAnimating) return;
    final progress = engine.clearAnimProgress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    final scale = 1.0 + progress * 0.2;

    for (final key in engine.clearedCellKeys) {
      final r = key ~/ BlockPuzzleEngine.gridSize;
      final c = key % BlockPuzzleEngine.gridSize;
      final cx = gridLeft + (c + 0.5) * cellSize;
      final cy = gridTop + (r + 0.5) * cellSize;

      // 글로우 서클
      canvas.drawCircle(
        Offset(cx, cy), cellSize * scale * 0.6,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.4),
      );

      // 사각형 플래시
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: cellSize * scale, height: cellSize * scale),
          const Radius.circular(4),
        ),
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.6),
      );
    }
  }

  // ---- 고스트 프리뷰 ----
  void _drawGhostPreview(Canvas canvas) {
    if (draggingIndex == null || ghostX == null || ghostY == null) return;
    final shape = engine.currentShapes[draggingIndex!];
    if (shape == null) return;

    final color = ghostValid ? blockColors[shape.colorIndex] : const Color(0xFFFF0000);

    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (!shape.cells[r][c]) continue;
        final gx = ghostX! + c;
        final gy = ghostY! + r;
        if (gx < 0 || gx >= BlockPuzzleEngine.gridSize || gy < 0 || gy >= BlockPuzzleEngine.gridSize) continue;
        _drawBlock(canvas, gridLeft + gx * cellSize, gridTop + gy * cellSize, cellSize, color, ghostValid ? 0.4 : 0.15);
      }
    }

    if (ghostValid) {
      double minX = double.infinity, minY = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity;
      for (int r = 0; r < shape.height; r++) {
        for (int c = 0; c < shape.width; c++) {
          if (!shape.cells[r][c]) continue;
          final px = gridLeft + (ghostX! + c) * cellSize;
          final py = gridTop + (ghostY! + r) * cellSize;
          if (px < minX) minX = px;
          if (py < minY) minY = py;
          if (px + cellSize > maxX) maxX = px + cellSize;
          if (py + cellSize > maxY) maxY = py + cellSize;
        }
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(minX, minY, maxX, maxY), const Radius.circular(4)),
        Paint()
          ..color = blockColors[shape.colorIndex].withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  // ---- 위기 모드 글로우 ----
  void _drawDangerGlow(Canvas canvas) {
    if (!engine.isDangerMode) return;
    final pulse = (sin(engine.dangerPulse) + 1) / 2;
    final alpha = 0.05 + pulse * 0.15;

    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(gridLeft - 4, gridTop - 4, gridPixelSize + 8, gridPixelSize + 8),
      const Radius.circular(10),
    );
    canvas.drawRRect(borderRect, Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // 내부 비네팅 글로우
    canvas.drawRRect(borderRect, Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFF0000).withValues(alpha: alpha * 0.5),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(gridLeft - 4, gridTop - 4, gridPixelSize + 8, gridPixelSize + 8)));
  }

  // ---- 파티클 (그리드 로컬 좌표) ----
  void _drawParticles(Canvas canvas) {
    for (final p in engine.particles) {
      final alpha = p.life.clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      final color = blockColors[p.colorIndex % blockColors.length];

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      // 글로우
      canvas.drawCircle(
        Offset.zero, p.size + 2,
        Paint()..color = color.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // 파티클 본체 (둥근 사각형)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
          Radius.circular(p.size * 0.2),
        ),
        Paint()..color = color.withValues(alpha: alpha),
      );

      // 하이라이트
      canvas.drawCircle(
        Offset(-p.size * 0.15, -p.size * 0.15),
        p.size * 0.2,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.5),
      );

      canvas.restore();
    }
  }

  // ---- 블록 트레이 ----
  void _drawShapeTray(Canvas canvas, Size size) {
    final trayRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, trayTop - 4, size.width - 8, trayHeight + 8),
      const Radius.circular(12),
    );
    canvas.drawRRect(trayRect, Paint()..color = const Color(0xFF141428).withValues(alpha: 0.6));

    for (int i = 0; i < engine.currentShapes.length && i < shapeBounds.length; i++) {
      if (draggingIndex == i) continue;
      final shape = engine.currentShapes[i];
      if (shape == null) continue;
      final canPlace = engine.canPlaceAnywhere(shape);
      _drawShapeInArea(canvas, shape, shapeBounds[i], canPlace ? 0.9 : 0.2);

      // 놓을 수 없는 블록에 X 표시
      if (!canPlace) {
        final cx = shapeBounds[i].center.dx;
        final cy = shapeBounds[i].center.dy;
        final xPaint = Paint()
          ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.4)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - 10, cy - 10), Offset(cx + 10, cy + 10), xPaint);
        canvas.drawLine(Offset(cx + 10, cy - 10), Offset(cx - 10, cy + 10), xPaint);
      }
    }
  }

  void _drawShapeInArea(Canvas canvas, BlockShape shape, Rect area, double alpha) {
    final maxDim = max(shape.width, shape.height);
    final sCellSize = min(area.width * 0.65, area.height * 0.7) / max(maxDim, 1);
    final totalW = shape.width * sCellSize;
    final totalH = shape.height * sCellSize;
    final startX = area.center.dx - totalW / 2;
    final startY = area.center.dy - totalH / 2;
    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (!shape.cells[r][c]) continue;
        _drawBlock(canvas, startX + c * sCellSize, startY + r * sCellSize, sCellSize, blockColors[shape.colorIndex], alpha);
      }
    }
  }

  // ---- 드래그 중인 블록 ----
  void _drawDraggingShape(Canvas canvas) {
    if (draggingIndex == null || dragPosition == null) return;
    final shape = engine.currentShapes[draggingIndex!];
    if (shape == null) return;
    final color = blockColors[shape.colorIndex];
    final startX = dragPosition!.dx - shape.width * cellSize / 2;
    final startY = dragPosition!.dy - shape.height * cellSize / 2 - 50;

    // 글로우 배경
    canvas.drawCircle(
      Offset(dragPosition!.dx, dragPosition!.dy - 50),
      max(shape.width, shape.height) * cellSize * 0.6,
      Paint()..color = color.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    for (int r = 0; r < shape.height; r++) {
      for (int c = 0; c < shape.width; c++) {
        if (!shape.cells[r][c]) continue;
        _drawBlock(canvas, startX + c * cellSize, startY + r * cellSize, cellSize, color, 0.85);
      }
    }
  }

  // ---- 점수 팝업 ----
  void _drawPopups(Canvas canvas, Size size) {
    for (final popup in engine.popups) {
      final alpha = popup.life.clamp(0.0, 1.0);
      final px = popup.x * size.width;
      final py = popup.y * size.height;
      final scale = 0.8 + 0.2 * alpha; // 줄어들면서 페이드아웃

      final style = TextStyle(
        color: popup.isCombo
            ? Color.lerp(const Color(0xFFFECA57), const Color(0xFFFF6B6B), 0.3)!.withValues(alpha: alpha)
            : Colors.white.withValues(alpha: alpha),
        fontSize: (popup.isCombo ? 22 : 18) * scale,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: alpha * 0.8), blurRadius: 6),
          if (popup.isCombo)
            Shadow(color: const Color(0xFFFF6B6B).withValues(alpha: alpha * 0.4), blurRadius: 12),
        ],
      );

      final tp = TextPainter(text: TextSpan(text: popup.text, style: style), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
