import 'package:flutter/material.dart';
import 'microgame_base.dart';

/// 미니게임 전용 테마 및 색상
class MicroGameTheme {
  MicroGameTheme._(); // prevent instantiation

  // 브랜드 컬러
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color secondaryColor = Color(0xFFFFE66D);
  static const Color successColor = Color(0xFF51CF66);
  static const Color failureColor = Color(0xFFFF6B6B);
  static const Color warningColor = Color(0xFFFFD93D);

  // 사전 정의 반투명 색상 (withOpacity 대체 → 성능 최적화)
  static const Color black60 = Color(0x99000000);
  static const Color black38 = Color(0x61000000);
  static const Color black26 = Color(0x42000000);
  static const Color black54 = Color(0x8A000000);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color successHalf = Color(0x8051CF66);
  static const Color failureHalf = Color(0x80FF6B6B);

  // 배경 그라데이션
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF51CF66), Color(0xFF38D9A9)],
  );

  static const LinearGradient failureGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8787)],
  );

  // 난이도별 색상
  static Color difficultyColor(MicroGameDifficulty d) {
    switch (d) {
      case MicroGameDifficulty.easy:
        return const Color(0xFF51CF66);
      case MicroGameDifficulty.medium:
        return const Color(0xFFFFD93D);
      case MicroGameDifficulty.hard:
        return const Color(0xFFFF922B);
      case MicroGameDifficulty.extreme:
        return const Color(0xFFFF0000);
    }
  }

  static String difficultyLabel(MicroGameDifficulty d) {
    switch (d) {
      case MicroGameDifficulty.easy:
        return 'EASY';
      case MicroGameDifficulty.medium:
        return 'NORMAL';
      case MicroGameDifficulty.hard:
        return 'HARD';
      case MicroGameDifficulty.extreme:
        return 'EXTREME';
    }
  }

  // 텍스트 스타일
  static const TextStyle titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(color: black26, offset: Offset(2, 2), blurRadius: 4),
    ],
  );

  static const TextStyle instructionStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle countdownStyle = TextStyle(
    fontSize: 80,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(color: black38, offset: Offset(4, 4), blurRadius: 8),
    ],
  );

  // 애니메이션 간격
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // 진동 패턴
  static const List<int> successVibration = [0, 50, 50, 50];
  static const List<int> failureVibration = [0, 100, 50, 100];
}

/// 공통 UI 위젯
class MicroGameWidgets {
  MicroGameWidgets._();

  /// 타이머 프로그레스 바 (시간 잔량에 따라 색상 자동 변경)
  static Widget buildTimerBar(double progress, {bool isWarning = false}) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    return RepaintBoundary(
      child: Container(
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: MicroGameTheme.white24,
          borderRadius: BorderRadius.circular(4),
        ),
        child: FractionallySizedBox(
          widthFactor: clampedProgress,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              gradient: isWarning || clampedProgress < 0.3
                  ? const LinearGradient(colors: [Colors.red, Colors.orange])
                  : clampedProgress < 0.6
                      ? const LinearGradient(colors: [Colors.orange, Colors.yellow])
                      : const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
              borderRadius: BorderRadius.circular(4),
              boxShadow: clampedProgress < 0.3
                  ? const [BoxShadow(color: Color(0x80FF0000), blurRadius: 6)]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  /// 결과 배지 (성공/실패) — 스케일 애니메이션 내장
  static Widget buildResultBadge({
    required bool isSuccess,
    required String text,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: isSuccess
              ? MicroGameTheme.successGradient
              : MicroGameTheme.failureGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isSuccess
                  ? MicroGameTheme.successHalf
                  : MicroGameTheme.failureHalf,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSuccess ? '✅' : '❌',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 점수 표시
  static Widget buildScoreDisplay(int score, {double fontSize = 48}) {
    return Text(
      '$score',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        shadows: const [
          Shadow(color: MicroGameTheme.black38, offset: Offset(3, 3), blurRadius: 6),
        ],
      ),
    );
  }

  /// 지시문 표시 (글래스모피즘 스타일)
  static Widget buildInstruction(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: MicroGameTheme.black38,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MicroGameTheme.white24, width: 1),
      ),
      child: Text(
        text,
        style: MicroGameTheme.instructionStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
