import 'dart:math';
import 'dart:ui' as ui;

import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/shared/graphics/pixel_arrow_renderer.dart';
import 'package:flutter/material.dart';

class ThemeSelectorTile extends StatelessWidget {
  const ThemeSelectorTile({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.size = 62,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.24)
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.05),
                  scheme.surface,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.70)
                : scheme.outline.withValues(alpha: 0.32),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class BoardThemeSwatchPreview extends StatelessWidget {
  const BoardThemeSwatchPreview({super.key, required this.palette});

  final AppBoardPalette palette;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 27,
        height: 27,
        child: Column(
          children: [
            Row(
              children: [
                Container(width: 13.5, height: 13.5, color: palette.darkSquare),
                Container(
                  width: 13.5,
                  height: 13.5,
                  color: palette.lightSquare,
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 13.5,
                  height: 13.5,
                  color: palette.lightSquare,
                ),
                Container(width: 13.5, height: 13.5, color: palette.darkSquare),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PieceThemePreviewTile extends StatelessWidget {
  const PieceThemePreviewTile({
    super.key,
    required this.pieceThemeIndex,
    this.pieceSize = 18.0,
  });

  final int pieceThemeIndex;
  final double pieceSize;

  @override
  Widget build(BuildContext context) {
    final width = pieceSize > 18 ? pieceSize * 2.4 : 42.0;
    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemePreviewPiece(
            piece: 'k_w',
            pieceThemeIndex: pieceThemeIndex,
            size: pieceSize,
          ),
          const SizedBox(width: 3),
          _ThemePreviewPiece(
            piece: 'k_b',
            pieceThemeIndex: pieceThemeIndex,
            size: pieceSize,
          ),
        ],
      ),
    );
  }
}

class ArrowThemePreviewTile extends StatelessWidget {
  const ArrowThemePreviewTile({super.key, required this.arrowThemeIndex});

  final int arrowThemeIndex;

  @override
  Widget build(BuildContext context) {
    final normalizedIndex = arrowThemeIndex.clamp(
      0,
      AppThemeProvider.arrowThemeCount - 1,
    );
    return SizedBox(
      width: 42,
      height: 42,
      child: CustomPaint(
        painter: _ArrowThemePreviewPainter(
          mode: ArrowThemeMode.values[normalizedIndex],
        ),
      ),
    );
  }
}

class _ThemePreviewPiece extends StatelessWidget {
  const _ThemePreviewPiece({
    required this.piece,
    required this.pieceThemeIndex,
    required this.size,
  });

  final String piece;
  final int pieceThemeIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPiece = AppThemeProvider.pieceAssetForIndex(
      pieceThemeIndex,
      piece,
    );
    final baseImage = Image.asset(
      'assets/pieces/$assetPiece.png',
      width: size,
      height: size,
    );
    if (AppThemeProvider.useClassicPiecesForIndex(pieceThemeIndex)) {
      return baseImage;
    }

    final tinted = ColorFiltered(
      colorFilter: ColorFilter.mode(
        AppThemeProvider.pieceTintColorForIndex(pieceThemeIndex, piece),
        BlendMode.modulate,
      ),
      child: baseImage,
    );

    if (!piece.endsWith('_b')) {
      return tinted;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final offset in const <Offset>[
          Offset(-0.65, 0),
          Offset(0.65, 0),
          Offset(0, -0.65),
          Offset(0, 0.65),
          Offset(-0.5, -0.5),
          Offset(0.5, -0.5),
          Offset(-0.5, 0.5),
          Offset(0.5, 0.5),
        ])
          Transform.translate(
            offset: offset,
            child: Opacity(
              opacity: 0.18,
              child: Image.asset(
                'assets/pieces/$assetPiece.png',
                width: size,
                height: size,
                color: const Color(0xFFF7FBFF),
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
        tinted,
      ],
    );
  }
}

class _ArrowThemePreviewPainter extends CustomPainter {
  _ArrowThemePreviewPainter({required this.mode})
    : super(repaint: PixelArrowRenderer.repaintListenable);

  static const Color _previewTailColor = Color(0xFFFF4E4E);
  static const Color _previewMidColor = Color(0xFFFFE55A);
  static const Color _previewTipColor = Color(0xFF2FD46F);
  static const Color _previewOutlineColor = Color(0xFF121212);

  final ArrowThemeMode mode;

  Shader _previewGradientShader({
    required Offset start,
    required Offset end,
    double darken = 0.0,
    double lighten = 0.0,
  }) {
    Color adjust(Color color) {
      var adjusted = color;
      if (darken > 0) {
        adjusted = Color.lerp(adjusted, Colors.black, darken)!;
      }
      if (lighten > 0) {
        adjusted = Color.lerp(adjusted, Colors.white, lighten)!;
      }
      return adjusted;
    }

    return ui.Gradient.linear(
      start,
      end,
      <Color>[
        adjust(_previewTailColor),
        adjust(_previewMidColor),
        adjust(_previewTipColor),
      ],
      const <double>[0.0, 0.58, 1.0],
      TileMode.clamp,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.20, size.height * 0.78);
    final end = Offset(size.width * 0.80, size.height * 0.24);
    final direction = end - start;
    final length = direction.distance;
    if (length <= 0.001) {
      return;
    }

    final unit = direction / length;
    final perp = Offset(-unit.dy, unit.dx);
    switch (mode) {
      case ArrowThemeMode.classic:
        final shadowPaint = Paint()
          ..color = const Color(0xFF0F1722).withValues(alpha: 0.28)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(start, end - (unit * 8), shadowPaint);

        final bodyPaint = Paint()
          ..shader = _previewGradientShader(start: start, end: end)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(start, end - (unit * 10), bodyPaint);

        final headPath = Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(
            end.dx - 13 * cos(0.40) * unit.dx + 13 * sin(0.40) * perp.dx,
            end.dy - 13 * cos(0.40) * unit.dy + 13 * sin(0.40) * perp.dy,
          )
          ..lineTo(end.dx - 9 * unit.dx, end.dy - 9 * unit.dy)
          ..lineTo(
            end.dx - 13 * cos(0.40) * unit.dx - 13 * sin(0.40) * perp.dx,
            end.dy - 13 * cos(0.40) * unit.dy - 13 * sin(0.40) * perp.dy,
          )
          ..close();
        canvas.drawPath(
          headPath,
          Paint()..shader = _previewGradientShader(start: start, end: end),
        );
        canvas.drawPath(
          headPath,
          Paint()
            ..color = _previewOutlineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      case ArrowThemeMode.pixel:
        PixelArrowRenderer.paint(
          canvas: canvas,
          start: start,
          end: end,
          pixelSize: 2.6,
          color: _previewTipColor,
          tailColor: _previewTailColor,
          midColor: _previewMidColor,
          tipColor: _previewTipColor,
          outlineColor: _previewOutlineColor,
        );
      case ArrowThemeMode.heavy3d:
        const heavyPreviewHeadScale = 0.75;
        final heavyPreviewHeadLen = 18.0 * heavyPreviewHeadScale;
        final heavyPreviewHeadWing = 10.0 * heavyPreviewHeadScale;
        final heavyPreviewHeadWaist = 9.0 * heavyPreviewHeadScale;
        final heavyPreviewShaftStop = 12.0 * heavyPreviewHeadScale;
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.28)
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawLine(
          start + const Offset(1.5, 2.5),
          end - (unit * (heavyPreviewShaftStop - 2.0)),
          shadowPaint,
        );

        final basePaint = Paint()
          ..shader = _previewGradientShader(
            start: start,
            end: end,
            darken: 0.55,
          )
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(start, end - (unit * heavyPreviewShaftStop), basePaint);

        final corePaint = Paint()
          ..shader = _previewGradientShader(
            start: start,
            end: end,
            lighten: 0.05,
          )
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(start, end - (unit * heavyPreviewShaftStop), corePaint);
        canvas.drawLine(
          start - (perp * 1.8),
          end - (unit * (heavyPreviewShaftStop + 1.0)) - (perp * 1.8),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.60)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );

        final headPath = Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(
            end.dx -
                unit.dx * heavyPreviewHeadLen +
                perp.dx * heavyPreviewHeadWing,
            end.dy -
                unit.dy * heavyPreviewHeadLen +
                perp.dy * heavyPreviewHeadWing,
          )
          ..lineTo(
            end.dx - unit.dx * heavyPreviewHeadWaist,
            end.dy - unit.dy * heavyPreviewHeadWaist,
          )
          ..lineTo(
            end.dx -
                unit.dx * heavyPreviewHeadLen -
                perp.dx * heavyPreviewHeadWing,
            end.dy -
                unit.dy * heavyPreviewHeadLen -
                perp.dy * heavyPreviewHeadWing,
          )
          ..close();

        canvas.drawShadow(
          headPath,
          Colors.black.withValues(alpha: 0.60),
          4,
          false,
        );
        canvas.drawPath(
          headPath,
          Paint()
            ..shader = _previewGradientShader(
              start: start,
              end: end,
              lighten: 0.08,
            ),
        );
        canvas.drawPath(
          headPath,
          Paint()
            ..color = _previewOutlineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowThemePreviewPainter oldDelegate) {
    return oldDelegate.mode != mode;
  }
}
