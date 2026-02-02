import 'package:flutter/material.dart';
import '../services/upgrade_service.dart';
import '../services/game_data_service.dart';
import '../services/challenge_service.dart';

/// 업그레이드 페이지
class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  List<UpgradeStatus> _upgrades = [];
  int _currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _upgrades = UpgradeService.getAllUpgradeStatus(ChallengeService.getCurrentLevel());
      _currentPoints = GameDataService.getPoints();
    });
  }

  void _purchaseUpgrade(UpgradeStatus upgrade) {
    if (upgrade.isLocked) {
      _showMessage('레벨 ${upgrade.info.requiredLevel} 이상에서 해금됩니다!');
      return;
    }

    if (upgrade.isMaxLevel) {
      _showMessage('이미 최대 레벨입니다!');
      return;
    }

    if (_currentPoints < upgrade.nextCost) {
      _showMessage('포인트가 부족합니다!');
      return;
    }

    // 포인트 차감
    GameDataService.addPoints(-upgrade.nextCost);

    // 업그레이드 구매
    UpgradeService.purchaseUpgrade(upgrade.info.id, upgrade.nextCost);

    // 데이터 새로고침
    _loadData();

    _showMessage('${upgrade.info.name} 업그레이드 완료!');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF312E81)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildStatsCard(),
                    const SizedBox(height: 20),
                    ..._upgrades.map((upgrade) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _UpgradeCard(
                            upgrade: upgrade,
                            currentPoints: _currentPoints,
                            onPurchase: () => _purchaseUpgrade(upgrade),
                          ),
                        )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Text(
            '⚡ 업그레이드',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 6),
                Text(
                  '$_currentPoints P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalInvested = UpgradeService.getTotalInvestedPoints();
    final scoreMultiplier = UpgradeService.getScoreMultiplier();
    final pointsMultiplier = UpgradeService.getPointsMultiplier();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withValues(alpha: 0.3),
            Colors.blue.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                '현재 효과',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('점수', '×${scoreMultiplier.toStringAsFixed(1)}', Colors.amber),
              _buildStatItem('포인트', '×${pointsMultiplier.toStringAsFixed(1)}', Colors.green),
              _buildStatItem('투자', '${totalInvested}P', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// 업그레이드 카드
class _UpgradeCard extends StatelessWidget {
  final UpgradeStatus upgrade;
  final int currentPoints;
  final VoidCallback onPurchase;

  const _UpgradeCard({
    required this.upgrade,
    required this.currentPoints,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = currentPoints >= upgrade.nextCost;
    final isMaxLevel = upgrade.isMaxLevel;
    final isLocked = upgrade.isLocked;

    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMaxLevel 
                ? Colors.amber.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: isMaxLevel ? 2 : 1,
          ),
        ),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      upgrade.info.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            upgrade.info.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMaxLevel 
                                  ? Colors.amber.withValues(alpha: 0.3)
                                  : Colors.blue.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Lv.${upgrade.currentLevel}/${upgrade.info.maxLevel}',
                              style: TextStyle(
                                color: isMaxLevel ? Colors.amber : Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        upgrade.info.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (upgrade.currentLevel > 0)
                        Text(
                          '현재: ${upgrade.currentEffect}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Level Progress
          if (!isMaxLevel) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: upgrade.currentLevel / upgrade.info.maxLevel,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(Colors.blue),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Purchase Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: isLocked
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock, color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'LV ${upgrade.info.requiredLevel} 필요',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : isMaxLevel
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.amber, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'MAX LEVEL',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ElevatedButton(
                    onPressed: canAfford ? onPurchase : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford
                          ? const Color(0xFF3B82F6)
                          : Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: canAfford ? 5 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!canAfford)
                          const Icon(Icons.lock, size: 16)
                        else
                          const Icon(Icons.arrow_upward, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          canAfford
                              ? '업그레이드 (${upgrade.nextCost}P)'
                              : '포인트 부족 (${upgrade.nextCost}P)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          // Next Effect Preview
          if (!isMaxLevel && !isLocked)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '다음: ${upgrade.nextEffect}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
