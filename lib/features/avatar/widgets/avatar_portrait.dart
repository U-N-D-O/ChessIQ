import 'package:chessiq/features/avatar/models/avatar_catalog.dart';
import 'package:flutter/material.dart';

class AvatarPortrait extends StatelessWidget {
  const AvatarPortrait({
    super.key,
    required this.avatar,
    this.size = 88,
    this.radius = 22,
    this.borderColor,
    this.borderWidth = 1.8,
    this.backgroundColor,
    this.showShadow = true,
  });

  final AvatarCatalogEntry avatar;
  final double size;
  final double radius;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedBorderColor =
        borderColor ?? scheme.primary.withValues(alpha: 0.24);
    final resolvedBackgroundColor =
        backgroundColor ??
        Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.05),
          scheme.surface,
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedBackgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: resolvedBorderColor, width: borderWidth),
        boxShadow: showShadow
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 2),
        child: Image.asset(
          avatar.assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.account_circle_rounded,
              color: scheme.onSurface.withValues(alpha: 0.52),
              size: size * 0.54,
            );
          },
        ),
      ),
    );
  }
}
