import 'package:flutter/material.dart';
import 'zerosum_board.dart';

/// Zero Sum 게임 색상 테마
class ZeroSumColors {
  // 배경
  static const Color background = Color(0xFF1A1A2E);
  static const Color boardBackground = Color(0xFF16213E);
  static const Color cellBackground = Color(0xFF0F3460);

  // 블록 색상
  static const Color minusTwo = Color(0xFFE74C3C);
  static const Color minusOne = Color(0xFFE57373);
  static const Color zero = Color(0xFFFFC107);
  static const Color plusOne = Color(0xFF64B5F6);
  static const Color plusTwo = Color(0xFF2196F3);

  // 폭발 이펙트
  static const Color explosion = Color(0xFFFFD700);

  // UI
  static const Color headerText = Color(0xFFEAEAEA);
  static const Color scoreLabel = Color(0xFF94A3B8);
  static const Color scoreValue = Color(0xFFF8FAFC);
  static const Color buttonBackground = Color(0xFF4ECDC4);
  static const Color buttonText = Color(0xFF1A1A2E);

  /// 블록 값에 따른 색상 반환
  static Color getBlockColor(BlockValue value) {
    switch (value) {
      case BlockValue.minusTwo:
        return minusTwo;
      case BlockValue.minusOne:
        return minusOne;
      case BlockValue.zero:
        return zero;
      case BlockValue.plusOne:
        return plusOne;
      case BlockValue.plusTwo:
        return plusTwo;
    }
  }

  /// 블록 값에 따른 그라데이션 색상
  static List<Color> getBlockGradient(BlockValue value) {
    final base = getBlockColor(value);
    return [
      base,
      HSLColor.fromColor(base).withLightness(
        (HSLColor.fromColor(base).lightness - 0.15).clamp(0.0, 1.0),
      ).toColor(),
    ];
  }

  /// 블록 텍스트 색상
  static Color getBlockTextColor(BlockValue value) {
    if (value == BlockValue.zero) {
      return const Color(0xFF1A1A2E);
    }
    return Colors.white;
  }
}

/// 게임 카드 색상 (홈 화면용)
class ZeroSumCardColors {
  static const List<Color> gradient = [
    Color(0xFF00B4DB),
    Color(0xFF0083B0),
  ];
}
