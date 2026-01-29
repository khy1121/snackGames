import 'package:flutter/material.dart';
import '../game/game_page.dart';
import '../dice/dice_game_page.dart';
import '../zerosum/zerosum_page.dart';

/// 게임 정보 데이터
class GameInfo {
  final String title;
  final String subtitle;
  final String icon;
  final List<Color> colors;
  final String rules;
  final String difficulty;
  final Widget Function(BuildContext) pageBuilder;

  const GameInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.rules,
    required this.difficulty,
    required this.pageBuilder,
  });
}

/// 게임 정보 목록
final List<GameInfo> gameList = [
  GameInfo(
    title: '2048',
    subtitle: 'Slide & Merge Numbers',
    icon: '🔢',
    colors: const [Color(0xFFEDC22E), Color(0xFFF39C12)],
    rules: '''📖 게임 규칙
• 상하좌우로 스와이프하여 타일을 이동
• 같은 숫자의 타일이 만나면 합쳐짐
• 2048 타일을 만들면 승리!

🎯 목표
2 → 4 → 8 → 16 → ... → 2048''',
    difficulty: '''📈 난이도 상승
• 점수가 오를수록 빈 공간 감소
• 높은 숫자일수록 합치기 어려움
• 전략적인 타일 배치가 필수''',
    pageBuilder: (_) => const GamePage(),
  ),
  GameInfo(
    title: 'Dice Merge',
    subtitle: 'Match 3 Dice to Merge',
    icon: '🎲',
    colors: const [Color(0xFF00B894), Color(0xFF00CEC9)],
    rules: '''📖 게임 규칙
• 빈 칸을 탭하여 주사위 배치
• 같은 숫자 3개가 인접하면 합쳐짐
• 1→2→3→4→5→6→⭐ 순서로 업그레이드

🎯 목표
최대한 많은 ⭐(7) 주사위 생성''',
    difficulty: '''📈 난이도 상승
• 점수↑ → 랜덤 주사위 숫자 범위 증가
• 높은 주사위가 자주 등장 (합치기 어려움)
• 보드가 빠르게 채워짐''',
    pageBuilder: (_) => const DiceGamePage(),
  ),
  GameInfo(
    title: 'Zero Sum',
    subtitle: 'Make blocks sum to 0!',
    icon: '⚖️',
    colors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
    rules: '''📖 게임 규칙
• 열을 탭하여 블록 드롭 (-2 ~ +2)
• 인접 블록의 합이 0이면 폭발! 💥
• 0블록(⭐)은 조커 역할

🎯 목표
+1 + (-1) = 0 → 폭발!
+2 + (-1) + (-1) = 0 → 폭발!''',
    difficulty: '''📈 난이도 상승
• 점수↑ → 블록이 빠르게 쌓임
• 연쇄 반응(콤보)으로 고득점
• 전략적 음수/양수 배치 필요''',
    pageBuilder: (_) => const ZeroSumPage(),
  ),
];

/// 게임 허브 홈 페이지
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // 타이틀
              const Text(
                '🎮 Game Hub',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Choose your game',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // 게임 버튼들
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: gameList.length,
                  separatorBuilder: (_, _a) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final game = gameList[index];
                    return _GameCard(
                      game: game,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: game.pageBuilder,
                          ),
                        );
                      },
                      onInfoTap: () => _showGameInfo(context, game),
                    );
                  },
                ),
              ),
              
              // 푸터
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Made with ❤️ in Flutter',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGameInfo(BuildContext context, GameInfo game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              game.colors.first.withValues(alpha: 0.95),
              game.colors.last.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Text(game.icon, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          game.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              
              // 규칙
              Text(
                game.rules,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 난이도
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  game.difficulty,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 플레이 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: game.pageBuilder),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: game.colors.first,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '🎮 Play Now!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 게임 카드 위젯
class _GameCard extends StatefulWidget {
  final GameInfo game;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  const _GameCard({
    required this.game,
    required this.onTap,
    required this.onInfoTap,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.game.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.game.colors.first.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    widget.game.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.game.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 정보 버튼
              GestureDetector(
                onTap: widget.onInfoTap,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 화살표
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
