import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monochrome dark pieces use the blacker higher-contrast gray tint', () {
    expect(
      AppThemeProvider.pieceTintColorForIndex(5, 'p_b'),
      isSameColorAs(const Color(0xFF373737)),
    );
  });

  test('monochrome white pieces use the whiter high-contrast tint', () {
    expect(
      AppThemeProvider.pieceTintColorForIndex(5, 'p_w'),
      isSameColorAs(const Color(0xFFF6F6F6)),
    );
  });

  test('monochrome dark pieces render from the white asset silhouette', () {
    expect(AppThemeProvider.pieceAssetForIndex(5, 'p_b'), 'p_w');
    expect(AppThemeProvider.pieceAssetForIndex(5, 'k_b'), 'k_w');
  });

  test('monochrome piece theme requires its dedicated unlock', () {
    expect(
      AppThemeProvider.isPieceThemeIndexUnlocked(
        5,
        piecePackOwned: true,
        tuttiFruttiOwned: true,
        spectralOwned: true,
        monochromePiecesOwned: false,
      ),
      isFalse,
    );
    expect(
      AppThemeProvider.isPieceThemeIndexUnlocked(
        5,
        piecePackOwned: false,
        tuttiFruttiOwned: false,
        spectralOwned: false,
        monochromePiecesOwned: true,
      ),
      isTrue,
    );
  });

  test('ember dark pieces use the extra darker tint', () {
    expect(
      AppThemeProvider.pieceTintColorForIndex(1, 'p_b'),
      isSameColorAs(const Color(0xFF754732)),
    );
  });

  test('frost dark pieces use the slightly darker tint', () {
    expect(
      AppThemeProvider.pieceTintColorForIndex(2, 'p_b'),
      isSameColorAs(const Color(0xFF456485)),
    );
  });

  test('tutti frutti dark pieces use the configured hex tint', () {
    final tint = AppThemeProvider.pieceTintColorForIndex(3, 'p_b');

    expect(tint, const Color(0xFF36926C));
  });

  test('tutti frutti dark pieces render from the white asset silhouette', () {
    expect(AppThemeProvider.pieceAssetForIndex(3, 'p_b'), 'p_w');
    expect(AppThemeProvider.pieceAssetForIndex(3, 'k_b'), 'k_w');
  });

  test(
    'ember and frost dark pieces render from the white asset silhouette',
    () {
      expect(AppThemeProvider.pieceAssetForIndex(1, 'p_b'), 'p_w');
      expect(AppThemeProvider.pieceAssetForIndex(1, 'k_b'), 'k_w');
      expect(AppThemeProvider.pieceAssetForIndex(2, 'p_b'), 'p_w');
      expect(AppThemeProvider.pieceAssetForIndex(2, 'k_b'), 'k_w');
    },
  );

  test('tutti frutti white pieces keep the existing tint', () {
    expect(
      AppThemeProvider.pieceTintColorForIndex(3, 'p_w'),
      const Color(0xFFFFC8E8),
    );
    expect(AppThemeProvider.pieceAssetForIndex(3, 'p_w'), 'p_w');
    expect(AppThemeProvider.pieceAssetForIndex(1, 'p_w'), 'p_w');
    expect(AppThemeProvider.pieceAssetForIndex(2, 'p_w'), 'p_w');
    expect(AppThemeProvider.pieceAssetForIndex(5, 'p_w'), 'p_w');
  });
}
