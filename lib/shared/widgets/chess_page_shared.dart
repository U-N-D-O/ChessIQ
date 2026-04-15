part of '../../features/analysis/screens/chess_analysis_page.dart';

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

class _MenuSparkParticle {
  Offset position;
  final Offset velocity;
  final Color color;

  _MenuSparkParticle({
    required this.position,
    required this.velocity,
    required this.color,
  });
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

mixin _AnalysisPageShared on _ChessAnalysisPageStateBase {
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
