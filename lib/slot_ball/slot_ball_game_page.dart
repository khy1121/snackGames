import 'dart:math';
import 'package:flutter/material.dart';
import 'slot_ball_engine.dart';
import '../services/game_data_service.dart';
import '../services/vibration_service.dart';
import '../services/sfx_service_stub.dart'
    if (dart.library.html) '../services/sfx_service.dart';

/// 슬롯볼 게임 페이지
class SlotBallGamePage extends StatefulWidget {
  const SlotBallGamePage({super.key});

  @override
  State<SlotBallGamePage> createState() => _SlotBallGamePageState();
}

class _SlotBallGamePageState extends State<SlotBallGamePage>
    with SingleTickerProviderStateMixin {
  
  final SlotBallEngine _engine = SlotBallEngine();
  late AnimationController _ticker;
  DateTime? _startTime;
  
  // 드래그 관련
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _isDragging = false;
  
  // 보드 크기
  double _boardWidth = 0;
  double _boardHeight = 0;
  final GlobalKey _boardKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _engine.newGame();
    
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
    _ticker.repeat();
    
    GameDataService.setLastPlayedGame('slotball');
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
    if (_engine.isGameOver) return;
    
    _engine.update();
    
    // 게임 오버 체크
    if (_engine.isGameOver) {
      _onGameOver();
    }
    
    setState(() {});
  }
  
  void _onGameOver() {
    final totalScore = _engine.getFinalScore();
    final roundScore = totalScore - _engine.bankedScore;
    GameDataService.recordScore('slotball', totalScore);
    
    // 포인트 보상 (이번 라운드 점수의 2배)
    final points = roundScore * 2;
    GameDataService.addPoints(points);
    
    VibrationService.success();
    SfxService().playButtonClick();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _showGameOverDialog(totalScore, roundScore, points);
    });
  }
  
  void _showGameOverDialog(int totalScore, int roundScore, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '🎱 라운드 ${_engine.round} 종료!',
          style: const TextStyle(color: Colors.white, fontSize: 22),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 점수
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B894), Color(0xFF00CEC9)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text('이번 라운드', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(
                    '$roundScore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_engine.round > 1) Text(
                    '누적 총점: $totalScore',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 최고 점수
            Text(
              '🏆 최고 기록: ${GameDataService.getBestScore('slotball')}',
              style: const TextStyle(color: Color(0xFFFD79A8), fontSize: 16),
            ),
            
            const SizedBox(height: 8),
            
            // 포인트 보상
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '💰 +$points 포인트 획득!',
                style: const TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 공별 점수 요약
            _buildBallScoreSummary(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('나가기', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _engine.newGame();
                _startTime = DateTime.now();
              });
            },
            child: const Text('처음부터', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _engine.nextRound();
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00B894),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('다음 라운드 →', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBallScoreSummary() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: _engine.balls.map((ball) {
        final color = ball.scoreZone >= 5
            ? const Color(0xFFFF6B6B)
            : ball.scoreZone >= 3
                ? const Color(0xFFFECA57)
                : ball.scoreZone >= 1
                    ? const Color(0xFF48DBFB)
                    : Colors.grey;
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              '${ball.scoreZone}',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  void _onPanStart(DragStartDetails details) {
    if (!_engine.canLaunch) return;
    
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    final localPos = box.globalToLocal(details.globalPosition);
    
    // 하단 발사 영역에서만 드래그 시작
    if (localPos.dy > _boardHeight * 0.65) {
      _isDragging = true;
      _dragStart = localPos;
      _dragCurrent = localPos;
    }
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    setState(() {
      _dragCurrent = box.globalToLocal(details.globalPosition);
    });
  }
  
  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _dragStart == null || _dragCurrent == null) {
      _isDragging = false;
      return;
    }
    
    final dx = _dragCurrent!.dx - _dragStart!.dx;
    final dy = _dragCurrent!.dy - _dragStart!.dy;
    final distance = sqrt(dx * dx + dy * dy);
    
    // 새총: 아래로 당겼다 놓으면 발사 (dy > 10 = 아래로 당김)
    if (distance > 20) {
      _engine.launchBall(_dragStart!.dx, dx, dy);
      VibrationService.light();
      SfxService().playDropDice();
    }
    
    setState(() {
      _isDragging = false;
      _dragStart = null;
      _dragCurrent = null;
    });
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('⏸️ 일시정지', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // 이어하기
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.play_arrow),
                label: const Text('이어하기', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00B894),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _engine.newGame());
                      },
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('새 게임'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.exit_to_app, size: 20),
                      label: const Text('나가기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),
            
            // 점수 & 정보 바
            _buildScoreBar(),
            
            // 게임 보드
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _boardWidth = constraints.maxWidth;
                    _boardHeight = constraints.maxHeight;
                    _engine.setBoardSize(_boardWidth, _boardHeight);
                    
                    return GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        key: _boardKey,
                        size: Size(_boardWidth, _boardHeight),
                        painter: SlotBallPainter(
                          engine: _engine,
                          boardWidth: _boardWidth,
                          boardHeight: _boardHeight,
                          dragStart: _dragStart,
                          dragCurrent: _dragCurrent,
                          isDragging: _isDragging,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 하단 안내
            _buildBottomHint(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(
              '🎱 슬롯 볼  R${_engine.round}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _showPauseMenu,
            icon: const Icon(Icons.pause_circle_outline, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.8),
            const Color(0xFF16213E).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 점수
          Column(
            children: [
              const Text('점수', style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text(
                '${_engine.score}',
                style: const TextStyle(
                  color: Color(0xFF00B894),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // 구분선
          Container(width: 1, height: 30, color: Colors.white24),
          
          // 남은 공
          Column(
            children: [
              const Text('남은 공', style: TextStyle(color: Colors.white54, fontSize: 11)),
              Row(
                children: List.generate(
                  min(_engine.remainingBalls, 10),
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      Icons.circle,
                      size: i < 5 ? 10 : 8,
                      color: const Color(0xFF48DBFB).withValues(alpha: i < _engine.remainingBalls ? 1.0 : 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // 구분선
          Container(width: 1, height: 30, color: Colors.white24),
          
          // 최고 기록
          Column(
            children: [
              const Text('최고', style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text(
                '${GameDataService.getBestScore('slotball')}',
                style: const TextStyle(
                  color: Color(0xFFFD79A8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomHint() {
    final hintText = _engine.isGameOver
        ? '게임 종료!'
        : _engine.isLaunching
            ? '공이 움직이는 중...'
            : '🎱 아래로 당겼다 놓으면 발사!';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        hintText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
    );
  }
}

/// 슬롯볼 보드 커스텀 페인터
class SlotBallPainter extends CustomPainter {
  final SlotBallEngine engine;
  final double boardWidth;
  final double boardHeight;
  final Offset? dragStart;
  final Offset? dragCurrent;
  final bool isDragging;
  
  SlotBallPainter({
    required this.engine,
    required this.boardWidth,
    required this.boardHeight,
    this.dragStart,
    this.dragCurrent,
    required this.isDragging,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    _drawBoard(canvas, size);
    _drawScoreZones(canvas, size);
    _drawPegs(canvas, size);
    _drawBalls(canvas, size);
    _drawPopups(canvas, size);
    _drawLaunchArea(canvas, size);
    if (isDragging && dragStart != null && dragCurrent != null) {
      _drawAimIndicator(canvas, size);
    }
  }
  
  void _drawBoard(Canvas canvas, Size size) {
    // 보드 배경
    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRRect(boardRect, bgPaint);
    
    // 보드 테두리
    final borderPaint = Paint()
      ..color = const Color(0xFF8B6914)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(boardRect, borderPaint);
    
    // 내부 나무 테두리
    final innerBorder = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      const Radius.circular(14),
    );
    final innerPaint = Paint()
      ..color = const Color(0xFFB8860B).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(innerBorder, innerPaint);
  }
  
  void _drawScoreZones(Canvas canvas, Size size) {
    final zones = SlotBallEngine.scoreZones;
    
    for (int i = 0; i < zones.length; i++) {
      final zone = zones[i];
      final yStart = zone.yStart * size.height;
      final yEnd = zone.yEnd * size.height;
      
      // 구역 배경
      final Color zoneColor;
      switch (zone.points) {
        case 5: zoneColor = const Color(0xFFFF6B6B); break;
        case 3: zoneColor = const Color(0xFFFECA57); break;
        case 2: zoneColor = const Color(0xFF48DBFB); break;
        default: zoneColor = const Color(0xFF00D2D3); break;
      }
      
      final zonePaint = Paint()
        ..color = zoneColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      
      final zoneRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(6, yStart, size.width - 12, yEnd - yStart),
        topLeft: i == 0 ? const Radius.circular(12) : Radius.zero,
        topRight: i == 0 ? const Radius.circular(12) : Radius.zero,
      );
      canvas.drawRRect(zoneRect, zonePaint);
      
      // 구역 경계선
      final linePaint = Paint()
        ..color = zoneColor.withValues(alpha: 0.5)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(10, yEnd), Offset(size.width - 10, yEnd), linePaint);
      
      // 점수 텍스트
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${zone.points}점',
          style: TextStyle(
            color: zoneColor.withValues(alpha: 0.7),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (yStart + yEnd) / 2 - textPainter.height / 2,
        ),
      );
    }
    
    // "점수 없음" 영역 표시
    final noScoreY = zones.last.yEnd * size.height;
    final launchY = size.height * 0.65;
    
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(10, noScoreY), Offset(size.width - 10, noScoreY), dashPaint);
  }
  
  void _drawPegs(Canvas canvas, Size size) {
    for (final peg in engine.pegs) {
      final px = peg.getX(size.width);
      final py = peg.getY(size.height);
      final r = peg.radius * peg.hitScale;
      
      // 핀 그림자
      canvas.drawCircle(
        Offset(px + 1, py + 1), r,
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      );
      
      // 핀 색상
      final Color pegColor;
      switch (peg.type) {
        case PegType.bonus:
          pegColor = const Color(0xFFFECA57);
        case PegType.bumper:
          pegColor = const Color(0xFFFF6B6B);
        default:
          pegColor = const Color(0xFFDFE6E9);
      }
      
      // 핀 본체
      final pegPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.0,
          colors: [pegColor, pegColor.withValues(alpha: 0.6)],
        ).createShader(Rect.fromCircle(center: Offset(px, py), radius: r));
      canvas.drawCircle(Offset(px, py), r, pegPaint);
      
      // 핀 테두리
      canvas.drawCircle(
        Offset(px, py), r,
        Paint()
          ..color = pegColor.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      
      // 핀 하이라이트
      canvas.drawCircle(
        Offset(px - r * 0.2, py - r * 0.2), r * 0.3,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
      
      // 보너스 핀 별 표시
      if (peg.type == PegType.bonus) {
        final tp = TextPainter(
          text: const TextSpan(
            text: '★',
            style: TextStyle(color: Color(0xFFE17055), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
      }
      
      // 범퍼 외곽 글로우
      if (peg.type == PegType.bumper) {
        canvas.drawCircle(
          Offset(px, py), r + 3,
          Paint()
            ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }
  
  void _drawPopups(Canvas canvas, Size size) {
    for (final popup in engine.popups) {
      final alpha = popup.life.clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: popup.text.isNotEmpty ? popup.text : '+${popup.points}',
          style: TextStyle(
            color: const Color(0xFFFECA57).withValues(alpha: alpha),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(popup.x - tp.width / 2, popup.y - tp.height / 2));
    }
  }
  
  void _drawBalls(Canvas canvas, Size size) {
    for (final ball in engine.balls) {
      if (!ball.isActive) continue;
      
      // 점수에 따른 색상
      final Color ballColor;
      if (ball.isMoving) {
        ballColor = const Color(0xFF48DBFB);
      } else if (ball.scoreZone >= 5) {
        ballColor = const Color(0xFFFF6B6B);
      } else if (ball.scoreZone >= 3) {
        ballColor = const Color(0xFFFECA57);
      } else if (ball.scoreZone >= 1) {
        ballColor = const Color(0xFF48DBFB);
      } else {
        ballColor = const Color(0xFF636E72);
      }
      
      // 공 그림자
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(ball.x + 2, ball.y + 2), ball.radius, shadowPaint);
      
      // 공 본체
      final ballPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 1.2,
          colors: [
            ballColor,
            ballColor.withValues(alpha: 0.7),
            ballColor.withValues(alpha: 0.4),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(ball.x, ball.y), radius: ball.radius),
        );
      canvas.drawCircle(Offset(ball.x, ball.y), ball.radius, ballPaint);
      
      // 공 하이라이트
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4);
      canvas.drawCircle(
        Offset(ball.x - ball.radius * 0.25, ball.y - ball.radius * 0.25),
        ball.radius * 0.3,
        highlightPaint,
      );
      
      // 점수 표시 (정지 시)
      if (!ball.isMoving && ball.scoreZone > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${ball.scoreZone}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(ball.x - tp.width / 2, ball.y - tp.height / 2));
      }
    }
  }
  
  void _drawLaunchArea(Canvas canvas, Size size) {
    final launchY = size.height * 0.75;
    
    // 발사 라인
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.5;
    
    // 점선 그리기
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = 10;
    while (startX < size.width - 10) {
      canvas.drawLine(
        Offset(startX, launchY),
        Offset(min(startX + dashWidth, size.width - 10), launchY),
        linePaint,
      );
      startX += dashWidth + dashSpace;
    }
    
    // 발사 영역 안내
    if (engine.canLaunch && !isDragging) {
      final tp = TextPainter(
        text: TextSpan(
          text: '⬇️ 아래로 당겼다 놓기',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 13,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height - 40));
    }
  }
  
  void _drawAimIndicator(Canvas canvas, Size size) {
    if (dragStart == null || dragCurrent == null) return;
    
    final dx = dragCurrent!.dx - dragStart!.dx;
    final dy = dragCurrent!.dy - dragStart!.dy;
    final distance = sqrt(dx * dx + dy * dy);
    
    if (distance < 10) return;
    
    // 파워 (당긴 거리 기준)
    final power = (distance / 250).clamp(0.0, 1.0);
    
    // 파워에 따른 색상
    final Color arrowColor;
    if (power < 0.3) {
      arrowColor = const Color(0xFF48DBFB);
    } else if (power < 0.6) {
      arrowColor = const Color(0xFFFECA57);
    } else {
      arrowColor = const Color(0xFFFF6B6B);
    }
    
    // 새총 줄 (시작점 → 드래그 현재 위치)
    final linePaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(dragStart!, dragCurrent!, linePaint);
    
    // 발사 예측 방향 (당긴 반대쪽으로 점선)
    final launchDirX = -dx / distance;
    final launchDirY = -dy / distance;
    final predictLength = power * 250;
    
    final predPaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.4)
      ..strokeWidth = 2;
    
    const dotSpacing = 12.0;
    for (double d = 20; d < predictLength; d += dotSpacing) {
      final px = dragStart!.dx + launchDirX * d;
      final py = dragStart!.dy + launchDirY * d;
      if (py < 0 || py > size.height) break;
      canvas.drawCircle(Offset(px, py), 2.5, predPaint);
    }
    
    // 공 위치 (발사 시작점)
    final previewPaint = Paint()
      ..color = arrowColor.withValues(alpha: 0.5);
    canvas.drawCircle(dragStart!, 14, previewPaint);
    
    // 파워 바 (드래그 현재 위치 아래)
    final barWidth = 60.0;
    final barHeight = 8.0;
    final barX = dragCurrent!.dx - barWidth / 2;
    final barY = dragCurrent!.dy + 20;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth * power, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = arrowColor,
    );
    
    // 파워 % 텍스트
    final tp = TextPainter(
      text: TextSpan(
        text: '${(power * 100).toInt()}%',
        style: TextStyle(color: arrowColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(barX + barWidth + 6, barY - 2));
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
