import 'package:flutter/material.dart';

/// A move quality marker that maps Stockfish evaluation changes into a
/// human-friendly classification badge.
///
/// The score delta is expected to be measured from the perspective of the
/// player who just moved. Positive values indicate an improvement for the
/// mover; negative values indicate a weakening of the position.
class MoveQualityBadge extends StatelessWidget {
  const MoveQualityBadge({
    super.key,
    required this.playerDeltaCentipawns,
    this.showLabel = true,
  });

  final int playerDeltaCentipawns;
  final bool showLabel;

  static MoveQuality classify(int playerDeltaCentipawns) {
    if (playerDeltaCentipawns >= 250) {
      return MoveQuality.brilliant;
    }
    if (playerDeltaCentipawns >= 160) {
      return MoveQuality.great;
    }
    if (playerDeltaCentipawns >= 100) {
      return MoveQuality.best;
    }
    if (playerDeltaCentipawns >= 60) {
      return MoveQuality.excellent;
    }
    if (playerDeltaCentipawns >= 20) {
      return MoveQuality.good;
    }
    if (playerDeltaCentipawns <= -350) {
      return MoveQuality.blunder;
    }
    if (playerDeltaCentipawns <= -200) {
      return MoveQuality.miss;
    }
    if (playerDeltaCentipawns <= -80) {
      return MoveQuality.mistake;
    }
    if (playerDeltaCentipawns <= -20) {
      return MoveQuality.inaccuracy;
    }
    return MoveQuality.none;
  }

  static String labelFor(MoveQuality quality) {
    switch (quality) {
      case MoveQuality.brilliant:
        return 'Brilliant (!!)';
      case MoveQuality.great:
        return 'Great (!)';
      case MoveQuality.best:
        return 'Best (⭐)';
      case MoveQuality.excellent:
        return 'Excellent (👍)';
      case MoveQuality.good:
        return 'Good (✅)';
      case MoveQuality.inaccuracy:
        return 'Inaccuracy (!?)';
      case MoveQuality.mistake:
        return 'Mistake (?)';
      case MoveQuality.miss:
        return 'Miss';
      case MoveQuality.blunder:
        return 'Blunder (??)';
      case MoveQuality.none:
        return '';
    }
  }

  static Color colorFor(MoveQuality quality) {
    switch (quality) {
      case MoveQuality.brilliant:
        return const Color(0xFFFFD700);
      case MoveQuality.great:
        return const Color(0xFF9C27B0);
      case MoveQuality.best:
        return const Color(0xFF03A9F4);
      case MoveQuality.excellent:
        return const Color(0xFF4CAF50);
      case MoveQuality.good:
        return const Color(0xFF8BC34A);
      case MoveQuality.inaccuracy:
        return const Color(0xFFFFC107);
      case MoveQuality.mistake:
        return const Color(0xFFFF9800);
      case MoveQuality.miss:
        return const Color(0xFFFF5722);
      case MoveQuality.blunder:
        return const Color(0xFFF44336);
      case MoveQuality.none:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quality = classify(playerDeltaCentipawns);
    if (quality == MoveQuality.none) {
      return const SizedBox.shrink();
    }

    final label = labelFor(quality);
    final color = colorFor(quality);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        showLabel ? label : _symbolFor(quality),
        style: TextStyle(
          color: color.darken(0.16),
          fontWeight: FontWeight.w700,
          fontSize: 12.0,
        ),
      ),
    );
  }

  static String _symbolFor(MoveQuality quality) {
    switch (quality) {
      case MoveQuality.brilliant:
        return '!!';
      case MoveQuality.great:
        return '!';
      case MoveQuality.best:
        return '⭐';
      case MoveQuality.excellent:
        return '👍';
      case MoveQuality.good:
        return '✅';
      case MoveQuality.inaccuracy:
        return '!?';
      case MoveQuality.mistake:
        return '?';
      case MoveQuality.miss:
        return 'Miss';
      case MoveQuality.blunder:
        return '??';
      case MoveQuality.none:
        return '';
    }
  }
}

enum MoveQuality {
  brilliant,
  great,
  best,
  excellent,
  good,
  inaccuracy,
  mistake,
  miss,
  blunder,
  none,
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
