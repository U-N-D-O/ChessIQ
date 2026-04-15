import 'dart:math';
import 'dart:ui' as ui;

import 'package:chessiq/features/quiz/models/quiz_models.dart';
import 'package:flutter/material.dart';

class QuizAccuracyTrendPainter extends CustomPainter {
  final List<QuizAccuracyPoint> accuracySeries;
  final List<QuizAccuracyPoint> amountSeries;
  final bool isDarkMode;

  QuizAccuracyTrendPainter({
    required this.accuracySeries,
    required this.amountSeries,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final axisLabelColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.78)
        : Colors.black.withValues(alpha: 0.82);
    final gridColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (final y in [0.25, 0.5, 0.75]) {
      final dy = size.height * y;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    if (accuracySeries.isEmpty || amountSeries.isEmpty) return;

    final maxAmount = amountSeries
        .map((point) => point.value)
        .fold<double>(0.0, (prev, value) => max(prev, value));
    final amountScale = max(maxAmount, 1.0);

    final accuracyPoints = <Offset>[];
    final amountPoints = <Offset>[];
    for (var i = 0; i < accuracySeries.length; i++) {
      final x = accuracySeries.length == 1
          ? size.width / 2
          : (size.width * i) / (accuracySeries.length - 1);
      final accuracyY = size.height * (1 - (accuracySeries[i].value / 100.0));
      final amountY = size.height * (1 - (amountSeries[i].value / amountScale));
      accuracyPoints.add(Offset(x, accuracyY.clamp(0, size.height)));
      amountPoints.add(Offset(x, amountY.clamp(0, size.height)));
    }

    final amountPath = Path()
      ..moveTo(amountPoints.first.dx, amountPoints.first.dy);
    for (var i = 1; i < amountPoints.length; i++) {
      amountPath.lineTo(amountPoints[i].dx, amountPoints[i].dy);
    }

    canvas.drawPath(
      amountPath,
      Paint()
        ..color = const Color(0xFFF4E9C2).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final amountCirclePaint = Paint()..color = const Color(0xFFFFB26A);
    for (final point in amountPoints) {
      canvas.drawCircle(point, 2.8, amountCirclePaint);
    }

    final fillPath = Path()
      ..moveTo(accuracyPoints.first.dx, size.height)
      ..lineTo(accuracyPoints.first.dx, accuracyPoints.first.dy);
    for (var i = 1; i < accuracyPoints.length; i++) {
      fillPath.lineTo(accuracyPoints[i].dx, accuracyPoints[i].dy);
    }
    fillPath
      ..lineTo(accuracyPoints.last.dx, size.height)
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

    final accuracyPath = Path()
      ..moveTo(accuracyPoints.first.dx, accuracyPoints.first.dy);
    for (var i = 1; i < accuracyPoints.length; i++) {
      accuracyPath.lineTo(accuracyPoints[i].dx, accuracyPoints[i].dy);
    }

    canvas.drawPath(
      accuracyPath,
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

    for (final point in accuracyPoints) {
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

    final labelStyle = TextStyle(color: axisLabelColor, fontSize: 10);
    final tpLeftTop = TextPainter(
      text: TextSpan(text: '100%', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLeftTop.paint(canvas, Offset(0, -tpLeftTop.height / 2));
    final tpLeftBottom = TextPainter(
      text: TextSpan(text: '0%', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLeftBottom.paint(
      canvas,
      Offset(0, size.height - tpLeftBottom.height / 2),
    );

    final tpRightTop = TextPainter(
      text: TextSpan(text: maxAmount.round().toString(), style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpRightTop.paint(
      canvas,
      Offset(size.width - tpRightTop.width, -tpRightTop.height / 2),
    );
    final tpRightBottom = TextPainter(
      text: TextSpan(text: '0', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpRightBottom.paint(
      canvas,
      Offset(
        size.width - tpRightBottom.width,
        size.height - tpRightBottom.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant QuizAccuracyTrendPainter oldDelegate) {
    return oldDelegate.accuracySeries != accuracySeries ||
        oldDelegate.amountSeries != amountSeries ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}
