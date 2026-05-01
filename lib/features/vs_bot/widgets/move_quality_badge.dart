import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/analysis/models/move_quality.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Presentation-only badge for a previously classified move quality.
class MoveQualityBadge extends StatelessWidget {
  const MoveQualityBadge({
    super.key,
    required this.quality,
    this.showLabel = true,
  });

  final MoveQuality? quality;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final quality = this.quality;
    if (quality == null) {
      return const SizedBox.shrink();
    }

    final presentation = quality.presentation;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final useMonochrome = context.watch<AppThemeProvider>().isMonochrome;
    final assessmentColor = presentation.color;
    final shellColor = useMonochrome
        ? Color.alphaBlend(
            scheme.onSurface.withValues(alpha: isLight ? 0.06 : 0.12),
            scheme.surface,
          )
        : assessmentColor.withValues(alpha: 0.14);
    final borderColor = useMonochrome
        ? scheme.onSurface.withValues(alpha: isLight ? 0.18 : 0.28)
        : assessmentColor.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: shellColor,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        showLabel ? presentation.badgeLabel : presentation.displaySymbol,
        style: TextStyle(
          color: useMonochrome ? assessmentColor : assessmentColor.darken(0.16),
          fontWeight: FontWeight.w700,
          fontSize: 12.0,
        ),
      ),
    );
  }
}

extension _ColorBrightnessExtension on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
