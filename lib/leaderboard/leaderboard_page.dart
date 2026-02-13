import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _gameIds = ['dice', '2048', 'slotball', 'blockpuzzle', 'microgame_rush'];
  
  // Mapping game IDs to human-readable names or icons
  final Map<String, String> _gameTitles = {
    'dice': '주사위 합치기',
    '2048': '2048',
    'slotball': '슬롯 볼',
    'blockpuzzle': '블록 퍼즐',
    'microgame_rush': '미니게임 러시',
  };

  // Cache futures to prevent FutureBuilder from re-firing on rebuild
  final Map<String, Future<List<LeaderboardEntry>>> _cachedFutures = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _gameIds.length, vsync: this);
    _loadAllScores();
  }

  void _loadAllScores() {
    for (final id in _gameIds) {
      _cachedFutures[id] = LeaderboardService.getTopScores(id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EC),
      appBar: AppBar(
        title: const Text('🏆 명예의 전당'),
        backgroundColor: const Color(0xFFF7F5EC),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF2E5940),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2E5940),
          tabs: _gameIds.map((id) => Tab(text: _gameTitles[id])).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _gameIds.map((id) => _buildLeaderboardList(id)).toList(),
      ),
    );
  }

  Widget _buildLeaderboardList(String gameId) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: _cachedFutures[gameId],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('랭킹을 불러올 수 없습니다.\n${snapshot.error}'));
        }

        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(child: Text('아직 등록된 랭킹이 없습니다.\n첫 번째 주인공이 되어보세요!'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildRankItem(entry, index);
          },
        );
      },
    );
  }

  Widget _buildRankItem(LeaderboardEntry entry, int index) {
    Color rankColor;
    double scale = 1.0;
    
    if (index == 0) {
      rankColor = const Color(0xFFFFD700); // Gold
      scale = 1.05;
    } else if (index == 1) {
      rankColor = const Color(0xFFC0C0C0); // Silver
    } else if (index == 2) {
      rankColor = const Color(0xFFCD7F32); // Bronze
    } else {
      rankColor = Colors.grey.shade300;
    }

    return Transform.scale(
      scale: scale,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: index < 3 ? Border.all(color: rankColor, width: 2) : null,
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: index < 3 ?  Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Name & Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatDate(entry.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Score
            Text(
              '${entry.score}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF2E5940),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }
}
