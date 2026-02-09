import 'package:flutter/material.dart';

/// 미니게임 전용 테마 및 색상
class MicroGameTheme {
  // 브랜드 컬러
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color secondaryColor = Color(0xFFFFE66D);
  static const Color successColor = Color(0xFF51CF66);
  static const Color failureColor = Color(0xFFFF6B6B);
  static const Color warningColor = Color(0xFFFFD93D);
  
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
  
  // 텍스트 스타일
  static const TextStyle titleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.black26,
        offset: Offset(2, 2),
        blurRadius: 4,
      ),
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
      Shadow(
        color: Colors.black38,
        offset: Offset(4, 4),
        blurRadius: 8,
      ),
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
  /// 타이머 프로그레스 바
  static Widget buildTimerBar(double progress, {bool isWarning = false}) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: isWarning
                ? const LinearGradient(colors: [Colors.red, Colors.orange])
                : const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
  
  /// 결과 배지 (성공/실패)
  static Widget buildResultBadge({
    required bool isSuccess,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: isSuccess ? MicroGameTheme.successGradient : MicroGameTheme.failureGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isSuccess ? MicroGameTheme.successColor : MicroGameTheme.failureColor).withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
          Shadow(
            color: Colors.black38,
            offset: Offset(3, 3),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
  
  /// 지시문 표시
  static Widget buildInstruction(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: MicroGameTheme.instructionStyle,
        textAlign: TextAlign.center,
      ),
    );
  }
}
