import 'package:flutter/material.dart';
import 'zerosum_board.dart';
import 'zerosum_theme.dart';

class BlockWidget extends StatelessWidget {
  final BlockValue value;
  final double size;
  final bool isSelected;
  final bool isDimmed;

  const BlockWidget({
    super.key,
    required this.value,
    required this.size,
    this.isSelected = false,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ZeroSumColors.getBlockColor(value);
    
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDimmed 
            ? color.withValues(alpha: 0.1) 
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? ZeroSumColors.pathActive 
              : (isDimmed ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.6)),
          width: isSelected ? 3 : 1.5,
        ),
        boxShadow: isSelected || !isDimmed
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          value.value > 0 ? '+${value.value}' : '${value.value}',
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w900,
            shadows: isSelected || !isDimmed
                ? [
                    Shadow(
                      color: color,
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
