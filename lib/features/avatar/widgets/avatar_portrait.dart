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
            return _GeneratedAvatarPortrait(
              avatar: avatar,
              size: size,
              radius: radius - 2,
            );
          },
        ),
      ),
    );
  }
}

class _GeneratedAvatarPortrait extends StatelessWidget {
  const _GeneratedAvatarPortrait({
    required this.avatar,
    required this.size,
    required this.radius,
  });

  final AvatarCatalogEntry avatar;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hash = _stableAvatarHash(avatar.id);
    final base = _generatedAvatarPalette[hash % _generatedAvatarPalette.length];
    final accent = _avatarBucketAccent(avatar.bucket, scheme);
    final secondary = Color.lerp(base, accent, 0.42)!;
    final initials = _avatarInitials(avatar.name);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(base, Colors.white, 0.14)!,
            secondary,
            Color.lerp(base, Colors.black, 0.32)!,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(
            painter: _GeneratedAvatarPatternPainter(
              hash: hash,
              accent: accent.withValues(alpha: 0.58),
              foreground: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Center(
            child: Container(
              width: size * 0.54,
              height: size * 0.54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.34),
                  width: size * 0.025,
                ),
              ),
              child: Text(
                initials,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * (initials.length > 1 ? 0.23 : 0.30),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  shadows: <Shadow>[
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: size * 0.12,
            right: size * 0.12,
            bottom: size * 0.09,
            child: Container(
              height: size * 0.045,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: accent.withValues(alpha: 0.58),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedAvatarPatternPainter extends CustomPainter {
  const _GeneratedAvatarPatternPainter({
    required this.hash,
    required this.accent,
    required this.foreground,
  });

  final int hash;
  final Color accent;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = foreground;
    final large = size.shortestSide;
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.18),
      large * 0.24,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.82),
      large * 0.28,
      paint,
    );

    paint
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = large * 0.045;
    final inset = large * (0.13 + ((hash % 5) * 0.015));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          inset,
          inset,
          size.width - inset * 2,
          size.height - inset * 2,
        ),
        Radius.circular(large * 0.18),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GeneratedAvatarPatternPainter oldDelegate) {
    return oldDelegate.hash != hash ||
        oldDelegate.accent != accent ||
        oldDelegate.foreground != foreground;
  }
}

const List<Color> _generatedAvatarPalette = <Color>[
  Color(0xFF255C7A),
  Color(0xFF4D6E38),
  Color(0xFF7C4A2D),
  Color(0xFF65448A),
  Color(0xFF86622D),
  Color(0xFF2F726A),
  Color(0xFF7B3D55),
  Color(0xFF355A9A),
];

Color _avatarBucketAccent(AvatarRarityBucket bucket, ColorScheme scheme) {
  switch (bucket) {
    case AvatarRarityBucket.normal:
      return const Color(0xFF8BB9F4);
    case AvatarRarityBucket.rare:
      return const Color(0xFF58D6A9);
    case AvatarRarityBucket.epic:
      return const Color(0xFFC486F7);
    case AvatarRarityBucket.legendary:
      return const Color(0xFFFFD45C);
    case AvatarRarityBucket.promo:
      return scheme.primary;
  }
}

int _stableAvatarHash(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }
  return hash;
}

String _avatarInitials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'[^A-Za-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) {
    return '?';
  }
  if (words.length == 1) {
    final word = words.first;
    final first = word.characters.first.toUpperCase();
    final second = word.characters.length > 1
        ? word.characters.elementAt(1).toUpperCase()
        : '';
    return '$first$second';
  }
  return '${words.first.characters.first}${words.last.characters.first}'
      .toUpperCase();
}
