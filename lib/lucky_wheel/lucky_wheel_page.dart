import 'package:flutter/material.dart';
import 'dart:math';
import '../services/lucky_wheel_service.dart';
import '../services/game_data_service.dart';
import '../services/challenge_service.dart';

class LuckyWheelPage extends StatefulWidget {
  const LuckyWheelPage({super.key});

  @override
  State<LuckyWheelPage> createState() => _LuckyWheelPageState();
}

class _LuckyWheelPageState extends State<LuckyWheelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSpinning = false;
  int _userPoints = 0;
  int _selectedSlot = 0;

  final List<WheelSlot> _slots = LuckyWheelService.getWheelSlots();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final points = await GameDataService.getPoints();
    setState(() {
      _userPoints = points;
    });
  }

  Future<void> _spinWheel() async {
    if (_isSpinning) return;

    if (_userPoints < LuckyWheelService.spinCost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ 포인트가 부족합니다!')),
        );
      }
      return;
    }

    setState(() {
      _isSpinning = true;
    });

    // 포인트 차감
    GameDataService.addPoints(-LuckyWheelService.spinCost);

    // 보상 결정
    final reward = LuckyWheelService.spin();

    // 애니메이션: 여러 바퀴 돌고 결과 슬롯에 정지
    final random = Random();
    // final extraSpins = 5 + random.nextInt(3); // 5~7바퀴 추가 회전 (현재 미사용)
    // final targetRotation = extraSpins * 2 * pi + (_selectedSlot * 2 * pi / _slots.length); // Unused

    _controller.reset();
    await _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 3000),
      curve: Curves.easeOutCubic,
    );

    // 보상 지급
    GameDataService.addPoints(reward.points);
    ChallengeService.addXP(reward.exp);

    await _loadData();

    if (mounted) {
      _showRewardDialog(reward);
    }

    setState(() {
      _isSpinning = false;
    });
  }

  void _showRewardDialog(WheelReward reward) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(reward.description),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reward.type == RewardType.jackpot)
              const Text(
                '🎰',
                style: TextStyle(fontSize: 80),
              )
            else if (reward.type == RewardType.large)
              const Text(
                '🌟',
                style: TextStyle(fontSize: 60),
              )
            else if (reward.type == RewardType.medium)
              const Text(
                '✨',
                style: TextStyle(fontSize: 50),
              )
            else
              const Text(
                '🎁',
                style: TextStyle(fontSize: 40),
              ),
            const SizedBox(height: 20),
            Text(
              '포인트: +${reward.points}P',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (reward.exp > 0)
              Text(
                '경험치: +${reward.exp}XP',
                style: const TextStyle(fontSize: 16),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎰 럭키 휠'),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900,
              Colors.purple.shade600,
              Colors.purple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 포인트 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.yellow, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '$_userPoints P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // 룰렛 휠
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 회전하는 휠
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _controller.value * 2 * pi * 5,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: CustomPaint(
                            painter: WheelPainter(_slots),
                          ),
                        ),
                      ),
                      // 중앙 버튼
                      GestureDetector(
                        onTap: _isSpinning ? null : _spinWheel,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isSpinning ? Colors.grey : Colors.yellow,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _isSpinning ? '...' : 'SPIN',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 포인터
                      Positioned(
                        top: -10,
                        child: Icon(
                          Icons.arrow_drop_down,
                          size: 60,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 비용 안내
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                '1회 비용: ${LuckyWheelService.spinCost} P',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '총 플레이: ${LuckyWheelService.getTotalSpins()}회',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<WheelSlot> slots;

  WheelPainter(this.slots);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sliceAngle = 2 * pi / slots.length;

    for (int i = 0; i < slots.length; i++) {
      final paint = Paint()
        ..color = Color(slots[i].color)
        ..style = PaintingStyle.fill;

      final startAngle = i * sliceAngle - pi / 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      // 테두리
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );

      // 텍스트
      final textPainter = TextPainter(
        text: TextSpan(
          text: slots[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final textAngle = startAngle + sliceAngle / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * cos(textAngle) - textPainter.width / 2;
      final textY = center.dy + textRadius * sin(textAngle) - textPainter.height / 2;

      textPainter.paint(canvas, Offset(textX, textY));
    }

    // 중앙 원
    final centerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 50, centerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
