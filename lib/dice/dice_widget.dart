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
    Widget diceWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
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
        boxShadow: [
          BoxShadow(
            color: _getDiceColors().first.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: dice.isMagic
          ? _buildMagicDice()
          : _buildNormalDice(),
    );
    
    // 새 주사위 애니메이션
    if (isNew) {
      diceWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: diceWidget,
      );
    }
    
    // 머지 애니메이션
    if (isMerging) {
      diceWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.3, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: diceWidget,
      );
    }
    
    return diceWidget;
  }
  
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
  
  Widget _buildNormalDice() {
    return Padding(
      padding: EdgeInsets.all(size * 0.15),
      child: _buildDots(),
    );
  }
  
  Widget _buildDots() {
    final dotSize = size * 0.18;
    
    Widget dot = Container(
      width: dotSize,
      height: dotSize,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
      ),
    );
    
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
  int? _hoveredColumn;
  
  @override
  Widget build(BuildContext context) {
    // 테마 색상 (없으면 기본값)
    final boardColor = widget.theme?.boardColor ?? const Color(0xFF2D3436);
    final cellColor = widget.theme?.cellColor ?? Colors.transparent; // Not strictly used in current layout but good for future

    return LayoutBuilder(
      builder: (context, constraints) {
        // 가로/세로 중 더 제한적인 방향 기준으로 셀 크기 계산
        final maxCellWidth = (constraints.maxWidth - 24) / DiceMergeBoard.cols;
        final maxCellHeight = (constraints.maxHeight - 24) / DiceMergeBoard.rows;
        final cellSize = maxCellWidth < maxCellHeight ? maxCellWidth : maxCellHeight;
        
        final boardWidth = cellSize * DiceMergeBoard.cols + 16;
        final boardHeight = cellSize * DiceMergeBoard.rows + 16;
        
        return Center(
          child: MouseRegion(
            onExit: (_) => setState(() => _hoveredColumn = null),
            child: Container(
              width: boardWidth,
              height: boardHeight,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: boardColor, // Theme Color
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(DiceMergeBoard.rows, (row) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(DiceMergeBoard.cols, (col) {
                      final dice = widget.board.getDice(row, col);
                      final isNew = widget.newDice.contains((row, col));
                      final isMerging = widget.mergingDice.contains((row, col));
                      final isSelected = _hoveredColumn == col;
                      
                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredColumn = col),
                        child: GestureDetector(
                          onTap: () => widget.onColumnTap?.call(col),
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : cellColor.withValues(alpha: 0.1), // Slight tint for cell
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.05),
                                width: 0.5,
                              ),
                            ),
                            child: dice != null
                                ? DiceWidget(
                                    dice: dice,
                                    size: cellSize - 4,
                                    isNew: isNew,
                                    isMerging: isMerging,
                                    theme: widget.theme, // Pass Theme
                                  )
                                : null,
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
