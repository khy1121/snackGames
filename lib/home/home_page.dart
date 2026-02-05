import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../game/game_page.dart';
import '../dice/dice_game_page.dart';

import '../profile/profile_page.dart';
import '../shop/shop_page.dart';
import '../shop/upgrade_page.dart';
import '../lucky_wheel/lucky_wheel_page.dart';
import '../services/game_data_service.dart';
import '../services/daily_mission_service.dart';
import '../services/achievement_service.dart';
import '../services/challenge_service.dart';
import '../services/upgrade_service.dart';
import '../services/daily_attendance_service.dart';
import '../services/lucky_wheel_service.dart';
import '../services/pwa_install_service.dart';
import '../services/vibration_service.dart';
import '../services/music_player_service.dart';
import '../challenge/challenge_page.dart';
import '../settings/settings_page.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/animated_counter.dart';
import '../widgets/music_player_popup.dart';

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
    id: 'dice',
    title: '합쳐라! 주사위',
    subtitle: '주사위 3개 매칭하기',
    icon: '🎲',
    colors: const [Color(0xFF00B894), Color(0xFF00CEC9)],
    rules: '''📖 게임 규칙
• 빈 칸에 주사위 배치
• 같은 숫자 3개 인접 시 합체
• ⭐x3 = 💥3x3 대폭발!''',
    difficulty: '''📈 난이도
• 점수↑ → 랜덤 범위↑
• 보드가 빠르게 채워짐''',
    pageBuilder: (_) => const DiceGamePage(),
  ),

  GameInfo(
    id: '2048',
    title: '배수의 법칙',
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
  bool _isPWAInstallable = false;
  
  // Cached data to prevent excessive service calls
  String? _lastPlayed;
  DailyMission? _mission;
  RankInfo? _rank;
  int _level = 1;
  LevelData? _levelData;
  double _xpProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initServices();
    if (kIsWeb) {
      _initPWA();
    }
  }

  void _initPWA() {
    PWAInstallService.initialize();
    setState(() {
      _isPWAInstallable = PWAInstallService.shouldShowInstallButton();
    });
  }

  Future<void> _installPWA() async {
    // iOS인 경우 설치 안내 표시
    if (PWAInstallService.isIOS() && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.apple, color: Colors.black),
              SizedBox(width: 8),
              Text('iOS 앱 설치 방법'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. 하단의 공유 버튼 (📤)을 누르세요',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '2. "홈 화면에 추가"를 선택하세요',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                '3. "추가"를 눌러 설치를 완료하세요',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Android/Chrome - 자동 설치 프롬프트
    final success = await PWAInstallService.installPWA();
    if (success && mounted) {
      // 설치가 승인됨 - 버튼 숨김
      setState(() {
        _isPWAInstallable = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📱 앱 설치가 시작되었습니다!')),
      );
    } else if (mounted) {
      // 사용자가 거부했거나 설치 불가능 - 버튼 유지
      setState(() {
        _isPWAInstallable = PWAInstallService.shouldShowInstallButton();
      });
    }
  }

  Future<void> _initServices() async {
    await GameDataService.init();
    await VibrationService.init(GameDataService.prefs);
    await DailyMissionService.init(GameDataService.prefs);
    await AchievementService.init(GameDataService.prefs);
    await ChallengeService.init(GameDataService.prefs);
    await UpgradeService.init(GameDataService.prefs);
    await DailyAttendanceService.init();
    await LuckyWheelService.init();
    
    // 통합 음악 플레이어 초기화 (웹에서는 사용자 상호작용 후 재생)
    await MusicPlayerService().initialize();
    
    if (mounted) {
      _loadCachedData();
      _checkDailyAttendance(); // 앱 시작 시 출석 체크
      setState(() => _isLoading = false);
    }
  }
  
  /// Load and cache all data to prevent excessive service calls
  void _loadCachedData() {
    // Sync external data first
    final totalGames = GameDataService.getTotalGamesPlayed();
    final bestScore2048 = GameDataService.getBestScore('2048');
    final bestScoreDice = GameDataService.getBestScore('dice');
    
    AchievementService.syncFromGameData(totalGames);
    ChallengeService.syncFromGameData(totalGames, bestScore2048, bestScoreDice);

    _lastPlayed = GameDataService.getLastPlayedGame();
    _mission = DailyMissionService.currentMission;
    _rank = AchievementService.getCurrentRank();
    _level = ChallengeService.getCurrentLevel();
    _levelData = ChallengeService.getCurrentLevelData();
    _xpProgress = ChallengeService.getXPProgress();
  }

  // 일일 출석 체크
  Future<void> _checkDailyAttendance() async {
    if (DailyAttendanceService.hasAttendedToday()) {
      return; // 이미 출석함
    }

    final reward = await DailyAttendanceService.checkAttendance();
    if (reward != null && mounted) {
      _showAttendanceDialog(reward);
    }
  }

  void _showAttendanceDialog(AttendanceReward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(reward.isSpecial ? '🎉' : '🎁'),
            const SizedBox(width: 8),
            Text(reward.isSpecial ? '7일 연속 출석!' : '출석 완료!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reward.isSpecial)
              const Text(
                '대박! 7일 연속 출석 달성!\n특별 보상을 드립니다!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )
            else
              Text(
                '${reward.streakDays}일 연속 출석 중!',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '포인트: +${reward.points}P',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '경험치: +${reward.exp}XP',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '계속 출석하면 더 큰 보상을!',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 보상 지급
              GameDataService.addPoints(reward.points);
              ChallengeService.addXP(reward.exp);
              Navigator.pop(context);
              _loadCachedData(); // 데이터 새로고침
              setState(() {});
            },
            child: const Text('받기!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍿', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                '스낵게임즈',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '기다림을 게임으로 바꾸다',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
            ],
          ),
        ),
      );
    }

    // Use cached data instead of calling services every build
    return Listener(
      onPointerDown: (_) {
        // 웹/PWA에서 사용자 상호작용 시 음악 재생 시작
        if (kIsWeb) {
          MusicPlayerService().onUserInteraction();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // 헤더 (홈, 게임 탭에서만 표시)
              if (_rank != null && _currentNavIndex < 2) _buildHeader(_rank!, _level, _xpProgress),

              // 메인 컨텐츠 (탭에 따라 변경)
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
        // 하단 네비게이션 바
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                  _buildNavItem(2, Icons.emoji_events_rounded, '도전'),
                  _buildNavItem(3, Icons.settings_rounded, '설정'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Views ---

  Widget _buildHubView(
      String? lastPlayed, DailyMission? mission, LevelData? levelData) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 12),

        // 레벨 정보 카드 (Hub Only)
        if (levelData != null) _buildLevelCard(levelData),
        const SizedBox(height: 16),

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

        // 바로가기 힌트
        GestureDetector(
          onTap: () => setState(() => _currentNavIndex = 1),
          child: Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: const Color(0xFF2E5940),
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: const Color(0xFF2E5940).withValues(alpha: 0.3),
                   blurRadius: 8,
                   offset: const Offset(0, 4),
                 ),
               ],
             ),
             child: Row(
               children: [
                 const Icon(Icons.videogame_asset, color: Colors.white),
                 const SizedBox(width: 12),
                 const Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text('새로운 게임 찾기', 
                       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     Text('아케이드 탭으로 이동하기',
                       style: TextStyle(color: Colors.white70, fontSize: 12)),
                   ],
                 ),
                 const Spacer(),
                 const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
               ],
             ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 튜토리얼 카드
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DiceGamePage(isTutorial: true),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B894), Color(0xFF00D2A0)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '주사위 합치기를 배워볼까요?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '쉽고 재미있는 튜토리얼',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '플레이',
                    style: TextStyle(
                      color: Color(0xFF00B894),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 새 기능: 출석 & 럭키 휠
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: '🎁',
                title: '출석 체크',
                subtitle: '${DailyAttendanceService.getStreakDays()}일 연속',
                colors: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                onTap: () => _checkDailyAttendance(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                icon: '🎰',
                title: '럭키 휠',
                subtitle: '행운을 시험해보세요',
                colors: const [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LuckyWheelPage()),
                  );
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 40),
          const Center(
            child: Text(
              '짧게, 가볍게, 계속하게 \u26A1',
              style: TextStyle(
                color: Color(0xFF2E5940),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBody() {
    switch (_currentNavIndex) {
      case 0:
        return _buildHubView(_lastPlayed, _mission, _levelData);
      case 1:
        return _buildGameListView();
      case 2:
        return const ChallengePage();
      case 3:
        return const SettingsPage();
      default:
        return _buildHubView(_lastPlayed, _mission, _levelData);
    }
  }

  Widget _buildGameListView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 12),
        // 섹션 헤더
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                '🎮 모든 게임',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                '${gameList.length}개',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        // 게임 리스트 (Grid로 변경 가능, 현재는 List 유지)
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
      ],
    );
  }

  // --- Components ---

  Widget _buildLevelCard(LevelData levelData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E5940).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2E5940),
            child: Text(
              '${levelData.level}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lv.${levelData.level} ${levelData.name}',
                style: const TextStyle(
                  color: Color(0xFF2E5940),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '게임을 플레이하고 XP를 획득하세요!',
                style: TextStyle(
                  color: Color(0xFF2E5940),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
        // 탭 전환 시 데이터 리프레시
        if (index == 0) _loadCachedData(); 
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF667EEA).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF2E5940) : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? const Color(0xFF2E5940) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(RankInfo rank, int level, double xpProgress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          // 첫 번째 줄: 브랜드 + 레벨 + 프로필
          Row(
            children: [
              // 브랜드 로고
              const Text('🍿', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '스낵게임즈',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E5940),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'v2.5.5',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF00B894),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        AnimatedCounter(
                          value: level,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF00B894),
                            fontWeight: FontWeight.bold,
                          ),
                          prefix: 'Lv.',
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 60,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: xpProgress),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00B894)),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 프로필 버튼
              GestureDetector(
                onTap: () => _showPopup(const ProfilePage()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF2E5940).withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(rank.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        rank.name,
                        style: const TextStyle(
                          color: Color(0xFF2E5940),
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
          
          const SizedBox(height: 10),
          
          // 두 번째 줄: 기능 버튼들 (레이블 포함)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 업그레이드
              _buildLabeledButton(
                icon: Icons.upgrade_rounded,
                label: '강화',
                color: const Color(0xFF9B59B6),
                onTap: () => _showPopup(const UpgradePage()),
              ),
              
              // 음악 토글
              ListenableBuilder(
                listenable: MusicPlayerService(),
                builder: (context, child) {
                  final musicService = MusicPlayerService();
                  return _buildLabeledButton(
                    icon: musicService.isMusicEnabled ? Icons.music_note : Icons.music_off,
                    label: '음악',
                    color: musicService.isMusicEnabled ? const Color(0xFF00B894) : Colors.grey,
                    onTap: () => musicService.toggleMusic(),
                  );
                },
              ),
              
              // 플레이리스트
              _buildLabeledButton(
                icon: Icons.queue_music_rounded,
                label: '목록',
                color: const Color(0xFF6C5CE7),
                onTap: () => showMusicPlayerPopup(context),
              ),
              
              // PWA 설치 (조건부)
              if (_isPWAInstallable)
                _buildLabeledButton(
                  icon: Icons.download_rounded,
                  label: '설치',
                  color: const Color(0xFF00B894),
                  onTap: _installPWA,
                ),
              
              // 상점
              _buildLabeledButton(
                icon: Icons.store_rounded,
                label: '상점',
                color: const Color(0xFFE67E22),
                onTap: () => _showPopup(const ShopPage()),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 모토
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E5940).withValues(alpha: 0.1)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '기다림을 게임으로 바꾸다 ✨',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2E5940),
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

    return GlassmorphismCard(
      blur: 20,
      opacity: 0.15,
      borderRadius: BorderRadius.circular(24),
      gradientColors: [
        const Color(0xFF9F7AEA),
        const Color(0xFF7F9CF5),
      ],
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                '이어하기',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                game.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      game.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (game.id == 'dice') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiceGamePage(resume: true)),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: game.pageBuilder),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF9F7AEA),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '플레이',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMission(DailyMission mission) {
    final percent = (mission.progress * 100).toInt();

    return GlassmorphismCard(
      blur: 15,
      opacity: 0.12,
      borderRadius: BorderRadius.circular(20),
      gradientColors: const [
        Color(0xFFFF9F43),
        Color(0xFFFFBE76),
      ],
      padding: const EdgeInsets.all(20),
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
              Expanded(
                child: Text(
                  '오늘의 미션',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              if (mission.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            style: TextStyle(
              color: Theme.of(context).primaryColor,
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
                      mission.isCompleted ? Colors.green : const Color(0xFFFF9F43),
                    ),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: TextStyle(
                  color: mission.isCompleted ? Colors.green : const Color(0xFFFF9F43),
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

  void _navigateToGame(GameInfo game) {
    GameDataService.setLastPlayedGame(game.id);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: game.pageBuilder),
      ).then((_) {
        // Reload and sync all data when returning from game
        if (mounted) {
          _loadCachedData();
          setState(() {});
        }
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

  Widget _buildFeatureCard({
    required String icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 헤더 아이콘 버튼 빌더
  Widget _buildHeaderIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  /// 레이블이 있는 버튼 빌더 (모바일 최적화)
  Widget _buildLabeledButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPopup(Widget page) {
    showDialog(
      context: context,
      barrierDismissible: true, // 바깥 클릭 시 닫힘
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8, // 화면 높이의 80%
          constraints: const BoxConstraints(maxWidth: 500), // 최대 너비 제한
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Dialog 자체 배경은 투명하게 하고 내부 Page의 배경을 사용하거나,
            // 여기서 클립을 적용하여 내부 Page가 둥근 모서리를 가지도록 함
          ),
          clipBehavior: Clip.hardEdge,
          child: page,
        ),
      ),
    ).then((_) {
      // 팝업이 닫힐 때 데이터 새로고침
      if (mounted) {
        _loadCachedData();
        setState(() {});
      }
    });
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
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
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
