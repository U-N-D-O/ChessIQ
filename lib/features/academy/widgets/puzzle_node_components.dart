part of 'package:chessiq/features/academy/screens/puzzle_node_screen.dart';

class _PerspectiveEvalBar extends StatelessWidget {
  const _PerspectiveEvalBar({
    required this.evalWhitePawns,
    required this.playerIsBlack,
    required this.monochrome,
  });

  final double evalWhitePawns;
  final bool playerIsBlack;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final whiteShare = ((evalWhitePawns.clamp(-12.0, 12.0) + 12.0) / 24.0)
        .clamp(0.0, 1.0);
    final blackShare = 1.0 - whiteShare;

    final playerShare = playerIsBlack ? blackShare : whiteShare;
    final opponentShare = 1.0 - playerShare;
    final playerLeading = playerShare >= opponentShare;

    final lightMonoFill = const Color(0xFFE6E6E6);
    final darkMonoFill = const Color(0xFF111111);
    final lightFill = monochrome ? lightMonoFill : Colors.white;
    final darkFill = monochrome ? darkMonoFill : const Color(0xFF1F2732);

    final playerFill = monochrome
        ? (playerLeading ? lightFill : darkFill)
        : (playerIsBlack ? darkFill : lightFill);
    final opponentFill = monochrome
        ? (playerLeading ? darkFill : lightFill)
        : (playerIsBlack ? lightFill : darkFill);

    final topFlex = max(1, (opponentShare * 100).round());
    final bottomFlex = max(1, (playerShare * 100).round());

    return Container(
      width: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.48)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Column(
          children: [
            Expanded(
              flex: topFlex,
              child: Container(color: opponentFill),
            ),
            Expanded(
              flex: bottomFlex,
              child: Container(color: playerFill),
            ),
          ],
        ),
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

    final paint = Paint()
      ..color = const Color(0xFFBFC5CE).withValues(alpha: opacity)
      ..strokeWidth = size.width * 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(fromCenter, toCenter, paint);

    final direction = toCenter - fromCenter;
    final length = direction.distance;
    if (length <= 0.001) return;
    final unit = direction / length;
    final headBase = toCenter - unit * (size.width * 0.04);
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
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
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

class _ThemeSelectorPill extends StatelessWidget {
  const _ThemeSelectorPill({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.20)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.05),
                  scheme.surface,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.64)
                : scheme.outline.withValues(alpha: 0.30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniSquare extends StatelessWidget {
  const _MiniSquare({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
