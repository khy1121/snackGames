import 'package:flutter/material.dart';

/// 2048 게임 색상 테마
class GameColors {
  // 배경색
  static const Color background = Color(0xFFFAF8EF);
  static const Color boardBackground = Color(0xFFBBADA0);
  static const Color emptyTile = Color(0xFFCDC1B4);
  
  // 타일 배경색
  static Color getTileColor(int value) {
    return switch (value) {
      0 => emptyTile,
      2 => const Color(0xFFEEE4DA),
      4 => const Color(0xFFEDE0C8),
      8 => const Color(0xFFF2B179),
      16 => const Color(0xFFF59563),
      32 => const Color(0xFFF67C5F),
      64 => const Color(0xFFF65E3B),
      128 => const Color(0xFFEDCF72),
      256 => const Color(0xFFEDCC61),
      512 => const Color(0xFFEDC850),
      1024 => const Color(0xFFEDC53F),
      2048 => const Color(0xFFEDC22E),
      _ => const Color(0xFF3C3A32), // 4096+
    };
  }
  
  // 타일 텍스트 색상
  static Color getTileTextColor(int value) {
    return value <= 4 ? const Color(0xFF776E65) : Colors.white;
  }
  
  // 버튼 색상
  static const Color buttonBackground = Color(0xFF8F7A66);
  static const Color buttonText = Colors.white;
  
  // 헤더 텍스트
  static const Color headerText = Color(0xFF776E65);
  static const Color scoreLabel = Color(0xFFEEE4DA);
  static const Color scoreValue = Colors.white;
}

/// 타일 텍스트 크기
class GameSizes {
  static double getTileFontSize(int value, double tileSize) {
    if (value < 100) return tileSize * 0.45;
    if (value < 1000) return tileSize * 0.38;
    if (value < 10000) return tileSize * 0.32;
    return tileSize * 0.26;
  }
}
