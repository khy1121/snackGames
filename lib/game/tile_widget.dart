import 'package:flutter/material.dart';
import 'game_theme.dart';

/// 개별 타일 위젯
class TileWidget extends StatelessWidget {
  final int value;
  final double size;
  final bool isNew;
  final bool isMerged;
  
  const TileWidget({
    super.key,
    required this.value,
    required this.size,
    this.isNew = false,
    this.isMerged = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = GameColors.getTileColor(value);
    final textColor = GameColors.getTileTextColor(value);
    final fontSize = GameSizes.getTileFontSize(value, size);
    
    Widget tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.08),
        boxShadow: value > 0
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                if (value >= 128)
                  BoxShadow(
                    color: color.withValues(alpha: value >= 1024 ? 0.7 : value >= 512 ? 0.55 : value >= 256 ? 0.45 : 0.35),
                    blurRadius: value >= 1024 ? 24 : value >= 512 ? 18 : value >= 256 ? 14 : 10,
                    spreadRadius: value >= 1024 ? 5 : value >= 512 ? 3 : value >= 256 ? 2 : 1,
                  ),
              ]
            : null,
      ),
      child: value > 0
          ? Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            )
          : null,
    );
    
    // 새 타일 애니메이션
    if (isNew && value > 0) {
      tile = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: tile,
      );
    }
    
    // 병합 애니메이션
    if (isMerged) {
      tile = TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.2, end: 1.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: tile,
      );
    }
    
    return tile;
  }
}

/// 게임 보드 그리드 위젯
class BoardWidget extends StatelessWidget {
  final List<List<int>> tiles;
  final Set<(int, int)> newTiles;
  final Set<(int, int)> mergedTiles;
  final double boardSize;
  
  const BoardWidget({
    super.key,
    required this.tiles,
    required this.newTiles,
    required this.mergedTiles,
    required this.boardSize,
  });
  
  @override
  Widget build(BuildContext context) {
    const gridSize = 4;
    const spacing = 10.0;
    final tileSize = (boardSize - spacing * (gridSize + 1)) / gridSize;
    
    return Container(
      width: boardSize,
      height: boardSize,
      padding: const EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: GameColors.boardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // 빈 타일 배경
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
            ),
            itemCount: gridSize * gridSize,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: GameColors.emptyTile,
                  borderRadius: BorderRadius.circular(tileSize * 0.08),
                ),
              );
            },
          ),
          
          // 실제 타일들
          ...List.generate(gridSize, (row) {
            return List.generate(gridSize, (col) {
              final value = tiles[row][col];
              if (value == 0) return const SizedBox.shrink();
              
              final isNew = newTiles.contains((row, col));
              final isMerged = mergedTiles.contains((row, col));
              
              return Positioned(
                left: col * (tileSize + spacing),
                top: row * (tileSize + spacing),
                child: TileWidget(
                  value: value,
                  size: tileSize,
                  isNew: isNew,
                  isMerged: isMerged,
                ),
              );
            });
          }).expand((x) => x),
        ],
      ),
    );
  }
}
