import 'package:flutter/material.dart';
import 'zerosum_board.dart';
import 'zerosum_theme.dart';

/// 개별 블록 위젯
class BlockWidget extends StatelessWidget {
  final BlockValue value;
  final double size;
  final bool isNew;
  final bool isExploding;

  const BlockWidget({
    super.key,
    required this.value,
    required this.size,
    this.isNew = false,
    this.isExploding = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ZeroSumColors.getBlockGradient(value),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ZeroSumColors.getBlockColor(value).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: value == BlockValue.zero
            ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          _getDisplayText(),
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            color: ZeroSumColors.getBlockTextColor(value),
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (value.value > 0) return '+${value.value}';
    if (value.value == 0) return '⭐';
    return '${value.value}';
  }
}

/// 애니메이션이 있는 블록 위젯
class AnimatedBlockWidget extends StatefulWidget {
  final BlockValue value;
  final double size;
  final bool isNew;
  final bool isExploding;
  final VoidCallback? onExplosionComplete;

  const AnimatedBlockWidget({
    super.key,
    required this.value,
    required this.size,
    this.isNew = false,
    this.isExploding = false,
    this.onExplosionComplete,
  });

  @override
  State<AnimatedBlockWidget> createState() => _AnimatedBlockWidgetState();
}

class _AnimatedBlockWidgetState extends State<AnimatedBlockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.isNew ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.isNew) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isExploding && !oldWidget.isExploding) {
      _controller.reset();
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: 1.5,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller.forward().then((_) {
        widget.onExplosionComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isExploding
            ? _scaleAnimation.value
            : (widget.isNew ? _scaleAnimation.value : 1.0);
        final opacity = widget.isExploding ? _opacityAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: BlockWidget(
              value: widget.value,
              size: widget.size,
              isNew: widget.isNew,
              isExploding: widget.isExploding,
            ),
          ),
        );
      },
    );
  }
}

/// 다음 블록 프리뷰 위젯
class NextBlockPreview extends StatelessWidget {
  final BlockValue value;

  const NextBlockPreview({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ZeroSumColors.cellBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ZeroSumColors.getBlockColor(value).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'NEXT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ZeroSumColors.scoreLabel,
            ),
          ),
          const SizedBox(height: 8),
          BlockWidget(value: value, size: 50),
        ],
      ),
    );
  }
}
