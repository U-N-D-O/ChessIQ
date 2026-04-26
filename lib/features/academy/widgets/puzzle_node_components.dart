part of 'package:chessiq/features/academy/screens/puzzle_node_screen.dart';

class _PerspectiveEvalBar extends StatelessWidget {
  const _PerspectiveEvalBar({
    required this.evalFromPlayerPerspective,
    required this.playerIsBlack,
    required this.monochrome,
    this.axis = Axis.vertical,
  });

  final double evalFromPlayerPerspective;
  final bool playerIsBlack;
  final bool monochrome;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final playerShare =
        ((evalFromPlayerPerspective.clamp(-12.0, 12.0) + 12.0) / 24.0).clamp(
          0.0,
          1.0,
        );
    final opponentShare = 1.0 - playerShare;

    final lightMonoFill = const Color(0xFFE6E6E6);
    final darkMonoFill = const Color(0xFF111111);
    final lightFill = monochrome ? lightMonoFill : Colors.white;
    final darkFill = monochrome ? darkMonoFill : const Color(0xFF1F2732);

    final playerFill = playerIsBlack ? darkFill : lightFill;
    final opponentFill = playerIsBlack ? lightFill : darkFill;

    final topFlex = max(1, (opponentShare * 100).round());
    final bottomFlex = max(1, (playerShare * 100).round());

    final segments = axis == Axis.vertical
        ? <Widget>[
            Expanded(
              flex: topFlex,
              child: Container(color: opponentFill),
            ),
            Expanded(
              flex: bottomFlex,
              child: Container(color: playerFill),
            ),
          ]
        : <Widget>[
            Expanded(
              flex: bottomFlex,
              child: Container(color: playerFill),
            ),
            Expanded(
              flex: topFlex,
              child: Container(color: opponentFill),
            ),
          ];

    return Container(
      width: axis == Axis.vertical ? 18 : null,
      height: axis == Axis.horizontal ? 14 : null,
      decoration: puzzleAcademyPanelDecoration(
        palette: palette,
        accent: monochrome ? palette.text : palette.cyan,
        fillColor: palette.panelAlt,
        radius: 999,
        borderWidth: 2,
        elevated: false,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Flex(direction: axis, children: segments),
      ),
    );
  }
}

class _GreyArrowPainter extends CustomPainter {
  const _GreyArrowPainter({
    required this.fromSquare,
    required this.toSquare,
    required this.flipped,
    required this.opacity,
  });

  final String? fromSquare;
  final String? toSquare;
  final bool flipped;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final from = fromSquare;
    final to = toSquare;
    if (from == null || to == null || from.length != 2 || to.length != 2) {
      return;
    }

    final fromCenter = _squareCenter(size, from, flipped);
    final toCenter = _squareCenter(size, to, flipped);
    final direction = toCenter - fromCenter;
    final length = direction.distance;
    if (length <= 0.001) return;
    final unit = direction / length;

    final paint = Paint()
      ..color = const Color(0xFFBFC5CE).withValues(alpha: opacity)
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final headBase = toCenter - unit * (size.width * 0.04);

    // With round caps, trim by half the stroke so the visible shaft ends
    // exactly at the arrowhead base instead of protruding into the tip.
    final shaftEnd = headBase - unit * (paint.strokeWidth * 0.5);
    canvas.drawLine(fromCenter, shaftEnd, paint);

    final perp = Offset(-unit.dy, unit.dx);
    final wing = size.width * 0.016;

    final path = Path()
      ..moveTo(toCenter.dx, toCenter.dy)
      ..lineTo(headBase.dx + perp.dx * wing, headBase.dy + perp.dy * wing)
      ..lineTo(headBase.dx - perp.dx * wing, headBase.dy - perp.dy * wing)
      ..close();

    final fill = Paint()
      ..color = const Color(0xFFBFC5CE).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);
  }

  Offset _squareCenter(Size size, String square, bool flipped) {
    final file = square.codeUnitAt(0) - 97;
    final rank = int.parse(square[1]);

    final visualFile = flipped ? 7 - file : file;
    final visualRankFromTop = flipped ? rank - 1 : 8 - rank;

    final tile = size.width / 8;
    return Offset((visualFile + 0.5) * tile, (visualRankFromTop + 0.5) * tile);
  }

  @override
  bool shouldRepaint(covariant _GreyArrowPainter oldDelegate) {
    return oldDelegate.fromSquare != fromSquare ||
        oldDelegate.toSquare != toSquare ||
        oldDelegate.flipped != flipped ||
        oldDelegate.opacity != opacity;
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    required this.monochrome,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool monochrome;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 74 : 96,
            child: Text(
              label,
              style: puzzleAcademyHudStyle(
                palette: palette,
                size: compact ? 9.8 : 10.6,
                weight: FontWeight.w700,
                letterSpacing: 0.85,
                height: 1.0,
                color: palette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: puzzleAcademyHudStyle(
                palette: palette,
                size: compact ? 10.4 : 11.2,
                weight: FontWeight.w700,
                color: palette.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DragPieceData {
  const _DragPieceData({required this.from});

  final String from;
}
