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
  if (!context.mounted) return;

  AppThemeUnlockState unlockState;
  try {
    unlockState = await themeProvider.loadThemeUnlockState();
  } catch (error, stackTrace) {
    debugPrint('Academy settings unlock state failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    unlockState = const AppThemeUnlockState();
  }

  final availableBoardThemeIndices =
      AppThemeProvider.availableBoardThemeIndices(
        themePackOwned: unlockState.themePackOwned,
        sakuraBoardOwned: unlockState.sakuraBoardOwned,
        tropicalBoardOwned: unlockState.tropicalBoardOwned,
      );
  final availablePieceThemeIndices =
      AppThemeProvider.availablePieceThemeIndices(
        piecePackOwned: unlockState.piecePackOwned,
        tuttiFruttiOwned: unlockState.tuttiFruttiOwned,
        spectralOwned: unlockState.spectralOwned,
        monochromePiecesOwned: unlockState.monochromePiecesOwned,
      );

  if (!context.mounted) return;

  Future<void> openSheet({
    UniversalSettingsSelectorBuilder? boardThemeSelectorBuilder,
    UniversalSettingsSelectorBuilder? pieceThemeSelectorBuilder,
  }) {
    return showUniversalSettingsSheet(
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
      boardThemeSelectorBuilder: boardThemeSelectorBuilder,
      pieceThemeSelectorBuilder: pieceThemeSelectorBuilder,
    );
  }

  try {
    await openSheet(
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
                    setSheetState(() {});
                    unawaited(themeProvider.setBoardThemeIndex(index));
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
                    setSheetState(() {});
                    unawaited(themeProvider.setPieceThemeIndex(index));
                  },
                  child: PieceThemePreviewTile(pieceThemeIndex: index),
                );
              })
              .toList(growable: false),
        );
      },
    );
  } catch (error, stackTrace) {
    debugPrint('Academy settings sheet failed, falling back: $error');
    debugPrintStack(stackTrace: stackTrace);
    if (!context.mounted) return;
    await openSheet();
  }
}
