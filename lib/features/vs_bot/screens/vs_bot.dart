// ignore_for_file: unused_element, unnecessary_overrides

part of '../../analysis/screens/chess_analysis_page.dart';

abstract class _VsBotState extends _StoreState {
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

    final isLandscape = scene.width > scene.height;
    final bubbleMaxWidth = min(
      228 * scale,
      scene.width * (isLandscape ? 0.42 : 0.58),
    );

    final left = (center.dx + (26 * scale)).clamp(
      8.0,
      max(8.0, scene.width - bubbleMaxWidth - (12 * scale)),
    );
    final top = (center.dy - (20 * scale)).clamp(
      6.0,
      max(6.0, scene.height - ((isLandscape ? 92 : 82) * scale)),
    );
    final pointerTargetDy = center.dy - top.toDouble();

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: IgnorePointer(
        child: _buildBotSpeechBubble(
          scale,
          maxWidth: bubbleMaxWidth,
          pointerTargetDy: pointerTargetDy,
        ),
      ),
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
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final arcade = _vsBotArcadePaletteFor(context, monochrome: useMonochrome);
    final profileAccent = _vsBotProfileAccent(bot.profile, arcade);
    final difficultyAccent = _botDifficultyColor(_selectedBotDifficulty);
    final frameAccent = Color.lerp(profileAccent, difficultyAccent, 0.55)!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: frameAccent.withValues(alpha: 0.88),
          width: max(1.8, size * 0.045),
        ),
        boxShadow: [
          BoxShadow(
            color: frameAccent.withValues(
              alpha: arcade.monochrome ? 0.18 : 0.28,
            ),
            blurRadius: max(10.0, size * 0.22),
            spreadRadius: max(1.0, size * 0.03),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: max(10.0, size * 0.20),
            offset: Offset(0, max(4.0, size * 0.08)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(max(3.0, size * 0.055)),
        child: ClipOval(
          child: avatarAsset != null
              ? Image.asset(avatarAsset, fit: BoxFit.cover)
              : Container(
                  color: arcade.shell,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: difficultyAccent,
                    size: size * 0.42,
                  ),
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
    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final arcade = _vsBotArcadePaletteFor(context, monochrome: useMonochrome);
    final profileAccent = _vsBotProfileAccent(bot.profile, arcade);
    final difficultyAccent = _botDifficultyColor(_selectedBotDifficulty);
    final stageAccent = Color.lerp(profileAccent, difficultyAccent, 0.55)!;
    final glyphAccent = Color.lerp(arcade.crimson, stageAccent, 0.45)!;
    final glyphSecondary = Color.lerp(arcade.pink, arcade.cyan, 0.28)!;
    final compactScene = scene.width <= 390 || scene.height <= 430;

    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        final t = _introController.value.clamp(0.0, 1.0);
        final fade = 1.0 - ((t - 0.80) / 0.15).clamp(0.0, 1.0);
        final baseCenter = Offset(
          scene.width * 0.5,
          scene.height * (compactScene ? 0.39 : 0.42),
        );
        final impactT = Curves.easeOut.transform(
          ((t - 0.28) / 0.12).clamp(0.0, 1.0),
        );
        final impactShake =
            sin(impactT * pi * 9.0) * (1.0 - impactT) * (12 * scale);
        final center = baseCenter.translate(impactShake, 0);
        final glyphSize = (compactScene ? 64.0 : 76.0) * scale;
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
        final avatarStart =
            center + Offset((compactScene ? 78 : 92) * scale, 6 * scale);
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
          (compactScene ? 56 : 64) * scale,
          34 * scale,
          avatarTravelT,
        )!;
        final avatarRotation = ui.lerpDouble(0.26, 0.0, avatarTravelT)!;
        final avatarOpacity = ((t - 0.32) / 0.08).clamp(0.0, 1.0) * fade;
        final glyphYOffset = -16 * scale * exitLiftT;
        final introPlateWidth = min(
          224 * scale,
          scene.width * (compactScene ? 0.72 : 0.76),
        );
        final namePlateWidth = min(
          276 * scale,
          scene.width * (compactScene ? 0.82 : 0.88),
        );

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
                          child: glowText(1.0, glyphAccent, glyphGlow * 1.1),
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
                              glyphSecondary,
                              glyphGlow * 0.85,
                            ),
                          ),
                        ),
                      glowText(
                        1.0,
                        Color.lerp(
                          glyphSecondary,
                          Colors.white,
                          0.36,
                        )!.withValues(alpha: 0.82),
                        glyphGlow * 0.34,
                      ),
                      Text(
                        glyph,
                        style: GoogleFonts.orbitron(
                          fontSize: glyphSize,
                          fontWeight: FontWeight.w900,
                          height: 0.84,
                          color: glyphAccent,
                          shadows: [
                            Shadow(
                              color: glyphAccent.withValues(alpha: 0.95),
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
                    left: center.dx - (introPlateWidth / 2),
                    top:
                        center.dy -
                        ((compactScene ? 102 : 118) * scale) +
                        glyphYOffset,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (0.44 + (impactFlash * 0.18)) * fade,
                        child: Container(
                          width: introPlateWidth,
                          padding: EdgeInsets.symmetric(
                            horizontal: (compactScene ? 12 : 14) * scale,
                            vertical: (compactScene ? 8 : 9) * scale,
                          ),
                          decoration: _vsBotArcadePanelDecoration(
                            palette: arcade,
                            accent: stageAccent,
                            radius: 18 * scale,
                            borderWidth: max(1.4, 2.0 * scale),
                            inset: true,
                            elevated: false,
                            fillColor: arcade.marquee,
                          ),
                          child: Text(
                            'MATCH START',
                            textAlign: TextAlign.center,
                            style: puzzleAcademyIdentityStyle(
                              palette: arcade.base,
                              size: 7.8 * scale,
                              color: stageAccent,
                              withGlow: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
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
                                  glyphAccent.withValues(alpha: 0.32),
                                  glyphSecondary.withValues(alpha: 0.14),
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
                              color: stageAccent.withValues(alpha: 0.55),
                              width: max(
                                1.4,
                                3.6 * scale * (1.0 - shockwaveT * 0.45),
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glyphAccent.withValues(alpha: 0.24),
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
                                  Color.lerp(
                                    glyphSecondary,
                                    Colors.white,
                                    0.40,
                                  )!.withValues(alpha: 0.58),
                                  glyphAccent.withValues(alpha: 0.20),
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
                  Positioned(
                    left: center.dx - (namePlateWidth / 2),
                    top:
                        center.dy +
                        ((compactScene ? 38 : 44) * scale) +
                        glyphYOffset,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (0.38 + (impactFlash * 0.18)) * fade,
                        child: Container(
                          width: namePlateWidth,
                          padding: EdgeInsets.symmetric(
                            horizontal: (compactScene ? 12 : 16) * scale,
                            vertical: 8 * scale,
                          ),
                          decoration: _vsBotArcadePanelDecoration(
                            palette: arcade,
                            accent: profileAccent,
                            radius: 16 * scale,
                            borderWidth: max(1.2, 1.8 * scale),
                            inset: true,
                            elevated: false,
                            fillColor: arcade.panelAlt,
                          ),
                          child: Text(
                            '${bot.name.toUpperCase()} // ${_selectedBotDifficulty.label.toUpperCase()}',
                            textAlign: TextAlign.center,
                            style: puzzleAcademyIdentityStyle(
                              palette: arcade.base,
                              size: 6.8 * scale,
                              color: profileAccent,
                              withGlow: true,
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

  Widget _buildBotSpeechBubble(
    double scale, {
    double? maxWidth,
    required double pointerTargetDy,
  }) {
    final full = _botSpeechFullText;
    if (full == null || full.isEmpty) {
      return const SizedBox.shrink();
    }

    final useMonochrome =
        context.watch<AppThemeProvider>().isMonochrome ||
        _isCinematicThemeEnabled;
    final arcade = _vsBotArcadePaletteFor(context, monochrome: useMonochrome);
    final bot = _selectedBot;
    final profileAccent = bot == null
        ? arcade.cyan
        : _vsBotProfileAccent(bot.profile, arcade);
    final difficultyAccent = _botDifficultyColor(_selectedBotDifficulty);
    final bubbleAccent = Color.lerp(profileAccent, difficultyAccent, 0.45)!;
    final text = _botSpeechVisibleText.isEmpty ? '...' : _botSpeechVisibleText;
    final tailHeight = 20 * scale;
    final tailTipYOffset = tailHeight * 0.58;
    final tailTop = (pointerTargetDy - tailTipYOffset).clamp(
      4.0 * scale,
      34.0 * scale,
    );
    final tailAngle =
        ((pointerTargetDy - (18 * scale)) / (24 * scale)).clamp(-0.34, 0.34);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? (214 * scale)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: tailTop),
            child: Transform.translate(
              offset: Offset(1.2 * scale, 0),
              child: Transform.rotate(
                angle: tailAngle,
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 1 * scale),
                  child: CustomPaint(
                    size: Size(18 * scale, tailHeight),
                    painter: _SpeechTailPainter(
                      fillColor: Color.alphaBlend(
                        bubbleAccent.withValues(
                          alpha: arcade.monochrome ? 0.08 : 0.14,
                        ),
                        arcade.panelAlt,
                      ),
                      strokeColor: bubbleAccent.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                11 * scale,
                8 * scale,
                11 * scale,
                10 * scale,
              ),
              decoration: _vsBotArcadePanelDecoration(
                palette: arcade,
                accent: bubbleAccent,
                radius: 14 * scale,
                borderWidth: max(1.2, 1.8 * scale),
                inset: true,
                elevated: false,
                fillColor: arcade.panelAlt,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bot == null
                        ? 'BOT COMMS'
                        : '${bot.name.toUpperCase()} COMMS',
                    style: puzzleAcademyIdentityStyle(
                      palette: arcade.base,
                      size: 7.2 * scale,
                      color: bubbleAccent,
                      withGlow: true,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    text,
                    softWrap: true,
                    style: GoogleFonts.pixelifySans(
                      color: arcade.text,
                      fontSize: 12.0 * scale,
                      height: 1.14,
                      fontWeight: FontWeight.w500,
                      shadows: puzzleAcademyTextGlow(
                        arcade.text,
                        monochrome: arcade.monochrome,
                        strength: 0.44,
                      ),
                    ),
                  ),
                ],
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
    final tip = Offset(size.width * 0.08, size.height * 0.58);
    final top = Offset(size.width * 0.98, size.height * 0.18);
    final bottom = Offset(size.width * 0.98, size.height * 0.86);
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.20,
        size.width * 0.34,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.50,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.68,
        size.width * 0.34,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.90,
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
        ..strokeWidth = size.width * 0.08,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeechTailPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
