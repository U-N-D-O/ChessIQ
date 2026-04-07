import 'dart:async';
import 'dart:math';

import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:flutter/material.dart';

typedef UniversalSettingsExtraBuilder =
    List<Widget> Function(BuildContext context, StateSetter setSheetState);

typedef UniversalSettingsSelectorBuilder =
    Widget Function(StateSetter setSheetState);

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
  bool showBoardPerspectiveSection = false,
  UniversalSettingsSelectorBuilder? boardPerspectiveSectionBuilder,
  bool showEngineControlsSection = false,
  UniversalSettingsExtraBuilder? extraSectionsBuilder,
}) async {
  var selectedThemeMode = themeMode;
  var selectedThemeStyle = themeStyle;
  var draftDepth = engineDepth.clamp(10, max(10, maxEngineDepth));
  var draftSuggestions = suggestedMoves.clamp(0, max(0, maxSuggestedMoves));
  var draftSound = soundEnabled ?? false;
  var draftHaptics = hapticsEnabled ?? false;
  final showFeedbackToggles =
      onSoundEnabledChanged != null || onHapticsEnabledChanged != null;

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
          final extraSections =
              extraSectionsBuilder?.call(context, setSheetState) ??
              const <Widget>[];
          final boardThemeSelector = boardThemeSelectorBuilder?.call(
            setSheetState,
          );
          final pieceThemeSelector = pieceThemeSelectorBuilder?.call(
            setSheetState,
          );
          final boardPerspectiveSelector = showBoardPerspective
              ? boardPerspectiveSectionBuilder?.call(setSheetState)
              : null;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            color: scheme.surface,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
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
                      if (showFeedbackToggles)
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
                                      setSheetState(() => draftHaptics = next);
                                      unawaited(
                                        Future.sync(
                                          () => onHapticsEnabledChanged(next),
                                        ),
                                      );
                                    },
                                    icon: _HapticsGlyph(enabled: draftHaptics),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                                  selectedThemeStyle == AppThemeStyle.standard,
                              activeColor: const Color(0xFF3F6ED8),
                              swatches: const <Color>[
                                Color(0xFFD8B640),
                                Color(0xFF3F6ED8),
                                Color(0xFF5CCB8A),
                              ],
                              onTap: () {
                                setSheetState(() {
                                  selectedThemeStyle = AppThemeStyle.standard;
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
                                setSheetState(() {
                                  selectedThemeStyle = AppThemeStyle.monochrome;
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
                          'Color Mode',
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
                            setSheetState(() => selectedThemeMode = next);
                            unawaited(
                              Future.sync(() => onThemeModeChanged(next)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (boardPerspectiveSelector != null) ...[
                    const SizedBox(height: 10),
                    _SettingsCard(
                      backgroundColor: sectionColor,
                      borderColor: scheme.outline.withValues(alpha: 0.24),
                      child: boardPerspectiveSelector,
                    ),
                  ],
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
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$draftDepth',
                                style: theme.textTheme.titleSmall?.copyWith(
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
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$draftSuggestions',
                                style: theme.textTheme.titleSmall?.copyWith(
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
                              setSheetState(() => draftSuggestions = next);
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
          enabled ? Icons.vibration_rounded : Icons.do_not_disturb_on_rounded,
          size: 20,
          color: color,
        ),
        if (!enabled)
          Positioned(
            bottom: 7,
            child: Container(
              width: 12,
              height: 1.6,
              color: color.withValues(alpha: 0.82),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: swatches
                              .map(
                                (color) => Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
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
                  ],
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
    );
  }
}
