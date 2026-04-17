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
  Widget _buildBotAvatarOverlay(double scale) {
    return _buildBotSpeechBubble(scale);
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
        child: bot.avatarAsset != null
            ? Image.asset(bot.avatarAsset!, fit: BoxFit.cover)
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
        final fade = 1.0 - ((t - 0.95) / 0.05).clamp(0.0, 1.0);
        final baseCenter = Offset(scene.width * 0.5, scene.height * 0.42);
        final impactT = Curves.easeOut.transform(
          ((t - 0.28) / 0.12).clamp(0.0, 1.0),
        );
        final impactShake =
            sin(impactT * pi * 9.0) * (1.0 - impactT) * (12 * scale);
        final center = baseCenter.translate(impactShake, 0);
        final glyphSize = 76.0 * scale;
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
        final coreScale =
            0.90 + (0.10 * glyphSettleT) + (0.08 * (1.0 - impactT));
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
        final avatarSize = ui.lerpDouble(64 * scale, 34 * scale, avatarTravelT)!;
        final avatarRotation = ui.lerpDouble(0.26, 0.0, avatarTravelT)!;
        final avatarOpacity = ((t - 0.32) / 0.08).clamp(0.0, 1.0) * fade;

        Widget buildGlyph(String glyph, Offset offset, double rotation) {
          return Positioned(
            left: center.dx + offset.dx - (glyphSize * 0.28),
            top: center.dy + offset.dy - (glyphSize * 0.62),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: coreScale,
                child: Text(
                  glyph,
                  style: GoogleFonts.orbitron(
                    fontSize: glyphSize,
                    fontWeight: FontWeight.w900,
                    height: 0.84,
                    color: const Color(0xFFFF3B3B),
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
            padding: EdgeInsets.only(bottom: 2 * scale),
            child: CustomPaint(
              size: Size(8 * scale, 14 * scale),
              painter: _SpeechTailPainter(
                fillColor: Color.alphaBlend(
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
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
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
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
    final path = Path()
      ..moveTo(size.width, 0)
      ..quadraticBezierTo(0, size.height * 0.38, size.width, size.height)
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
  }

  @override
  bool shouldRepaint(covariant _SpeechTailPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}