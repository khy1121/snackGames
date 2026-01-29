import 'package:flutter/material.dart';

/// 테마 데이터 모델
class DiceThemeData {
  final String id;
  final String name;
  final LinearGradient backgroundGradient;
  final Color boardColor;
  final Color cellColor;
  final Color textColor;
  final List<Color> diceColors; // 1~6 주사위 색상
  final String? backgroundImage; // 배경 이미지 (옵션)
  final String fontHandle; // 폰트 (Google Fonts 연동 예정)

  const DiceThemeData({
    required this.id,
    required this.name,
    required this.backgroundGradient,
    required this.boardColor,
    required this.cellColor,
    required this.textColor,
    required this.diceColors,
    this.backgroundImage,
    this.fontHandle = 'Roboto',
  });
}

/// 테마 관리자
class DiceTheme {
  static const DiceThemeData cyberpunk = DiceThemeData(
    id: 'cyberpunk',
    name: 'Cyberpunk',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    ),
    boardColor: Color(0xFF1E1E2E),
    cellColor: Color(0xFF2D3436),
    textColor: Colors.white,
    diceColors: [
      Color(0xFFEF5350), // 1: Red
      Color(0xFFEC407A), // 2: Pink
      Color(0xFFAB47BC), // 3: Purple
      Color(0xFF7E57C2), // 4: Deep Purple
      Color(0xFF5C6BC0), // 5: Indigo
      Color(0xFF42A5F5), // 6: Blue
    ],
  );

  static const DiceThemeData korean = DiceThemeData(
    id: 'korean',
    name: '오색무늬',
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)], // Traditional Paper
    ),
    boardColor: Color(0xFF5D4037), // Wood
    cellColor: Color(0xFFD7CCC8), // Light Wood
    textColor: Colors.black87,
    diceColors: [
      Color(0xFFD32F2F), // 1: Red (Yang)
      Color(0xFF1976D2), // 2: Blue (Yin)
      Color(0xFFFBC02D), // 3: Yellow (Center)
      Color(0xFFFFFFFF), // 4: White (Metal) - Needs border
      Color(0xFF212121), // 5: Black (Water)
      Color(0xFF388E3C), // 6: Green (Wood)
    ],
  );

    static const DiceThemeData western = DiceThemeData(
    id: 'western',
    name: 'Western',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
    ),
    boardColor: Color(0xFF3E2723),
    cellColor: Color(0xFFA1887F),
    textColor: Color(0xFFFFD54F),
    diceColors: [
      Color(0xFF8D6E63),
      Color(0xFFA1887F),
      Color(0xFFBCAAA4),
      Color(0xFFD7CCC8),
      Color(0xFFEFEBE9),
      Color(0xFFFFF3E0),
    ],
  );
  
  static const DiceThemeData tropical = DiceThemeData(
    id: 'tropical',
    name: 'Tropical',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF009688), Color(0xFF80CBC4)],
    ),
    boardColor: Color(0xFF004D40),
    cellColor: Color(0xFF4DB6AC),
    textColor: Colors.white,
    diceColors: [
      Color(0xFFC6FF00), 
      Color(0xFF76FF03),
      Color(0xFF00E676),
      Color(0xFF1DE9B6),
      Color(0xFF00B0FF),
      Color(0xFF2979FF),
    ],
  );

  static const DiceThemeData space = DiceThemeData(
    id: 'space',
    name: 'Space',
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF000000), Color(0xFF1A237E)],
    ),
    boardColor: Color(0xFF311B92),
    cellColor: Color(0xFF4527A0),
    textColor: Colors.white,
    diceColors: [
      Color(0xFFFF1744),
      Color(0xFFFF4081),
      Color(0xFFE040FB),
      Color(0xFF7C4DFF),
      Color(0xFF536DFE),
      Color(0xFF448AFF),
    ],
  );

  static DiceThemeData getTheme(String id) {
    switch (id) {
      case 'korean': return korean;
      case 'western': return western;
      case 'tropical': return tropical;
      case 'space': return space;
      case 'cyberpunk':
      default: return cyberpunk;
    }
  }
}
