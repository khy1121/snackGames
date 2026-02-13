import 'game_data_service.dart';

class LeaderboardEntry {
  final String userId;
  final String username;
  final int score;
  final DateTime timestamp;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.score,
    required this.timestamp,
    this.rank = 0,
  });

  factory LeaderboardEntry.fromFirestore(Map<String, dynamic> data, String userId, int rank) {
    return LeaderboardEntry(
      userId: userId,
      username: data['username'] ?? 'Unknown',
      score: data['score'] ?? 0,
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      rank: rank,
    );
  }

  // Mock factory
  factory LeaderboardEntry.mock(int index) {
    return LeaderboardEntry(
      userId: 'mock_user_$index',
      username: 'Player $index',
      score: 10000 - (index * 500),
      timestamp: DateTime.now().subtract(Duration(minutes: index * 10)),
      rank: index + 1,
    );
  }
}

class LeaderboardService {
  // Always run in mock mode since Firebase is not included
  static const bool _isMockMode = true;

  static Future<void> init() async {
    print('📊 LeaderboardService initialized in Mock Mode.');
  }

  static Future<void> submitScore(String gameId, int score) async {
    print('📝 [Mock] Submitting score $score for $gameId');
    // In production, this would save to a backend
  }

  // Stream for real-time updates (mock only)
  static Stream<List<LeaderboardEntry>> getTopScoresStream(String gameId, {int limit = 10}) {
    return Stream.value(List.generate(limit, (index) => LeaderboardEntry.mock(index)));
  }

  static Future<List<LeaderboardEntry>> getTopScores(String gameId, {int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(limit, (index) => LeaderboardEntry.mock(index));
  }
}
