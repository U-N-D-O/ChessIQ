import 'dart:async';
import 'dart:math';

import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:flutter/material.dart';

typedef UniversalSettingsExtraBuilder =
    List<Widget> Function(
      BuildContext context,
      StateSetter setSheetState,
      VoidCallback markChanged,
    );

typedef UniversalSettingsSelectorBuilder =
    Widget Function(StateSetter setSheetState, VoidCallback markChanged);

Future<void> showUniversalSettingsSheet({
  required BuildContext context,
  required ThemeMode themeMode,
  required AppThemeStyle themeStyle,
  required FutureOr<void> Function(ThemeMode mode) onThemeModeChanged,
  required FutureOr<void> Function(AppThemeStyle style) onThemeStyleChanged,
  required bool isAcademyMode,
  String title = 'Settings',
  int engineDepth = 20,
  int maxEngineDepth = 24,
  String Function(int value)? engineDepthLabelBuilder,
  int suggestedMoves = 3,
  int maxSuggestedMoves = 5,
  ValueChanged<int>? onEngineDepthChanged,
  ValueChanged<int>? onEngineDepthChangeEnd,
  ValueChanged<int>? onSuggestedMovesChanged,
  ValueChanged<int>? onSuggestedMovesChangeEnd,
  bool? soundEnabled,
  bool? hapticsEnabled,
  FutureOr<void> Function(bool enabled)? onSoundEnabledChanged,
  FutureOr<void> Function(bool enabled)? onHapticsEnabledChanged,
  UniversalSettingsSelectorBuilder? boardThemeSelectorBuilder,
  UniversalSettingsSelectorBuilder? pieceThemeSelectorBuilder,
  UniversalSettingsSelectorBuilder? arrowThemeSelectorBuilder,
  bool showBoardPerspectiveSection = false,
  UniversalSettingsSelectorBuilder? boardPerspectiveSectionBuilder,
  bool showEngineControlsSection = false,
  UniversalSettingsExtraBuilder? extraSectionsBuilder,
}) async {
  var selectedThemeMode = themeMode;
  var selectedThemeStyle = themeStyle;
  int draftDepth = engineDepth.clamp(10, max(10, maxEngineDepth));
  int draftSuggestions = suggestedMoves.clamp(0, max(0, maxSuggestedMoves));
  var draftSound = soundEnabled ?? false;
  var draftHaptics = hapticsEnabled ?? false;
  var hasChangedSettings = false;
  final maxSheetHeight = min(MediaQuery.of(context).size.height * 0.92, 720.0);

  final showBoardPerspective = !isAcademyMode && showBoardPerspectiveSection;

  final showEngineControls =
      !isAcademyMode &&
      showEngineControlsSection &&
      onEngineDepthChanged != null &&
      onEngineDepthChangeEnd != null &&
      onSuggestedMovesChanged != null &&
      onSuggestedMovesChangeEnd != null;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    clipBehavior: Clip.antiAlias,
    constraints: BoxConstraints(maxHeight: maxSheetHeight),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final scheme = theme.colorScheme;
      final sectionColor = Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.06),
        scheme.surface,
      );

      return StatefulBuilder(
        builder: (context, setSheetState) {
          void markChanged() {
            if (hasChangedSettings) {
              return;
            }
            setSheetState(() => hasChangedSettings = true);
          }

          final mediaQuery = MediaQuery.of(context);
          final bottomSafePadding = mediaQuery.viewPadding.bottom;
          final contentBottomPadding =
              (hasChangedSettings ? 140.0 : 20.0) + bottomSafePadding;
          final extraSections =
              extraSectionsBuilder?.call(context, setSheetState, markChanged) ??
              const <Widget>[];
          final boardThemeSelector = boardThemeSelectorBuilder?.call(
            setSheetState,
            markChanged,
          );
          final pieceThemeSelector = pieceThemeSelectorBuilder?.call(
            setSheetState,
            markChanged,
          );
          final arrowThemeSelector = arrowThemeSelectorBuilder?.call(
            setSheetState,
            markChanged,
          );
          final boardPerspectiveSelector = showBoardPerspective
              ? boardPerspectiveSectionBuilder?.call(setSheetState, markChanged)
              : null;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            color: scheme.surface,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      contentBottomPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (onSoundEnabledChanged != null)
                                    _HeaderToggleButton(
                                      active: draftSound,
                                      tooltip: draftSound
                                          ? 'Sound On'
                                          : 'Sound Off',
                                      onTap: () {
                                        final next = !draftSound;
                                        markChanged();
                                        setSheetState(() => draftSound = next);
                                        unawaited(
                                          Future.sync(
                                            () => onSoundEnabledChanged(next),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        draftSound
                                            ? Icons.volume_up_rounded
                                            : Icons.volume_off_rounded,
                                        size: 20,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  if (onHapticsEnabledChanged != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: _HeaderToggleButton(
                                        active: draftHaptics,
                                        tooltip: draftHaptics
                                            ? 'Haptics On'
                                            : 'Haptics Off',
                                        onTap: () {
                                          final next = !draftHaptics;
                                          markChanged();
                                          setSheetState(
                                            () => draftHaptics = next,
                                          );
                                          unawaited(
                                            Future.sync(
                                              () =>
                                                  onHapticsEnabledChanged(next),
                                            ),
                                          );
                                        },
                                        icon: _HapticsGlyph(
                                          enabled: draftHaptics,
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _HeaderToggleButton(
                                      active: false,
                                      tooltip: 'Close settings',
                                      onTap: () => Navigator.of(context).pop(),
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (boardPerspectiveSelector != null) ...[
                          _SettingsCard(
                            backgroundColor: sectionColor,
                            borderColor: scheme.outline.withValues(alpha: 0.24),
                            child: boardPerspectiveSelector,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (boardThemeSelector != null) ...[
                          _SettingsCard(
                            backgroundColor: sectionColor,
                            borderColor: scheme.outline.withValues(alpha: 0.24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Board Theme',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                boardThemeSelector,
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (pieceThemeSelector != null) ...[
                          _SettingsCard(
                            backgroundColor: sectionColor,
                            borderColor: scheme.outline.withValues(alpha: 0.24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Piece Theme',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                pieceThemeSelector,
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (arrowThemeSelector != null) ...[
                          _SettingsCard(
                            backgroundColor: sectionColor,
                            borderColor: scheme.outline.withValues(alpha: 0.24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Arrow Theme',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                arrowThemeSelector,
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _SettingsCard(
                          backgroundColor: sectionColor,
                          borderColor: scheme.outline.withValues(alpha: 0.24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UI Theme',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _ThemeStyleSwatchTile(
                                    tooltip: 'Neon',
                                    selected:
                                        selectedThemeStyle ==
                                        AppThemeStyle.standard,
                                    activeColor: const Color(0xFF3F6ED8),
                                    swatches: const <Color>[
                                      Color(0xFFD8B640),
                                      Color(0xFF3F6ED8),
                                      Color(0xFF5CCB8A),
                                    ],
                                    onTap: () {
                                      if (selectedThemeStyle ==
                                          AppThemeStyle.standard) {
                                        return;
                                      }
                                      markChanged();
                                      setSheetState(() {
                                        selectedThemeStyle =
                                            AppThemeStyle.standard;
                                      });
                                      unawaited(
                                        Future.sync(
                                          () => onThemeStyleChanged(
                                            AppThemeStyle.standard,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _ThemeStyleSwatchTile(
                                    tooltip: 'Mono',
                                    selected:
                                        selectedThemeStyle ==
                                        AppThemeStyle.monochrome,
                                    activeColor: const Color(0xFF808080),
                                    swatches: const <Color>[
                                      Color(0xFF0C0C0C),
                                      Color(0xFFFFFFFF),
                                      Color(0xFF808080),
                                    ],
                                    onTap: () {
                                      if (selectedThemeStyle ==
                                          AppThemeStyle.monochrome) {
                                        return;
                                      }
                                      markChanged();
                                      setSheetState(() {
                                        selectedThemeStyle =
                                            AppThemeStyle.monochrome;
                                      });
                                      unawaited(
                                        Future.sync(
                                          () => onThemeStyleChanged(
                                            AppThemeStyle.monochrome,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _SettingsCard(
                          backgroundColor: sectionColor,
                          borderColor: scheme.outline.withValues(alpha: 0.24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Day/Night Toggle',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SegmentedButton<ThemeMode>(
                                showSelectedIcon: false,
                                segments: const <ButtonSegment<ThemeMode>>[
                                  ButtonSegment<ThemeMode>(
                                    value: ThemeMode.light,
                                    label: Text('Light'),
                                    icon: Icon(Icons.light_mode_outlined),
                                  ),
                                  ButtonSegment<ThemeMode>(
                                    value: ThemeMode.dark,
                                    label: Text('Dark'),
                                    icon: Icon(Icons.dark_mode_outlined),
                                  ),
                                  ButtonSegment<ThemeMode>(
                                    value: ThemeMode.system,
                                    label: Text('System'),
                                    icon: Icon(Icons.brightness_auto_outlined),
                                  ),
                                ],
                                selected: <ThemeMode>{selectedThemeMode},
                                onSelectionChanged: (selection) {
                                  if (selection.isEmpty) return;
                                  final next = selection.first;
                                  if (next == selectedThemeMode) {
                                    return;
                                  }
                                  markChanged();
                                  setSheetState(() => selectedThemeMode = next);
                                  unawaited(
                                    Future.sync(() => onThemeModeChanged(next)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (showEngineControls) ...[
                          const SizedBox(height: 10),
                          _SettingsCard(
                            backgroundColor: sectionColor,
                            borderColor: scheme.outline.withValues(alpha: 0.24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Search Depth',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      engineDepthLabelBuilder?.call(
                                            draftDepth,
                                          ) ??
                                          '$draftDepth',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  min: 10,
                                  max: max(10, maxEngineDepth).toDouble(),
                                  divisions: max(1, maxEngineDepth - 10),
                                  value: draftDepth.toDouble(),
                                  onChanged: (value) {
                                    final next = value.toInt();
                                    if (next == draftDepth) {
                                      return;
                                    }
                                    markChanged();
                                    setSheetState(() => draftDepth = next);
                                    onEngineDepthChanged(next);
                                  },
                                  onChangeEnd: (value) {
                                    final next = value.toInt();
                                    onEngineDepthChangeEnd(next);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SettingsCard(
                            backgroundColor: sectionColor,
                            borderColor: scheme.outline.withValues(alpha: 0.24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Suggested Moves',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$draftSuggestions',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: scheme.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  min: 0,
                                  max: max(1, maxSuggestedMoves).toDouble(),
                                  divisions: max(1, maxSuggestedMoves),
                                  value: draftSuggestions.toDouble(),
                                  onChanged: (value) {
                                    final next = value.toInt();
                                    if (next == draftSuggestions) {
                                      return;
                                    }
                                    markChanged();
                                    setSheetState(
                                      () => draftSuggestions = next,
                                    );
                                    onSuggestedMovesChanged(next);
                                  },
                                  onChangeEnd: (value) {
                                    final next = value.toInt();
                                    onSuggestedMovesChangeEnd(next);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (extraSections.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ...extraSections,
                        ],
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      ignoring: !hasChangedSettings,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        offset: hasChangedSettings
                            ? Offset.zero
                            : const Offset(0, 1),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          opacity: hasChangedSettings ? 1 : 0,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16 + bottomSafePadding,
                            ),
                            child: _SettingsBottomActionBar(
                              onClose: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _SettingsBottomActionBar extends StatelessWidget {
  const _SettingsBottomActionBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
      scheme.surface,
    );

    final infoBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 20,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings updated',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Keep editing or tap Done to close this panel.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.30 : 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 420;
            final button = SizedBox(
              width: compact ? double.infinity : null,
              child: FilledButton.icon(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Done'),
              ),
            );

            if (compact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [infoBlock, const SizedBox(height: 12), button],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: infoBlock),
                const SizedBox(width: 12),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderToggleButton extends StatelessWidget {
  const _HeaderToggleButton({
    required this.active,
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  final bool active;
  final String tooltip;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? scheme.primary.withValues(alpha: 0.16)
                  : scheme.surface.withValues(alpha: 0.70),
              border: Border.all(
                color: active
                    ? scheme.primary.withValues(alpha: 0.42)
                    : scheme.outline.withValues(alpha: 0.24),
              ),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

class _HapticsGlyph extends StatelessWidget {
  const _HapticsGlyph({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          enabled ? Icons.vibration_rounded : Icons.vibration_outlined,
          size: 20,
          color: color,
        ),
        if (!enabled)
          Transform.rotate(
            angle: -0.85,
            child: Container(
              width: 18,
              height: 2,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeStyleSwatchTile extends StatelessWidget {
  const _ThemeStyleSwatchTile({
    required this.tooltip,
    required this.selected,
    required this.activeColor,
    required this.swatches,
    required this.onTap,
  });

  final String tooltip;
  final bool selected;
  final Color activeColor;
  final List<Color> swatches;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: selected
                  ? activeColor.withValues(alpha: 0.14)
                  : Color.alphaBlend(
                      scheme.primary.withValues(alpha: 0.04),
                      scheme.surface,
                    ),
              border: Border.all(
                color: selected
                    ? activeColor.withValues(alpha: 0.60)
                    : scheme.outline.withValues(alpha: 0.24),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 18,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: swatches
                            .map(
                              (color) => Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: color.computeLuminance() > 0.7
                                        ? Colors.black12
                                        : Colors.white12,
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.palette_outlined,
                    size: 18,
                    color: selected
                        ? activeColor
                        : scheme.onSurface.withValues(alpha: 0.68),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
