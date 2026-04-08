import 'dart:ui' as ui;

import 'package:chessiq/features/quiz/models/quiz_models.dart';
import 'package:flutter/material.dart';

class QuizAccuracyTrendPainter extends CustomPainter {
  final List<QuizAccuracyPoint> series;

  QuizAccuracyTrendPainter({required this.series});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    for (final y in [0.25, 0.5, 0.75]) {
      final dy = size.height * y;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    if (series.isEmpty) return;

    final points = <Offset>[];
    for (var i = 0; i < series.length; i++) {
      final x = series.length == 1
          ? size.width / 2
          : (size.width * i) / (series.length - 1);
      final y = size.height * (1 - (series[i].value / 100.0));
      points.add(Offset(x, y.clamp(0, size.height)));
    }

    if (points.length >= 2) {
      final fillPath = Path()
        ..moveTo(points.first.dx, size.height)
        ..lineTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath
        ..lineTo(points.last.dx, size.height)
        ..close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
            const Color(0xFF5AAEE8).withValues(alpha: 0.32),
            const Color(0xFF2A6CF0).withValues(alpha: 0.06),
          ])
          ..style = PaintingStyle.fill,
      );
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [
          const Color(0xFF5AAEE8),
          const Color(0xFF7EDC8A),
        ])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final point in points) {
      canvas.drawCircle(point, 3.3, Paint()..color = const Color(0xFF8FD0FF));
      canvas.drawCircle(
        point,
        6.5,
        Paint()
          ..color = const Color(0xFF5AAEE8).withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant QuizAccuracyTrendPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}
