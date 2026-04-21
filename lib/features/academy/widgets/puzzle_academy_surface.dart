import 'dart:ui';

import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const String puzzleAcademyDisplayFontFamily = 'PixgamerRegular';
const String puzzleAcademyHudFontFamily = 'PixelatedElegance';
const String puzzleAcademyCompactFontFamily = 'Cairopixel';
const String puzzleAcademyIdentityFontFamily = 'PressStart2P';

class PuzzleAcademyPalette {
  const PuzzleAcademyPalette({
    required this.monochrome,
    required this.isDark,
    required this.backdrop,
    required this.shell,
    required this.panel,
    required this.panelAlt,
    required this.line,
    required this.shadow,
    required this.text,
    required this.textMuted,
    required this.cyan,
    required this.amber,
    required this.emerald,
    required this.signal,
    required this.boardDark,
    required this.boardLight,
  });

  final bool monochrome;
  final bool isDark;
  final Color backdrop;
  final Color shell;
  final Color panel;
  final Color panelAlt;
  final Color line;
  final Color shadow;
  final Color text;
  final Color textMuted;
  final Color cyan;
  final Color amber;
  final Color emerald;
  final Color signal;
  final Color boardDark;
  final Color boardLight;
}

PuzzleAcademyPalette puzzleAcademyPalette(
  BuildContext context, {
  bool? monochromeOverride,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final appTheme = context.read<AppThemeProvider>();
  final boardPalette = appTheme.boardPalette();
  final isDark = theme.brightness == Brightness.dark;
  final useMonochrome = monochromeOverride ?? appTheme.isMonochrome;
  final text = useMonochrome && !isDark ? Colors.black : scheme.onSurface;
  final cyan = useMonochrome
      ? text.withValues(alpha: isDark ? 0.82 : 0.72)
      : Color.lerp(
          scheme.secondary,
          boardPalette.lightSquare,
          isDark ? 0.22 : 0.10,
        )!;
  final amber = useMonochrome
      ? text.withValues(alpha: isDark ? 0.68 : 0.56)
      : Color.lerp(
          scheme.primary,
          const Color(0xFFFFC857),
          isDark ? 0.35 : 0.25,
        )!;
  final emerald = useMonochrome
      ? text.withValues(alpha: isDark ? 0.58 : 0.46)
      : Color.lerp(scheme.tertiary, const Color(0xFF88D498), 0.22)!;
  final boardDark = useMonochrome
      ? Color.lerp(
          boardPalette.darkSquare,
          scheme.outline,
          isDark ? 0.20 : 0.45,
        )!
      : Color.lerp(
          boardPalette.darkSquare,
          scheme.secondary,
          isDark ? 0.30 : 0.20,
        )!;
  final boardLight = useMonochrome
      ? Color.lerp(
          boardPalette.lightSquare,
          scheme.surface,
          isDark ? 0.20 : 0.40,
        )!
      : Color.lerp(
          boardPalette.lightSquare,
          scheme.surface,
          isDark ? 0.18 : 0.42,
        )!;
  final backdrop = Color.alphaBlend(
    boardDark.withValues(alpha: isDark ? 0.34 : 0.18),
    scheme.surface,
  );
  final shell = Color.alphaBlend(
    boardLight.withValues(alpha: isDark ? 0.10 : 0.24),
    backdrop,
  );
  final panel = Color.alphaBlend(
    scheme.surface.withValues(alpha: isDark ? 0.94 : 0.97),
    shell,
  );
  final panelAlt = Color.alphaBlend(
    boardLight.withValues(alpha: isDark ? 0.15 : 0.28),
    shell,
  );
  final line = Color.alphaBlend(
    scheme.outline.withValues(alpha: isDark ? 0.82 : 0.92),
    boardDark.withValues(alpha: 0.06),
  );
  final signal = useMonochrome
      ? text.withValues(alpha: 0.70)
      : Color.lerp(scheme.primary, const Color(0xFFFF9A62), 0.45)!;
  return PuzzleAcademyPalette(
    monochrome: useMonochrome,
    isDark: isDark,
    backdrop: backdrop,
    shell: shell,
    panel: panel,
    panelAlt: panelAlt,
    line: line,
    shadow: Colors.black.withValues(alpha: isDark ? 0.42 : 0.16),
    text: text,
    textMuted: text.withValues(alpha: isDark ? 0.74 : 0.68),
    cyan: cyan,
    amber: amber,
    emerald: emerald,
    signal: signal,
    boardDark: boardDark,
    boardLight: boardLight,
  );
}

bool puzzleAcademyShouldReduceEffects(BuildContext context) {
  final disableAnimations =
      MediaQuery.maybeOf(context)?.disableAnimations ??
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations;
  return disableAnimations;
}

Duration puzzleAcademyMotionDuration({
  required bool reducedEffects,
  int milliseconds = 180,
  int reducedMilliseconds = 0,
}) {
  return Duration(
    milliseconds: reducedEffects ? reducedMilliseconds : milliseconds,
  );
}

Curve puzzleAcademyMotionCurve({required bool reducedEffects}) {
  return reducedEffects ? Curves.linear : Curves.easeOutCubic;
}

WidgetStateProperty<Color?> puzzleAcademyInteractiveOverlay({
  required PuzzleAcademyPalette palette,
  required Color accent,
}) {
  return WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.disabled)) {
      return null;
    }
    if (states.contains(WidgetState.pressed)) {
      return accent.withValues(alpha: palette.monochrome ? 0.18 : 0.12);
    }
    if (states.contains(WidgetState.focused)) {
      return accent.withValues(alpha: palette.monochrome ? 0.14 : 0.09);
    }
    if (states.contains(WidgetState.hovered)) {
      return accent.withValues(alpha: palette.monochrome ? 0.10 : 0.06);
    }
    return null;
  });
}

List<BoxShadow> puzzleAcademySurfaceGlow(
  Color color, {
  required bool monochrome,
  double strength = 1.0,
}) {
  if (!monochrome) {
    return <BoxShadow>[
      BoxShadow(
        color: color.withValues(alpha: 0.14 * strength),
        blurRadius: 20 * strength,
        spreadRadius: 0.8 * strength,
        offset: Offset(0, 12 * strength),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10 * strength),
        blurRadius: 24 * strength,
        offset: Offset(0, 14 * strength),
      ),
    ];
  }
  return <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: 0.14 * strength),
      blurRadius: 22 * strength,
      spreadRadius: 0.6 * strength,
      offset: Offset(0, 8 * strength),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.05 * strength),
      blurRadius: 10 * strength,
      spreadRadius: -2 * strength,
      offset: Offset(0, -1.5 * strength),
    ),
  ];
}

List<Shadow> puzzleAcademyTextGlow(
  Color color, {
  required bool monochrome,
  double strength = 1.0,
}) {
  if (!monochrome) {
    return <Shadow>[
      Shadow(
        color: color.withValues(alpha: 0.16 * strength),
        blurRadius: 14 * strength,
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.12 * strength),
        blurRadius: 8 * strength,
        offset: const Offset(0, 2),
      ),
    ];
  }
  return <Shadow>[
    Shadow(
      color: color.withValues(alpha: 0.26 * strength),
      blurRadius: 10 * strength,
    ),
    Shadow(
      color: Colors.white.withValues(alpha: 0.08 * strength),
      blurRadius: 18 * strength,
    ),
  ];
}

BoxDecoration puzzleAcademyTagDecoration({
  required PuzzleAcademyPalette palette,
  required Color accent,
  bool filled = false,
  double radius = 5,
}) {
  final base = Color.alphaBlend(
    accent.withValues(
      alpha: filled
          ? (palette.monochrome ? 0.24 : 0.18)
          : (palette.monochrome ? 0.16 : 0.11),
    ),
    palette.panelAlt,
  );
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.alphaBlend(accent.withValues(alpha: filled ? 0.14 : 0.08), base),
        base,
        Color.alphaBlend(
          palette.boardLight.withValues(
            alpha: palette.monochrome ? 0.04 : 0.06,
          ),
          base,
        ),
      ],
      stops: const <double>[0.0, 0.58, 1.0],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: accent.withValues(alpha: filled ? 0.68 : 0.56),
      width: 2,
    ),
    boxShadow: puzzleAcademySurfaceGlow(
      accent,
      monochrome: palette.monochrome,
      strength: filled ? 0.16 : 0.10,
    ),
  );
}

TextStyle puzzleAcademyDisplayStyle({
  required PuzzleAcademyPalette palette,
  double size = 24,
  FontWeight weight = FontWeight.w700,
  double letterSpacing = 0.9,
  double height = 0.95,
  Color? color,
  bool withGlow = true,
}) {
  return TextStyle(
    fontFamily: puzzleAcademyDisplayFontFamily,
    fontFamilyFallback: const <String>['Courier New'],
    color: color ?? palette.text,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    shadows: withGlow
        ? puzzleAcademyTextGlow(
            color ?? palette.text,
            monochrome: palette.monochrome,
            strength: size >= 24 ? 1.08 : 0.88,
          )
        : null,
  );
}

TextStyle puzzleAcademyHudStyle({
  required PuzzleAcademyPalette palette,
  double size = 12.5,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 0.7,
  double height = 1.3,
  Color? color,
  bool withGlow = false,
}) {
  return TextStyle(
    fontFamily: puzzleAcademyHudFontFamily,
    fontFamilyFallback: const <String>['Courier New'],
    color: color ?? palette.textMuted,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    shadows: withGlow
        ? puzzleAcademyTextGlow(
            color ?? palette.textMuted,
            monochrome: palette.monochrome,
            strength: 0.7,
          )
        : null,
  );
}

TextStyle puzzleAcademyCompactStyle({
  required PuzzleAcademyPalette palette,
  double size = 12.2,
  FontWeight weight = FontWeight.w600,
  double letterSpacing = 0.24,
  double height = 1.24,
  Color? color,
  bool withGlow = false,
}) {
  return TextStyle(
    fontFamily: puzzleAcademyCompactFontFamily,
    fontFamilyFallback: const <String>['Courier New'],
    color: color ?? palette.textMuted,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    shadows: withGlow
        ? puzzleAcademyTextGlow(
            color ?? palette.textMuted,
            monochrome: palette.monochrome,
            strength: 0.56,
          )
        : null,
  );
}

TextStyle puzzleAcademyIdentityStyle({
  required PuzzleAcademyPalette palette,
  double size = 11.2,
  FontWeight weight = FontWeight.w400,
  double letterSpacing = 0.18,
  double height = 1.32,
  Color? color,
  bool withGlow = false,
}) {
  return TextStyle(
    fontFamily: puzzleAcademyIdentityFontFamily,
    fontFamilyFallback: const <String>['Courier New'],
    color: color ?? palette.text,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
    shadows: withGlow
        ? puzzleAcademyTextGlow(
            color ?? palette.text,
            monochrome: palette.monochrome,
            strength: 0.6,
          )
        : null,
  );
}

BoxDecoration puzzleAcademyPanelDecoration({
  required PuzzleAcademyPalette palette,
  Color? accent,
  Color? fillColor,
  Color? borderColor,
  double radius = 8,
  double borderWidth = 3,
  bool elevated = true,
}) {
  final effectiveAccent = accent ?? palette.cyan;
  final background = fillColor ?? palette.panel;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.alphaBlend(
          effectiveAccent.withValues(alpha: palette.monochrome ? 0.08 : 0.12),
          background,
        ),
        background,
        Color.alphaBlend(
          palette.boardLight.withValues(
            alpha: palette.monochrome ? 0.03 : 0.05,
          ),
          background,
        ),
      ],
      stops: const <double>[0.0, 0.56, 1.0],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? palette.line, width: borderWidth),
    boxShadow: elevated
        ? <BoxShadow>[
            BoxShadow(
              color: palette.shadow,
              offset: const Offset(6, 6),
              blurRadius: 0,
            ),
            ...puzzleAcademySurfaceGlow(
              effectiveAccent,
              monochrome: palette.monochrome,
              strength: 0.8,
            ),
          ]
        : puzzleAcademySurfaceGlow(
            effectiveAccent,
            monochrome: palette.monochrome,
            strength: 0.5,
          ),
  );
}

ButtonStyle puzzleAcademyFilledButtonStyle({
  required PuzzleAcademyPalette palette,
  required Color backgroundColor,
  required Color foregroundColor,
  Color? disabledBackgroundColor,
  Color? disabledForegroundColor,
  BorderSide? side,
  EdgeInsetsGeometry? padding,
  double radius = 8,
}) {
  return FilledButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    disabledBackgroundColor:
        disabledBackgroundColor ?? backgroundColor.withValues(alpha: 0.26),
    disabledForegroundColor:
        disabledForegroundColor ?? foregroundColor.withValues(alpha: 0.54),
    shadowColor: palette.monochrome
        ? backgroundColor.withValues(alpha: 0.34)
        : backgroundColor.withValues(alpha: 0.20),
    elevation: palette.monochrome ? 3.2 : 1.6,
    surfaceTintColor: palette.monochrome
        ? Colors.white.withValues(alpha: 0.05)
        : null,
    padding: padding,
    side: side,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    textStyle: puzzleAcademyHudStyle(
      palette: palette,
      size: 11.8,
      weight: FontWeight.w800,
      letterSpacing: 0.9,
      height: 1.0,
      color: foregroundColor,
    ),
  ).copyWith(
    overlayColor: puzzleAcademyInteractiveOverlay(
      palette: palette,
      accent: palette.monochrome ? foregroundColor : Colors.white,
    ),
  );
}

ButtonStyle puzzleAcademyOutlinedButtonStyle({
  required PuzzleAcademyPalette palette,
  required Color accent,
  EdgeInsetsGeometry? padding,
  double radius = 8,
}) {
  return OutlinedButton.styleFrom(
    foregroundColor: accent,
    side: BorderSide(
      color: accent.withValues(alpha: palette.monochrome ? 0.82 : 0.90),
      width: 2,
    ),
    backgroundColor: accent.withValues(alpha: palette.monochrome ? 0.18 : 0.10),
    shadowColor: palette.monochrome
        ? accent.withValues(alpha: 0.28)
        : accent.withValues(alpha: 0.16),
    elevation: palette.monochrome ? 2.6 : 1.0,
    padding: padding,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    textStyle: puzzleAcademyHudStyle(
      palette: palette,
      size: 11.8,
      weight: FontWeight.w800,
      letterSpacing: 0.9,
      height: 1.0,
      color: accent,
    ),
  ).copyWith(
    overlayColor: puzzleAcademyInteractiveOverlay(
      palette: palette,
      accent: accent,
    ),
  );
}

class PuzzleAcademyAnimatedSwap extends StatelessWidget {
  const PuzzleAcademyAnimatedSwap({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 180),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (puzzleAcademyShouldReduceEffects(context)) {
      return child;
    }
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class PuzzleAcademyPressable extends StatefulWidget {
  const PuzzleAcademyPressable({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.monochromeOverride,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;
  final bool? monochromeOverride;
  final BorderRadius borderRadius;

  @override
  State<PuzzleAcademyPressable> createState() => _PuzzleAcademyPressableState();
}

class _PuzzleAcademyPressableState extends State<PuzzleAcademyPressable> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool hovered) {
    if (!mounted || widget.onTap == null || _hovered == hovered) {
      return;
    }
    setState(() => _hovered = hovered);
  }

  void _setPressed(bool pressed) {
    if (!mounted || widget.onTap == null || _pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: widget.monochromeOverride,
    );
    final reducedEffects = puzzleAcademyShouldReduceEffects(context);
    final effectiveAccent = widget.accent ?? palette.cyan;
    final slideOffset = reducedEffects
        ? Offset.zero
        : Offset(0, _pressed ? 0.008 : (_hovered ? -0.012 : 0));

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) {
        _setHovered(false);
        _setPressed(false);
      },
      child: AnimatedSlide(
        duration: puzzleAcademyMotionDuration(
          reducedEffects: reducedEffects,
          milliseconds: 150,
        ),
        curve: puzzleAcademyMotionCurve(reducedEffects: reducedEffects),
        offset: slideOffset,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _setPressed,
            borderRadius: widget.borderRadius,
            overlayColor: puzzleAcademyInteractiveOverlay(
              palette: palette,
              accent: effectiveAccent,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class PuzzleAcademyPanel extends StatelessWidget {
  const PuzzleAcademyPanel({
    super.key,
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.fillColor,
    this.borderColor,
    this.radius = 8,
    this.borderWidth = 3,
    this.elevated = true,
    this.monochromeOverride,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? fillColor;
  final Color? borderColor;
  final double radius;
  final double borderWidth;
  final bool elevated;
  final bool? monochromeOverride;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochromeOverride,
    );
    final panel = Container(
      decoration: puzzleAcademyPanelDecoration(
        palette: palette,
        accent: accent,
        fillColor: fillColor,
        borderColor: borderColor,
        radius: radius,
        borderWidth: borderWidth,
        elevated: elevated,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (margin == null) {
      return panel;
    }
    return Padding(padding: margin!, child: panel);
  }
}

class PuzzleAcademyTag extends StatelessWidget {
  const PuzzleAcademyTag({
    super.key,
    required this.label,
    required this.accent,
    this.icon,
    this.foregroundColor,
    this.padding,
    this.radius = 5,
    this.compact = false,
    this.filled = false,
    this.monochromeOverride,
  });

  final String label;
  final Color accent;
  final IconData? icon;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool compact;
  final bool filled;
  final bool? monochromeOverride;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochromeOverride,
    );
    final contentColor = foregroundColor ?? accent;
    return Container(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 4 : 6,
          ),
      decoration: puzzleAcademyTagDecoration(
        palette: palette,
        accent: accent,
        filled: filled,
        radius: radius,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: compact ? 12 : 13, color: contentColor),
                SizedBox(width: compact ? 4 : 6),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: compact ? 10.2 : 10.8,
                  weight: FontWeight.w800,
                  letterSpacing: compact ? 0.82 : 0.95,
                  height: 1.0,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PuzzleAcademySectionHeader extends StatelessWidget {
  const PuzzleAcademySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.accent,
    this.icon,
    this.trailing,
    this.titleColor,
    this.subtitleColor,
    this.titleSize = 14,
    this.subtitleSize = 12.2,
    this.titleWeight = FontWeight.w800,
    this.monochromeOverride,
  });

  final String title;
  final String? subtitle;
  final Color? accent;
  final IconData? icon;
  final Widget? trailing;
  final Color? titleColor;
  final Color? subtitleColor;
  final double titleSize;
  final double subtitleSize;
  final FontWeight titleWeight;
  final bool? monochromeOverride;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochromeOverride,
    );
    final effectiveAccent = accent ?? palette.cyan;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackTrailing = trailing != null && constraints.maxWidth < 220;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (stackTrailing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (icon != null) ...<Widget>[
                        Icon(icon, color: effectiveAccent, size: titleSize + 2),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: puzzleAcademyDisplayStyle(
                            palette: palette,
                            size: titleSize,
                            weight: titleWeight,
                            color: titleColor ?? effectiveAccent,
                            letterSpacing: palette.monochrome ? 0.24 : 0.10,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  trailing!,
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, color: effectiveAccent, size: titleSize + 2),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: puzzleAcademyDisplayStyle(
                        palette: palette,
                        size: titleSize,
                        weight: titleWeight,
                        color: titleColor ?? effectiveAccent,
                        letterSpacing: palette.monochrome ? 0.24 : 0.10,
                        height: 1.0,
                      ),
                    ),
                  ),
                  if (trailing != null) ...<Widget>[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: trailing!,
                      ),
                    ),
                  ],
                ],
              ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: puzzleAcademyCompactStyle(
                  palette: palette,
                  size: subtitleSize,
                  weight: FontWeight.w600,
                  color: subtitleColor ?? palette.textMuted,
                  height: 1.26,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class PuzzleAcademySkeletonBlock extends StatelessWidget {
  const PuzzleAcademySkeletonBlock({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
    this.accent,
    this.monochromeOverride,
  });

  final double? width;
  final double height;
  final double radius;
  final Color? accent;
  final bool? monochromeOverride;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochromeOverride,
    );
    final effectiveAccent = accent ?? palette.line;
    final base = Color.alphaBlend(
      effectiveAccent.withValues(alpha: palette.monochrome ? 0.12 : 0.08),
      palette.panelAlt,
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            base,
            Color.alphaBlend(palette.boardLight.withValues(alpha: 0.10), base),
            base,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: effectiveAccent.withValues(
            alpha: palette.monochrome ? 0.18 : 0.14,
          ),
          width: 1.2,
        ),
      ),
    );
  }
}

class PuzzleAcademySkeletonParagraph extends StatelessWidget {
  const PuzzleAcademySkeletonParagraph({
    super.key,
    this.lines = 3,
    this.lineHeight = 12,
    this.spacing = 8,
    this.lastLineWidthFactor = 0.72,
    this.accent,
    this.monochromeOverride,
  });

  final int lines;
  final double lineHeight;
  final double spacing;
  final double lastLineWidthFactor;
  final Color? accent;
  final bool? monochromeOverride;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(lines, (index) {
            final isLast = index == lines - 1;
            final width = isLast && constraints.maxWidth.isFinite
                ? constraints.maxWidth * lastLineWidthFactor.clamp(0.2, 1.0)
                : null;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == lines - 1 ? 0 : spacing,
              ),
              child: PuzzleAcademySkeletonBlock(
                width: width,
                height: lineHeight,
                accent: accent,
                monochromeOverride: monochromeOverride,
              ),
            );
          }),
        );
      },
    );
  }
}

class PuzzleAcademyDialogShell extends StatelessWidget {
  const PuzzleAcademyDialogShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.accent,
    this.icon,
    this.actions = const <Widget>[],
    this.monochromeOverride,
    this.maxWidth = 620,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Color? accent;
  final IconData? icon;
  final List<Widget> actions;
  final bool? monochromeOverride;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochromeOverride,
    );
    final effectiveAccent = accent ?? palette.cyan;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: puzzleAcademyPanelDecoration(
                palette: palette,
                accent: effectiveAccent,
                fillColor: palette.panel,
                borderColor: effectiveAccent.withValues(alpha: 0.55),
                radius: 10,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: effectiveAccent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: effectiveAccent.withValues(alpha: 0.46),
                                width: 2,
                              ),
                            ),
                            child: Icon(icon, color: effectiveAccent, size: 20),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                title,
                                style: puzzleAcademyDisplayStyle(
                                  palette: palette,
                                  size: 20,
                                  color: effectiveAccent,
                                ),
                              ),
                              if (subtitle != null) ...<Widget>[
                                const SizedBox(height: 8),
                                Text(
                                  subtitle!,
                                  style: puzzleAcademyHudStyle(
                                    palette: palette,
                                    size: 12.2,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    child,
                    if (actions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PuzzleAcademySheetShell extends StatelessWidget {
  const PuzzleAcademySheetShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.accent,
    this.icon,
    this.trailing,
    this.monochromeOverride,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Color? accent;
  final IconData? icon;
  final Widget? trailing;
  final bool? monochromeOverride;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochromeOverride,
    );
    final effectiveAccent = accent ?? palette.cyan;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: puzzleAcademyPanelDecoration(
                palette: palette,
                accent: effectiveAccent,
                fillColor: palette.panel,
                borderColor: effectiveAccent.withValues(alpha: 0.52),
                radius: 10,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (icon != null) ...<Widget>[
                          Icon(icon, color: effectiveAccent, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: puzzleAcademyDisplayStyle(
                              palette: palette,
                              size: 16,
                              color: effectiveAccent,
                            ),
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: puzzleAcademyHudStyle(
                          palette: palette,
                          size: 11.8,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PuzzleAcademyInfoButton extends StatelessWidget {
  const PuzzleAcademyInfoButton({
    super.key,
    required this.title,
    required this.message,
    this.accent,
    this.icon = Icons.info_outline_rounded,
    this.monochromeOverride,
  });

  final String title;
  final String message;
  final Color? accent;
  final IconData icon;
  final bool? monochromeOverride;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochromeOverride,
    );
    final effectiveAccent = accent ?? palette.cyan;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        overlayColor: puzzleAcademyInteractiveOverlay(
          palette: palette,
          accent: effectiveAccent,
        ),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => PuzzleAcademyDialogShell(
              title: title,
              accent: effectiveAccent,
              icon: icon,
              monochromeOverride: monochromeOverride,
              actions: <Widget>[
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: puzzleAcademyFilledButtonStyle(
                    palette: puzzleAcademyPalette(
                      dialogContext,
                      monochromeOverride: monochromeOverride,
                    ),
                    backgroundColor: effectiveAccent,
                    foregroundColor: effectiveAccent.computeLuminance() > 0.55
                        ? const Color(0xFF081015)
                        : Colors.white,
                  ),
                  child: const Text('CLOSE'),
                ),
              ],
              child: Text(
                message,
                style: puzzleAcademyHudStyle(
                  palette: puzzleAcademyPalette(
                    dialogContext,
                    monochromeOverride: monochromeOverride,
                  ),
                  size: 12.2,
                  weight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          );
        },
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: effectiveAccent.withValues(
              alpha: palette.monochrome ? 0.16 : 0.12,
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: effectiveAccent.withValues(alpha: 0.50),
              width: 2,
            ),
          ),
          child: Icon(icon, size: 18, color: effectiveAccent),
        ),
      ),
    );
  }
}
