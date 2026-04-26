part of '../../analysis/screens/chess_analysis_page.dart';

extension _QuizAcademySurface on _QuizScreen {
  _QuizAcademyPalette _academyPalette({
    required ColorScheme scheme,
    required bool useMonochrome,
    required bool isDark,
  }) {
    final boardPalette = context.read<AppThemeProvider>().boardPalette();
    final text = useMonochrome && !isDark ? Colors.black : scheme.onSurface;
    final cyan = useMonochrome
        ? text.withValues(alpha: isDark ? 0.82 : 0.72)
        : Color.lerp(
            scheme.secondary,
            boardPalette.lightSquare,
            isDark ? 0.22 : 0.10,
          )!;
    final amber = useMonochrome
        ? text.withValues(alpha: isDark ? 0.68 : 0.56)
        : Color.lerp(
            scheme.primary,
            const Color(0xFFFFC857),
            isDark ? 0.35 : 0.25,
          )!;
    final emerald = useMonochrome
        ? text.withValues(alpha: isDark ? 0.58 : 0.46)
        : Color.lerp(scheme.tertiary, const Color(0xFF88D498), 0.22)!;
    final boardDark = useMonochrome
        ? Color.lerp(
            boardPalette.darkSquare,
            scheme.outline,
            isDark ? 0.20 : 0.45,
          )!
        : Color.lerp(
            boardPalette.darkSquare,
            scheme.secondary,
            isDark ? 0.30 : 0.20,
          )!;
    final boardLight = useMonochrome
        ? Color.lerp(
            boardPalette.lightSquare,
            scheme.surface,
            isDark ? 0.20 : 0.40,
          )!
        : Color.lerp(
            boardPalette.lightSquare,
            scheme.surface,
            isDark ? 0.18 : 0.42,
          )!;
    final backdrop = Color.alphaBlend(
      boardDark.withValues(alpha: isDark ? 0.34 : 0.18),
      scheme.surface,
    );
    final shell = Color.alphaBlend(
      boardLight.withValues(alpha: isDark ? 0.10 : 0.24),
      backdrop,
    );
    final panel = Color.alphaBlend(
      scheme.surface.withValues(alpha: isDark ? 0.94 : 0.97),
      shell,
    );
    final panelAlt = Color.alphaBlend(
      boardLight.withValues(alpha: isDark ? 0.15 : 0.28),
      shell,
    );
    final line = Color.alphaBlend(
      scheme.outline.withValues(alpha: isDark ? 0.82 : 0.92),
      boardDark.withValues(alpha: 0.06),
    );
    final signal = useMonochrome
        ? text.withValues(alpha: 0.70)
        : Color.lerp(scheme.primary, const Color(0xFFFF9A62), 0.45)!;
    return _QuizAcademyPalette(
      backdrop: backdrop,
      shell: shell,
      panel: panel,
      panelAlt: panelAlt,
      line: line,
      shadow: Colors.black.withValues(alpha: isDark ? 0.42 : 0.16),
      text: text,
      textMuted: text.withValues(alpha: isDark ? 0.74 : 0.68),
      cyan: cyan,
      amber: amber,
      emerald: emerald,
      signal: signal,
      boardDark: boardDark,
      boardLight: boardLight,
    );
  }

  TextStyle _academyDisplayStyle({
    required _QuizAcademyPalette palette,
    double size = 28,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 1.0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _quizAcademyDisplayFontFamily,
      fontFamilyFallback: const <String>['Courier New'],
      color: color ?? palette.text,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: 0.95,
    );
  }

  TextStyle _academyHudStyle({
    required _QuizAcademyPalette palette,
    double size = 12.5,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0.55,
    Color? color,
    double height = 1.35,
  }) {
    return TextStyle(
      fontFamily: _quizAcademyHudFontFamily,
      fontFamilyFallback: const <String>['Courier New'],
      color: color ?? palette.textMuted,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  Color _academyQuizModeAccent(
    _QuizAcademyPalette palette,
    GambitQuizMode mode,
  ) {
    return mode == GambitQuizMode.guessName ? palette.cyan : palette.amber;
  }

  IconData _academyQuizModeIcon(GambitQuizMode mode) {
    return mode == GambitQuizMode.guessName
        ? Icons.badge_outlined
        : Icons.route_outlined;
  }

  String _academyQuizModeTitle(GambitQuizMode mode) {
    return mode == GambitQuizMode.guessName
        ? 'Identify Opening Name'
        : 'Complete Opening Line';
  }

  String _academyQuizModeInfoMessage(GambitQuizMode mode) {
    return mode == GambitQuizMode.guessName
        ? 'See the position, then choose the correct opening name. This mode keeps the standard 10-question quiz flow and uses the selected level rules.'
        : 'See the position, then choose the correct next move to continue the opening line. This mode keeps the standard 10-question quiz flow and uses the selected level rules.';
  }

  String _academyQuizModeStartLabel(GambitQuizMode mode) {
    return mode == GambitQuizMode.guessName
        ? 'START NAME QUIZ'
        : 'START LINE QUIZ';
  }

  Widget _academyPixelPanel({
    Key? panelKey,
    required _QuizAcademyPalette palette,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Color? fillColor,
    Color? borderColor,
    Color? accent,
  }) {
    final effectiveAccent = accent ?? palette.cyan;
    final background = fillColor ?? palette.panel;
    return Container(
      key: panelKey,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              effectiveAccent.withValues(alpha: 0.08),
              background,
            ),
            background,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor ?? palette.line, width: 3),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            offset: const Offset(6, 6),
            blurRadius: 0,
          ),
          BoxShadow(
            color: effectiveAccent.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _academyPanelHeader({
    required _QuizAcademyPalette palette,
    required String title,
    required String subtitle,
    String? infoTitle,
    String? infoMessage,
    Key? infoButtonKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: _academyDisplayStyle(
                  palette: palette,
                  size: 20,
                  weight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ),
            if (infoMessage != null) ...<Widget>[
              const SizedBox(width: 8),
              _buildQuizInfoButton(
                buttonKey: infoButtonKey,
                title: infoTitle ?? title,
                message: infoMessage,
              ),
            ],
          ],
        ),
        if (subtitle.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: _academyHudStyle(
              palette: palette,
              size: 12.5,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _academyHudButton({
    Key? buttonKey,
    required _QuizAcademyPalette palette,
    required IconData icon,
    required String label,
    required Color accent,
    required VoidCallback? onTap,
    bool filled = false,
  }) {
    final background = filled
        ? accent
        : Color.alphaBlend(accent.withValues(alpha: 0.08), palette.shell);
    final foreground = filled
        ? (accent.computeLuminance() > 0.55
              ? const Color(0xFF081015)
              : Colors.white)
        : accent;
    final effectiveForeground = onTap == null
        ? foreground.withValues(alpha: 0.50)
        : foreground;
    final effectiveBorder = onTap == null
        ? accent.withValues(alpha: 0.24)
        : accent.withValues(alpha: filled ? 0.90 : 0.48);
    final effectiveBackground = onTap == null
        ? background.withValues(alpha: 0.55)
        : background;

    return Material(
      key: buttonKey,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: effectiveBackground,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: effectiveBorder, width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.shadow.withValues(
                  alpha: onTap == null ? 0.14 : 0.22,
                ),
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: effectiveForeground),
              const SizedBox(width: 8),
              Text(
                label,
                style: _academyHudStyle(
                  palette: palette,
                  color: effectiveForeground,
                  size: 11.8,
                  weight: FontWeight.w800,
                  letterSpacing: 1.0,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _academyTag({
    required _QuizAcademyPalette palette,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accent.withValues(alpha: 0.48), width: 2),
      ),
      child: Text(
        label,
        style: _academyHudStyle(
          palette: palette,
          color: accent,
          size: 10.5,
          weight: FontWeight.w800,
          letterSpacing: 0.95,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _academyBackdropLayer({required _QuizAcademyPalette palette}) {
    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _QuizAcademyBackdropPainter(
                    palette: palette,
                    phase: _menuDotTime,
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: const Alignment(-0.82, -0.72),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.cyan.withValues(alpha: 0.12),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.cyan.withValues(alpha: 0.18),
                    blurRadius: 120,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.90, -0.68),
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.amber.withValues(alpha: 0.10),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.amber.withValues(alpha: 0.18),
                    blurRadius: 110,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.05, 1.08),
            child: Container(
              width: 520,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    palette.boardDark.withValues(alpha: 0.06),
                    palette.boardDark.withValues(alpha: 0.22),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.boardDark.withValues(alpha: 0.18),
                    blurRadius: 120,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
