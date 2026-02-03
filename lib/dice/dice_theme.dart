import 'package:flutter/material.dart';

/// 렌더링 스타일 정의
enum DiceStyle {
  standard, // 기존 스타일 (그림자 포함)
  neon,     // 최적화된 네온 스타일 (No Blur, Stroke)
  retro,    // 최적화된 레트로 스타일 (Solid Box, No Blur)
  glass,    // 최적화된 유리 스타일 (Translucent, No Blur)
}

/// 테마 데이터 모델
class DiceThemeData {
  final String id;
  final String name;
  final String description; // 설명 추가
  final int price;          // 가격 추가 (0 = 무료)
  final LinearGradient backgroundGradient;
  final Color boardColor;
  final Color cellColor;
  final Color textColor;
  final List<Color> diceColors; 
  final String? backgroundImage; 
  final String fontHandle; 
  
  // 렌더링 옵션
  final DiceStyle style;
  final bool enableShadows; // 고사양 전용
  final double blurRadius;  // 0 = 최적화

  const DiceThemeData({
    required this.id,
    required this.name,
    this.description = '',
    this.price = 0,
    required this.backgroundGradient,
    required this.boardColor,
    required this.cellColor,
    required this.textColor,
    required this.diceColors,
    this.backgroundImage,
    this.fontHandle = 'Roboto',
    this.style = DiceStyle.standard,
    this.enableShadows = true,
    this.blurRadius = 8.0,
  });

  DiceThemeData copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    LinearGradient? backgroundGradient,
    Color? boardColor,
    Color? cellColor,
    Color? textColor,
    List<Color>? diceColors,
    String? backgroundImage,
    String? fontHandle,
    DiceStyle? style,
    bool? enableShadows,
    double? blurRadius,
  }) {
    return DiceThemeData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      boardColor: boardColor ?? this.boardColor,
      cellColor: cellColor ?? this.cellColor,
      textColor: textColor ?? this.textColor,
      diceColors: diceColors ?? this.diceColors,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      fontHandle: fontHandle ?? this.fontHandle,
      style: style ?? this.style,
      enableShadows: enableShadows ?? this.enableShadows,
      blurRadius: blurRadius ?? this.blurRadius,
    );
  }
}

/// 테마 관리자
class DiceTheme {
  static const DiceThemeData cyberpunk = DiceThemeData(
    id: 'cyberpunk',
    name: 'Cyberpunk',
    description: 'Neon lights and high contrast. Optimized for performance.',
    price: 0,
    style: DiceStyle.neon, // 최적화된 네온 스타일
    enableShadows: false,  // 그림자 끔
    blurRadius: 0,
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    ),
    boardColor: Color(0xFF1E1E2E),
    cellColor: Color(0xFF2D3436),
    textColor: Colors.white,
    diceColors: [
      Color(0xFFFF5252), 
      Color(0xFFFFB74D), 
      Color(0xFFFFEB3B), 
      Color(0xFF69F0AE), 
      Color(0xFF40C4FF), 
      Color(0xFFE040FB), 
    ],
  );

  static const DiceThemeData korean = DiceThemeData(
    id: 'korean',
    name: '오색무늬',
    description: 'Traditional Korean aesthetics with a retro paper feel.',
    price: 500,
    style: DiceStyle.retro, // 최적화된 레트로 스타일
    enableShadows: false,
    blurRadius: 0,
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)], 
    ),
    boardColor: Color(0xFF5D4037), 
    cellColor: Color(0xFFD7CCC8), 
    textColor: Colors.black87,
    diceColors: [
      Color(0xFFD32F2F), 
      Color(0xFF1976D2), 
      Color(0xFFFBC02D), 
      Color(0xFFFFFFFF), 
      Color(0xFF212121), 
      Color(0xFF388E3C), 
    ],
  );

  static const DiceThemeData glass = DiceThemeData( // New Theme
    id: 'glass',
    name: 'Glassmorphism',
    description: 'Modern, clean, and transparent.',
    price: 1000,
    style: DiceStyle.glass, // 최적화된 글래스 스타일
    enableShadows: false,
    blurRadius: 0,
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFa8edea), Color(0xFFfed6e3)], // Soft pastel
    ),
    boardColor: Color(0x40FFFFFF), // Semi-transparent white
    cellColor: Color(0x20FFFFFF),
    textColor: Color(0xFF2D3436),
    diceColors: [
      Color(0xFFff9a9e),
      Color(0xFFfad0c4),
      Color(0xFFa18cd1),
      Color(0xFFfbc2eb),
      Color(0xFF8fd3f4),
      Color(0xFF84fab0),
    ],
  );

  static const DiceThemeData western = DiceThemeData(
    id: 'western',
    name: 'Western',
    description: 'Dusty trails and wooden saloons.',
    price: 300,
    style: DiceStyle.standard,
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
    ),
    boardColor: Color(0xFF3E2723),
    cellColor: Color(0xFFA1887F),
    textColor: Color(0xFFFFD54F),
    diceColors: [
      Color(0xFF8D6E63), Color(0xFFA1887F), Color(0xFFBCAAA4),
      Color(0xFFD7CCC8), Color(0xFFEFEBE9), Color(0xFFFFF3E0),
    ],
  );
  
  static const DiceThemeData tropical = DiceThemeData(
    id: 'tropical',
    name: 'Tropical',
    description: 'Fresh vibes from the rainforest.',
    price: 300,
    style: DiceStyle.standard,
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF009688), Color(0xFF80CBC4)],
    ),
    boardColor: Color(0xFF004D40),
    cellColor: Color(0xFF4DB6AC),
    textColor: Colors.white,
    diceColors: [
      Color(0xFFC6FF00), Color(0xFF76FF03), Color(0xFF00E676),
      Color(0xFF1DE9B6), Color(0xFF00B0FF), Color(0xFF2979FF),
    ],
  );

  static const DiceThemeData space = DiceThemeData(
    id: 'space',
    name: 'Space',
    description: 'Deep space mystery.',
    price: 800,
    style: DiceStyle.neon, // Space fits Neon too
    enableShadows: true,   // Keep shadows for space? Or optimize? Let's keep shadows for premium feel if user wants
    blurRadius: 8.0,
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF000000), Color(0xFF1A237E)],
    ),
    boardColor: Color(0xFF311B92),
    cellColor: Color(0xFF4527A0),
    textColor: Colors.white,
    diceColors: [
      Color(0xFFFF1744), Color(0xFFFF4081), Color(0xFFE040FB),
      Color(0xFF7C4DFF), Color(0xFF536DFE), Color(0xFF448AFF),
    ],
  );

  static const DiceThemeData nature = DiceThemeData(
    id: 'nature',
    name: 'Nature',
    description: 'Serene beige and green tones.',
    price: 0,
    style: DiceStyle.standard,
    enableShadows: false,
    blurRadius: 0,
    backgroundGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF7F5EC), Color(0xFFE8E6D9)],
    ),
    boardColor: Color(0xFF2E5940),
    cellColor: Color(0xFF5D7D6B),
    textColor: Color(0xFF2E5940),
    diceColors: [
      Color(0xFFC8E6C9), // 1
      Color(0xFFA5D6A7), // 2
      Color(0xFF81C784), // 3
      Color(0xFF66BB6A), // 4
      Color(0xFF43A047), // 5
      Color(0xFF2E7D32), // 6
    ],
  );

  static List<DiceThemeData> getAllThemes() {
    return [nature, cyberpunk, korean, western, tropical, space, glass];
  }

  static DiceThemeData getTheme(String id) {
    return getAllThemes().firstWhere(
      (t) => t.id == id,
      orElse: () => nature,
    );
  }
}
