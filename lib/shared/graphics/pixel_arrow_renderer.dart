import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PixelArrowRenderer {
  static final _PixelArrowAssetNotifier _assetNotifier =
      _PixelArrowAssetNotifier();
  static final Map<_PixelArrowHeadDirection, _PixelArrowHeadSprite>
  _headSprites = <_PixelArrowHeadDirection, _PixelArrowHeadSprite>{};
  static Future<void>? _loadingSpritesFuture;

  static Listenable get repaintListenable => _assetNotifier;

  static void paint({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required double pixelSize,
    required Color color,
    double alphaScale = 1.0,
    bool animatePulse = false,
    double progress = 0.0,
  }) {
    _ensureHeadSpritesLoaded();

    final snappedStart = _snapToCellCenter(start, pixelSize);
    final snappedEnd = _snapToCellCenter(end, pixelSize);
    final direction = snappedEnd - snappedStart;
    final length = direction.distance;
    if (length <= pixelSize * 5) {
      return;
    }

    final unit = direction / length;
    final headDirection = _PixelArrowHeadDirection.fromOffset(direction);
    final headSprite = _headSprites[headDirection];
    final diagonalLineInflate = headDirection.isDiagonal
        ? pixelSize * 0.125
        : 0.0;

    final outlineColor = _darkenColor(
      color,
      0.76,
    ).withValues(alpha: max(0.84, alphaScale));
    final topLightColor = _lightenColor(
      color,
      0.24,
    ).withValues(alpha: alphaScale);
    final bodyColor = color.withValues(alpha: alphaScale);
    final shadowColor = _darkenColor(color, 0.18).withValues(alpha: alphaScale);
    final pulseColor = _lightenColor(
      color,
      0.56,
    ).withValues(alpha: min(1.0, 0.72 * alphaScale));
    final headTintColor = _lightenColor(
      color,
      0.10,
    ).withValues(alpha: alphaScale);

    final fillCells = <Point<int>, _PixelCellPaint>{};
    final shaftEnd = _shaftEndForHead(
      start: snappedStart,
      end: snappedEnd,
      pixelSize: pixelSize,
      unit: unit,
      direction: headDirection,
      headSprite: headSprite,
    );
    final shaftCells = _rasterizeLine(
      start: snappedStart,
      end: shaftEnd,
      pixelSize: pixelSize,
    );

    for (var index = 0; index < shaftCells.length; index++) {
      final t = shaftCells.length <= 1 ? 0.0 : index / (shaftCells.length - 1);
      final shade = t < 0.22
          ? Color.lerp(topLightColor, bodyColor, min(1.0, t / 0.22))!
          : (t > 0.84 ? shadowColor : bodyColor);
      fillCells[shaftCells[index]] = _PixelCellPaint(
        color: shade,
        progressT: t,
      );
    }

    if (fillCells.isEmpty) {
      fillCells[_worldToCell(snappedStart, pixelSize)] = const _PixelCellPaint(
        color: Colors.white,
        progressT: 0.0,
      );
    }

    final outlineCells = <Point<int>>{};
    for (final key in fillCells.keys) {
      for (final neighbor in _cardinalNeighbors) {
        final edge = Point<int>(key.x + neighbor.x, key.y + neighbor.y);
        if (!fillCells.containsKey(edge)) {
          outlineCells.add(edge);
        }
      }
    }

    final pulseCells = <Point<int>, Color>{};
    final pulseCoreCells = <Point<int>, Color>{};
    final pulseAuraCells = <Point<int>, Color>{};
    if (animatePulse) {
      const pulseReach = 0.28;
      const pulseCoreReach = 0.12;
      final pulseTravel = 1.0 + (pulseReach * 2);
      final pulseCenter = (-pulseReach) + (pulseTravel * (progress % 1.0));
      for (final entry in fillCells.entries) {
        final distanceFromCenter = (entry.value.progressT - pulseCenter).abs();
        final glowIntensity = 1.0 - (distanceFromCenter / pulseReach);
        if (glowIntensity <= 0) {
          continue;
        }

        pulseCells[entry.key] = Color.lerp(
          entry.value.color,
          pulseColor,
          glowIntensity.clamp(0.0, 1.0) * 0.92,
        )!;

        final coreIntensity = 1.0 - (distanceFromCenter / pulseCoreReach);
        if (coreIntensity > 0) {
          pulseCoreCells[entry.key] = Colors.white.withValues(
            alpha: coreIntensity.clamp(0.0, 1.0) * 0.88 * alphaScale,
          );

          for (final neighbor in _cardinalNeighbors) {
            final edge = Point<int>(
              entry.key.x + neighbor.x,
              entry.key.y + neighbor.y,
            );
            if (fillCells.containsKey(edge)) {
              continue;
            }
            final existingAura = pulseAuraCells[edge];
            final auraAlpha = coreIntensity.clamp(0.0, 1.0) * 0.22 * alphaScale;
            if (existingAura == null || auraAlpha > existingAura.a) {
              pulseAuraCells[edge] = pulseColor.withValues(alpha: auraAlpha);
            }
          }
        }
      }
    }

    void drawCell(Point<int> cell, Color shade, {double inflate = 0.0}) {
      canvas.drawRect(
        Rect.fromLTWH(
          cell.x.toDouble() * pixelSize - inflate,
          cell.y.toDouble() * pixelSize - inflate,
          pixelSize + (inflate * 2),
          pixelSize + (inflate * 2),
        ),
        Paint()
          ..color = shade
          ..style = PaintingStyle.fill
          ..isAntiAlias = false,
      );
    }

    for (final cell in outlineCells) {
      drawCell(cell, outlineColor, inflate: diagonalLineInflate);
    }
    for (final entry in fillCells.entries) {
      drawCell(entry.key, entry.value.color, inflate: diagonalLineInflate);
    }
    for (final entry in pulseCells.entries) {
      drawCell(entry.key, entry.value, inflate: diagonalLineInflate);
    }
    for (final entry in pulseAuraCells.entries) {
      drawCell(entry.key, entry.value, inflate: diagonalLineInflate);
    }
    for (final entry in pulseCoreCells.entries) {
      drawCell(entry.key, entry.value, inflate: diagonalLineInflate);
    }

    if (headSprite != null) {
      _paintHeadSprite(
        canvas: canvas,
        end: snappedEnd,
        pixelSize: pixelSize,
        direction: headDirection,
        headSprite: headSprite,
        color: headTintColor,
      );
    }
  }

  static Color _lightenColor(Color color, double amount) {
    return Color.lerp(color, Colors.white, amount.clamp(0.0, 1.0))!;
  }

  static Color _darkenColor(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount.clamp(0.0, 1.0))!;
  }

  static Offset _snapToCellCenter(Offset point, double pixelSize) {
    return Offset(
      (point.dx / pixelSize).roundToDouble() * pixelSize + (pixelSize / 2),
      (point.dy / pixelSize).roundToDouble() * pixelSize + (pixelSize / 2),
    );
  }

  static void _ensureHeadSpritesLoaded() {
    if (_headSprites.length == _PixelArrowHeadDirection.values.length) {
      return;
    }
    _loadingSpritesFuture ??= _loadHeadSprites();
  }

  static Future<void> _loadHeadSprites() async {
    try {
      final sprites = await Future.wait<_PixelArrowHeadSprite>(
        _PixelArrowHeadDirection.values.map(_loadHeadSprite),
      );
      for (
        var index = 0;
        index < _PixelArrowHeadDirection.values.length;
        index++
      ) {
        _headSprites[_PixelArrowHeadDirection.values[index]] = sprites[index];
      }
      _assetNotifier.markUpdated();
    } catch (error) {
      debugPrint('Failed to load pixel arrowhead sprites: $error');
    } finally {
      _loadingSpritesFuture = null;
    }
  }

  static Future<_PixelArrowHeadSprite> _loadHeadSprite(
    _PixelArrowHeadDirection direction,
  ) async {
    final byteData = await rootBundle.load(direction.assetPath);
    final bytes = byteData.buffer.asUint8List(
      byteData.offsetInBytes,
      byteData.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();

    final image = frame.image;
    final rawBytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rawBytes == null) {
      throw StateError(
        'Could not read raw RGBA bytes for ${direction.assetPath}.',
      );
    }

    final metrics = _measureHeadSprite(
      rgbaBytes: rawBytes.buffer.asUint8List(
        rawBytes.offsetInBytes,
        rawBytes.lengthInBytes,
      ),
      width: image.width,
      height: image.height,
      directionVector: direction.vector,
    );
    return _PixelArrowHeadSprite(
      image: image,
      tip: metrics.tip,
      tipToBackDistance: metrics.tipToBackDistance,
    );
  }

  static _PixelArrowHeadMetrics _measureHeadSprite({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    required Offset directionVector,
  }) {
    const alphaThreshold = 12;
    const epsilon = 0.0001;
    var maxProjection = double.negativeInfinity;
    var minProjection = double.infinity;
    final tipPixels = <Offset>[];
    final backPixels = <Offset>[];

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixelOffset = ((y * width) + x) * 4;
        final alpha = rgbaBytes[pixelOffset + 3];
        if (alpha <= alphaThreshold) {
          continue;
        }

        final pixelCenter = Offset(x + 0.5, y + 0.5);
        final projection =
            (pixelCenter.dx * directionVector.dx) +
            (pixelCenter.dy * directionVector.dy);

        if (projection > maxProjection + epsilon) {
          maxProjection = projection;
          tipPixels
            ..clear()
            ..add(pixelCenter);
        } else if ((projection - maxProjection).abs() <= epsilon) {
          tipPixels.add(pixelCenter);
        }

        if (projection < minProjection - epsilon) {
          minProjection = projection;
          backPixels
            ..clear()
            ..add(pixelCenter);
        } else if ((projection - minProjection).abs() <= epsilon) {
          backPixels.add(pixelCenter);
        }
      }
    }

    if (tipPixels.isEmpty || backPixels.isEmpty) {
      throw StateError('Arrowhead sprite has no opaque pixels.');
    }

    return _PixelArrowHeadMetrics(
      tip: _averageOffset(tipPixels),
      tipToBackDistance: max(1.0, maxProjection - minProjection),
    );
  }

  static Offset _averageOffset(List<Offset> points) {
    var sumX = 0.0;
    var sumY = 0.0;
    for (final point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }
    return Offset(sumX / points.length, sumY / points.length);
  }

  static Offset _shaftEndForHead({
    required Offset start,
    required Offset end,
    required double pixelSize,
    required Offset unit,
    required _PixelArrowHeadDirection direction,
    required _PixelArrowHeadSprite? headSprite,
  }) {
    if (headSprite == null) {
      return end;
    }

    final baseDistance =
        headSprite.tipToBackDistance *
        _headScale(direction, headSprite, pixelSize);
    final totalLength = (end - start).distance;
    final isShortDiagonal =
        direction.isDiagonal && totalLength <= pixelSize * 20.0;
    final clampedDistance = min(
      totalLength - pixelSize,
      max(pixelSize * 1.8, baseDistance),
    );
    final headOverlap = isShortDiagonal ? pixelSize * 1.55 : pixelSize * 0.30;
    return end - (unit * max(pixelSize, clampedDistance - headOverlap));
  }

  static double _headScale(
    _PixelArrowHeadDirection direction,
    _PixelArrowHeadSprite headSprite,
    double pixelSize,
  ) {
    final desiredHeadCells = direction.isDiagonal ? 3.9 : 4.4;
    return (pixelSize * desiredHeadCells) /
        max(1.0, headSprite.tipToBackDistance);
  }

  static List<Point<int>> _rasterizeLine({
    required Offset start,
    required Offset end,
    required double pixelSize,
  }) {
    final startCell = _worldToCell(start, pixelSize);
    final endCell = _worldToCell(end, pixelSize);
    final cells = <Point<int>>[];

    var x0 = startCell.x;
    var y0 = startCell.y;
    final x1 = endCell.x;
    final y1 = endCell.y;
    final dx = (x1 - x0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final dy = -(y1 - y0).abs();
    final sy = y0 < y1 ? 1 : -1;
    var error = dx + dy;

    while (true) {
      final point = Point<int>(x0, y0);
      if (cells.isEmpty || cells.last != point) {
        cells.add(point);
      }
      if (x0 == x1 && y0 == y1) {
        break;
      }
      final doubleError = error * 2;
      if (doubleError >= dy) {
        error += dy;
        x0 += sx;
      }
      if (doubleError <= dx) {
        error += dx;
        y0 += sy;
      }
    }

    return cells;
  }

  static Point<int> _worldToCell(Offset point, double pixelSize) {
    return Point<int>(
      ((point.dx - (pixelSize / 2)) / pixelSize).round(),
      ((point.dy - (pixelSize / 2)) / pixelSize).round(),
    );
  }

  static void _paintHeadSprite({
    required Canvas canvas,
    required Offset end,
    required double pixelSize,
    required _PixelArrowHeadDirection direction,
    required _PixelArrowHeadSprite headSprite,
    required Color color,
  }) {
    final scale = _headScale(direction, headSprite, pixelSize);
    final destinationRect = Rect.fromLTWH(
      end.dx - (headSprite.tip.dx * scale),
      end.dy - (headSprite.tip.dy * scale),
      headSprite.image.width * scale,
      headSprite.image.height * scale,
    );
    canvas.drawImageRect(
      headSprite.image,
      Rect.fromLTWH(
        0,
        0,
        headSprite.image.width.toDouble(),
        headSprite.image.height.toDouble(),
      ),
      destinationRect,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false
        ..colorFilter = ColorFilter.mode(color, BlendMode.modulate),
    );
  }

  static const List<Point<int>> _cardinalNeighbors = <Point<int>>[
    Point<int>(-1, 0),
    Point<int>(1, 0),
    Point<int>(0, -1),
    Point<int>(0, 1),
  ];
}

class _PixelArrowAssetNotifier extends ChangeNotifier {
  void markUpdated() {
    notifyListeners();
  }
}

class _PixelArrowHeadMetrics {
  const _PixelArrowHeadMetrics({
    required this.tip,
    required this.tipToBackDistance,
  });

  final Offset tip;
  final double tipToBackDistance;
}

class _PixelArrowHeadSprite {
  const _PixelArrowHeadSprite({
    required this.image,
    required this.tip,
    required this.tipToBackDistance,
  });

  final ui.Image image;
  final Offset tip;
  final double tipToBackDistance;
}

enum _PixelArrowHeadDirection {
  down('assets/arrows/8-bit_1_1.png', Offset(0, 1)),
  left('assets/arrows/8-bit_1_2.png', Offset(-1, 0)),
  up('assets/arrows/8-bit_1_3.png', Offset(0, -1)),
  right('assets/arrows/8-bit_1_4.png', Offset(1, 0)),
  downLeft('assets/arrows/8-bit_2_1.png', Offset(-0.70710678, 0.70710678)),
  upLeft('assets/arrows/8-bit_2_2.png', Offset(-0.70710678, -0.70710678)),
  upRight('assets/arrows/8-bit_2_3.png', Offset(0.70710678, -0.70710678)),
  downRight('assets/arrows/8-bit_2_4.png', Offset(0.70710678, 0.70710678));

  const _PixelArrowHeadDirection(this.assetPath, this.vector);

  final String assetPath;
  final Offset vector;

  bool get isDiagonal =>
      this == downLeft ||
      this == upLeft ||
      this == upRight ||
      this == downRight;

  static _PixelArrowHeadDirection fromOffset(Offset direction) {
    final angle = atan2(direction.dy, direction.dx);
    final octant = ((angle + (pi / 8)) / (pi / 4)).floor();
    switch ((octant % 8 + 8) % 8) {
      case 0:
        return right;
      case 1:
        return downRight;
      case 2:
        return down;
      case 3:
        return downLeft;
      case 4:
        return left;
      case 5:
        return upLeft;
      case 6:
        return up;
      case 7:
        return upRight;
    }
    return right;
  }
}

class _PixelCellPaint {
  const _PixelCellPaint({required this.color, required this.progressT});

  final Color color;
  final double progressT;
}
