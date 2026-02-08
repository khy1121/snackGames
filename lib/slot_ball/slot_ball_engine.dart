import 'dart:math';

/// 슬롯볼 공 클래스
class SlotBall {
  double x, y;       // 위치
  double vx, vy;     // 속도
  double radius;
  bool isActive;     // 보드 위에 있는지
  bool isScored;     // 점수 계산됨
  int scoreZone;     // 위치한 점수 구역 (0=미배치)
  final int index;   // 공 번호
  
  SlotBall({
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.radius = 14,
    this.isActive = true,
    this.isScored = false,
    this.scoreZone = 0,
    required this.index,
  });
  
  bool get isMoving => vx.abs() > 0.3 || vy.abs() > 0.3;
  
  /// 공과 공 사이 거리
  double distanceTo(SlotBall other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }
}

/// 점수 구역
class ScoreZone {
  final int points;       // 점수
  final double yStart;    // 시작 Y (비율 0~1)
  final double yEnd;      // 끝 Y (비율 0~1)
  final String label;
  
  const ScoreZone({
    required this.points,
    required this.yStart,
    required this.yEnd,
    required this.label,
  });
}

/// 슬롯볼 물리 엔진 및 게임 로직
class SlotBallEngine {
  // 보드 크기 (런타임에 설정)
  double boardWidth = 300;
  double boardHeight = 600;
  
  // 물리 상수
  static const double friction = 0.987;          // 마찰 (매 프레임)
  static const double wallRestitution = 0.4;     // 벽 반발 계수
  static const double ballRestitution = 0.7;     // 공-공 반발 계수
  static const double minVelocity = 0.3;         // 정지 판정 속도
  static const double maxLaunchPower = 45.0;     // 최대 발사 힘
  static const double launchMultiplier = 0.12;   // 드래그→속도 변환 계수
  
  // 점수 구역 정의 (보드 상단에서부터)
  static const List<ScoreZone> scoreZones = [
    ScoreZone(points: 5, yStart: 0.00, yEnd: 0.08, label: '5'),
    ScoreZone(points: 3, yStart: 0.08, yEnd: 0.18, label: '3'),
    ScoreZone(points: 2, yStart: 0.18, yEnd: 0.30, label: '2'),
    ScoreZone(points: 1, yStart: 0.30, yEnd: 0.42, label: '1'),
  ];
  
  // 게임 상태
  List<SlotBall> balls = [];
  int currentBallIndex = 0;
  int totalBalls = 10;
  int score = 0;
  int bestScore = 0;
  bool isGameOver = false;
  bool isLaunching = false;   // 현재 공이 움직이는 중
  int round = 1;
  
  // 발사 관련
  double launchX = 0;         // 발사 시작 X 위치
  
  SlotBallEngine();
  
  /// 보드 크기 설정
  void setBoardSize(double width, double height) {
    boardWidth = width;
    boardHeight = height;
  }
  
  /// 새 게임 시작
  void newGame() {
    balls.clear();
    currentBallIndex = 0;
    score = 0;
    isGameOver = false;
    isLaunching = false;
    round = 1;
  }
  
  /// 현재 공이 모두 정지했는지 확인
  bool get allBallsStopped => balls.every((b) => !b.isMoving);
  
  /// 다음 공 발사 가능 여부
  bool get canLaunch => !isLaunching && !isGameOver && currentBallIndex < totalBalls;
  
  /// 남은 공 수
  int get remainingBalls => totalBalls - currentBallIndex;
  
  /// 공 발사 (새총 방식: 아래로 당기면 위로 발사)
  void launchBall(double startX, double dragDx, double dragDy) {
    if (!canLaunch) return;
    
    // 새총: 드래그 반대 방향으로 발사 (아래로 당기면 vy 음수 = 위로)
    double vx = -dragDx * launchMultiplier;
    double vy = -dragDy * launchMultiplier;
    
    // 최대 속도 제한
    final speed = sqrt(vx * vx + vy * vy);
    if (speed > maxLaunchPower) {
      vx = vx / speed * maxLaunchPower;
      vy = vy / speed * maxLaunchPower;
    }
    
    // 최소 위쪽 발사력 보장
    if (vy > -5) vy = -5;
    
    final ball = SlotBall(
      x: startX.clamp(30, boardWidth - 30),
      y: boardHeight - 50,
      vx: vx,
      vy: vy,
      radius: 14,
      index: currentBallIndex,
    );
    
    balls.add(ball);
    currentBallIndex++;
    isLaunching = true;
  }
  
  /// 물리 업데이트 (매 프레임 호출)
  void update() {
    bool anyMoving = false;
    
    for (final ball in balls) {
      if (!ball.isActive || !ball.isMoving) continue;
      
      anyMoving = true;
      
      // 속도에 마찰 적용
      ball.vx *= friction;
      ball.vy *= friction;
      
      // 위치 업데이트
      ball.x += ball.vx;
      ball.y += ball.vy;
      
      // 좌우 벽 충돌
      if (ball.x - ball.radius < 0) {
        ball.x = ball.radius;
        ball.vx = -ball.vx * wallRestitution;
      } else if (ball.x + ball.radius > boardWidth) {
        ball.x = boardWidth - ball.radius;
        ball.vx = -ball.vx * wallRestitution;
      }
      
      // 상단 벽 충돌 (보드 끝)
      if (ball.y - ball.radius < 0) {
        ball.y = ball.radius;
        ball.vy = -ball.vy * wallRestitution;
      }
      
      // 하단 벽 (되돌아오기 방지 - 발사 라인 아래로는 갈 수 없음)
      final launchLine = boardHeight - 30;
      if (ball.y + ball.radius > launchLine && ball.vy > 0) {
        ball.y = launchLine - ball.radius;
        ball.vy = -ball.vy * wallRestitution * 0.3;
      }
      
      // 정지 판정
      if (ball.vx.abs() < minVelocity && ball.vy.abs() < minVelocity) {
        ball.vx = 0;
        ball.vy = 0;
      }
    }
    
    // 공-공 충돌 처리
    _handleBallCollisions();
    
    // 모든 공이 정지하면 점수 계산
    if (!anyMoving && isLaunching) {
      isLaunching = false;
      _calculateScores();
      
      // 모든 공을 사용했으면 게임 오버
      if (currentBallIndex >= totalBalls) {
        isGameOver = true;
      }
    }
  }
  
  /// 공-공 충돌 처리
  void _handleBallCollisions() {
    for (int i = 0; i < balls.length; i++) {
      for (int j = i + 1; j < balls.length; j++) {
        final a = balls[i];
        final b = balls[j];
        
        if (!a.isActive || !b.isActive) continue;
        
        final dist = a.distanceTo(b);
        final minDist = a.radius + b.radius;
        
        if (dist < minDist && dist > 0) {
          // 충돌 발생 - 분리
          final nx = (b.x - a.x) / dist;
          final ny = (b.y - a.y) / dist;
          
          // 겹침 해소
          final overlap = minDist - dist;
          a.x -= nx * overlap * 0.5;
          a.y -= ny * overlap * 0.5;
          b.x += nx * overlap * 0.5;
          b.y += ny * overlap * 0.5;
          
          // 상대 속도
          final dvx = a.vx - b.vx;
          final dvy = a.vy - b.vy;
          final dvDotN = dvx * nx + dvy * ny;
          
          // 접근 중일 때만 충돌 처리
          if (dvDotN > 0) {
            final impulse = dvDotN * ballRestitution;
            a.vx -= impulse * nx;
            a.vy -= impulse * ny;
            b.vx += impulse * nx;
            b.vy += impulse * ny;
          }
        }
      }
    }
  }
  
  /// 점수 계산 (모든 공의 현재 위치 기반)
  void _calculateScores() {
    score = 0;
    for (final ball in balls) {
      if (!ball.isActive) continue;
      ball.scoreZone = _getScoreForPosition(ball.y);
      score += ball.scoreZone;
    }
  }
  
  /// 위치에 따른 점수
  int _getScoreForPosition(double y) {
    final ratio = y / boardHeight;
    for (final zone in scoreZones) {
      if (ratio >= zone.yStart && ratio < zone.yEnd) {
        return zone.points;
      }
    }
    return 0; // 점수 구역 밖
  }
  
  /// 최종 점수 계산
  int getFinalScore() {
    _calculateScores();
    return score;
  }
}
