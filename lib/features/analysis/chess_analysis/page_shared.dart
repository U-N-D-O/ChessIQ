part of '../screens/chess_analysis_page.dart';

class _RenderedMoveToken {
  final String notation;
  final String movingPiece;
  final String? capturedPiece;

  const _RenderedMoveToken({
    required this.notation,
    required this.movingPiece,
    this.capturedPiece,
  });
}

enum _MenuAccentSlot { cyan, amber, pink, emerald }

enum _MenuSparkVisual { pixel, shard, sprite }

enum _MenuBackdropSpriteRole { king, queen, rook, bishop, knight, pawn }

class _MenuSparkParticle {
  Offset position;
  Offset velocity;
  double age = 0.0;
  double rotation;
  final double angularVelocity;
  final double life;
  final double size;
  final _MenuSparkVisual visual;
  final _MenuAccentSlot accent;
  final _MenuBackdropSpriteRole? spriteRole;
  final bool useDarkSprite;
  final bool mirrorX;

  _MenuSparkParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.size,
    required this.visual,
    required this.accent,
    required this.rotation,
    required this.angularVelocity,
    this.spriteRole,
    this.useDarkSprite = false,
    this.mirrorX = false,
  }) : assert(
         visual != _MenuSparkVisual.sprite || spriteRole != null,
         'Sprite particles require a sprite role.',
       );

  double get progress {
    final value = life <= 0 ? 1.0 : age / life;
    if (value <= 0.0) return 0.0;
    if (value >= 1.0) return 1.0;
    return value;
  }
}

class _MenuBackdropSpritePlacement {
  const _MenuBackdropSpritePlacement({
    required this.alignment,
    required this.role,
    required this.accent,
    required this.sizeFactor,
    required this.opacity,
    required this.driftPhase,
    required this.driftRadius,
    required this.driftSpeed,
    required this.rotation,
    this.useDarkSprite = false,
    this.mirrorX = false,
  });

  final Alignment alignment;
  final _MenuBackdropSpriteRole role;
  final _MenuAccentSlot accent;
  final double sizeFactor;
  final double opacity;
  final double driftPhase;
  final double driftRadius;
  final double driftSpeed;
  final double rotation;
  final bool useDarkSprite;
  final bool mirrorX;
}

class _MenuBlastBackdropPainter extends CustomPainter {
  const _MenuBlastBackdropPainter({
    required this.time,
    required this.impact,
    required this.blueAlignment,
    required this.yellowAlignment,
    required this.cyan,
    required this.amber,
    required this.pink,
    required this.crimson,
    required this.lineColor,
    required this.reducedEffects,
  });

  final double time;
  final double impact;
  final Offset blueAlignment;
  final Offset yellowAlignment;
  final Color cyan;
  final Color amber;
  final Color pink;
  final Color crimson;
  final Color lineColor;
  final bool reducedEffects;

  double _unit(double value) {
    if (value <= 0.0) return 0.0;
    if (value >= 1.0) return 1.0;
    return value;
  }

  Offset _alignmentToOffset(Size size, Offset alignment) {
    return Offset(
      (alignment.dx + 1.0) * size.width * 0.5,
      (alignment.dy + 1.0) * size.height * 0.5,
    );
  }

  void _paintCheckerBurst(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
  ) {
    final rayCount = reducedEffects ? 12 : 18;
    final delta = (2 * pi) / rayCount;
    final rotation = time * 0.18;
    final colors = <Color>[cyan, amber, pink, crimson];

    for (var index = 0; index < rayCount; index++) {
      final startAngle = rotation + index * delta;
      final endAngle = startAngle + delta * 0.58;
      final sweepPulse = (sin(time * 0.9 + index * 0.6) + 1.0) * 0.5;
      final burstOuter =
          outerRadius * (0.90 + sweepPulse * 0.10 + impact * 0.12);
      final color = colors[index % colors.length].withValues(
        alpha: _unit((reducedEffects ? 0.04 : 0.08) + impact * 0.05),
      );
      final path = Path()
        ..moveTo(
          center.dx + cos(startAngle) * innerRadius,
          center.dy + sin(startAngle) * innerRadius,
        )
        ..lineTo(
          center.dx + cos(startAngle) * burstOuter,
          center.dy + sin(startAngle) * burstOuter,
        )
        ..lineTo(
          center.dx + cos(endAngle) * burstOuter,
          center.dy + sin(endAngle) * burstOuter,
        )
        ..lineTo(
          center.dx + cos(endAngle) * (innerRadius * 1.06),
          center.dy + sin(endAngle) * (innerRadius * 1.06),
        )
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  void _paintSteppedSquareRing(
    Canvas canvas,
    Offset center,
    double halfExtent,
    double thickness,
    Color color,
    int phase,
  ) {
    final segments = reducedEffects ? 10 : 14;
    final segmentSize = (halfExtent * 2) / segments;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var index = 0; index < segments; index++) {
      if ((index + phase) % 3 == 1) continue;
      final offset = -halfExtent + segmentSize * (index + 0.5);
      final longSide = segmentSize * 0.74;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + offset, center.dy - halfExtent),
            width: longSide,
            height: thickness,
          ),
          const Radius.circular(1.2),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + halfExtent, center.dy + offset),
            width: thickness,
            height: longSide,
          ),
          const Radius.circular(1.2),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx - offset, center.dy + halfExtent),
            width: longSide,
            height: thickness,
          ),
          const Radius.circular(1.2),
        ),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx - halfExtent, center.dy - offset),
            width: thickness,
            height: longSide,
          ),
          const Radius.circular(1.2),
        ),
        paint,
      );
    }
  }

  void _paintOrbitDebris(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
  ) {
    final debrisCount = reducedEffects ? 12 : 22;
    final colors = <Color>[cyan, amber, pink, crimson, lineColor];

    for (var index = 0; index < debrisCount; index++) {
      final radiusPulse = (sin(time * 1.1 + index * 0.7) + 1.0) * 0.5;
      final radius = ui.lerpDouble(
        innerRadius * 1.06,
        outerRadius * 0.96,
        radiusPulse,
      )!;
      final angle = index * 0.62 + time * (0.36 + (index % 4) * 0.04);
      final position = center + Offset(cos(angle), sin(angle)) * radius;
      final size = (reducedEffects ? 4.0 : 6.0) + (index % 3).toDouble();
      final paint = Paint()
        ..color = colors[index % colors.length].withValues(
          alpha: _unit((reducedEffects ? 0.05 : 0.09) + impact * 0.04),
        );

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(angle + pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: size,
            height: size * (index.isEven ? 1.0 : 0.62),
          ),
          const Radius.circular(1.0),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _paintPerspectiveGrid(
    Canvas canvas,
    Size size,
    Offset center,
    double outerRadius,
  ) {
    final horizonY = ui.lerpDouble(size.height * 0.30, center.dy * 0.88, 0.62)!;
    final gridPaint = Paint()
      ..color = lineColor.withValues(alpha: reducedEffects ? 0.08 : 0.14)
      ..strokeWidth = reducedEffects ? 0.9 : 1.1
      ..style = PaintingStyle.stroke;
    final glowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, horizonY),
        Offset(0, size.height),
        <Color>[
          cyan.withValues(alpha: reducedEffects ? 0.0 : 0.02),
          lineColor.withValues(alpha: reducedEffects ? 0.04 : 0.10),
          lineColor.withValues(alpha: 0.0),
        ],
      );

    final laneCount = reducedEffects ? 7 : 11;
    for (var lane = 0; lane < laneCount; lane++) {
      final t = laneCount == 1 ? 0.5 : lane / (laneCount - 1);
      final normalized = t - 0.5;
      final topX = center.dx + normalized * outerRadius * 0.34;
      final controlX = center.dx + normalized * outerRadius * 0.82;
      final bottomX = center.dx + normalized * size.width * 1.22;
      final controlY = ui.lerpDouble(horizonY, size.height, 0.54)!;
      final path = Path()
        ..moveTo(topX, horizonY)
        ..quadraticBezierTo(controlX, controlY, bottomX, size.height);
      canvas.drawPath(path, gridPaint);
    }

    final rowCount = reducedEffects ? 4 : 6;
    for (var row = 0; row < rowCount; row++) {
      final progress = (row + 1) / rowCount;
      final eased = progress * progress;
      final y = ui.lerpDouble(horizonY + 14, size.height * 0.98, eased)!;
      final halfWidth = ui.lerpDouble(
        outerRadius * 0.18,
        size.width * 0.52,
        eased,
      )!;
      canvas.drawLine(
        Offset(center.dx - halfWidth, y),
        Offset(center.dx + halfWidth, y),
        gridPaint,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      glowPaint,
    );

    if (!reducedEffects) {
      canvas.drawLine(
        Offset(center.dx - outerRadius * 0.28, horizonY),
        Offset(center.dx + outerRadius * 0.28, horizonY),
        Paint()
          ..color = cyan.withValues(alpha: 0.10)
          ..strokeWidth = 1.6,
      );
    }
  }

  void _paintSignalHalo(
    Canvas canvas, {
    required Offset anchor,
    required Color primaryColor,
    required Color secondaryColor,
    required double polarity,
    required double innerRadius,
  }) {
    final haloRadius = innerRadius * (0.22 + impact * 0.08);
    final bloomPaint = Paint()
      ..shader = ui.Gradient.radial(
        anchor,
        haloRadius * (reducedEffects ? 1.3 : 1.8),
        <Color>[
          primaryColor.withValues(alpha: reducedEffects ? 0.10 : 0.16),
          secondaryColor.withValues(alpha: reducedEffects ? 0.04 : 0.08),
          Colors.transparent,
        ],
      );
    canvas.drawCircle(
      anchor,
      haloRadius * (reducedEffects ? 1.3 : 1.8),
      bloomPaint,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = reducedEffects ? 1.4 : 1.8;
    final ringCount = reducedEffects ? 1 : 2;
    for (var ring = 0; ring < ringCount; ring++) {
      final radius = haloRadius + ring * 12.0;
      final startAngle = time * (0.75 + ring * 0.12) * polarity;
      ringPaint.color = (ring.isEven ? primaryColor : secondaryColor)
          .withValues(
            alpha: _unit((reducedEffects ? 0.12 : 0.18) + impact * 0.06),
          );
      canvas.drawArc(
        Rect.fromCircle(center: anchor, radius: radius),
        startAngle,
        pi * (reducedEffects ? 0.46 : 0.58),
        false,
        ringPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: anchor, radius: radius * 0.84),
        startAngle + pi,
        pi * 0.24,
        false,
        ringPaint,
      );
    }

    if (!reducedEffects) {
      _paintSteppedSquareRing(
        canvas,
        anchor,
        haloRadius * 0.62,
        2.6,
        secondaryColor.withValues(alpha: 0.12 + impact * 0.06),
        ((time * 3).round()) % 3,
      );
    }

    final satelliteCount = reducedEffects ? 3 : 5;
    for (var index = 0; index < satelliteCount; index++) {
      final orbitAngle =
          time * (0.92 + index * 0.06) * polarity +
          index * (2 * pi / satelliteCount);
      final orbitRadius = haloRadius + 8 + (index.isEven ? 0 : 8);
      final point =
          anchor +
          Offset(cos(orbitAngle), sin(orbitAngle) * 0.88) * orbitRadius;
      final size = reducedEffects ? 3.0 : 4.4;
      final paint = Paint()
        ..color = (index.isEven ? primaryColor : secondaryColor).withValues(
          alpha: 0.18 + impact * 0.08,
        );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(orbitAngle + pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: size,
            height: size * (index.isEven ? 1.0 : 0.66),
          ),
          const Radius.circular(1.0),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _paintAmbientGlitchStrips(Canvas canvas, Size size) {
    final stripCount = reducedEffects ? 3 : 6;
    for (var index = 0; index < stripCount; index++) {
      final progress = ((time * 0.05) + index * 0.17) % 1.0;
      final y = ui.lerpDouble(
        size.height * 0.14,
        size.height * 0.84,
        progress,
      )!;
      final width = size.width * (0.14 + ((index % 3) * 0.08));
      final left = (size.width * ((sin(time * 0.8 + index * 1.4) + 1.0) * 0.34))
          .clamp(0.0, size.width - width);
      final rect = Rect.fromLTWH(left, y, width, reducedEffects ? 3.0 : 4.8);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topLeft, rect.topRight, <Color>[
            (index.isEven ? cyan : amber).withValues(alpha: 0.0),
            (index.isEven ? pink : crimson).withValues(
              alpha: reducedEffects ? 0.06 : 0.12,
            ),
            (index.isEven ? cyan : amber).withValues(alpha: 0.0),
          ]),
      );
    }

    if (!reducedEffects) {
      final blockCount = 7;
      for (var index = 0; index < blockCount; index++) {
        final x =
            size.width *
            (((cos(time * 0.9 + index * 1.2) + 1.0) * 0.4).clamp(0.0, 1.0));
        final y =
            size.height *
            (((sin(time * 0.7 + index * 1.5) + 1.0) * 0.32).clamp(0.08, 0.92));
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 6 + (index % 3) * 3,
            height: 3 + (index % 2) * 2,
          ),
          Paint()
            ..color = (index.isEven ? cyan : amber).withValues(alpha: 0.08),
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = size.shortestSide;
    final innerRadius = shortest * 0.32;
    final outerRadius = shortest * 0.58;
    final impactStep = (impact * 6).round() / 6;
    final blueOffset = _alignmentToOffset(size, blueAlignment);
    final yellowOffset = _alignmentToOffset(size, yellowAlignment);

    _paintPerspectiveGrid(canvas, size, center, outerRadius);
    _paintAmbientGlitchStrips(canvas, size);

    _paintCheckerBurst(canvas, center, innerRadius, outerRadius);

    for (var ring = 0; ring < (reducedEffects ? 1 : 2); ring++) {
      final progress = ((time * (0.16 + ring * 0.05)) + ring * 0.33) % 1.0;
      final extent = ui.lerpDouble(
        innerRadius * 0.92,
        outerRadius * (0.98 + impactStep * 0.08),
        progress,
      )!;
      final alpha = (1.0 - progress) * (reducedEffects ? 0.08 : 0.13);
      _paintSteppedSquareRing(
        canvas,
        center,
        extent,
        reducedEffects ? 4.0 : 6.0,
        lineColor.withValues(alpha: _unit(alpha + impactStep * 0.05)),
        ring,
      );
    }

    _paintOrbitDebris(canvas, center, innerRadius, outerRadius);
    _paintSignalHalo(
      canvas,
      anchor: blueOffset,
      primaryColor: cyan,
      secondaryColor: pink,
      polarity: -1.0,
      innerRadius: innerRadius,
    );
    _paintSignalHalo(
      canvas,
      anchor: yellowOffset,
      primaryColor: amber,
      secondaryColor: crimson,
      polarity: 1.0,
      innerRadius: innerRadius,
    );
  }

  @override
  bool shouldRepaint(covariant _MenuBlastBackdropPainter old) {
    return old.time != time ||
        old.impact != impact ||
        old.blueAlignment != blueAlignment ||
        old.yellowAlignment != yellowAlignment ||
        old.cyan != cyan ||
        old.amber != amber ||
        old.pink != pink ||
        old.crimson != crimson ||
        old.lineColor != lineColor ||
        old.reducedEffects != reducedEffects;
  }
}

enum _CreditsBackdropDotRole { green, blue, yellow }

enum _CreditsVisualMode { modern, glitchToRetro, retro, glitchToModern }

class _CreditsDialogVisuals {
  const _CreditsDialogVisuals({
    required this.palette,
    required this.mode,
    required this.themeBlend,
    required this.glitchStrength,
    required this.reducedEffects,
    required this.shellStart,
    required this.shellEnd,
    required this.panel,
    required this.panelAlt,
    required this.frame,
    required this.edgeGlow,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.tertiaryAccent,
    required this.titleColor,
  });

  final PuzzleAcademyPalette palette;
  final _CreditsVisualMode mode;
  final double themeBlend;
  final double glitchStrength;
  final bool reducedEffects;
  final Color shellStart;
  final Color shellEnd;
  final Color panel;
  final Color panelAlt;
  final Color frame;
  final Color edgeGlow;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color tertiaryAccent;
  final Color titleColor;

  bool get isRetro => themeBlend >= 0.56;

  BorderRadius get shellRadius => BorderRadius.circular(isRetro ? 12 : 24);
}

class _CreditsBackdropDot {
  Offset position;
  Offset velocity;
  final Color color;
  final double radius;
  final _CreditsBackdropDotRole role;
  double contactDuration = 0.0;

  _CreditsBackdropDot({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.role,
  });
}

class _CreditsRetroBackdropPainter extends CustomPainter {
  const _CreditsRetroBackdropPainter({
    required this.phase,
    required this.themeBlend,
    required this.glitchStrength,
    required this.gridColor,
    required this.scanColor,
    required this.highlightColor,
    required this.reducedEffects,
  });

  final double phase;
  final double themeBlend;
  final double glitchStrength;
  final Color gridColor;
  final Color scanColor;
  final Color highlightColor;
  final bool reducedEffects;

  @override
  void paint(Canvas canvas, Size size) {
    final blend = max(themeBlend, glitchStrength * 0.85);
    if (blend <= 0.0) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.05 + blend * 0.16)
      ..strokeWidth = reducedEffects ? 0.8 : 1.0;
    const cellSize = 28.0;
    final yShift = (phase * 12) % cellSize;

    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = -cellSize + yShift; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final scanPaint = Paint()
      ..color = scanColor.withValues(alpha: 0.018 + blend * 0.04);
    for (double y = 0; y <= size.height; y += 10) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scanPaint);
    }

    final sparklePaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.08 + blend * 0.14);
    for (var index = 0; index < 18; index++) {
      final progress = ((index * 0.13) + phase * 0.02) % 1.0;
      final x = size.width * ((index * 29 % 100) / 100);
      final y = size.height * (0.08 + progress * 0.68);
      final sparkleSize = index.isEven ? 2.0 : 3.0;
      canvas.drawRect(
        Rect.fromLTWH(x, y, sparkleSize, sparkleSize),
        sparklePaint,
      );
    }

    if (glitchStrength > 0.01) {
      final sweepY = (phase * 1.8 % 1.0) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(0, sweepY, size.width, reducedEffects ? 4 : 7),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, sweepY),
            Offset(size.width, sweepY),
            <Color>[
              highlightColor.withValues(alpha: 0.0),
              highlightColor.withValues(alpha: 0.10 + glitchStrength * 0.16),
              highlightColor.withValues(alpha: 0.0),
            ],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CreditsRetroBackdropPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.themeBlend != themeBlend ||
        oldDelegate.glitchStrength != glitchStrength ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.scanColor != scanColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.reducedEffects != reducedEffects;
  }
}

class _CreditsGlitchOverlayPainter extends CustomPainter {
  const _CreditsGlitchOverlayPainter({
    required this.phase,
    required this.strength,
    required this.primary,
    required this.secondary,
    required this.reducedEffects,
  });

  final double phase;
  final double strength;
  final Color primary;
  final Color secondary;
  final bool reducedEffects;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0.0) {
      return;
    }

    final bandCount = reducedEffects ? 3 : 6;
    for (var index = 0; index < bandCount; index++) {
      final progress = ((phase * 1.7) + index * 0.19) % 1.0;
      final y = size.height * progress;
      final height = (reducedEffects ? 6.0 : 10.0) + index * 2.0;
      final offset =
          sin((phase * 2 * pi) + index * 0.9) *
          strength *
          (reducedEffects ? 6.0 : 14.0);
      final tint = index.isEven ? primary : secondary;
      final widthFactor =
          0.56 + ((sin(phase * 8.0 + index * 1.4) + 1.0) * 0.22);
      final left = size.width * ((cos(phase * 6.0 + index * 0.7) + 1.0) * 0.18);
      final bandRect = Rect.fromLTWH(left, y, size.width * widthFactor, height);

      canvas.save();
      canvas.translate(offset, 0);
      canvas.drawRect(
        bandRect,
        Paint()..color = tint.withValues(alpha: 0.05 + strength * 0.09),
      );
      canvas.restore();

      if (!reducedEffects) {
        canvas.drawRect(
          Rect.fromLTWH(
            max(0, bandRect.left - 8),
            bandRect.top + 1,
            min(size.width, bandRect.width * 0.2),
            max(1.0, bandRect.height - 2),
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.02 + strength * 0.08),
        );
      }
    }

    if (!reducedEffects) {
      final blockCount = 4;
      for (var index = 0; index < blockCount; index++) {
        final blockY = size.height * (((phase * 1.2) + index * 0.23) % 1.0);
        final blockLeft =
            size.width *
            (((sin(phase * 9.0 + index) + 1.0) * 0.32).clamp(0.0, 0.64));
        final blockWidth = size.width * (0.10 + ((index % 3) * 0.05));
        canvas.drawRect(
          Rect.fromLTWH(blockLeft, blockY, blockWidth, 8 + index * 2),
          Paint()
            ..color = (index.isEven ? primary : secondary).withValues(
              alpha: 0.04 + strength * 0.10,
            ),
        );
      }
    }

    final sweepY = ((phase * 2.4) + strength * 0.12) % 1.0 * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, sweepY, size.width, reducedEffects ? 1.5 : 2.5),
      Paint()..color = Colors.white.withValues(alpha: 0.06 + strength * 0.10),
    );

    if (!reducedEffects && strength > 0.55) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..blendMode = BlendMode.difference
          ..color = Colors.white.withValues(alpha: 0.018 + strength * 0.03),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CreditsGlitchOverlayPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.strength != strength ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.reducedEffects != reducedEffects;
  }
}

class _CreditsGlitchBandClipper extends CustomClipper<Rect> {
  const _CreditsGlitchBandClipper({
    required this.topFraction,
    required this.heightFraction,
    this.horizontalInsetFraction = 0.0,
  });

  final double topFraction;
  final double heightFraction;
  final double horizontalInsetFraction;

  @override
  Rect getClip(Size size) {
    final inset = (size.width * horizontalInsetFraction).clamp(
      0.0,
      size.width * 0.45,
    );
    final top = (size.height * topFraction).clamp(0.0, size.height);
    final height = (size.height * heightFraction).clamp(0.0, size.height - top);
    return Rect.fromLTWH(inset, top, max(0.0, size.width - inset * 2), height);
  }

  @override
  bool shouldReclip(covariant _CreditsGlitchBandClipper oldClipper) {
    return oldClipper.topFraction != topFraction ||
        oldClipper.heightFraction != heightFraction ||
        oldClipper.horizontalInsetFraction != horizontalInsetFraction;
  }
}

class _RegularPolygonPainter extends CustomPainter {
  const _RegularPolygonPainter({
    required this.sides,
    required this.strokeColor,
    required this.strokeWidth,
  });

  final int sides;
  final Color strokeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    if (sides <= 0) {
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = (2 * pi * i / sides) - pi / 2;
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RegularPolygonPainter old) {
    return old.sides != sides ||
        old.strokeColor != strokeColor ||
        old.strokeWidth != strokeWidth;
  }
}

abstract class _AnalysisPageShared extends _VsBotState {
  @override
  Future<void> _showThemedErrorDialog({
    required String message,
    String title = 'Something went wrong',
    bool includeInternetHint = false,
  }) async {
    if (!mounted) return;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final useMonochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final panelColor = useMonochrome
        ? (isDark ? const Color(0xFF111111) : const Color(0xFFF7F7F7))
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: isDark ? 0.14 : 0.06),
            scheme.surface,
          );
    final accent = useMonochrome
        ? (isDark ? const Color(0xFFD0D0D0) : const Color(0xFF4A4A4A))
        : const Color(0xFF5AAEE8);

    final text = includeInternetHint
        ? '$message\n\nTry again when you have internet connection.'
        : message;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: panelColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
        contentPadding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: accent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          text,
          style: TextStyle(
            color: scheme.onSurface.withValues(alpha: 0.88),
            height: 1.3,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: useMonochrome
                  ? (isDark ? Colors.black : Colors.white)
                  : const Color(0xFF07131F),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _pieceCodeForSanToken(String san, bool isWhiteMove) {
    final cleaned = _sanitizeSanToken(san);
    String pieceCode;

    if (cleaned.startsWith('O-O')) {
      pieceCode = 'k';
    } else {
      final designator = RegExp(r'^[KQRBN]').stringMatch(cleaned);
      switch (designator) {
        case 'K':
          pieceCode = 'k';
          break;
        case 'Q':
          pieceCode = 'q';
          break;
        case 'R':
          pieceCode = 't';
          break;
        case 'B':
          pieceCode = 'b';
          break;
        case 'N':
          pieceCode = 'n';
          break;
        default:
          pieceCode = 'p';
          break;
      }
    }

    return '${pieceCode}_${isWhiteMove ? 'w' : 'b'}';
  }

  List<_RenderedMoveToken> _renderedMoveTokens(String notation) {
    final tokens = _moveSequenceTokens(notation);
    if (tokens.isEmpty) return const <_RenderedMoveToken>[];

    final rendered = <_RenderedMoveToken>[];
    var state = _initialBoardState();
    var whiteToMove = true;

    for (int index = 0; index < tokens.length; index++) {
      final token = tokens[index];
      final fallbackPiece = _pieceCodeForSanToken(token, whiteToMove);
      final uciMove = _resolveSanToUci(state, token, whiteToMove);

      if (uciMove == null) {
        rendered.add(
          _RenderedMoveToken(notation: token, movingPiece: fallbackPiece),
        );
        whiteToMove = !whiteToMove;
        continue;
      }

      final from = uciMove.substring(0, 2);
      final to = uciMove.substring(2, 4);
      final movingPiece = state[from] ?? fallbackPiece;
      String? capturedPiece = state[to];

      if (capturedPiece == null &&
          movingPiece.startsWith('p') &&
          from[0] != to[0]) {
        final targetRank = int.parse(to[1]);
        final capturedRank = whiteToMove ? targetRank - 1 : targetRank + 1;
        final capturedSquare = '${to[0]}$capturedRank';
        capturedPiece = state[capturedSquare];
      }

      rendered.add(
        _RenderedMoveToken(
          notation: token,
          movingPiece: movingPiece,
          capturedPiece: capturedPiece,
        ),
      );

      state = _applyUciMove(state, uciMove);
      whiteToMove = !whiteToMove;
    }

    return rendered;
  }

  @override
  Widget _buildMoveSequenceText(
    String notation, {
    double fontSize = 12,
    Color color = Colors.white70,
    FontWeight fontWeight = FontWeight.w600,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
  }) {
    final renderedTokens = _renderedMoveTokens(notation);
    if (renderedTokens.isEmpty) {
      return Text(
        notation,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
        ),
      );
    }

    final iconSize = fontSize + 4;
    final spans = <InlineSpan>[];
    for (int index = 0; index < renderedTokens.length; index++) {
      final token = renderedTokens[index];
      if (index > 0) {
        spans.add(const TextSpan(text: '  '));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(
              right: token.capturedPiece == null ? 4 : 0,
            ),
            child: _pieceImage(
              token.movingPiece,
              width: iconSize,
              height: iconSize,
            ),
          ),
        ),
      );
      if (token.capturedPiece != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              Icons.arrow_right_alt_rounded,
              size: fontSize + 2,
              color: color.withValues(alpha: 0.85),
            ),
          ),
        );
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 3),
              child: _pieceImage(
                token.capturedPiece!,
                width: iconSize,
                height: iconSize,
              ),
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: token.notation,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
            fontWeight: fontWeight,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
