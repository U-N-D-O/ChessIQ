part of '../../analysis/screens/chess_analysis_page.dart';

String _menuLogoAsset(BuildContext context) {
  return Theme.of(context).brightness == Brightness.light
      ? 'assets/logo2.png'
      : 'assets/logo.png';
}

TextStyle _mainMenuPixelStyle({
  required Color color,
  double size = 10.2,
  double height = 1.2,
  double letterSpacing = 0.0,
}) {
  return TextStyle(
    fontFamily: 'PressStart2P',
    fontFamilyFallback: const <String>['Courier New'],
    color: color,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    super.key,
    required this.menuReady,
    required this.menuRevealController,
    required this.sectionTransitionController,
    required this.logoAsset,
    required this.child,
  });

  final bool menuReady;
  final Animation<double> menuRevealController;
  final Animation<double> sectionTransitionController;
  final String logoAsset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isLandscape = media.orientation == Orientation.landscape;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final menuTopColor = Color.alphaBlend(
      Color.lerp(
        scheme.primary,
        scheme.secondary,
        0.32,
      )!.withValues(alpha: isDark ? 0.12 : 0.05),
      scheme.surface,
    );
    final menuBottomColor = Color.alphaBlend(
      scheme.tertiary.withValues(alpha: isDark ? 0.08 : 0.04),
      scheme.surface,
    );

    final content = !menuReady
        ? Center(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: menuRevealController,
                curve: Curves.easeOutCubic,
              ),
              child: Image.asset(logoAsset, width: 220, fit: BoxFit.contain),
            ),
          )
        : FadeTransition(
            opacity: CurvedAnimation(
              parent: sectionTransitionController,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [menuTopColor, scheme.surface, menuBottomColor],
            stops: const [0.0, 0.72, 1.0],
          ),
        ),
        child: isLandscape ? content : SafeArea(child: content),
      ),
    );
  }
}
