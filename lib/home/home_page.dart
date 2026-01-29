import 'package:flutter/material.dart';
import '../game/game_page.dart';
import '../dice/dice_game_page.dart';
import '../zerosum/zerosum_page.dart';
import '../profile/profile_page.dart';
import '../services/game_data_service.dart';
import '../services/daily_mission_service.dart';
import '../services/achievement_service.dart';

/// 게임 정보 데이터
class GameInfo {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final List<Color> colors;
  final String rules;
  final String difficulty;
  final Widget Function(BuildContext) pageBuilder;

  const GameInfo({
    required this.id,
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
    id: '2048',
    title: '2048',
    subtitle: '스와이프로 숫자 합치기',
    icon: '🔢',
    colors: const [Color(0xFFEDC22E), Color(0xFFF39C12)],
    rules: '''📖 게임 규칙
• 스와이프로 타일 이동
• 같은 숫자 합치기
• 2048 타일 만들기!''',
    difficulty: '''📈 난이도
• 점수↑ → 빈 공간↓
• 전략적 배치 필수''',
    pageBuilder: (_) => const GamePage(),
  ),
  GameInfo(
    id: 'dice',
    title: 'Dice Merge',
    subtitle: '주사위 3개 매칭하기',
    icon: '🎲',
    colors: const [Color(0xFF00B894), Color(0xFF00CEC9)],
    rules: '''📖 게임 규칙
• 빈 칸에 주사위 배치
• 같은 숫자 3개 인접 시 합체
• 1→2→3→...→⭐ 업그레이드''',
    difficulty: '''📈 난이도
• 점수↑ → 랜덤 범위↑
• 보드가 빠르게 채워짐''',
    pageBuilder: (_) => const DiceGamePage(),
  ),
  GameInfo(
    id: 'zerosum',
    title: 'Zero Sum',
    subtitle: '합을 0으로 만들기',
    icon: '⚖️',
    colors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
    rules: '''📖 게임 규칙
• 열 탭으로 블록 드롭
• 인접 블록 합=0 → 폭발!
• 0블록(⭐)은 조커''',
    difficulty: '''📈 난이도
• 점수↑ → 블록 빠르게 쌓임
• 콤보로 고득점''',
    pageBuilder: (_) => const ZeroSumPage(),
  ),
];

/// 스낵게임즈 홈 페이지
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await GameDataService.init();
    await DailyMissionService.init(GameDataService.prefs);
    await AchievementService.init(GameDataService.prefs);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF667EEA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍿', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                '스낵게임즈',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '기다림을 게임으로 바꾸다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    final lastPlayed = GameDataService.getLastPlayedGame();
    final mission = DailyMissionService.currentMission;
    final rank = AchievementService.getCurrentRank();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Stitch Purple Theme
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              _buildHeader(rank),

              // 컨텐츠
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 12),

                    // 이어하기 버튼
                    if (lastPlayed != null) ...[
                      _buildContinueButton(lastPlayed),
                      const SizedBox(height: 16),
                    ],

                    // 데일리 미션
                    if (mission != null) ...[
                      _buildDailyMission(mission),
                      const SizedBox(height: 20),
                    ],

                    // 섹션 헤더
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Text(
                            '🎮 인기 게임 리스트',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${gameList.length}개',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 게임 리스트
                    ...gameList.map((game) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GameCard(
                            game: game,
                            bestScore: GameDataService.getBestScore(game.id),
                            todayScore: GameDataService.getTodayScore(game.id),
                            onTap: () => _navigateToGame(game),
                            onInfoTap: () => _showGameInfo(game),
                          ),
                        )),

                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        '짧게, 가볍게, 계속하게/ ⚡',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // 하단 네비게이션 바
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, '홈'),
                _buildNavItem(1, Icons.games_rounded, '게임'),
                _buildNavItem(2, Icons.leaderboard_rounded, '랭킹'),
                _buildNavItem(3, Icons.settings_rounded, '설정'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF667EEA).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF667EEA) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? const Color(0xFF667EEA) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RankInfo rank) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              // 브랜드 로고
              const Text('🍿', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '스낵게임즈',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 프로필 버튼
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(rank.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        rank.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 모토 (Pill-shaped translucent container)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '기다림을 게임으로 바꾸다 ✨',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(String gameId) {
    final game =
        gameList.firstWhere((g) => g.id == gameId, orElse: () => gameList.first);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9F7AEA).withValues(alpha: 0.9), // Lighter Purple
            const Color(0xFF7F9CF5).withValues(alpha: 0.9), // Blue-ish
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D28D9).withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              const Text(
                '이어하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(20),
                 ),
                 child: Text(
                     'PLAY',
                     style: TextStyle(
                         color: const Color(0xFF7F9CF5),
                         fontWeight: FontWeight.bold,
                         fontSize: 12,
                     ),
                 ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
               // Game Icon / Grid Preview
               Container(
                 width: 60,
                 height: 60,
                 decoration: BoxDecoration(
                   color: Colors.white.withValues(alpha: 0.2),
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: Center(child: Text(game.icon, style: const TextStyle(fontSize: 32))),
               ),
               const SizedBox(width: 16),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     game.title,
                     style: const TextStyle(
                       fontSize: 28,
                       fontWeight: FontWeight.w800,
                       color: Colors.white,
                       fontStyle: FontStyle.italic, 
                     ),
                   ),
                   Text(
                     game.subtitle,
                     style: TextStyle(
                       fontSize: 13,
                       color: Colors.white.withValues(alpha: 0.9),
                     ),
                   ),
                 ],
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMission(DailyMission mission) {
    final percent = (mission.progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF9F43).withValues(alpha: 0.25),
            const Color(0xFFFFBE76).withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF9F43).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9F43).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('📋', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '오늘의 미션',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (mission.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✓ 완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F43).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎁 ${mission.reward}P',
                    style: const TextStyle(
                      color: Color(0xFFFF9F43),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mission.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: mission.progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      mission.isCompleted
                          ? Colors.green
                          : const Color(0xFFFF9F43),
                    ),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: TextStyle(
                  color: mission.isCompleted
                      ? Colors.green
                      : const Color(0xFFFF9F43),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToGame(GameInfo game) async {
    await GameDataService.setLastPlayedGame(game.id);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: game.pageBuilder),
      ).then((_) {
        setState(() {});
      });
    }
  }

  void _showGameInfo(GameInfo game) {
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
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(game.icon, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                game.rules,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  game.difficulty,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToGame(game);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: game.colors.first,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('🎮 Play Now!',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
  final int bestScore;
  final int todayScore;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  const _GameCard({
    required this.game,
    required this.bestScore,
    required this.todayScore,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.game.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(widget.game.icon,
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.game.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.game.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildScoreBadge(
                            'Best', widget.bestScore, Colors.amber),
                        const SizedBox(width: 8),
                        _buildScoreBadge(
                            'Today', widget.todayScore, Colors.white70),
                      ],
                    ),
                  ],
                ),
              ),
              // 버튼들
              Column(
                children: [
                  GestureDetector(
                    onTap: widget.onInfoTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info_outline,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.play_circle_filled,
                      color: Colors.white.withValues(alpha: 0.9), size: 28),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(String label, int score, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        Text(
          score > 0 ? '$score' : '--',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
