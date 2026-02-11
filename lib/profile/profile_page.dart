import 'package:flutter/material.dart';
import '../services/game_data_service.dart';
import '../services/achievement_service.dart';
import '../services/daily_mission_service.dart';

/// 프로필 페이지 - 랭크, 통계, 업적
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final rank = AchievementService.getCurrentRank();
    final totalPoints = AchievementService.getTotalPoints();
    final achievements = AchievementService.getAllAchievements();
    final totalGames = GameDataService.getTotalGamesPlayed();
    final totalTime = GameDataService.getTotalPlayTime();
    final rewards = DailyMissionService.getTotalRewards();

    // 다음 랭크까지
    final nextRank = AchievementService.ranks.firstWhere(
      (r) => r.minPoints > rank.minPoints,
      orElse: () => rank,
    );
    final pointsToNext = nextRank.minPoints - totalPoints;
    final progressToNext = (totalPoints - rank.minPoints) /
        (nextRank.minPoints - rank.minPoints).clamp(1, double.infinity);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '프로필',
          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 랭크 카드
            _buildRankCard(rank, totalPoints, pointsToNext, progressToNext, nextRank),
            const SizedBox(height: 20),

            // 통계
            _buildStatsRow(context, totalGames, totalTime, rewards),
            const SizedBox(height: 24),

            // High Scores 섹션
            _buildSectionHeader(context, '🏆 High Scores'),
            const SizedBox(height: 12),
            _buildHighScores(context),
            const SizedBox(height: 24),

            // 게임별 플레이 통계 섹션
            _buildSectionHeader(context, '📊 게임별 플레이 횟수'),
            const SizedBox(height: 12),
            _buildPerGameStats(context),
            const SizedBox(height: 24),

            // 업적 섹션
            _buildSectionHeader(context, '🎖️ Achievements'),
            const SizedBox(height: 12),
            ...achievements.map((a) => _buildAchievementItem(context, a)),

            // 브랜드 푸터
            const SizedBox(height: 32),
            Center(
              child: Text(
                'SNACK GAMES 🍿',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildRankCard(
      RankInfo rank, int totalPoints, int pointsToNext, double progress, RankInfo nextRank) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withValues(alpha: 0.3),
            const Color(0xFF764BA2).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // Rank Tier
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'RANK TIER',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Rank Icon & Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(rank.icon, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rank.name} Tier',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Total Points: $totalPoints',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress to next rank
          if (rank.name != 'Diamond') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '다음 랭크까지 $pointsToNext 포인트',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '$totalPoints / ${nextRank.minPoints}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF667EEA)),
                minHeight: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int totalGames, int totalTime, int rewards) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(context, '🎮', '총 게임', '$totalGames회'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(context, '⏱️', '플레이 시간', '$totalTime분'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(context, '🎁', '보상', '$rewards'),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighScores(BuildContext context) {
    final games = [
      {'icon': '🔢', 'name': '배수의 법칙', 'score': GameDataService.getBestScore('2048')},
      {'icon': '🎲', 'name': '합쳐라! 주사위', 'score': GameDataService.getBestScore('dice')},
      {'icon': '🎱', 'name': '슬롯 볼', 'score': GameDataService.getBestScore('slotball')},
      {'icon': '🧩', 'name': '블록 블리츠', 'score': GameDataService.getBestScore('blockpuzzle')},
      {'icon': '⚡', 'name': '미니게임 러시', 'score': GameDataService.getBestScore('microgame_rush')},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: games.map((game) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(game['icon'] as String, 
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    game['name'] as String,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  (game['score'] as int) > 0 ? '${game['score']}점' : '--',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementItem(BuildContext context, Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final progressValue = achievement.currentValue / achievement.targetValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF667EEA).withValues(alpha: 0.1)
            : Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: isUnlocked
            ? Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF667EEA).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 20,
                  color: isUnlocked ? const Color(0xFF667EEA) : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUnlocked
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.7)
                        : Colors.grey.withValues(alpha: 0.7),
                  ),
                ),
                if (!isUnlocked && achievement.targetValue > 1) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressValue.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF667EEA)),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 상태
          if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✓',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (achievement.targetValue > 1)
            Text(
              '${achievement.currentValue}/${achievement.targetValue}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            )
          else
            const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  Widget _buildPerGameStats(BuildContext context) {
    final gameStats = [
      {'icon': '🎲', 'name': '주사위', 'id': 'dice'},
      {'icon': '🔢', 'name': '배수의 법칙', 'id': '2048'},
      {'icon': '🎱', 'name': '슬롯 볼', 'id': 'slotball'},
      {'icon': '🧩', 'name': '블록 블리츠', 'id': 'blockpuzzle'},
      {'icon': '⚡', 'name': '미니게임', 'id': 'microgame_rush'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: gameStats.map((game) {
          final count = GameDataService.prefs.getInt('game_count_${game['id']}') ?? 0;
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 80) / 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(game['icon'] as String, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game['name'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$count회',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
