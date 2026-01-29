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
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '프로필',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            _buildStatsRow(totalGames, totalTime, rewards),
            const SizedBox(height: 24),

            // High Scores 섹션
            _buildSectionHeader('🏆 High Scores'),
            const SizedBox(height: 12),
            _buildHighScores(),
            const SizedBox(height: 24),

            // 업적 섹션
            _buildSectionHeader('🎖️ Achievements'),
            const SizedBox(height: 12),
            ...achievements.map((a) => _buildAchievementItem(a)),

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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
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

  Widget _buildStatsRow(int totalGames, int totalTime, int rewards) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('🎮', '총 게임', '$totalGames회'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard('⏱️', '플레이 시간', '$totalTime분'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard('🎁', '보상', '$rewards'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighScores() {
    final games = [
      {'icon': '🔢', 'name': '2048', 'score': GameDataService.getBestScore('2048')},
      {'icon': '🎲', 'name': 'Dice Merge', 'score': GameDataService.getBestScore('dice')},
      {'icon': '⚖️', 'name': 'Zero Sum', 'score': GameDataService.getBestScore('zerosum')},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${(game['score'] as int) > 0 ? '${game['score']}점' : '--'}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
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

  Widget _buildAchievementItem(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final progressValue = achievement.currentValue / achievement.targetValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF667EEA).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
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
                  ? const Color(0xFF667EEA).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 20,
                  color: isUnlocked ? null : Colors.grey,
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
                    color: isUnlocked ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUnlocked
                        ? Colors.white.withValues(alpha: 0.7)
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
}
