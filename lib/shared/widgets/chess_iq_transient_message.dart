import 'dart:async';

import 'package:chessiq/features/academy/widgets/puzzle_academy_surface.dart';
import 'package:flutter/material.dart';

class ChessIqTransientMessage {
  ChessIqTransientMessage._();

  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    IconData icon = Icons.info_outline_rounded,
    Color? accent,
    bool emphasizeMessage = false,
    Alignment alignment = const Alignment(0, -0.08),
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    final trimmedMessage = message.trim();
    final trimmedTitle = title?.trim();
    if (trimmedMessage.isEmpty) {
      return;
    }

    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ??
        Navigator.maybeOf(context, rootNavigator: true)?.overlay;
    if (overlay == null) {
      return;
    }

    dismiss();

    final entry = OverlayEntry(
      builder: (overlayContext) => _ChessIqTransientMessageOverlay(
        title: trimmedTitle == null || trimmedTitle.isEmpty
            ? null
            : trimmedTitle,
        message: trimmedMessage,
        icon: icon,
        accent: accent,
        emphasizeMessage: emphasizeMessage,
        alignment: alignment,
        duration: duration,
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration + const Duration(milliseconds: 140), () {
      if (identical(_activeEntry, entry)) {
        dismiss();
      }
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final entry = _activeEntry;
    _activeEntry = null;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }
}

class _ChessIqTransientMessageOverlay extends StatelessWidget {
  const _ChessIqTransientMessageOverlay({
    required this.message,
    required this.icon,
    required this.emphasizeMessage,
    required this.alignment,
    required this.duration,
    this.title,
    this.accent,
  });

  final String? title;
  final String message;
  final IconData icon;
  final Color? accent;
  final bool emphasizeMessage;
  final Alignment alignment;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(context);
    final reducedEffects = puzzleAcademyShouldReduceEffects(context);
    final effectiveAccent = accent ?? palette.cyan;
    final highlightedMessage = title != null && emphasizeMessage;

    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: duration,
            curve: Curves.linear,
            builder: (context, progress, child) {
              final reveal = reducedEffects
                  ? (progress / 0.12).clamp(0.0, 1.0).toDouble()
                  : Curves.easeOutBack.transform(
                      (progress / 0.26).clamp(0.0, 1.0),
                    );
              final fadeOut = Curves.easeIn.transform(
                ((progress - 0.78) / 0.22).clamp(0.0, 1.0),
              );
              final opacity = (reveal * (1.0 - fadeOut)).clamp(0.0, 1.0)
                  .toDouble();
              final rise = reducedEffects ? 0.0 : (1.0 - reveal) * 18.0;
              final scale = reducedEffects ? 1.0 : 0.94 + (reveal * 0.06);

              return Align(
                alignment: alignment,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: Offset(0, rise),
                    child: Transform.scale(scale: scale, child: child),
                  ),
                ),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Material(
                color: Colors.transparent,
                child: PuzzleAcademyPanel(
                  accent: effectiveAccent,
                  radius: 14,
                  borderWidth: 2.6,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (title != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            _ChessIqTransientMessageBadge(
                              icon: icon,
                              accent: effectiveAccent,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                title!,
                                textAlign: TextAlign.center,
                                style: puzzleAcademyHudStyle(
                                  palette: palette,
                                  size: 11.1,
                                  weight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  height: 1.0,
                                  color: effectiveAccent,
                                  withGlow: !reducedEffects,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        _ChessIqTransientMessageBadge(
                          icon: icon,
                          accent: effectiveAccent,
                        ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: puzzleAcademyHudStyle(
                          palette: palette,
                          size: highlightedMessage ? 14.1 : 12.2,
                          weight: highlightedMessage
                              ? FontWeight.w800
                              : FontWeight.w700,
                          letterSpacing: highlightedMessage ? 0.92 : 0.56,
                          height: highlightedMessage ? 1.12 : 1.28,
                          color: highlightedMessage
                              ? effectiveAccent
                              : palette.text,
                          withGlow: highlightedMessage && !reducedEffects,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChessIqTransientMessageBadge extends StatelessWidget {
  const _ChessIqTransientMessageBadge({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = puzzleAcademyPalette(context);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.15),
        border: Border.all(
          color: accent.withValues(alpha: palette.monochrome ? 0.72 : 0.82),
          width: 1.6,
        ),
        boxShadow: puzzleAcademySurfaceGlow(
          accent,
          monochrome: palette.monochrome,
          strength: 0.34,
        ),
      ),
      child: Icon(icon, size: 18, color: accent),
    );
  }
}