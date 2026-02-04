import 'package:flutter/material.dart';
import '../dice_board.dart';
import '../dice_game_page.dart';

/// 튜토리얼용 간단한 보드 클래스
class TutorialBoard {
  // 6행 5열 그리드
  List<List<Dice?>> grid = List.generate(6, (_) => List.filled(5, null));
  
  void clear() {
    grid = List.generate(6, (_) => List.filled(5, null));
  }
  
  void placeDice(int row, int col, Dice dice) {
    if (row >= 0 && row < 6 && col >= 0 && col < 5) {
      grid[row][col] = dice;
    }
  }
  
  Dice? getDice(int row, int col) {
    if (row >= 0 && row < 6 && col >= 0 && col < 5) {
      return grid[row][col];
    }
    return null;
  }
}

/// 주사위 게임 튜토리얼 페이지
class DiceTutorialPage extends StatefulWidget {
  const DiceTutorialPage({super.key});

  @override
  State<DiceTutorialPage> createState() => _DiceTutorialPageState();
}

class _DiceTutorialPageState extends State<DiceTutorialPage> {
  int _currentStep = 0;
  final TutorialBoard _board = TutorialBoard();
  final List<TutorialStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _initializeTutorialSteps();
    _prepareStep0();
  }

  void _initializeTutorialSteps() {
    _steps.addAll([
      // 0. 환영
      TutorialStep(
        title: '주사위 합치기에 오신 것을 환영합니다! 🎲',
        description: '같은 숫자 주사위를 3개 이상 모으면\n더 큰 숫자로 합쳐집니다!\n\n쉽고 재미있어요. 시작해볼까요?',
        buttonText: '시작하기',
        highlightArea: HighlightArea.none,
      ),
      // 1. 주사위 배치 방법
      TutorialStep(
        title: '주사위 놓는 방법',
        description: '아래 주사위를 원하는 칸에 터치하면\n주사위가 떨어집니다.\n\n한 번 터치해보세요! 👇',
        buttonText: '주사위 놓았어요',
        highlightArea: HighlightArea.board,
        demoMode: true,
      ),
      // 2. 1+1+1 합치기
      TutorialStep(
        title: '주사위 합치기',
        description: '1이 3개 모이면 자동으로 합쳐져서\n2가 됩니다!\n\n1을 3개 모아볼까요? 🎯',
        buttonText: '다음',
        highlightArea: HighlightArea.board,
        targetDiceValue: 1,
        targetCount: 3,
      ),
      // 3. 같은 숫자 모으기
      TutorialStep(
        title: '더 큰 주사위 만들기',
        description: '2가 3개 모이면 3이 되고\n3이 3개 모이면 4가 됩니다!\n\n계속 합쳐서 큰 숫자를 만들어요 📈',
        buttonText: '다음',
        highlightArea: HighlightArea.board,
      ),
      // 4. 콤보 시스템
      TutorialStep(
        title: '콤보로 더 많은 점수!',
        description: '한 번에 여러 개를 합치면\n콤보 점수를 받아요!\n\n연속으로 합치면 점수가 두 배로! 🔥',
        buttonText: '다음',
        highlightArea: HighlightArea.score,
      ),
      // 5. 별 주사위
      TutorialStep(
        title: '특별한 별(⭐) 주사위',
        description: '6이 3개 모이면 별(⭐) 주사위가 돼요!\n별은 아무 숫자와도 합칠 수 있어요 ⭐',
        buttonText: '다음',
        highlightArea: HighlightArea.none,
      ),
      // 6. 매직 주사위
      TutorialStep(
        title: '마법의 매직(✨) 주사위',
        description: '별(⭐) 3개를 모으면 매직(✨)이 돼요!\n매직은 주변 주사위를 모두 없애줘요 💫',
        buttonText: '다음',
        highlightArea: HighlightArea.none,
      ),
      // 7. 높은 점수 팁
      TutorialStep(
        title: '높은 점수를 위한 꿀팁! 🍯',
        description: '1. 같은 숫자를 한 곳에 모으세요\n'
            '2. 한 번에 많이 합쳐서 콤보!\n'
            '3. 아래쪽부터 채우면 좋아요\n'
            '4. 별(⭐)은 위급할 때 사용!',
        buttonText: '다음',
        highlightArea: HighlightArea.none,
      ),
      // 8. 시작하기
      TutorialStep(
        title: '준비 완료! 🎉',
        description: '이제 진짜 게임을 시작할 준비가 됐어요!\n\n높은 점수에 도전해보세요!\n화이팅! 💪',
        buttonText: '게임 시작!',
        highlightArea: HighlightArea.none,
      ),
    ]);
  }

  void _prepareStep0() {
    // 초기 보드는 비어있음
  }

  void _prepareStep1() {
    // 보드를 비우고 첫 주사위 준비
    _board.clear();
    setState(() {});
  }

  void _prepareStep2() {
    // 1이 2개 있는 상태로 시작
    _board.clear();
    _board.placeDice(4, 0, Dice(value: 1));
    _board.placeDice(4, 1, Dice(value: 1));
    setState(() {});
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      
      // 각 단계별 준비
      if (_currentStep == 1) _prepareStep1();
      if (_currentStep == 2) _prepareStep2();
    } else {
      // 튜토리얼 완료 - 실제 게임 시작
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DiceGamePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a3528), Color(0xFF2E5940)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 진행 상황
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / _steps.length,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF00B894)),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_currentStep + 1}/${_steps.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 게임 보드 미리보기
              if (step.highlightArea == HighlightArea.board)
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00B894),
                          width: 3,
                        ),
                      ),
                      child: AspectRatio(
                        aspectRatio: 5 / 6,
                        child: _buildSimpleBoard(),
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              
              // 설명 카드
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5940),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: Color(0xFF2E5940),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B894),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          step.buttonText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleBoard() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final row = index ~/ 5;
        final col = index % 5;
        final dice = _board.grid[row][col];
        
        return GestureDetector(
          onTap: _currentStep == 1 || _currentStep == 2
              ? () => _handleCellTap(row, col)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: dice != null
                  ? _getDiceColor(dice.value)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: dice != null
                  ? Text(
                      dice.isMagic ? '✨' : dice.value == 7 ? '⭐' : '${dice.value}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _handleCellTap(int row, int col) {
    if (_board.grid[row][col] == null) {
      setState(() {
        _board.placeDice(row, col, Dice(value: 1));
        
        // 단계 2에서 1이 3개가 되면 자동으로 합치기
        if (_currentStep == 2) {
          final ones = _countDiceValue(1);
          if (ones >= 3) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _mergeDice();
            });
          }
        }
      });
    }
  }

  int _countDiceValue(int value) {
    int count = 0;
    for (var row in _board.grid) {
      for (var dice in row) {
        if (dice != null && dice.value == value) count++;
      }
    }
    return count;
  }

  void _mergeDice() {
    // 간단한 머지 로직 (데모용)
    final positions = <(int, int)>[];
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 5; c++) {
        if (_board.grid[r][c]?.value == 1) {
          positions.add((r, c));
        }
      }
    }
    
    if (positions.length >= 3) {
      // 처음 3개를 제거하고 첫 위치에 2 배치
      for (int i = 1; i < 3; i++) {
        _board.grid[positions[i].$1][positions[i].$2] = null;
      }
      _board.grid[positions[0].$1][positions[0].$2] = Dice(value: 2);
      setState(() {});
    }
  }

  Color _getDiceColor(int value) {
    return switch (value) {
      1 => const Color(0xFFFF6B6B),
      2 => const Color(0xFFFFA726),
      3 => const Color(0xFFFFEB3B),
      4 => const Color(0xFF66BB6A),
      5 => const Color(0xFF42A5F5),
      6 => const Color(0xFFAB47BC),
      _ => Colors.grey,
    };
  }
}

enum HighlightArea {
  none,
  board,
  score,
  nextDice,
}

class TutorialStep {
  final String title;
  final String description;
  final String buttonText;
  final HighlightArea highlightArea;
  final bool demoMode;
  final int? targetDiceValue;
  final int? targetCount;

  TutorialStep({
    required this.title,
    required this.description,
    required this.buttonText,
    this.highlightArea = HighlightArea.none,
    this.demoMode = false,
    this.targetDiceValue,
    this.targetCount,
  });
}
