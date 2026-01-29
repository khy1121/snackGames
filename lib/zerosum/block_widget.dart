import 'package:flutter/material.dart';
import 'zerosum_board.dart';
import 'zerosum_theme.dart';

/// 개별 버블 위젯 (원형)
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            ZeroSumColors.getBlockColor(value).withValues(alpha: 0.8), // 밝은 중심
            ZeroSumColors.getBlockColor(value), // 기본 색상
          ],
          center: const Alignment(-0.3, -0.3),
          radius: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 하이라이트 (광택)
          Positioned(
            left: size * 0.2,
            top: size * 0.2,
            child: Container(
              width: size * 0.25,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.all(Radius.elliptical(size, size)),
              ),
              transform: Matrix4.rotationZ(-0.5),
            ),
          ),
          
          // 텍스트
          CustomPaint(
            painter: _TextShadowPainter(
              text: _getDisplayText(),
              color: ZeroSumColors.getBlockTextColor(value),
              fontSize: size * 0.45,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayText() {
    if (value.value > 0) return '+${value.value}';
    if (value.value == 0) return '★'; // 별 모양 변경
    return '${value.value}';
  }
}

class _TextShadowPainter extends CustomPainter {
  final String text;
  final Color color;
  final double fontSize;

  _TextShadowPainter({
    required this.text,
    required this.color,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
        shadows: [
          Shadow(
            blurRadius: 2,
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 기존 애니메이션 위젯들은 원형 디자인을 따름 (Transform 등은 그대로 유지)
// 다만 슈팅 게임이므로 DroppingBlockWidget보다는 ShootingBubbleWidget 등이 필요하지만
// 여기서는 기본적인 BlockWidget만 리디자인하고 Page에서 애니메이션 처리
