import 'package:chessiq/core/theme/app_theme_provider.dart';
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
