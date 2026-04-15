import 'dart:math';
import 'dart:ui' as ui;

import 'package:chessiq/features/analysis/models/analysis_models.dart';
import 'package:flutter/material.dart';

class EnergyArrowPainter extends CustomPainter {
  final List<EngineLine> lines;
  final int bestEval;
  final double progress;
  final bool reverse;
  final bool showSequenceNumbers;
  final Color? overrideColor;
  final bool staticArrowStyle;

  EnergyArrowPainter({
    required this.lines,
    required this.bestEval,
    required this.progress,
    required this.reverse,
    this.showSequenceNumbers = false,
    this.overrideColor,
    this.staticArrowStyle = false,
  });

  Color _getRelativeColor(int currentEval, int multiPv) {
    if (multiPv == 1) return const Color(0xFF00FF88);
    final loss = (bestEval - currentEval).abs();
    if (loss < 30) return const Color(0xFF00FF88).withValues(alpha: 0.7);
    if (loss < 100) return Colors.yellowAccent;
    if (loss < 250) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _darkenColor(Color color, double amount) {
    final factor = (1.0 - amount).clamp(0.0, 1.0);
    return Color.fromARGB(
      color.a.toInt(),
      (color.r * factor).round().clamp(0, 255),
      (color.g * factor).round().clamp(0, 255),
      (color.b * factor).round().clamp(0, 255),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double boardInset = 2.0;
    final sq = (size.width - (boardInset * 2)) / 8;

    // Pre-compute badge positions with greedy collision avoidance.
    // The best line (multiPv == 1) picks its preferred spot first; subsequent
    // lines try alternative t-values along their own arrow until the gap to
    // every already-placed badge is at least minSafeGap pixels.
    final Map<int, Offset> badgeCenters = {};
    if (showSequenceNumbers) {
      const double badgeR = 9.2;
      const double minSafeGap = badgeR * 2 + 3.0;
      const List<double> tCandidates = [
        0.50, 0.35, 0.65, 0.28, 0.72, 0.20, 0.80,
      ];
      final sortedLines = [...lines]
        ..sort((a, b) => a.multiPv.compareTo(b.multiPv));
      for (final line in sortedLines) {
        final lStart =
            _getOffset(line.move.substring(0, 2), sq, size, boardInset);
        final lEnd =
            _getOffset(line.move.substring(2, 4), sq, size, boardInset);
        final ldx = lEnd.dx - lStart.dx;
        final ldy = lEnd.dy - lStart.dy;
        final ldist = sqrt(ldx * ldx + ldy * ldy);
        if (ldist < 0.001) {
          badgeCenters[line.multiPv] = lStart;
          continue;
        }
        final lUnitX = ldx / ldist;
        final lUnitY = ldy / ldist;
        final lLineEnd =
            Offset(lEnd.dx - lUnitX * 10, lEnd.dy - lUnitY * 10);

        Offset bestPos = Offset.lerp(lStart, lLineEnd, 0.5)!;
        double bestMinDist = -1.0;
        for (final t in tCandidates) {
          final candidate = Offset.lerp(lStart, lLineEnd, t)!;
          var minDist = double.infinity;
          for (final placed in badgeCenters.values) {
            final d = (candidate - placed).distance;
            if (d < minDist) minDist = d;
          }
          // No existing badges yet → first line always succeeds immediately.
          if (badgeCenters.isEmpty) minDist = double.infinity;
          if (minDist > bestMinDist) {
            bestMinDist = minDist;
            bestPos = candidate;
            if (minDist >= minSafeGap) break; // clear spot found
          }
        }
        badgeCenters[line.multiPv] = bestPos;
      }
    }

    for (final line in lines.reversed) {
      final start = _getOffset(line.move.substring(0, 2), sq, size, boardInset);
      final end = _getOffset(line.move.substring(2, 4), sq, size, boardInset);

      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance < 0.001) continue;
      final unitX = dx / distance;
      final unitY = dy / distance;
      final lineEnd = Offset(end.dx - unitX * 10, end.dy - unitY * 10);

      final isGambitMode = showSequenceNumbers;
      final isFirstArrow = line.multiPv == 1;
      final useStaticStyle = staticArrowStyle && isGambitMode;
      final baseColor =
          overrideColor ?? _getRelativeColor(line.eval, line.multiPv);

      final alphaScale = useStaticStyle
          ? 0.92
          : (isGambitMode
                ? (isFirstArrow
                      ? 1.0
                      : max(0.45, 1.0 - (line.multiPv - 1) * 0.10))
                : 1.0);

      final baseStrokeWidth = useStaticStyle
          ? 4.8
          : (isGambitMode
                ? (isFirstArrow ? 9.0 : (line.multiPv == 2 ? 5.5 : 4.5))
                : 4.6);
      final strokeWidth = (!useStaticStyle && !isGambitMode && isFirstArrow)
          ? (baseStrokeWidth * 1.30)
          : baseStrokeWidth;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(lineEnd.dx, lineEnd.dy);

      final outlineStrokeWidth = strokeWidth + (useStaticStyle ? 1.8 : 1.6);
      final outlineColor = _darkenColor(
        baseColor,
        0.15,
      ).withValues(alpha: useStaticStyle ? 0.72 : 0.45 * alphaScale);
      final outlinePaint = Paint()
        ..strokeWidth = outlineStrokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..color = outlineColor;
      canvas.drawPath(path, outlinePaint);

      final basePaint = Paint()
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..color = baseColor.withValues(
          alpha: useStaticStyle ? 0.58 : 0.30 * alphaScale,
        );
      canvas.drawPath(path, basePaint);

      if (!useStaticStyle) {
        final pulseHalfLen = max(18.0, distance * 0.14);
        final travel = distance + (pulseHalfLen * 2);
        final pulseCenter = (-pulseHalfLen) + (travel * (progress % 1.0));
        final pulseStart = Offset(
          start.dx + unitX * (pulseCenter - pulseHalfLen),
          start.dy + unitY * (pulseCenter - pulseHalfLen),
        );
        final pulseEnd = Offset(
          start.dx + unitX * (pulseCenter + pulseHalfLen),
          start.dy + unitY * (pulseCenter + pulseHalfLen),
        );

        final pulsePaint = Paint()
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..shader = ui.Gradient.linear(
            pulseStart,
            pulseEnd,
            [
              baseColor.withValues(alpha: 0.0),
              baseColor.withValues(alpha: alphaScale),
              baseColor.withValues(alpha: 0.0),
            ],
            const [0.0, 0.5, 1.0],
            TileMode.clamp,
          );
        canvas.drawPath(path, pulsePaint);
      }

      final angle = atan2(end.dy - start.dy, end.dx - start.dx);
      final baseHeadLen = useStaticStyle
          ? 18.0
          : (isGambitMode && isFirstArrow ? 22.0 : 18.0);
      final headLen = (!useStaticStyle && !isGambitMode && isFirstArrow)
          ? (baseHeadLen * 1.30)
          : baseHeadLen;
      final headWaist = headLen * (2.0 / 3.0);
      final headPath = Path()
        ..moveTo(end.dx, end.dy)
        ..lineTo(
          end.dx - headLen * cos(angle - 0.40),
          end.dy - headLen * sin(angle - 0.40),
        )
        ..lineTo(
          end.dx - headWaist * cos(angle),
          end.dy - headWaist * sin(angle),
        )
        ..lineTo(
          end.dx - headLen * cos(angle + 0.40),
          end.dy - headLen * sin(angle + 0.40),
        )
        ..close();

      final solidHeadColor = baseColor.withValues(alpha: alphaScale);
      canvas.drawPath(
        headPath,
        Paint()
          ..color = solidHeadColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        headPath,
        Paint()
          ..color = _darkenColor(solidHeadColor, 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round,
      );

      if (isGambitMode) {
        const badgeRadius = 9.2;
        final markerCenter =
            badgeCenters[line.multiPv] ?? Offset.lerp(start, lineEnd, 0.5)!;

        if (useStaticStyle) {
          canvas.drawCircle(
            markerCenter,
            badgeRadius,
            Paint()..color = const Color(0xFF1D222A).withValues(alpha: 0.96),
          );
        } else if (isFirstArrow) {
          canvas.drawCircle(
            markerCenter,
            badgeRadius + 5,
            Paint()
              ..color = const Color(0xFFFFD700).withValues(alpha: 0.28)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          canvas.drawCircle(
            markerCenter,
            badgeRadius,
            Paint()
              ..shader = ui.Gradient.radial(
                markerCenter,
                badgeRadius,
                [const Color(0xFF1D222A), const Color(0xFF0C1016)],
                const [0.0, 1.0],
              ),
          );
        } else {
          canvas.drawCircle(
            markerCenter,
            badgeRadius,
            Paint()..color = baseColor.withValues(alpha: 0.92 * alphaScale),
          );
        }

        canvas.drawCircle(
          markerCenter,
          badgeRadius,
          Paint()
            ..color = useStaticStyle
                ? baseColor
                : (isFirstArrow
                      ? const Color(0xFFFFD700)
                      : baseColor.withValues(alpha: alphaScale))
            ..style = PaintingStyle.stroke
            ..strokeWidth = useStaticStyle ? 1.8 : (isFirstArrow ? 2.5 : 1.5),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: line.multiPv.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(
            markerCenter.dx - textPainter.width / 2,
            markerCenter.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  Offset _getOffset(String square, double sq, Size size, double inset) {
    var col = square.codeUnitAt(0) - 97;
    var row = int.parse(square[1]) - 1;
    if (reverse) {
      col = 7 - col;
    } else {
      row = 7 - row;
    }
    return Offset(inset + col * sq + sq / 2, inset + row * sq + sq / 2);
  }

  @override
  bool shouldRepaint(EnergyArrowPainter oldDelegate) => true;
}
