// ignore_for_file: unused_element, unnecessary_overrides

part of '../../analysis/screens/chess_analysis_page.dart';

mixin _VsBotState on _ChessAnalysisPageStateCore {
  final GlobalKey _botAvatarKey = GlobalKey();
  Timer? _botSpeechTypeTimer;
  Timer? _botSpeechHideTimer;
  String? _botSpeechFullText;
  String _botSpeechVisibleText = '';
  int _botSpeechVersion = 0;

  @override
  Key? get _botAvatarWidgetKey => _botAvatarKey;

  @override
  String get _introSoundAssetPath =>
      _playVsBot ? 'sounds/vs.mp3' : super._introSoundAssetPath;

  @override
  double get _botAvatarIntroArrivalProgress => 0.69;

  @override
  double get _botAvatarIntroOpacity {
    if (!_playVsBot || _introCompleted) {
      return 1.0;
    }
    return 0.0;
  }

  @override
  bool get _botAvatarOverlayOnRight => true;

  @override
  Widget _buildBotAvatarOverlay(double scale) {
    return const SizedBox.shrink();
  }

  @override
  Widget _wrapBotAvatarInteractive(double scale, Widget child) {
    return child;
  }

  @override
  Widget _buildTopMostOverlay(Size scene, double scale) {
    final full = _botSpeechFullText;
    if (full == null || full.isEmpty) {
      return const SizedBox.shrink();
    }

    final center = _botAvatarCenterInScene();
    if (center == null) {
      return const SizedBox.shrink();
    }

    final left = (center.dx + (26 * scale)).clamp(
      8.0,
      max(8.0, scene.width - (228 * scale)),
    );
    final top = (center.dy - (20 * scale)).clamp(
      6.0,
      max(6.0, scene.height - (56 * scale)),
    );

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: IgnorePointer(child: _buildBotSpeechBubble(scale)),
    );
  }

  @override
  Widget _buildSceneIntroOverlay(Size scene, double scale) {
    if (_playVsBot) {
      return _buildVsBotIntroOverlay(scene, scale);
    }
    return super._buildSceneIntroOverlay(scene, scale);
  }

  @override
  void _clearVsBotOverlayState() {
    _clearBotSpeechState();
    super._clearVsBotOverlayState();
  }

  Offset? _botAvatarCenterInScene() {
    final avatarContext = _botAvatarKey.currentContext;
    final sceneContext = _sceneKey.currentContext;
    if (avatarContext == null || sceneContext == null) {
      return null;
    }

    final avatarBox = _renderBoxFromContext(avatarContext);
    final sceneBox = _renderBoxFromContext(sceneContext);
    if (avatarBox == null || sceneBox == null) {
      return null;
    }

    return sceneBox.globalToLocal(
      avatarBox.localToGlobal(avatarBox.size.center(Offset.zero)),
    );
  }

  Offset? _vsBotIntroAvatarTarget(Size scene) {
    if (scene.width > scene.height) {
      return _squareCenterInScene(_humanPlaysWhite ? 'e8' : 'e1');
    }
    return _botAvatarCenterInScene();
  }

  Widget _buildVsBotIntroAvatar(BotCharacter bot, double size) {
    final avatarAsset = bot.avatarAssetFor(_selectedBotDifficulty);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFA2A2).withValues(alpha: 0.92),
          width: max(1.6, size * 0.038),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D4D).withValues(alpha: 0.34),
            blurRadius: size * 0.34,
            spreadRadius: size * 0.018,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarAsset != null
            ? Image.asset(avatarAsset, fit: BoxFit.cover)
            : Container(
                color: const Color(0xFF230B0B),
                alignment: Alignment.center,
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: const Color(0xFFFFB3B3),
                  size: size * 0.52,
                ),
              ),
      ),
    );
  }

  Widget _buildVsBotIntroOverlay(Size scene, double scale) {
    final bot = _selectedBot;
    if (bot == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        final t = _introController.value.clamp(0.0, 1.0);
        final fade = 1.0 - ((t - 0.80) / 0.15).clamp(0.0, 1.0);
        final baseCenter = Offset(scene.width * 0.5, scene.height * 0.42);
        final impactT = Curves.easeOut.transform(
          ((t - 0.28) / 0.12).clamp(0.0, 1.0),
        );
        final impactShake =
            sin(impactT * pi * 9.0) * (1.0 - impactT) * (12 * scale);
        final center = baseCenter.translate(impactShake, 0);
        final glyphSize = 76.0 * scale;
        final hazeOpacity = ((t - 0.06) / 0.18).clamp(0.0, 1.0) * fade;
        final impactFlash = sin(impactT * pi).clamp(0.0, 1.0);
        final shockwaveT = ((t - 0.27) / 0.34).clamp(0.0, 1.0);
        final exitLiftT = Curves.easeIn.transform(
          ((t - 0.80) / 0.15).clamp(0.0, 1.0),
        );
        final glyphEntryT = Curves.easeOutBack.transform(
          (t / 0.26).clamp(0.0, 1.0),
        );
        final glyphSettleT = Curves.easeInOut.transform(
          ((t - 0.20) / 0.14).clamp(0.0, 1.0),
        );
        final vOffset = Offset.lerp(
          Offset(-glyphSize * 1.9, -glyphSize * 1.4),
          Offset(-34 * scale, -2 * scale),
          glyphEntryT,
        )!;
        final sOffset = Offset.lerp(
          Offset(scene.width + glyphSize * 0.9, scene.height + glyphSize * 0.7),
          Offset(34 * scale, 2 * scale),
          glyphEntryT,
        )!;
        final vRotation = ui.lerpDouble(-1.30, -0.08, glyphSettleT)!;
        final sRotation = ui.lerpDouble(1.30, 0.08, glyphSettleT)!;
        final cinematicPulse = sin(impactT * pi) * 0.12;
        final coreScale =
            0.88 +
            (0.12 * glyphSettleT) +
            (0.11 * (1.0 - impactT)) +
            cinematicPulse;
        final glyphGlow =
            ui.lerpDouble(16 * scale, 38 * scale, impactFlash) ?? 16 * scale;
        final glyphTrailOpacity =
            ((1.0 - glyphSettleT) * 0.32 + impactFlash * 0.18) * fade;
        final avatarRevealT = Curves.easeOutBack.transform(
          ((t - 0.30) / 0.12).clamp(0.0, 1.0),
        );
        final avatarTravelT = Curves.easeInOutCubic.transform(
          ((t - 0.48) / 0.30).clamp(0.0, 1.0),
        );
        final avatarStart = center + Offset(92 * scale, 6 * scale);
        final avatarTarget =
            _vsBotIntroAvatarTarget(scene) ??
            Offset(scene.width - (34 * scale), scene.height * 0.78);
        final avatarBase = Offset.lerp(
          avatarStart,
          avatarTarget,
          avatarTravelT,
        )!;
        final avatarArcLift = sin(pi * avatarTravelT) * (54 * scale);
        final avatarPosition = avatarBase.translate(0, -avatarArcLift);
        final avatarSize = ui.lerpDouble(
          64 * scale,
          34 * scale,
          avatarTravelT,
        )!;
        final avatarRotation = ui.lerpDouble(0.26, 0.0, avatarTravelT)!;
        final avatarOpacity = ((t - 0.32) / 0.08).clamp(0.0, 1.0) * fade;
        final glyphYOffset = -16 * scale * exitLiftT;

        Widget buildGlyph(String glyph, Offset offset, double rotation) {
          final glyphLeft = center.dx + offset.dx - (glyphSize * 0.28);
          final glyphTop =
              center.dy + offset.dy - (glyphSize * 0.62) + glyphYOffset;

          Widget glowText(double fontScale, Color color, double blur) {
            return Text(
              glyph,
              style: GoogleFonts.orbitron(
                fontSize: glyphSize * fontScale,
                fontWeight: FontWeight.w900,
                height: 0.84,
                color: color,
                shadows: [
                  Shadow(
                    color: color.withValues(alpha: 0.95),
                    blurRadius: blur,
                  ),
                ],
              ),
            );
          }

          return Positioned(
            left: glyphLeft,
            top: glyphTop,
            child: Opacity(
              opacity: fade,
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: coreScale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: 0.44 * fade,
                        child: Transform.scale(
                          scale: 1.28 + (impactFlash * 0.16),
                          child: glowText(
                            1.0,
                            const Color(0xFFFF5A5A),
                            glyphGlow * 1.1,
                          ),
                        ),
                      ),
                      if (glyphTrailOpacity > 0.01)
                        Opacity(
                          opacity: glyphTrailOpacity,
                          child: Transform.translate(
                            offset: Offset(
                              glyph == 'V' ? -14 * scale : 14 * scale,
                              10 * scale,
                            ),
                            child: glowText(
                              0.98,
                              const Color(0xFFFF1F1F),
                              glyphGlow * 0.85,
                            ),
                          ),
                        ),
                      glowText(
                        1.0,
                        const Color(0xFFFFC3C3).withValues(alpha: 0.82),
                        glyphGlow * 0.34,
                      ),
                      Text(
                        glyph,
                        style: GoogleFonts.orbitron(
                          fontSize: glyphSize,
                          fontWeight: FontWeight.w900,
                          height: 0.84,
                          color: const Color(0xFFFF2F2F),
                          shadows: [
                            Shadow(
                              color: const Color(
                                0xFFFF2F2F,
                              ).withValues(alpha: 0.95),
                              blurRadius: glyphGlow * 0.42,
                            ),
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.42),
                              blurRadius: 10 * scale,
                              offset: Offset(0, 5 * scale),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return IgnorePointer(
          child: Opacity(
            opacity: fade,
            child: SizedBox(
              width: scene.width,
              height: scene.height,
              child: Stack(
                children: [
                  Positioned(
                    left: center.dx - (scene.width * 0.40),
                    top: center.dy - (scene.width * 0.40) + glyphYOffset,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: hazeOpacity,
                        child: Transform.scale(
                          scaleY: 0.70,
                          child: Container(
                            width: scene.width * 0.80,
                            height: scene.width * 0.80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(
                                    0xFFFF4A4A,
                                  ).withValues(alpha: 0.34),
                                  const Color(
                                    0xFFFF1C1C,
                                  ).withValues(alpha: 0.14),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.52, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: center.dx - (72 * scale * shockwaveT) - (20 * scale),
                    top:
                        center.dy -
                        (72 * scale * shockwaveT) -
                        (20 * scale) +
                        glyphYOffset,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1.0 - shockwaveT) * 0.55 * fade,
                        child: Container(
                          width: 40 * scale + (144 * scale * shockwaveT),
                          height: 40 * scale + (144 * scale * shockwaveT),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFFFFB0B0,
                              ).withValues(alpha: 0.55),
                              width: max(
                                1.4,
                                3.6 * scale * (1.0 - shockwaveT * 0.45),
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF3B3B,
                                ).withValues(alpha: 0.24),
                                blurRadius: 24 * scale,
                                spreadRadius: 4 * scale,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: center.dx - (80 * scale),
                    top: center.dy - (46 * scale) + glyphYOffset,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: impactFlash * 0.30 * fade,
                        child: Transform.scale(
                          scaleY: 0.58,
                          child: Container(
                            width: 160 * scale,
                            height: 160 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(
                                    0xFFFFE0E0,
                                  ).withValues(alpha: 0.58),
                                  const Color(
                                    0xFFFF9090,
                                  ).withValues(alpha: 0.20),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.32, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  buildGlyph('V', vOffset, vRotation),
                  buildGlyph('S', sOffset, sRotation),
                  Positioned(
                    left: avatarPosition.dx - (avatarSize / 2),
                    top: avatarPosition.dy - (avatarSize / 2),
                    child: Opacity(
                      opacity: avatarOpacity,
                      child: Transform.rotate(
                        angle: avatarRotation,
                        child: Transform.scale(
                          scale: max(0.25, avatarRevealT),
                          child: _buildVsBotIntroAvatar(bot, avatarSize),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void _recordVsBotSessionResult(GameOutcome outcome) {
    super._recordVsBotSessionResult(outcome);
  }

  void _clearBotSpeechState() {
    _botSpeechTypeTimer?.cancel();
    _botSpeechTypeTimer = null;
    _botSpeechHideTimer?.cancel();
    _botSpeechHideTimer = null;
    _botSpeechFullText = null;
    _botSpeechVisibleText = '';
    _botSpeechVersion += 1;
  }

  String _pieceLabelForBotSpeech(String pieceCode) {
    switch (pieceCode[0]) {
      case 'p':
        return 'pawn';
      case 'n':
        return 'knight';
      case 'b':
        return 'bishop';
      case 't':
        return 'rook';
      case 'q':
        return 'queen';
      case 'k':
        return 'king';
      default:
        return 'piece';
    }
  }

  String _buildContextualBotSpeech(BotCharacter bot) {
    final humanToMove = _isWhiteTurn == _humanPlaysWhite;
    final inCheck = _isKingAttacked(boardState, _isWhiteTurn);
    final last = _moveHistory.isNotEmpty ? _moveHistory.last : null;
    final lastByHuman = last != null && last.isWhite == _humanPlaysWhite;
    final capturedLabel = last?.pieceCaptured != null
        ? _pieceLabelForBotSpeech(last!.pieceCaptured!)
        : null;
    final displayedEval = _displayEvalForPov();

    return buildBotContextualLine(
      bot: bot,
      outcome: _gameOutcome,
      botThinking: _botThinking,
      humanPlaysWhite: _humanPlaysWhite,
      isWhiteTurn: _isWhiteTurn,
      inCheck: inCheck,
      humanToMove: humanToMove,
      lastNotation: last?.notation,
      lastCapturedPieceLabel: capturedLabel,
      lastByHuman: lastByHuman,
      currentOpening: _currentOpening,
      moveCount: _moveHistory.length,
      displayedEval: displayedEval,
      evalText: _evalTextForUi(displayedEval),
      variantSeed:
          (_moveHistory.length * 37 + _botSpeechVersion * 13) & 0x7FFFFFFF,
      recentCaptures: _moveHistory.length >= 4
          ? _moveHistory
                .sublist(_moveHistory.length - 4)
                .where((m) => m.pieceCaptured != null)
                .length
          : _moveHistory.where((m) => m.pieceCaptured != null).length,
      isBotCaptureStreak:
          _moveHistory.length >= 2 &&
          _moveHistory
              .sublist(_moveHistory.length - 2)
              .every(
                (m) => m.isWhite != _humanPlaysWhite && m.pieceCaptured != null,
              ),
      isEndgame: _moveHistory.length > 28,
    );
  }

  void _showBotSpeechBubble(String message) {
    final text = message.trim();
    if (text.isEmpty || !mounted) {
      return;
    }

    final version = _botSpeechVersion + 1;
    _botSpeechVersion = version;
    _botSpeechTypeTimer?.cancel();
    _botSpeechHideTimer?.cancel();

    setState(() {
      _botSpeechFullText = text;
      _botSpeechVisibleText = '';
    });

    var index = 0;
    _botSpeechTypeTimer = Timer.periodic(const Duration(milliseconds: 22), (
      timer,
    ) {
      if (!mounted || version != _botSpeechVersion) {
        timer.cancel();
        return;
      }

      index = min(text.length, index + 1);
      setState(() {
        _botSpeechVisibleText = text.substring(0, index);
      });

      if (index >= text.length) {
        timer.cancel();
        _botSpeechTypeTimer = null;
        _botSpeechHideTimer = Timer(const Duration(milliseconds: 3800), () {
          if (!mounted || version != _botSpeechVersion) {
            return;
          }
          setState(() {
            _botSpeechFullText = null;
            _botSpeechVisibleText = '';
          });
          _botSpeechHideTimer = null;
        });
      }
    });
  }

  Widget _buildBotSpeechBubble(double scale) {
    final full = _botSpeechFullText;
    if (full == null || full.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final text = _botSpeechVisibleText.isEmpty ? '...' : _botSpeechVisibleText;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 184 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 1 * scale),
            child: CustomPaint(
              size: Size(12 * scale, 16 * scale),
              painter: _SpeechTailPainter(
                fillColor: Color.alphaBlend(
                  (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.06,
                  ),
                  scheme.surface,
                ),
                strokeColor: scheme.outline.withValues(alpha: 0.42),
              ),
            ),
          ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 7 * scale,
              ),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.06,
                  ),
                  scheme.surface,
                ),
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.42),
                ),
              ),
              child: Text(
                text,
                softWrap: true,
                style: GoogleFonts.pixelifySans(
                  color: scheme.onSurface.withValues(alpha: 0.94),
                  fontSize: 12.2 * scale,
                  height: 1.12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> _onBotAvatarTapped() async {
    final bot = _selectedBot;
    if (bot == null || !_playVsBot || !mounted) {
      return;
    }
    await HapticFeedback.selectionClick();
    if (!mounted) {
      return;
    }
    _showBotSpeechBubble(_buildContextualBotSpeech(bot));
  }

  @override
  void _undoBotTurn() {
    super._undoBotTurn();
  }

  @override
  Widget _buildBotUndoButton() {
    return super._buildBotUndoButton();
  }
}

class _SpeechTailPainter extends CustomPainter {
  const _SpeechTailPainter({
    required this.fillColor,
    required this.strokeColor,
  });

  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final tip = Offset(size.width * 0.12, size.height * 0.62);
    final top = Offset(size.width * 0.96, size.height * 0.22);
    final bottom = Offset(size.width * 0.96, size.height * 0.90);
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(size.width * 0.50, size.height * 0.36, tip.dx, tip.dy)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.86,
        bottom.dx,
        bottom.dy,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final dotRadius = size.width * 0.16;
    canvas.drawCircle(
      tip,
      dotRadius,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      tip,
      dotRadius,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeechTailPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
