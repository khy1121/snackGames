import 'package:flutter/material.dart';
import 'dice_board.dart';
import 'dice_theme.dart';

/// 주사위 위젯
class DiceWidget extends StatelessWidget {
  final Dice dice;
  final double size;
  final bool isNew;
  final bool isMerging;
  final DiceThemeData? theme; // 테마 추가
  
  const DiceWidget({
    super.key,
    required this.dice,
    required this.size,
    this.isNew = false,
    this.isMerging = false,
    this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    // 테마 설정 가져오기 (없으면 기본값)
    final style = theme?.style ?? DiceStyle.standard;
    final enableShadows = theme?.enableShadows ?? true;
    final blurRadius = theme?.blurRadius ?? 4.0;
    
    // 스타일별 장식 생성
    BoxDecoration decoration;
    
    switch (style) {
      case DiceStyle.neon:
        // Neon: Dark background, bright border, no drop shadow (mostly)
        final color = _getDiceColors().last;
        decoration = BoxDecoration(
          color: color.withValues(alpha: 0.1), // Dark inner
          borderRadius: BorderRadius.circular(size * 0.2),
          border: Border.all(
            color: color, // Glowing border
            width: size * 0.08,
          ),
          boxShadow: enableShadows ? [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 4, // Very Small Glow
              spreadRadius: 1,
            ) 
          ] : null, // No heavy shadow
        );
        break;
        
      case DiceStyle.retro:
        // Retro: Solid colors, thick black border, hard offset shadow
        decoration = BoxDecoration(
          color: _getDiceColors().first,
          borderRadius: BorderRadius.circular(size * 0.1),
          border: Border.all(
             color: Colors.black87,
             width: size * 0.05,
          ),
          boxShadow: [
             // Hard Shadow (No Blur = Fast)
             BoxShadow(
               color: Colors.black38,
               blurRadius: 0, 
               offset: Offset(size * 0.08, size * 0.08),
             ),
          ],
        );
        break;
        
      case DiceStyle.glass:
        // Glass: Gradient fill, white border, no shadow
         decoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
               _getDiceColors().first.withValues(alpha: 0.7),
               _getDiceColors().last.withValues(alpha: 0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(size * 0.2),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.5,
          ),
        );
        break;
        
      case DiceStyle.standard:
      default:
        // Standard (Gradient + soft shadow)
        decoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getDiceColors(),
          ),
          borderRadius: BorderRadius.circular(size * 0.15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: enableShadows ? [
            BoxShadow(
              color: _getDiceColors().first.withValues(alpha: 0.3),
              blurRadius: blurRadius, // Use theme blur
              offset: const Offset(0, 2),
            ),
          ] : null,
        );
        break;
    }

    // Wrap static content in RepaintBoundary for better caching
    Widget diceWidget = Container(
      width: size,
      height: size,
      decoration: decoration,
      child: dice.isMagic
          ? _buildMagicDice()
          : _buildNormalDice(),
    );
    
    // Only animate when needed - reduce animation overhead
    if (isNew) {
      return RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800), // 800ms로 증가
          curve: _getAnimationCurve(),
          builder: (context, value, child) {
            return _buildNewDiceAnimation(value, child!);
          },
          child: diceWidget,
        ),
      );
    }
    
    if (isMerging) {
      return RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000), // 1000ms로 증가
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            // 펄스 효과: 작아졌다가 커지는 효과
            final pulseScale = value < 0.3 
                ? 1.0 - (value / 0.3) * 0.5  // 0.5배로 줄어듦
                : 0.5 + ((value - 0.3) / 0.7) * 0.7; // 1.2배로 커짐
            
            // 회전 효과
            final rotation = value * 3.14159 * 2; // 360도 회전
            
            // 발광 효과
            final glowIntensity = value < 0.5 ? value * 2 : (1.0 - value) * 2;
            
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getDiceColors().last.withValues(alpha: glowIntensity * 0.8),
                    blurRadius: 20 * glowIntensity,
                    spreadRadius: 5 * glowIntensity,
                  ),
                ],
              ),
              child: Transform.scale(
                scale: pulseScale,
                child: Transform.rotate(
                  angle: rotation,
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: diceWidget,
        ),
      );
    }
    
    return RepaintBoundary(child: diceWidget);
  }
  
  // 주사위 숫자별 애니메이션 커브
  Curve _getAnimationCurve() {
    if (dice.isMagic) return Curves.elasticOut;
    return switch (dice.value) {
      1 => Curves.easeOutQuad,        // 부드럽게
      2 => Curves.easeOutBack,        // 살짝 튕김
      3 => Curves.elasticOut,         // 탄력적
      4 => Curves.bounceOut,          // 바운스
      5 => Curves.easeOutCubic,       // 강력한 감속
      6 => Curves.easeOutExpo,        // 폭발적 감속
      _ => Curves.easeOut,
    };
  }
  
  // 주사위 숫자별 고유 등장 애니메이션
  Widget _buildNewDiceAnimation(double value, Widget child) {
    if (dice.isMagic) {
      // 매직 주사위: 무지개 펄스 + 회전
      final pulseScale = 0.3 + (value * 0.7) * (1.0 + 0.2 * (value < 0.5 ? value * 2 : (1 - value) * 2));
      final rotation = value * 3.14159 * 4; // 720도 회전
      final hue = (value * 360) % 360; // 무지개 색상
      
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: HSVColor.fromAHSV(value * 0.8, hue, 1, 1).toColor(),
              blurRadius: 30 * value,
              spreadRadius: 8 * value,
            ),
          ],
        ),
        child: Transform.scale(
          scale: pulseScale,
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(opacity: value, child: child),
          ),
        ),
      );
    }
    
    return switch (dice.value) {
      1 => _buildDice1Animation(value, child),  // 페이드인 + 작은 스케일
      2 => _buildDice2Animation(value, child),  // 좌우 흔들림
      3 => _buildDice3Animation(value, child),  // 회전 + 스케일
      4 => _buildDice4Animation(value, child),  // 바운스 효과
      5 => _buildDice5Animation(value, child),  // 파동 효과
      6 => _buildDice6Animation(value, child),  // 강력한 스핀 + 발광
      _ => Transform.scale(scale: value, child: child),
    };
  }
  
  // 1: 부드러운 페이드인 + 스케일
  Widget _buildDice1Animation(double value, Widget child) {
    return Transform.scale(
      scale: 0.5 + (value * 0.5),
      child: Opacity(
        opacity: value,
        child: child,
      ),
    );
  }
  
  // 2: 좌우 흔들림
  Widget _buildDice2Animation(double value, Widget child) {
    final wobble = (1 - value) * 0.3 * (value * 10 % 1 > 0.5 ? 1 : -1);
    return Transform.scale(
      scale: value,
      child: Transform.rotate(
        angle: wobble,
        child: Opacity(opacity: value, child: child),
      ),
    );
  }
  
  // 3: 회전 + 스케일
  Widget _buildDice3Animation(double value, Widget child) {
    final rotation = (1 - value) * 3.14159; // 180도
    return Transform.scale(
      scale: value,
      child: Transform.rotate(
        angle: rotation,
        child: Opacity(opacity: value, child: child),
      ),
    );
  }
  
  // 4: 바운스 효과
  Widget _buildDice4Animation(double value, Widget child) {
    // Curves.bounceOut 효과가 적용되어 자연스러운 바운스
    return Transform.scale(
      scale: value,
      child: Opacity(opacity: value, child: child),
    );
  }
  
  // 5: 파동 효과 (확대/축소 반복)
  Widget _buildDice5Animation(double value, Widget child) {
    final wave = value + (1 - value) * 0.3 * (value * 8 % 1 < 0.5 ? 1 : -1);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getDiceColors().last.withValues(alpha: (1 - value) * 0.5),
            blurRadius: 20 * (1 - value),
            spreadRadius: 5 * (1 - value),
          ),
        ],
      ),
      child: Transform.scale(
        scale: wave,
        child: Opacity(opacity: value, child: child),
      ),
    );
  }
  
  // 6: 강력한 스핀 + 발광 (별이 될 수 있는 주사위)
  Widget _buildDice6Animation(double value, Widget child) {
    final rotation = (1 - value) * 3.14159 * 3; // 540도 회전
    final glowIntensity = (1 - value) * 1.2;
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getDiceColors().last.withValues(alpha: glowIntensity * 0.8),
            blurRadius: 30 * glowIntensity,
            spreadRadius: 8 * glowIntensity,
          ),
        ],
      ),
      child: Transform.scale(
        scale: 0.3 + value * 0.7,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(opacity: value, child: child),
        ),
      ),
    );
  }
  
  // ... _getDiceColors restored ...
  List<Color> _getDiceColors() {
    if (dice.isMagic) {
      return [
        const Color(0xFFE040FB),
        const Color(0xFF7C4DFF),
      ];
    }

    // 테마 색상 사용
    if (theme != null && theme!.diceColors.length >= 6) {
      final color = theme!.diceColors[dice.value - 1]; // 1-based to 0-based
      // 그라데이션을 위해 약간 밝은/어두운 톤 자동 생성
      return [
        color.withValues(alpha: 0.8),
        color,
      ];
    }
    
    // Default (Cyberpunk Fallback)
    return switch (dice.value) {
      1 => [const Color(0xFFFF6B6B), const Color(0xFFEE5A52)],
      2 => [const Color(0xFFFFA726), const Color(0xFFFB8C00)],
      3 => [const Color(0xFFFFEB3B), const Color(0xFFFDD835)],
      4 => [const Color(0xFF66BB6A), const Color(0xFF43A047)],
      5 => [const Color(0xFF42A5F5), const Color(0xFF1E88E5)],
      6 => [const Color(0xFFAB47BC), const Color(0xFF8E24AA)],
      _ => [Colors.grey, Colors.grey.shade600],
    };
  }

  Widget _buildMagicDice() {
    return Center(
      child: Text(
        '✨',
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
  
  // Refactor Dots to simple shapes
  Widget _buildNormalDice() {
    return Padding(
      padding: EdgeInsets.all(size * 0.15),
      child: _buildDots(),
    );
  }
  
  Widget _buildDots() {
    final dotSize = size * 0.16; // Reduced from 0.18 to prevent overflow
    final style = theme?.style ?? DiceStyle.standard;
    
    Color dotColor = Colors.white;
    if (style == DiceStyle.neon) {
       dotColor = _getDiceColors().last; // Dots match neon color
    } else if (style == DiceStyle.glass) {
       dotColor = Colors.white.withValues(alpha: 0.9);
    }
    
    // Simple Circle Container (No Shadow)
    Widget dot = Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        // No dot shadows for anyone for performance
      ),
    );

    // ... Layout logic remains same ...
    
    switch (dice.value) {
      case 1:
        return Center(child: dot);
      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(alignment: Alignment.topRight, child: dot),
            Align(alignment: Alignment.bottomLeft, child: dot),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(alignment: Alignment.topRight, child: dot),
            Center(child: dot),
            Align(alignment: Alignment.bottomLeft, child: dot),
          ],
        );
      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot, dot],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot, dot],
            ),
          ],
        );
      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot, dot],
            ),
            Center(child: dot),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot, dot],
            ),
          ],
        );
      case 6:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot, dot],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot, dot],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot, dot],
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}

/// 게임 보드 위젯
class DiceBoardWidget extends StatefulWidget {
  final DiceMergeBoard board;
  final Set<(int, int)> newDice;
  final Set<(int, int)> mergingDice;
  final Function(int)? onColumnTap;
  final DiceThemeData? theme; // 테마 추가
  
  const DiceBoardWidget({
    super.key,
    required this.board,
    required this.newDice,
    required this.mergingDice,
    this.onColumnTap,
    this.theme,
  });

  @override
  State<DiceBoardWidget> createState() => _DiceBoardWidgetState();
}

class _DiceBoardWidgetState extends State<DiceBoardWidget> {
  
  @override
  Widget build(BuildContext context) {
    // 테마 색상 (없으면 기본값)
    final boardColor = widget.theme?.boardColor ?? const Color(0xFF2D3436);
    final cellColor = widget.theme?.cellColor ?? Colors.transparent; 

    return LayoutBuilder(
      builder: (context, constraints) {
        // 가로/세로 중 더 제한적인 방향 기준으로 셀 크기 계산
        final maxCellWidth = (constraints.maxWidth - 24) / DiceMergeBoard.cols;
        final maxCellHeight = (constraints.maxHeight - 24) / DiceMergeBoard.rows;
        final cellSize = maxCellWidth < maxCellHeight ? maxCellWidth : maxCellHeight;
        
        final boardWidth = cellSize * DiceMergeBoard.cols + 16;
        final boardHeight = cellSize * DiceMergeBoard.rows + 16;
        
        return Center(
          child: Container(
            width: boardWidth,
            height: boardHeight,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: boardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _BoardGrid(
              board: widget.board,
              cellSize: cellSize,
              cellColor: cellColor,
              newDice: widget.newDice,
              mergingDice: widget.mergingDice,
              onColumnTap: widget.onColumnTap,
              theme: widget.theme,
            ),
          ),
        );
      },
    );
  }
}

/// Separated grid widget for better performance
class _BoardGrid extends StatelessWidget {
  final DiceMergeBoard board;
  final double cellSize;
  final Color cellColor;
  final Set<(int, int)> newDice;
  final Set<(int, int)> mergingDice;
  final Function(int)? onColumnTap;
  final DiceThemeData? theme;

  const _BoardGrid({
    required this.board,
    required this.cellSize,
    required this.cellColor,
    required this.newDice,
    required this.mergingDice,
    required this.onColumnTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < DiceMergeBoard.rows; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int col = 0; col < DiceMergeBoard.cols; col++)
                _BoardCell(
                  row: row,
                  col: col,
                  board: board,
                  cellSize: cellSize,
                  cellColor: cellColor,
                  isNew: newDice.contains((row, col)),
                  isMerging: mergingDice.contains((row, col)),
                  onTap: onColumnTap,
                  theme: theme,
                ),
            ],
          ),
      ],
    );
  }
}

/// Individual cell widget for optimization
class _BoardCell extends StatelessWidget {
  final int row;
  final int col;
  final DiceMergeBoard board;
  final double cellSize;
  final Color cellColor;
  final bool isNew;
  final bool isMerging;
  final Function(int)? onTap;
  final DiceThemeData? theme;

  const _BoardCell({
    required this.row,
    required this.col,
    required this.board,
    required this.cellSize,
    required this.cellColor,
    required this.isNew,
    required this.isMerging,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final dice = board.getDice(row, col);
    
    return GestureDetector(
      onTap: () => onTap?.call(col),
      child: Container(
        width: cellSize,
        height: cellSize,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellColor.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
        child: dice != null
            ? DiceWidget(
                dice: dice,
                size: cellSize - 4,
                isNew: isNew,
                isMerging: isMerging,
                theme: theme,
              )
            : null,
      ),
    );
  }
}
