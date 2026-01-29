import 'package:flutter/material.dart';
import 'zerosum_board.dart';

/// Zero Sum Path Cyberpunk Theme
class ZeroSumColors {
  // Backgrounds
  static const Color background = Color(0xFF0F172A); // Dark Navy/Slate
  static const Color boardBackground = Color(0xFF1E293B);
  static const Color gridLine = Color(0xFF334155);

  // Path
  static const Color pathActive = Color(0xFF00FFFF); // Cyan Neon
  static const Color pathValid = Color(0xFF00FF00);  // Green Neon (Sum 0)
  
  // Text Colors
  static const Color textBright = Color(0xFFF1F5F9);
  static const Color textDim = Color(0xFF94A3B8);

  /// Neon Colors for Blocks
  static Color getBlockColor(BlockValue value) {
    if (value.value == 0) return Colors.white;
    if (value.value > 0) {
      // Positive: Cyan/Blue variants
      return const Color(0xFF06B6D4); // Cyan-500
    } else {
      // Negative: Magenta/Pink variants
      return const Color(0xFFD946EF); // Fuchsia-500
    }
  }

  static Color getBlockGlowColor(BlockValue value) {
    if (value.value == 0) return Colors.white;
    if (value.value > 0) return const Color(0xFF22D3EE); // Cyan-400
    return const Color(0xFFE879F9); // Fuchsia-400
  }
}
