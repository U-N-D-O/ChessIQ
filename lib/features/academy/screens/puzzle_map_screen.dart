import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/services/ad_service.dart';
import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/academy/screens/puzzle_grid_screen.dart';
import 'package:chessiq/features/academy/screens/puzzle_node_screen.dart';
import 'package:chessiq/features/academy/widgets/academy_theme_settings_sheet.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'package:chessiq/features/academy/widgets/puzzle_map_components.dart';

class PuzzleMapScreen extends StatefulWidget {
  const PuzzleMapScreen({
    super.key,
    required this.onBack,
    this.cinematicThemeEnabled = false,
  });

  final VoidCallback onBack;
  final bool cinematicThemeEnabled;

  @override
  State<PuzzleMapScreen> createState() => _PuzzleMapScreenState();
}

class _PuzzleMapScreenState extends State<PuzzleMapScreen>
    with TickerProviderStateMixin {
  static const String _muteSoundsKey = 'mute_sounds_v1';
  static const String _hapticsEnabledKey = 'haptics_enabled_v1';

  bool _didPrimeUi = false;
  String? _lastCelebrationKey;
  late final ConfettiController _confettiController;
  final AudioPlayer _academyStoreSfxPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _academyStoreSfxPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrimeUi) return;
    _didPrimeUi = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<PuzzleAcademyProvider>();
      await provider.initialize();
      if (!mounted) return;
      await _showPendingEducation(provider);
    });
  }

  Future<void> _showPendingEducation(PuzzleAcademyProvider provider) async {
    if (!mounted || !provider.initialized) return;

    final unlockedNodes = provider.orderedNodes.where((node) => node.unlocked);
    final firstUnlocked = unlockedNodes.isEmpty
        ? null
        : unlockedNodes.reduce((a, b) => a.startElo < b.startElo ? a : b);
    if (firstUnlocked != null) {
      final semester = provider.semesterForNode(firstUnlocked);
      if (provider.shouldShowSemesterIntro(semester.id)) {
        await _showSemesterIntroDialog(semester);
        if (!mounted) return;
        await provider.markSemesterSeen(semester.id);
      }
    }

    if (provider.shouldShowGrandmasterOracle) {
      await _showGrandmasterOracleDialog();
      if (!mounted) return;
      provider.consumeGrandmasterOracleTrigger();
    }

    if (provider.shouldShowBrainBreak) {
      await _showBrainBreakDialog(provider);
      if (!mounted) return;
      provider.consumeBrainBreakTrigger();
    }
  }

  void _handleCelebration(PuzzleAcademyProvider provider) {
    final key = provider.celebrationNodeKey;
    if (key == null || key == _lastCelebrationKey) return;
    _lastCelebrationKey = key;
    _confettiController.play();
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      provider.consumeCelebrationNode();
    });
  }

  Future<void> _showSemesterIntroDialog(SemesterRange semester) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF102036).withValues(alpha: 0.92),
                    const Color(0xFF0A1321).withValues(alpha: 0.94),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF6FE7FF).withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semester.title,
                    style: const TextStyle(
                      color: Color(0xFF6FE7FF),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    semester.intro,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD8B640),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Enter Semester'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBrainBreakDialog(PuzzleAcademyProvider provider) async {
    final shown = await AdService.instance.showInterstitialAd();
    if (!shown || !mounted) {
      return;
    }

    final economy = context.read<EconomyProvider>();
    await economy.awardAcademyInterstitialCoins();
    await provider.syncCoinsFromStoreState(notify: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Academy break complete. +10 coins.')),
      );
  }

  Future<void> _showGrandmasterOracleDialog() async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Grandmaster Oracle',
      pageBuilder: (context, _, _) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.72),
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.25, -0.35),
                      radius: 1.25,
                      colors: [
                        const Color(0xFF6FE7FF).withValues(alpha: 0.28),
                        const Color(0xFF102443).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.5, 0.2),
                      radius: 1.2,
                      colors: [
                        const Color(0xFFD8B640).withValues(alpha: 0.24),
                        const Color(0xFF2D1F08).withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 680),
                        padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF09111E).withValues(alpha: 0.88),
                              const Color(0xFF0B2134).withValues(alpha: 0.84),
                              const Color(0xFF251A09).withValues(alpha: 0.82),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(
                              0xFFD8B640,
                            ).withValues(alpha: 0.55),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF6FE7FF), Color(0xFFD8B640)],
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 56,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Neural Constraints Lifted',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Stockfish Depth 35 Unlocked',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFD8B640),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'The final academy seal is broken. Analysis Mode now has permanent access to Depth 33-35.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFD8B640),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Accept Upgrade'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openStore() {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Consumer<PuzzleAcademyProvider>(
          builder: (context, liveProvider, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Academy Store',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Coins: ${liveProvider.progress.coins}',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StoreRow(
                    icon: Icons.lightbulb_outline,
                    title: 'Hint Pack',
                    subtitle: '+3 Smart Hints',
                    price: '25 coins',
                    onBuy: () async {
                      final ok = await liveProvider.buyHintPack();
                      if (!mounted || !ok) return;
                      unawaited(_playAcademyBuySound());
                    },
                  ),
                  const SizedBox(height: 10),
                  _StoreRow(
                    icon: Icons.skip_next_rounded,
                    title: 'Skip Pack',
                    subtitle: '+2 Tactical Skips',
                    price: '35 coins',
                    onBuy: () async {
                      final ok = await liveProvider.buySkipPack();
                      if (!mounted || !ok) return;
                      unawaited(_playAcademyBuySound());
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _playAcademyBuySound() async {
    final prefs = await SharedPreferences.getInstance();
    final muted = prefs.getBool(_muteSoundsKey) ?? false;
    if (muted) {
      return;
    }

    try {
      await _academyStoreSfxPlayer.stop();
      await _academyStoreSfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _academyStoreSfxPlayer.play(
        AssetSource('sounds/academybuy.mp3'),
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );
    } catch (_) {
      // Keep purchases smooth even if audio playback fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PuzzleAcademyProvider>(
      builder: (context, provider, _) {
        final materialTheme = Theme.of(context);
        final scheme = materialTheme.colorScheme;
        final isDark = materialTheme.brightness == Brightness.dark;
        final monochrome =
            context.watch<AppThemeProvider>().isMonochrome ||
            widget.cinematicThemeEnabled;

        if (provider.isLoading || !provider.initialized) {
          return const Center(child: CircularProgressIndicator());
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleCelebration(provider);
          _showPendingEducation(provider);
        });

        return OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final landscape = orientation == Orientation.landscape;
                final grouped = _groupBySemester(provider);
                final leadTone = monochrome
                    ? const Color(0xFF808080)
                    : scheme.primary;
                final altTone = monochrome
                    ? const Color(0xFFA6A6A6)
                    : scheme.secondary;
                final rootContent = Stack(
                  children: [
                    Positioned.fill(child: _buildAtmosphere(monochrome)),
                    if (wide || landscape)
                      Row(
                        children: [
                          SizedBox(
                            width: min(360, constraints.maxWidth * 0.34),
                            child: _buildMasteryDashboard(
                              provider,
                              monochrome: monochrome,
                            ),
                          ),
                          Expanded(
                            child: _buildLandscapeMap(
                              provider,
                              grouped,
                              monochrome: monochrome,
                            ),
                          ),
                        ],
                      )
                    else
                      _buildPortraitMap(
                        provider,
                        grouped,
                        monochrome: monochrome,
                      ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: IgnorePointer(
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          emissionFrequency: 0.06,
                          numberOfParticles: 22,
                          maxBlastForce: 28,
                          minBlastForce: 12,
                          gravity: 0.14,
                          colors: const [
                            Color(0xFFD8B640),
                            Color(0xFFECCF7A),
                            Color(0xFFF4E9C2),
                            Color(0xFFB98A1B),
                          ],
                        ),
                      ),
                    ),
                  ],
                );

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          leadTone.withValues(alpha: isDark ? 0.16 : 0.06),
                          scheme.surface,
                        ),
                        scheme.surface,
                        Color.alphaBlend(
                          altTone.withValues(alpha: isDark ? 0.10 : 0.04),
                          scheme.surface,
                        ),
                      ],
                      stops: const [0.0, 0.52, 1.0],
                    ),
                  ),
                  child: rootContent,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAtmosphere(bool cinematic) {
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-0.88, -0.82),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (cinematic
                            ? const Color(0xFFB6BCC5)
                            : const Color(0xFF6FE7FF))
                        .withValues(alpha: cinematic ? 0.06 : 0.10),
                boxShadow: [
                  BoxShadow(
                    color:
                        (cinematic
                                ? const Color(0xFFB6BCC5)
                                : const Color(0xFF6FE7FF))
                            .withValues(alpha: cinematic ? 0.12 : 0.22),
                    blurRadius: 110,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.95, -0.75),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    (cinematic
                            ? const Color(0xFF9DA3AD)
                            : const Color(0xFFD8B640))
                        .withValues(alpha: cinematic ? 0.06 : 0.08),
                boxShadow: [
                  BoxShadow(
                    color:
                        (cinematic
                                ? const Color(0xFF9DA3AD)
                                : const Color(0xFFD8B640))
                            .withValues(alpha: cinematic ? 0.10 : 0.16),
                    blurRadius: 90,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitMap(
    PuzzleAcademyProvider provider,
    Map<SemesterRange, List<EloNodeProgress>> grouped, {
    required bool monochrome,
  }) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(provider, monochrome: monochrome),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              children: [
                _buildHeroStatsBar(provider),
                const SizedBox(height: 12),
                _DailyChallengeCard(
                  total: provider.dailyPuzzles.length,
                  completed: provider.completedTodayDailyCount,
                  hasTodayPuzzle: provider.hasTodayDailyPuzzle,
                  onTap: () => _openTodayDailyPuzzle(provider, monochrome),
                ),
                const SizedBox(height: 12),
                _LeaderboardCard(
                  entries: provider.academyScoreboardEntries,
                  title: 'Academy Scoreboard',
                  emptyLabel:
                      'Complete an exam to post your first Academy score.',
                ),
              ],
            ),
          ),
        ),
        for (final entry in grouped.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: _SemesterHeader(
                semester: entry.key,
                progress: provider.semesterProgress(entry.key),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildNodeTile(
                  provider,
                  entry.value[index],
                  compact: false,
                  monochrome: monochrome,
                ),
                childCount: entry.value.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildLandscapeMap(
    PuzzleAcademyProvider provider,
    Map<SemesterRange, List<EloNodeProgress>> grouped, {
    required bool monochrome,
  }) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(provider, monochrome: monochrome),
        for (final entry in grouped.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: _SemesterHeader(
                semester: entry.key,
                progress: provider.semesterProgress(entry.key),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.56,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildNodeTile(
                  provider,
                  entry.value[index],
                  compact: true,
                  monochrome: monochrome,
                ),
                childCount: entry.value.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(
    PuzzleAcademyProvider provider, {
    required bool monochrome,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 132,
      backgroundColor: Color.alphaBlend(
        scheme.primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.12 : 0.05,
        ),
        scheme.surface,
      ).withValues(alpha: 0.94),
      leading: IconButton(
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => _openQuickThemeSettings(),
          icon: const Icon(Icons.settings_outlined),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: _openStore,
            icon: const Icon(Icons.storefront_outlined),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 54, bottom: 12),
        title: Text(
          'Puzzle Academy',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary.withValues(
                  alpha: monochrome
                      ? 0.10
                      : (theme.brightness == Brightness.dark ? 0.16 : 0.08),
                ),
                scheme.secondary.withValues(
                  alpha: monochrome
                      ? 0.08
                      : (theme.brightness == Brightness.dark ? 0.12 : 0.06),
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMasteryDashboard(
    PuzzleAcademyProvider provider, {
    required bool monochrome,
  }) {
    return SafeArea(
      right: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 12, 20),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Mastery Dashboard',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHeroStatsBar(provider),
          const SizedBox(height: 12),
          _DashboardPanel(
            title: 'Current Title',
            accent: const Color(0xFFD8B640),
            child: Text(
              provider.currentTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          _DashboardPanel(
            title: 'Semester Progress',
            accent: const Color(0xFF6FE7FF),
            child: Column(
              children: provider.semesters
                  .map(
                    (semester) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              semester.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 110,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 7,
                                value: provider.semesterProgress(semester),
                                backgroundColor: Colors.white10,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6FE7FF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _DailyChallengeCard(
            total: provider.dailyPuzzles.length,
            completed: provider.completedTodayDailyCount,
            hasTodayPuzzle: provider.hasTodayDailyPuzzle,
            onTap: () => _openTodayDailyPuzzle(provider, monochrome),
          ),
          const SizedBox(height: 12),
          _LeaderboardCard(
            entries: provider.academyScoreboardEntries,
            title: 'Academy Scoreboard',
            emptyLabel: 'Complete an exam to post your first Academy score.',
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatsBar(PuzzleAcademyProvider provider) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.12 : 0.04,
              ),
              scheme.surface,
            ).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.30)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(
                label: 'Coins',
                value: provider.progress.coins.toString(),
                color: const Color(0xFFD8B640),
              ),
              _StatChip(
                label: 'Streak',
                value: provider.progress.streak.toString(),
                color: const Color(0xFF6FE7FF),
              ),
              _StatChip(
                label: 'Hints',
                value: provider.progress.freeHints.toString(),
                color: const Color(0xFF71B7FF),
              ),
              _StatChip(
                label: 'Skipped',
                value: provider.unresolvedSkippedPuzzleCount.toString(),
                color: const Color(0xFFE0A6FF),
              ),
              _StatChip(
                label: 'Solved',
                value: provider.totalSolved.toString(),
                color: const Color(0xFF9BE27C),
              ),
              _StatChip(
                label: 'Crowns',
                value: provider.masteredNodeCount.toString(),
                color: const Color(0xFFD8B640),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeTile(
    PuzzleAcademyProvider provider,
    EloNodeProgress node, {
    required bool compact,
    required bool monochrome,
  }) {
    final featured = provider.featuredPuzzleForNode(node);
    final solvedFeatured =
        featured != null && provider.isPuzzleSolved(featured.puzzleId);
    final heroTag = provider.heroTagForNode(node);

    return _PuzzleNodeCard(
      node: node,
      compact: compact,
      heroTag: heroTag,
      showGhost: solvedFeatured,
      showExamButton: provider.canTakeExam(node),
      bestExamScore: provider.bestExamResultForNode(node.key)?.score,
      lockedRequirementText: provider.unlockRequirementText(node),
      onExamTap: !provider.canTakeExam(node)
          ? null
          : () => _startExamForNode(provider, node, heroTag, monochrome),
      onTap: !node.unlocked
          ? null
          : () async {
              await provider.ensureNodePuzzlesLoadedForNode(node);
              if (!mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PuzzleGridScreen(
                    node: node,
                    heroTag: heroTag,
                    cinematicThemeEnabled: monochrome,
                  ),
                ),
              );
              if (!mounted) return;
            },
    );
  }

  void _openTodayDailyPuzzle(PuzzleAcademyProvider provider, bool monochrome) {
    final daily = provider.todayDailyPuzzle;
    if (daily == null) return;
    final dailyNode =
        provider.progress.nodes[provider.keyForRating(daily.rating)];
    if (dailyNode == null) return;
    final dailyIndex = provider.todayDailyPuzzleIndex;
    if (dailyIndex < 0) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleNodeScreen(
          node: dailyNode,
          heroTag: provider.heroTagForNode(dailyNode),
          initialPuzzle: daily,
          initialPuzzleIndex: dailyIndex,
          puzzleSequence: provider.dailyPuzzles,
          sequenceTitle: 'Daily Challenge',
          cinematicThemeEnabled: monochrome,
          onExitToMap: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _startExamForNode(
    PuzzleAcademyProvider provider,
    EloNodeProgress node,
    String heroTag,
    bool monochrome,
  ) async {
    await provider.ensureNodePuzzlesLoadedForNode(node);
    final sequence = await provider.buildExamPuzzleSequence(node);
    if (!mounted || sequence.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleNodeScreen(
          node: node,
          heroTag: heroTag,
          initialPuzzle: sequence.first,
          initialPuzzleIndex: 0,
          puzzleSequence: sequence,
          sequenceTitle: 'Bracket Exam',
          examMode: true,
          examDuration: provider.examDuration,
          cinematicThemeEnabled: monochrome,
          onExitToMap: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _openQuickThemeSettings() async {
    final theme = context.read<AppThemeProvider>();
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = !(prefs.getBool(_muteSoundsKey) ?? false);
    final hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;

    if (!mounted) return;
    await showAcademyThemeSettingsSheet(
      context: context,
      themeProvider: theme,
      soundEnabled: soundEnabled,
      hapticsEnabled: hapticsEnabled,
      onSoundEnabledChanged: (enabled) async {
        await prefs.setBool(_muteSoundsKey, !enabled);
      },
      onHapticsEnabledChanged: (enabled) async {
        await prefs.setBool(_hapticsEnabledKey, enabled);
      },
    );
  }

  Map<SemesterRange, List<EloNodeProgress>> _groupBySemester(
    PuzzleAcademyProvider provider,
  ) {
    final grouped = <SemesterRange, List<EloNodeProgress>>{};
    for (final semester in provider.semesters) {
      grouped[semester] = <EloNodeProgress>[];
    }

    for (final node in provider.orderedNodes) {
      final semester = provider.semesterForNode(node);
      grouped[semester]!.add(node);
    }

    grouped.removeWhere((_, nodes) => nodes.isEmpty);
    return grouped;
  }
}
