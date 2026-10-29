import 'package:flutter/material.dart';

/// Renders the iconic vault/safe icon featured in the Figma design:
/// A rounded box with an engraved cross and center dial.
class VaultIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color? backgroundColor;
  final double borderRadius;

  const VaultIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.backgroundColor,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = CustomPaint(
      size: Size(size, size),
      painter: _VaultPainter(color: color),
    );

    if (backgroundColor == null) {
      return iconWidget;
    }

    return Container(
      width: size * 1.8,
      height: size * 1.8,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: iconWidget,
    );
  }
}

class _VaultPainter extends CustomPainter {
  final Color color;

  _VaultPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.09;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer rounded rect
    final inset = strokeWidth / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(rect, paint);

    // Diagonal cross lines representing vault lock mechanism
    final p1 = Offset(size.width * 0.30, size.height * 0.30);
    final p2 = Offset(size.width * 0.70, size.height * 0.70);
    final p3 = Offset(size.width * 0.70, size.height * 0.30);
    final p4 = Offset(size.width * 0.30, size.height * 0.70);

    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p3, p4, paint);

    // Center circular dial
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.12,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VaultPainter oldDelegate) =>
      oldDelegate.color != color;
}
