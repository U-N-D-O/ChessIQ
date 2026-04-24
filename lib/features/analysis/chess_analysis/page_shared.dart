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

  void _paintRasterBand(
    Canvas canvas, {
    required Offset from,
    required Offset to,
    required Color color,
    required double thickness,
  }) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance <= 1.0) return;

    final angle = atan2(delta.dy, delta.dx);
    final steps = reducedEffects ? 8 : 12;
    final segmentLength = distance / steps;

    for (var index = 0; index < steps; index++) {
      final pulse = (sin(time * 2.4 + index * 0.8) + 1.0) * 0.5;
      final center = from + delta * ((index + 0.5) / steps);
      final paint = Paint()
        ..color = color.withValues(
          alpha: _unit((reducedEffects ? 0.03 : 0.06) + pulse * 0.05),
        );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: segmentLength * (0.72 + pulse * 0.22),
            height: thickness * (0.74 + (index % 3) * 0.18),
          ),
          const Radius.circular(1.0),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortest = size.shortestSide;
    final innerRadius = shortest * 0.32;
    final outerRadius = shortest * 0.58;
    final impactStep = (impact * 6).round() / 6;

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

    final blueOffset = _alignmentToOffset(size, blueAlignment);
    final yellowOffset = _alignmentToOffset(size, yellowAlignment);
    _paintRasterBand(
      canvas,
      from: blueOffset,
      to: center,
      color: cyan,
      thickness: reducedEffects ? 4.0 : 6.0,
    );
    _paintRasterBand(
      canvas,
      from: yellowOffset,
      to: center,
      color: amber,
      thickness: reducedEffects ? 4.0 : 6.0,
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
