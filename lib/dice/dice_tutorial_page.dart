import 'package:flutter/material.dart';
import 'dice_board.dart';
import 'dice_widget.dart';
import 'dice_theme.dart';

/// 주사위 게임 튜토리얼 페이지
class DiceTutorialPage extends StatefulWidget {
  const DiceTutorialPage({super.key});

  @override
  State<DiceTutorialPage> createState() => _DiceTutorialPageState();
}

class _DiceTutorialPageState extends State<DiceTutorialPage> {
  int _currentStep = 0;
  
  final List<TutorialStep> _steps = [
    TutorialStep(
      title: '주사위 게임에 오신 것을 환영합니다! 🎲',
      description: '같은 숫자의 주사위 3개를 모아서\n더 큰 숫자를 만드는 게임이에요!',
      emoji: '👋',
      diceExample: [1, 1, 1],
      exampleTitle: '예시',
      exampleDescription: '주사위 1 + 1 + 1 = 주사위 2',
    ),
    TutorialStep(
      title: '주사위 놓는 방법',
      description: '화면 아래에 나오는 주사위를\n원하는 칸에 터치해서 놓으세요',
      emoji: '☝️',
      instruction: '1. 아래쪽에 다음 주사위가 보여요\n2. 놓고 싶은 칸을 터치!\n3. 주사위가 위에서 아래로 떨어져요',
    ),
    TutorialStep(
      title: '주사위 합치는 방법',
      description: '같은 숫자 3개가 모이면\n자동으로 합쳐져요!',
      emoji: '✨',
      diceExample: [2, 2, 2],
      exampleTitle: '합치기 예시',
      exampleDescription: '주사위 2 + 2 + 2 = 주사위 3\n주사위 3 + 3 + 3 = 주사위 4\n주사위 4 + 4 + 4 = 주사위 5\n주사위 5 + 5 + 5 = 주사위 6',
    ),
    TutorialStep(
      title: '매직 주사위는 뭐예요? ✨',
      description: '주사위 6을 3개 모으면\n매직 주사위가 생겨요!',
      emoji: '🌟',
      diceExample: [6, 6, 6],
      exampleTitle: '매직 주사위',
      exampleDescription: '주사위 6 + 6 + 6 = 매직 주사위 ✨\n\n매직 주사위 2개를 모으면\n주변 3×3 영역이 폭발해요!\n큰 점수를 얻을 수 있어요! 💥',
      isMagic: true,
    ),
    TutorialStep(
      title: '콤보로 점수 올리기! 🔥',
      description: '한 번에 여러 개를 합치면\n콤보가 터져요!',
      emoji: '💯',
      instruction: '콤보 꿀팁:\n\n1. 같은 숫자를 여러 개 만들어요\n2. 한 번에 많이 합칠수록 점수 UP!\n3. 3개, 4개, 5개... 더 많이 모으세요!\n4. 콤보가 터지면 화면이 반짝여요 ✨',
    ),
    TutorialStep(
      title: '높은 점수를 위한 꿀팁! 🍯',
      description: '이렇게 하면 점수가 쑥쑥 올라가요',
      emoji: '🎯',
      instruction: '💡 고수의 비법:\n\n1️⃣ 한 칸에 높은 숫자 모으기\n   → 같은 줄에 비슷한 숫자를 놓으세요\n\n2️⃣ 빈 칸 많이 남겨두기\n   → 빈 칸이 많으면 합치기 쉬워요\n\n3️⃣ 콤보 노리기\n   → 한 번에 여러 개 합치면 대박!\n\n4️⃣ 매직 주사위 만들기\n   → 주사위 6을 3개 모으세요!',
    ),
    TutorialStep(
      title: '게임 오버는 언제? 😱',
      description: '보드가 가득 차면\n게임이 끝나요',
      emoji: '⚠️',
      instruction: '게임 오버 조건:\n\n❌ 모든 칸이 꽉 찼어요\n❌ 더 이상 합칠 수 없어요\n\n게임이 끝나도 괜찮아요!\n다시 도전하면 더 높은 점수를 얻을 수 있어요! 💪',
    ),
    TutorialStep(
      title: '이제 시작해볼까요? 🚀',
      description: '준비되셨나요?\n지금 바로 게임을 시작해보세요!',
      emoji: '🎮',
      instruction: '기억하세요:\n\n✅ 같은 숫자 3개를 모으기\n✅ 빈 칸 많이 남기기\n✅ 콤보로 높은 점수 얻기\n✅ 매직 주사위 만들기\n\n화이팅! 🎉',
      isLastStep: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E5940),
        title: const Text('주사위 게임 배우기', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 진행 상황 표시
            _buildProgressBar(),
            
            // 튜토리얼 내용
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 이모지
                    Text(
                      step.emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 24),
                    
                    // 제목
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
                    
                    // 설명
                    Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF5A7A65),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // 주사위 예시
                    if (step.diceExample != null) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              step.exampleTitle!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E5940),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // 주사위 표시
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: step.diceExample!.map((value) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: DiceWidget(
                                    dice: step.isMagic && value == 6 
                                        ? Dice(value: 0, type: DiceType.magic)
                                        : Dice(value: value),
                                    size: 70,
                                    theme: const DiceThemeData(
                                      id: 'tutorial',
                                      name: '튜토리얼',
                                      description: '튜토리얼용 테마',
                                      backgroundGradient: LinearGradient(
                                        colors: [Color(0xFFFAF8F3), Color(0xFFF5F3ED)],
                                      ),
                                      boardColor: Color(0xFFE8E6DB),
                                      cellColor: Color(0xFFCDC1B4),
                                      textColor: Color(0xFF776E65),
                                      diceColors: [],
                                      style: DiceStyle.standard,
                                      enableShadows: true,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            
                            if (step.exampleDescription != null) ...[
                              const SizedBox(height: 20),
                              Text(
                                step.exampleDescription!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5A7A65),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // 설명 텍스트
                    if (step.instruction != null) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          step.instruction!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2E5940),
                            height: 1.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // 하단 버튼
            _buildBottomButtons(step),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_currentStep + 1}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B894),
                ),
              ),
              Text(
                ' / ${_steps.length}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00B894)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomButtons(TutorialStep step) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 이전 버튼
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF00B894), width: 2),
                ),
                child: const Text(
                  '이전',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B894),
                  ),
                ),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 12),
          
          // 다음/시작 버튼
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: () {
                if (step.isLastStep) {
                  // 게임 시작
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/dice');
                } else {
                  setState(() {
                    _currentStep++;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF00B894),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                step.isLastStep ? '게임 시작하기! 🎮' : '다음',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 튜토리얼 단계 모델
class TutorialStep {
  final String title;
  final String description;
  final String emoji;
  final List<int>? diceExample;
  final String? exampleTitle;
  final String? exampleDescription;
  final String? instruction;
  final bool isLastStep;
  final bool isMagic;
  
  TutorialStep({
    required this.title,
    required this.description,
    required this.emoji,
    this.diceExample,
    this.exampleTitle,
    this.exampleDescription,
    this.instruction,
    this.isLastStep = false,
    this.isMagic = false,
  });
}
