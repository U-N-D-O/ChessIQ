import 'dart:math';
import 'dart:ui' as ui;

import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/analysis/models/analysis_models.dart';
import 'package:chessiq/shared/graphics/pixel_arrow_renderer.dart';
import 'package:flutter/material.dart';

class EnergyArrowPainter extends CustomPainter {
  static const Color _lightMonoOutline = Color(0xFFF7FBFF);

  final List<EngineLine> lines;
  final int bestEval;
  final double progress;
  final bool reverse;
  final bool showSequenceNumbers;
  final Color? overrideColor;
  final bool staticArrowStyle;
  final double boardInset;
  final ArrowThemeMode themeMode;

  EnergyArrowPainter({
    required this.lines,
    required this.bestEval,
    required this.progress,
    required this.reverse,
    this.showSequenceNumbers = false,
    this.overrideColor,
    this.staticArrowStyle = false,
    this.boardInset = 0.0,
    this.themeMode = ArrowThemeMode.classic,
  }) : super(repaint: PixelArrowRenderer.repaintListenable);

  // Anchor colors for the strength gradient. Each anchor is fully saturated
  // so neighbouring bands stay clearly distinguishable, even when the renderer
  // softens alpha for non-best lines.
  static const Color _strengthBest = Color(0xFF00E676); // vivid pure green
  static const Color _strengthGood = Color(0xFFAEEA00); // lime / chartreuse
  static const Color _strengthNeutral = Color(0xFFFFEA00); // saturated yellow
  static const Color _strengthSlip = Color(0xFFFF9100); // strong amber/orange
  static const Color _strengthError = Color(0xFFFF3D00); // deep orange-red
  static const Color _strengthCritical = Color(0xFFD50000); // intense red

  Color _lerpStrength(double loss) {
    // Piecewise linear interpolation across the loss spectrum. Stops are
    // chosen so the previous hard thresholds still mark the visual midpoint
    // of each transition.
    if (loss <= 0) return _strengthBest;
    if (loss < 30) {
      return Color.lerp(_strengthBest, _strengthGood, loss / 30)!;
    }
    if (loss < 100) {
      return Color.lerp(_strengthGood, _strengthNeutral, (loss - 30) / 70)!;
    }
    if (loss < 175) {
      return Color.lerp(_strengthNeutral, _strengthSlip, (loss - 100) / 75)!;
    }
    if (loss < 250) {
      return Color.lerp(_strengthSlip, _strengthError, (loss - 175) / 75)!;
    }
    if (loss < 500) {
      return Color.lerp(_strengthError, _strengthCritical, (loss - 250) / 250)!;
    }
    return _strengthCritical;
  }

  Color _getRelativeColor(int currentEval, int multiPv) {
    if (multiPv == 1) return _strengthBest;
    final loss = (bestEval - currentEval).abs().toDouble();
    return _lerpStrength(loss);
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

  bool _usesLightOutline(Color color) {
    final channelValues = <int>[
      color.r.toInt(),
      color.g.toInt(),
      color.b.toInt(),
    ]..sort();
    final channelSpread = channelValues.last - channelValues.first;
    return color.computeLuminance() < 0.22 && channelSpread <= 26;
  }

  Color _classicOutlineColor(
    Color color, {
    required bool useStaticStyle,
    required double alphaScale,
  }) {
    if (_usesLightOutline(color)) {
      return _lightMonoOutline.withValues(
        alpha: useStaticStyle ? 0.94 : max(0.76, alphaScale),
      );
    }
    return _darkenColor(
      color,
      0.15,
    ).withValues(alpha: useStaticStyle ? 0.72 : 0.45 * alphaScale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final usableBoardExtent = max(0.0, size.width - (boardInset * 2));
    if (usableBoardExtent <= 0) {
      return;
    }
    final sq = usableBoardExtent / 8;

    // Pre-compute badge positions with greedy collision avoidance.
    // The best line (multiPv == 1) picks its preferred spot first; subsequent
    // lines try alternative t-values along their own arrow until the gap to
    // every already-placed badge is at least minSafeGap pixels.
    final Map<int, Offset> badgeCenters = {};
    if (showSequenceNumbers) {
      const double badgeR = 9.2;
      const double minSafeGap = badgeR * 2 + 3.0;
      const List<double> tCandidates = [
        0.50,
        0.35,
        0.65,
        0.28,
        0.72,
        0.20,
        0.80,
      ];
      final sortedLines = [...lines]
        ..sort((a, b) => a.multiPv.compareTo(b.multiPv));
      for (final line in sortedLines) {
        final lStart = _getOffset(
          line.move.substring(0, 2),
          sq,
          size,
          boardInset,
        );
        final lEnd = _getOffset(
          line.move.substring(2, 4),
          sq,
          size,
          boardInset,
        );
        final ldx = lEnd.dx - lStart.dx;
        final ldy = lEnd.dy - lStart.dy;
        final ldist = sqrt(ldx * ldx + ldy * ldy);
        if (ldist < 0.001) {
          badgeCenters[line.multiPv] = lStart;
          continue;
        }
        final lUnitX = ldx / ldist;
        final lUnitY = ldy / ldist;
        final lLineEnd = Offset(lEnd.dx - lUnitX * 10, lEnd.dy - lUnitY * 10);

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

      final pixelMode = themeMode == ArrowThemeMode.pixel;
      final heavyMode = themeMode == ArrowThemeMode.heavy3d;
      const heavyLineScale = 0.75;
      final pixelStep = pixelMode ? max(3.0, min(4.5, sq * 0.08)) : 0.0;
      final themedStartInset = (pixelMode || heavyMode)
          ? min(sq * 0.36, distance * 0.32)
          : 0.0;
      final themedStart = Offset(
        start.dx + (unitX * themedStartInset),
        start.dy + (unitY * themedStartInset),
      );
      final renderStart = pixelMode
          ? _snapPoint(themedStart, pixelStep)
          : (heavyMode ? themedStart : start);
      final renderEnd = pixelMode ? _snapPoint(end, pixelStep) : end;
      final renderLineEnd = pixelMode
          ? _snapPoint(lineEnd, pixelStep)
          : lineEnd;
      final renderStrokeWidth = pixelMode
          ? max(
              pixelStep,
              (strokeWidth / pixelStep).roundToDouble() * pixelStep,
            )
          : (heavyMode ? strokeWidth * 1.55 * heavyLineScale : strokeWidth);

      if (pixelMode) {
        PixelArrowRenderer.paint(
          canvas: canvas,
          start: renderStart,
          end: renderEnd,
          pixelSize: pixelStep,
          color: baseColor,
          alphaScale: alphaScale,
          animatePulse: !useStaticStyle,
          progress: progress,
        );

        if (isGambitMode) {
          final markerCenter =
              badgeCenters[line.multiPv] ?? Offset.lerp(start, lineEnd, 0.5)!;
          _paintPixelBadge(
            canvas: canvas,
            center: markerCenter,
            step: pixelStep,
            label: line.multiPv.toString(),
            color: baseColor,
            alphaScale: alphaScale,
            emphasized: isFirstArrow,
          );
        }
        continue;
      }

      final angle = atan2(end.dy - start.dy, end.dx - start.dx);
      final baseHeadLen = useStaticStyle
          ? 18.0
          : (isGambitMode && isFirstArrow ? 22.0 : 18.0);
      final classicHeadLen = (!useStaticStyle && !isGambitMode && isFirstArrow)
          ? (baseHeadLen * 1.30)
          : baseHeadLen;
      const heavyHeadScale = 0.75;
      final headLen = heavyMode
          ? classicHeadLen * 1.35 * heavyHeadScale
          : classicHeadLen;
      final headWaist = headLen * (heavyMode ? 0.78 : 2.0 / 3.0);
      final headAngle = heavyMode ? 0.34 : 0.40;
      final heavyShaftEnd = heavyMode
          ? Offset(
              renderEnd.dx - (unitX * headWaist),
              renderEnd.dy - (unitY * headWaist),
            )
          : renderLineEnd;

      final path = Path()
        ..moveTo(renderStart.dx, renderStart.dy)
        ..lineTo(heavyShaftEnd.dx, heavyShaftEnd.dy);
      final heavyShaftLength = (heavyShaftEnd - renderStart).distance;

      if (heavyMode) {
        canvas.drawPath(
          path,
          Paint()
            ..strokeWidth = renderStrokeWidth + (8 * heavyLineScale)
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..color = Colors.black.withValues(alpha: 0.24 * alphaScale)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      final outlineStrokeWidth =
          renderStrokeWidth +
          (heavyMode ? 4.6 * heavyLineScale : (useStaticStyle ? 1.8 : 1.6));
      final outlineColor = heavyMode
          ? _darkenColor(
              baseColor,
              0.45,
            ).withValues(alpha: max(0.58, alphaScale * 0.80))
          : _classicOutlineColor(
              baseColor,
              useStaticStyle: useStaticStyle,
              alphaScale: alphaScale,
            );
      final outlinePaint = Paint()
        ..strokeWidth = outlineStrokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..color = outlineColor;
      canvas.drawPath(path, outlinePaint);

      final basePaint = Paint()
        ..strokeWidth = renderStrokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (heavyMode) {
        final bevelAxis = Offset(-unitY, unitX) * renderStrokeWidth;
        basePaint.shader = ui.Gradient.linear(
          renderStart - bevelAxis,
          renderStart + bevelAxis,
          <Color>[
            Colors.white.withValues(alpha: useStaticStyle ? 0.92 : 0.80),
            baseColor.withValues(alpha: useStaticStyle ? 0.88 : 0.76),
            _darkenColor(
              baseColor,
              0.55,
            ).withValues(alpha: useStaticStyle ? 0.92 : 0.86),
          ],
          const <double>[0.0, 0.42, 1.0],
          TileMode.clamp,
        );
      } else {
        basePaint.color = baseColor.withValues(
          alpha: useStaticStyle ? 0.58 : 0.30 * alphaScale,
        );
      }
      canvas.drawPath(path, basePaint);

      if (heavyMode) {
        final bevelOffset = Offset(-unitY, unitX) * (renderStrokeWidth * 0.18);
        final lowlightPath = Path()
          ..moveTo(
            renderStart.dx + bevelOffset.dx,
            renderStart.dy + bevelOffset.dy,
          )
          ..lineTo(
            heavyShaftEnd.dx + bevelOffset.dx,
            heavyShaftEnd.dy + bevelOffset.dy,
          );
        canvas.drawPath(
          lowlightPath,
          Paint()
            ..strokeWidth = renderStrokeWidth * 0.28
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..color = _darkenColor(
              baseColor,
              0.52,
            ).withValues(alpha: max(0.38, alphaScale * 0.62)),
        );

        final highlightPath = Path()
          ..moveTo(
            renderStart.dx - bevelOffset.dx,
            renderStart.dy - bevelOffset.dy,
          )
          ..lineTo(
            heavyShaftEnd.dx - bevelOffset.dx,
            heavyShaftEnd.dy - bevelOffset.dy,
          );
        canvas.drawPath(
          highlightPath,
          Paint()
            ..strokeWidth = renderStrokeWidth * 0.18
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..color = Colors.white.withValues(
              alpha: useStaticStyle ? 0.46 : 0.30 * alphaScale,
            ),
        );
      }

      if (!useStaticStyle) {
        final pulsePathStart = heavyMode ? renderStart : start;
        final pulsePathDistance = heavyMode ? heavyShaftLength : distance;
        final pulseHalfLen = max(18.0, pulsePathDistance * 0.14);
        final travel = pulsePathDistance + (pulseHalfLen * 2);
        final pulseCenter = (-pulseHalfLen) + (travel * (progress % 1.0));
        final pulseStart = Offset(
          pulsePathStart.dx + unitX * (pulseCenter - pulseHalfLen),
          pulsePathStart.dy + unitY * (pulseCenter - pulseHalfLen),
        );
        final pulseEnd = Offset(
          pulsePathStart.dx + unitX * (pulseCenter + pulseHalfLen),
          pulsePathStart.dy + unitY * (pulseCenter + pulseHalfLen),
        );

        final pulsePaint = Paint()
          ..strokeWidth = heavyMode
              ? renderStrokeWidth * 0.44
              : renderStrokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..shader = ui.Gradient.linear(
            pulseStart,
            pulseEnd,
            <Color>[
              baseColor.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: alphaScale),
              baseColor.withValues(alpha: 0.0),
            ],
            const <double>[0.0, 0.5, 1.0],
            TileMode.clamp,
          );
        canvas.drawPath(path, pulsePaint);
      }

      final headPoints = <Offset>[
        renderEnd,
        Offset(
          renderEnd.dx - headLen * cos(angle - headAngle),
          renderEnd.dy - headLen * sin(angle - headAngle),
        ),
        Offset(
          renderEnd.dx - headWaist * cos(angle),
          renderEnd.dy - headWaist * sin(angle),
        ),
        Offset(
          renderEnd.dx - headLen * cos(angle + headAngle),
          renderEnd.dy - headLen * sin(angle + headAngle),
        ),
      ];
      final headPath = Path()
        ..moveTo(headPoints.first.dx, headPoints.first.dy)
        ..lineTo(headPoints[1].dx, headPoints[1].dy)
        ..lineTo(headPoints[2].dx, headPoints[2].dy)
        ..lineTo(headPoints[3].dx, headPoints[3].dy)
        ..close();

      final solidHeadColor = baseColor.withValues(alpha: alphaScale);
      final headBorderColor = heavyMode
          ? _darkenColor(
              baseColor,
              0.48,
            ).withValues(alpha: useStaticStyle ? 0.96 : max(0.72, alphaScale))
          : (solidHeadColor.computeLuminance() > 0.62
                ? const Color(0xFF69727F).withValues(
                    alpha: useStaticStyle ? 0.96 : max(0.72, alphaScale),
                  )
                : _classicOutlineColor(
                    solidHeadColor,
                    useStaticStyle: useStaticStyle,
                    alphaScale: max(0.62, alphaScale),
                  ));
      if (heavyMode) {
        canvas.drawShadow(
          headPath,
          Colors.black.withValues(alpha: 0.72),
          4,
          false,
        );
      }
      final headFillPaint = Paint()..style = PaintingStyle.fill;
      if (heavyMode) {
        final headAxis = Offset(-unitY, unitX) * headLen;
        headFillPaint.shader = ui.Gradient.linear(
          renderEnd - headAxis,
          renderEnd + headAxis,
          <Color>[
            Colors.white.withValues(alpha: useStaticStyle ? 0.98 : 0.92),
            baseColor.withValues(alpha: useStaticStyle ? 0.94 : 0.88),
            _darkenColor(baseColor, 0.55).withValues(alpha: 0.94),
          ],
          const <double>[0.0, 0.38, 1.0],
          TileMode.clamp,
        );
      } else {
        headFillPaint
          ..color = solidHeadColor
          ..isAntiAlias = !pixelMode;
      }
      canvas.drawPath(headPath, headFillPaint);
      canvas.drawPath(
        headPath,
        Paint()
          ..color = headBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = useStaticStyle ? 1.8 : 1.4
          ..strokeJoin = StrokeJoin.round,
      );
      if (heavyMode) {
        final highlightPath = Path()
          ..moveTo(
            renderEnd.dx - headLen * cos(angle - headAngle * 0.72),
            renderEnd.dy - headLen * sin(angle - headAngle * 0.72),
          )
          ..lineTo(
            renderEnd.dx - headWaist * cos(angle) - unitY * 1.4,
            renderEnd.dy - headWaist * sin(angle) + unitX * 1.4,
          );
        canvas.drawPath(
          highlightPath,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.34 * alphaScale)
            ..strokeWidth = 1.4
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }

      if (isGambitMode) {
        const badgeRadius = 9.2;
        final markerCenter =
            badgeCenters[line.multiPv] ?? Offset.lerp(start, lineEnd, 0.5)!;
        final badgeBorderColor = isFirstArrow
            ? const Color(0xFF00FF88)
            : (useStaticStyle
                  ? baseColor
                  : baseColor.withValues(alpha: alphaScale));

        if (pixelMode) {
          final badgeRect = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: markerCenter,
              width: badgeRadius * 2.15,
              height: badgeRadius * 2.15,
            ),
            const Radius.circular(2),
          );
          canvas.drawRRect(
            badgeRect,
            Paint()
              ..color = const Color(0xFF151A22).withValues(alpha: 0.96)
              ..style = PaintingStyle.fill
              ..isAntiAlias = false,
          );
        } else if (heavyMode) {
          canvas.drawCircle(
            markerCenter,
            badgeRadius + 4.5,
            Paint()
              ..color = Colors.black.withValues(alpha: 0.22)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          );
          canvas.drawCircle(
            markerCenter,
            badgeRadius,
            Paint()
              ..shader = ui.Gradient.radial(
                markerCenter,
                badgeRadius,
                <Color>[
                  Colors.white.withValues(alpha: isFirstArrow ? 0.92 : 0.68),
                  _darkenColor(baseColor, 0.58).withValues(alpha: 0.96),
                ],
                const <double>[0.0, 1.0],
              ),
          );
        } else if (useStaticStyle) {
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
            ..color = badgeBorderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = pixelMode
                ? 2.0
                : (useStaticStyle ? 1.8 : (isFirstArrow ? 2.5 : 1.5)),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: line.multiPv.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: pixelMode ? 8.2 : 10.0,
              fontWeight: FontWeight.w900,
              fontFamily: pixelMode ? 'PressStart2P' : null,
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

  Offset _snapPoint(Offset point, double step) {
    if (step <= 0) {
      return point;
    }
    return Offset(
      (point.dx / step).roundToDouble() * step,
      (point.dy / step).roundToDouble() * step,
    );
  }

  Color _lightenColor(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount.clamp(0.0, 1.0))!;
  }

  void _paintPixelBadge({
    required Canvas canvas,
    required Offset center,
    required double step,
    required String label,
    required Color color,
    required double alphaScale,
    required bool emphasized,
  }) {
    final snappedCenter = _snapPoint(center, step);
    final outlineColor = _darkenColor(
      color,
      0.72,
    ).withValues(alpha: max(0.88, alphaScale));
    final lightColor = _lightenColor(
      color,
      emphasized ? 0.52 : 0.34,
    ).withValues(alpha: alphaScale);
    final midColor = _lightenColor(
      color,
      emphasized ? 0.20 : 0.08,
    ).withValues(alpha: alphaScale);
    final shadeColor = _darkenColor(
      color,
      emphasized ? 0.18 : 0.30,
    ).withValues(alpha: alphaScale);
    final outerRect = Rect.fromCenter(
      center: snappedCenter,
      width: step * 4.2,
      height: step * 3.8,
    );
    final innerRect = outerRect.deflate(step * 0.55);
    final outerRRect = RRect.fromRectAndRadius(
      outerRect,
      Radius.circular(step * 0.22),
    );
    final innerRRect = RRect.fromRectAndRadius(
      innerRect,
      Radius.circular(step * 0.16),
    );

    canvas.drawRRect(
      outerRRect,
      Paint()
        ..color = outlineColor
        ..style = PaintingStyle.fill
        ..isAntiAlias = false,
    );
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          innerRect.topLeft,
          innerRect.bottomRight,
          <Color>[lightColor, midColor, shadeColor],
          const <double>[0.0, 0.48, 1.0],
          TileMode.clamp,
        )
        ..style = PaintingStyle.fill
        ..isAntiAlias = false,
    );

    canvas.save();
    canvas.clipRRect(innerRRect);
    canvas.drawLine(
      _snapPoint(innerRect.topLeft + Offset(step * 0.20, step * 0.35), step),
      _snapPoint(innerRect.topRight + Offset(-step * 0.20, step * 0.35), step),
      Paint()
        ..color = _lightenColor(
          color,
          0.70,
        ).withValues(alpha: 0.42 * alphaScale)
        ..strokeWidth = max(step * 0.45, 1.0)
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.stroke
        ..isAntiAlias = false,
    );
    canvas.restore();

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: max(7.0, step * 0.75),
          fontWeight: FontWeight.w900,
          fontFamily: 'PressStart2P',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        snappedCenter.dx - (textPainter.width / 2),
        snappedCenter.dy - (textPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(EnergyArrowPainter oldDelegate) => true;
}
