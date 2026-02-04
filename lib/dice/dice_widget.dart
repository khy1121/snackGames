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
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Transform.rotate(
                angle: (1 - value) * 0.5,
                child: child,
              ),
            );
          },
          child: diceWidget,
        ),
      );
    }
    
    if (isMerging) {
      return RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
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
