import 'dart:math';

/// 주사위 타입
enum DiceType {
  normal,  // 일반 주사위 (1-6)
  magic,   // 매직 주사위 (6+6+6으로 생성)
}

/// 주사위 클래스
class Dice {
  final int value;      // 1-6 또는 0 (매직)
  final DiceType type;
  final String id;      // 고유 ID
  
  Dice({
    required this.value,
    this.type = DiceType.normal,
    String? id,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(10000)}';
  
  /// 매직 주사위 여부
  bool get isMagic => type == DiceType.magic;
  
  /// 표시할 값
  int get displayValue => isMagic ? 0 : value;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
  
  Dice copyWith({int? value, DiceType? type}) {
    return Dice(
      value: value ?? this.value,
      type: type ?? this.type,
      id: id,
    );
  }
}

/// 게임 보드 셀
class BoardCell {
  final int row;
  final int col;
  Dice? dice;
  
  BoardCell({required this.row, required this.col, this.dice});
  
  bool get isEmpty => dice == null;
  bool get hasDice => dice != null;
}

/// 주사위 머지 게임 보드
class DiceMergeBoard {
  static const int rows = 7;
  static const int cols = 5;
  
  late List<List<BoardCell>> cells;
  int score = 0;
  int bestScore = 0;
  int totalMerges = 0;
  bool isGameOver = false;
  Dice? nextDice;
  
  final Random _random = Random();
  
  DiceMergeBoard({this.bestScore = 0}) {
    _initBoard();
    _generateNextDice();
  }
  
  void _initBoard() {
    cells = List.generate(
      rows,
      (r) => List.generate(cols, (c) => BoardCell(row: r, col: c)),
    );
  }
  
  /// 새 게임
  void reset() {
    _initBoard();
    score = 0;
    totalMerges = 0;
    isGameOver = false;
    _generateNextDice();
  }
  
  /// 다음 주사위 생성
  void _generateNextDice() {
    // 1-6 랜덤, 낮은 숫자가 더 자주 나옴
    final weights = [25, 25, 20, 15, 10, 5]; // 1이 가장 자주
    int total = weights.reduce((a, b) => a + b);
    int rand = _random.nextInt(total);
    int value = 1;
    int cumulative = 0;
    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (rand < cumulative) {
        value = i + 1;
        break;
      }
    }
    nextDice = Dice(value: value);
  }
  
  /// 특정 열에 주사위 드롭
  DropResult? dropDice(int col) {
    if (isGameOver || nextDice == null) return null;
    if (col < 0 || col >= cols) return null;
    
    // 해당 열에서 비어있는 가장 아래 행 찾기
    int targetRow = -1;
    for (int r = rows - 1; r >= 0; r--) {
      if (cells[r][col].isEmpty) {
        targetRow = r;
        break;
      }
    }
    
    // 열이 가득 찬 경우
    if (targetRow == -1) return null;
    
    // 주사위 배치
    final droppedDice = nextDice!;
    cells[targetRow][col].dice = droppedDice;
    
    // 머지 체크 및 처리
    final mergeResult = _processMerges();
    
    // 점수 추가
    score += mergeResult.scoreGained;
    totalMerges += mergeResult.merges.length; // 머지 횟수 누적
    if (score > bestScore) bestScore = score;
    
    // 다음 주사위 생성
    _generateNextDice();
    
    // 게임 오버 체크
    _checkGameOver();
    
    return DropResult(
      droppedAt: (targetRow, col),
      merges: mergeResult.merges,
      scoreGained: mergeResult.scoreGained,
    );
  }
  
  /// 머지 처리 (연쇄 포함)
  MergeProcessResult _processMerges() {
    final allMerges = <MergeInfo>[];
    int totalScore = 0;
    
    bool merged;
    do {
      merged = false;
      
      // 모든 주사위에 대해 머지 가능한지 체크
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (cells[r][c].isEmpty) continue;
          
          final dice = cells[r][c].dice!;
          final matches = _findMatches(r, c, dice);
          
          if (matches.length >= 3) {
            // 3개 이상 매칭!
            merged = true;
            
            // 마지막으로 놓인 위치 (가장 높은 행 = 가장 낮은 r값)가 아닌
            // 가장 마지막으로 추가된 주사위 위치에 새 주사위 생성
            // 여기서는 가장 아래쪽 주사위 위치 사용
            int mergeRow = r;
            int mergeCol = c;
            for (final pos in matches) {
              if (pos.$1 > mergeRow || (pos.$1 == mergeRow && pos.$2 > mergeCol)) {
                mergeRow = pos.$1;
                mergeCol = pos.$2;
              }
            }
            
            // 매칭된 주사위들 제거
            for (final pos in matches) {
              cells[pos.$1][pos.$2].dice = null;
            }
            
            // 새 주사위 생성 (업그레이드)
            if (dice.isMagic) {
              // 매직 주사위 3개 = 3x3 폭발!
              int explosionScore = 0;
              final explodedPositions = <(int, int)>[];

              // 중심점 (mergeRow, mergeCol) 기준 3x3 영역 확인
              for (int r = mergeRow - 1; r <= mergeRow + 1; r++) {
                for (int c = mergeCol - 1; c <= mergeCol + 1; c++) {
                  if (r >= 0 && r < rows && c >= 0 && c < cols) {
                    if (cells[r][c].hasDice) {
                      cells[r][c].dice = null; // 제거
                      explosionScore += 100;   // 개당 점수
                      explodedPositions.add((r, c));
                    }
                  }
                }
              }
              
              totalScore += 1000 + explosionScore;
              
              allMerges.add(MergeInfo(
                positions: matches, // 원래 매칭된 위치들
                resultPosition: (mergeRow, mergeCol),
                resultDice: null,
                isMagicClear: true,
                explodedPositions: explodedPositions, // 폭발된 위치들 전달 (UI 효과용)
              ));
            } else if (dice.value == 6) {
              // 6+6+6 = 매직 주사위
              final magicDice = Dice(value: 0, type: DiceType.magic);
              cells[mergeRow][mergeCol].dice = magicDice;
              totalScore += 500;
              allMerges.add(MergeInfo(
                positions: matches,
                resultPosition: (mergeRow, mergeCol),
                resultDice: magicDice,
                isMagicCreated: true,
              ));
            } else {
              // 일반 업그레이드: 다음 숫자로
              final newDice = Dice(value: dice.value + 1);
              cells[mergeRow][mergeCol].dice = newDice;
              totalScore += dice.value * 10 * matches.length;
              allMerges.add(MergeInfo(
                positions: matches,
                resultPosition: (mergeRow, mergeCol),
                resultDice: newDice,
              ));
            }
            
            // 중력 적용
            _applyGravity();
            
            break; // 하나의 머지 후 다시 전체 스캔
          }
        }
        if (merged) break;
      }
    } while (merged);
    
    return MergeProcessResult(merges: allMerges, scoreGained: totalScore);
  }
  
  /// 연결된 같은 주사위 찾기 (BFS)
  List<(int, int)> _findMatches(int startRow, int startCol, Dice dice) {
    final matches = <(int, int)>[];
    final visited = <String>{};
    final queue = <(int, int)>[(startRow, startCol)];
    
    while (queue.isNotEmpty) {
      final (r, c) = queue.removeAt(0);
      final key = '$r,$c';
      
      if (visited.contains(key)) continue;
      if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
      if (cells[r][c].isEmpty) continue;
      
      final cellDice = cells[r][c].dice!;
      
      // 같은 종류의 주사위인지 확인
      bool isMatch = false;
      if (dice.isMagic && cellDice.isMagic) {
        isMatch = true;
      } else if (!dice.isMagic && !cellDice.isMagic && dice.value == cellDice.value) {
        isMatch = true;
      }
      
      if (!isMatch) continue;
      
      visited.add(key);
      matches.add((r, c));
      
      // 상하좌우 탐색
      queue.add((r - 1, c));
      queue.add((r + 1, c));
      queue.add((r, c - 1));
      queue.add((r, c + 1));
    }
    
    return matches;
  }
  
  /// 중력 적용 (주사위들이 아래로 떨어짐)
  void _applyGravity() {
    for (int c = 0; c < cols; c++) {
      // 각 열에서 주사위들을 아래로 모음
      final diceList = <Dice>[];
      for (int r = 0; r < rows; r++) {
        if (cells[r][c].hasDice) {
          diceList.add(cells[r][c].dice!);
          cells[r][c].dice = null;
        }
      }
      
      // 아래부터 채움
      int targetRow = rows - 1;
      for (final dice in diceList.reversed) {
        cells[targetRow][c].dice = dice;
        targetRow--;
      }
    }
  }
  
  /// 게임 오버 체크
  void _checkGameOver() {
    // 모든 열의 맨 위가 차있으면 게임 오버
    for (int c = 0; c < cols; c++) {
      if (cells[0][c].isEmpty) {
        return; // 아직 게임 가능
      }
    }
    isGameOver = true;
  }
  
  /// 특정 셀의 주사위 가져오기
  Dice? getDice(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) return null;
    return cells[row][col].dice;
  }
}

/// 드롭 결과
class DropResult {
  final (int, int) droppedAt;
  final List<MergeInfo> merges;
  final int scoreGained;
  
  DropResult({
    required this.droppedAt,
    required this.merges,
    required this.scoreGained,
  });
}

/// 머지 정보
class MergeInfo {
  final List<(int, int)> positions;
  final (int, int) resultPosition;
  final Dice? resultDice;
  final bool isMagicCreated;
  final bool isMagicClear;
  final List<(int, int)> explodedPositions; // 3x3 Explosion positions
  
  MergeInfo({
    required this.positions,
    required this.resultPosition,
    this.resultDice,
    this.isMagicCreated = false,
    this.isMagicClear = false,
    this.explodedPositions = const [],
  });
}

/// 머지 처리 결과
class MergeProcessResult {
  final List<MergeInfo> merges;
  final int scoreGained;
  
  MergeProcessResult({
    required this.merges,
    required this.scoreGained,
  });
}
