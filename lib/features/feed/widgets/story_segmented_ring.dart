import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Draws the WhatsApp/Instagram-style ring around a story avatar: one
/// arc segment per story that author has posted, each colored
/// independently so a viewer sees exactly which of that author's
/// stories they've already opened and which they haven't.
///
/// [unreadFlags] must have one entry per segment, same order the
/// viewer will page through them in. `true` = unread (bright), `false`
/// = already viewed by this viewer (dim).
class StorySegmentedRing extends StatelessWidget {
  final List<bool> unreadFlags;
  final double size;
  final double strokeWidth;
  final Color unreadColor;
  final Color readColor;
  final Widget child;

  const StorySegmentedRing({
    super.key,
    required this.unreadFlags,
    required this.child,
    this.size = 62,
    this.strokeWidth = 2.5,
    this.unreadColor = const Color(0xFF34D399),
    this.readColor = const Color(0x33FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _SegmentedRingPainter(
              segmentCount: unreadFlags.isEmpty ? 1 : unreadFlags.length,
              unreadFlags: unreadFlags.isEmpty ? [false] : unreadFlags,
              strokeWidth: strokeWidth,
              unreadColor: unreadColor,
              readColor: readColor,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(strokeWidth + 2.5),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SegmentedRingPainter extends CustomPainter {
  final int segmentCount;
  final List<bool> unreadFlags;
  final double strokeWidth;
  final Color unreadColor;
  final Color readColor;

  _SegmentedRingPainter({
    required this.segmentCount,
    required this.unreadFlags,
    required this.strokeWidth,
    required this.unreadColor,
    required this.readColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Single story = one clean unbroken ring, same as before. Multiple
    // stories = split into segments with small gaps between them.
    if (segmentCount <= 1) {
      final paint = Paint()
        ..color = unreadFlags.first ? unreadColor : readColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }

    const gapDegrees = 8.0;
    final totalGap = gapDegrees * segmentCount;
    final sweepDegrees = (360.0 - totalGap) / segmentCount;

    double startDegrees = -90.0; // start at 12 o'clock, like IG/WhatsApp
    for (var i = 0; i < segmentCount; i++) {
      final paint = Paint()
        ..color = unreadFlags[i] ? unreadColor : readColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        startDegrees * math.pi / 180,
        sweepDegrees * math.pi / 180,
        false,
        paint,
      );
      startDegrees += sweepDegrees + gapDegrees;
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedRingPainter oldDelegate) {
    return oldDelegate.segmentCount != segmentCount ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.unreadColor != unreadColor ||
        oldDelegate.readColor != readColor ||
        !_listEquals(oldDelegate.unreadFlags, unreadFlags);
  }

  bool _listEquals(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
