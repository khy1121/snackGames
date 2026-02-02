import 'package:flutter/material.dart';
import '../services/challenge_service.dart';
import '../services/game_data_service.dart';

/// 도전과제 페이지
class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key});

  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  @override
  void initState() {
    super.initState();
    _syncProgress();
  }

  /// 게임 데이터와 도전과제 진행도 동기화
  void _syncProgress() {
    final gamesPlayed = GameDataService.getTotalGamesPlayed();
    final bestDice = GameDataService.getBestScore('dice');
    final best2048 = GameDataService.getBestScore('2048');
    final bestScore = bestDice > best2048 ? bestDice : best2048;

    // 게임 횟수 관련 도전과제 동기화
    ChallengeService.updateProgress('play_1', gamesPlayed);
    ChallengeService.updateProgress('play_3', gamesPlayed);
    ChallengeService.updateProgress('play_5', gamesPlayed);
    ChallengeService.updateProgress('play_10', gamesPlayed);
    ChallengeService.updateProgress('play_15', gamesPlayed);
    ChallengeService.updateProgress('play_20', gamesPlayed);
    ChallengeService.updateProgress('play_30', gamesPlayed);
    ChallengeService.updateProgress('play_40', gamesPlayed);
    ChallengeService.updateProgress('play_50', gamesPlayed);
    ChallengeService.updateProgress('play_75', gamesPlayed);

    // 점수 관련 도전과제 동기화
    ChallengeService.updateProgress('score_300', bestScore);
    ChallengeService.updateProgress('score_500', bestScore);
    ChallengeService.updateProgress('score_1000', bestScore);
    ChallengeService.updateProgress('score_1500', bestScore);
    ChallengeService.updateProgress('score_2000', bestScore);
    ChallengeService.updateProgress('score_3000', bestScore);
    ChallengeService.updateProgress('score_4000', bestScore);
    ChallengeService.updateProgress('score_5000', bestScore);
    ChallengeService.updateProgress('score_7500', bestScore);
  }

  void _tryLevelUp() async {
    if (ChallengeService.canLevelUp()) {
      final reward = await ChallengeService.levelUp();
      if (reward > 0) {
        GameDataService.addPoints(reward);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 레벨업! +$reward 포인트 획득!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = ChallengeService.getCurrentLevel();
    final levelData = ChallengeService.getCurrentLevelData();
    final xp = ChallengeService.getCurrentXP();
    final xpProgress = ChallengeService.getXPProgress();
    final challenges = ChallengeService.getCurrentChallenges();
    final canLevelUp = ChallengeService.canLevelUp();
    final nextLevel = ChallengeService.getNextLevelData();

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
          '도전과제',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 현재 레벨 카드
            _buildLevelCard(level, levelData, xp, xpProgress, nextLevel),
            const SizedBox(height: 24),

            // 도전과제 섹션
            const Text(
              '🎯 현재 도전과제',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...challenges.map((c) => _buildChallengeItem(c)),
            const SizedBox(height: 24),

            // 레벨업 버튼
            if (nextLevel != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canLevelUp ? _tryLevelUp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canLevelUp
                        ? const Color(0xFF10B981)
                        : Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    canLevelUp
                        ? '🚀 레벨업! (+${levelData.reward}P)'
                        : '도전과제를 완료하세요',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // 레벨 목록
            const Text(
              '📋 전체 레벨',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...ChallengeService.levels.map((l) => _buildLevelListItem(l, level)),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(int level, LevelData data, int xp, double xpProgress, LevelData? nextLevel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667EEA).withValues(alpha: 0.4),
            const Color(0xFF764BA2).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Lv.$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'XP: $xp${nextLevel != null ? ' / ${nextLevel.xpRequired}' : ' (MAX)'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Text(
                  '+${data.reward}P',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (nextLevel != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: xpProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF667EEA)),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChallengeItem(Challenge challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: challenge.isCompleted
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: challenge.isCompleted
            ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: challenge.isCompleted
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              challenge.isCompleted ? Icons.check : Icons.flag,
              color: challenge.isCompleted ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: challenge.isCompleted ? Colors.white : Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: challenge.progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      challenge.isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF667EEA),
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${challenge.currentValue}/${challenge.targetValue}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: challenge.isCompleted ? const Color(0xFF10B981) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelListItem(LevelData levelData, int currentLevel) {
    final isUnlocked = levelData.level <= currentLevel;
    final isCurrent = levelData.level == currentLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFF667EEA).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF667EEA)
                  : Colors.grey.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${levelData.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              levelData.name,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.grey,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            isUnlocked ? '✓' : '🔒',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
