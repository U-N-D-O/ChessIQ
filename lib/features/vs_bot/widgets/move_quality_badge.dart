import 'package:flutter/material.dart';
import 'package:chessiq/features/analysis/models/move_quality.dart';

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
    final color = presentation.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        showLabel ? presentation.badgeLabel : presentation.displaySymbol,
        style: TextStyle(
          color: color.darken(0.16),
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
