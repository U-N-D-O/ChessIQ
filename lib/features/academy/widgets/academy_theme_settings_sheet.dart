import 'dart:async';

import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/shared/widgets/theme_selector_tiles.dart';
import 'package:chessiq/shared/widgets/universal_settings_sheet.dart';
import 'package:flutter/material.dart';

Future<void> showAcademyThemeSettingsSheet({
  required BuildContext context,
  required AppThemeProvider themeProvider,
  required bool soundEnabled,
  required bool hapticsEnabled,
  required FutureOr<void> Function(bool enabled) onSoundEnabledChanged,
  required FutureOr<void> Function(bool enabled) onHapticsEnabledChanged,
}) async {
  final unlockState = await themeProvider.loadThemeUnlockState();
  final availableBoardThemeIndices =
      AppThemeProvider.availableBoardThemeIndices(
        themePackOwned: unlockState.themePackOwned,
      );
  final availablePieceThemeIndices =
      AppThemeProvider.availablePieceThemeIndices(
        piecePackOwned: unlockState.piecePackOwned,
      );

  if (!context.mounted) return;

  await showUniversalSettingsSheet(
    context: context,
    title: 'Settings',
    isAcademyMode: true,
    showBoardPerspectiveSection: false,
    showEngineControlsSection: false,
    themeMode: themeProvider.themeMode,
    themeStyle: themeProvider.themeStyle,
    soundEnabled: soundEnabled,
    hapticsEnabled: hapticsEnabled,
    onThemeModeChanged: (mode) async {
      await themeProvider.setThemeMode(mode);
    },
    onThemeStyleChanged: (style) async {
      await themeProvider.setThemeStyle(style);
    },
    onSoundEnabledChanged: onSoundEnabledChanged,
    onHapticsEnabledChanged: onHapticsEnabledChanged,
    boardThemeSelectorBuilder: (setSheetState) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: availableBoardThemeIndices
            .map((index) {
              final selected = themeProvider.boardThemeIndex == index;
              return ThemeSelectorTile(
                selected: selected,
                onTap: () {
                  unawaited(themeProvider.setBoardThemeIndex(index));
                  setSheetState(() {});
                },
                child: BoardThemeSwatchPreview(
                  palette: AppThemeProvider.boardPaletteForIndex(index),
                ),
              );
            })
            .toList(growable: false),
      );
    },
    pieceThemeSelectorBuilder: (setSheetState) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: availablePieceThemeIndices
            .map((index) {
              final selected = themeProvider.pieceThemeIndex == index;
              return ThemeSelectorTile(
                selected: selected,
                onTap: () {
                  unawaited(themeProvider.setPieceThemeIndex(index));
                  setSheetState(() {});
                },
                child: PieceThemePreviewTile(pieceThemeIndex: index),
              );
            })
            .toList(growable: false),
      );
    },
  );
}
