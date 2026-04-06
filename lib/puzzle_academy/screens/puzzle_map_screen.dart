import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme_provider.dart';
import '../../widgets/universal_settings_sheet.dart';
import '../models/puzzle_progress_model.dart';
import '../providers/puzzle_academy_provider.dart';
import 'puzzle_grid_screen.dart';
import 'puzzle_node_screen.dart';

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
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF101A2A).withValues(alpha: 0.95),
                    const Color(0xFF0B1420).withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFF6FE7FF).withValues(alpha: 0.24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6FE7FF).withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      color: Color(0xFF6FE7FF),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Brain Break',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ten puzzles down. Take the premium recovery loop, then re-enter with sharper calculation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await provider.watchRewardedAd();
                      if (!mounted) return;
                      navigator.pop();
                    },
                    icon: const Icon(Icons.ondemand_video),
                    label: const Text('Watch Rewarded Ad (+10 Coins)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

  void _openStore(PuzzleAcademyProvider provider) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Academy Store',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 12),
              _StoreRow(
                icon: Icons.lightbulb_outline,
                title: 'Hint Pack',
                subtitle: '+3 Smart Hints',
                price: '25 coins',
                onBuy: () async {
                  final navigator = Navigator.of(context);
                  final ok = await provider.buyHintPack();
                  if (!mounted) return;
                  if (ok) navigator.pop();
                },
              ),
              const SizedBox(height: 10),
              _StoreRow(
                icon: Icons.skip_next_rounded,
                title: 'Skip Pack',
                subtitle: '+2 Tactical Skips',
                price: '35 coins',
                onBuy: () async {
                  final navigator = Navigator.of(context);
                  final ok = await provider.buySkipPack();
                  if (!mounted) return;
                  if (ok) navigator.pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
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
                _LeaderboardCard(entries: provider.dailyLeaderboard),
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
            onPressed: () => _openStore(provider),
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
                            ),
                          ),
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
          _LeaderboardCard(entries: provider.dailyLeaderboard),
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
                label: 'Skips',
                value: provider.progress.freeSkips.toString(),
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
        showSpeed:
          provider.hasSpeedDemonBadge(node.key) &&
          node.startElo != 450 &&
          node.startElo != 750,
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleNodeScreen(
          node: dailyNode,
          heroTag: provider.heroTagForNode(dailyNode),
          initialPuzzle: daily,
          initialPuzzleIndex: provider.indexOfPuzzleInNode(
            dailyNode,
            daily.puzzleId,
          ),
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
    await showUniversalSettingsSheet(
      context: context,
      title: 'Settings',
      isAcademyMode: true,
      showBoardPerspectiveSection: false,
      showEngineControlsSection: false,
      themeMode: theme.themeMode,
      themeStyle: theme.themeStyle,
      soundEnabled: soundEnabled,
      hapticsEnabled: hapticsEnabled,
      onThemeModeChanged: (mode) async {
        await theme.setThemeMode(mode);
      },
      onThemeStyleChanged: (style) async {
        await theme.setThemeStyle(style);
      },
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

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.10 : 0.04,
              ),
              scheme.surface,
            ).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.alphaBlend(
                accent.withValues(alpha: 0.26),
                scheme.outline,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.total,
    required this.completed,
    required this.hasTodayPuzzle,
    required this.onTap,
  });

  final int total;
  final int completed;
  final bool hasTodayPuzzle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = total <= 0
        ? 0.0
        : (completed / max(1, total)).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.16 : 0.06,
                  ),
                  scheme.surface,
                ).withValues(alpha: 0.96),
                Color.alphaBlend(
                  scheme.secondary.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.10 : 0.04,
                  ),
                  scheme.surface,
                ).withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.30)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Challenge',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  !hasTodayPuzzle
                      ? 'No daily set available for today yet.'
                      : '$completed / $total solved in today\'s challenge set',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress,
                    backgroundColor: scheme.outline.withValues(alpha: 0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFD8B640),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: hasTodayPuzzle ? onTap : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5AAEE8),
                      foregroundColor: const Color(0xFF07131F),
                      disabledBackgroundColor: scheme.outline.withValues(
                        alpha: 0.20,
                      ),
                      disabledForegroundColor: scheme.onSurface.withValues(
                        alpha: 0.42,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      hasTodayPuzzle
                          ? "Solve Today's Puzzle"
                          : 'Check Back Later!',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      title: 'Top 10 Global',
      accent: const Color(0xFF6FE7FF),
      child: Column(
        children: entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${entry.rank}',
                        style: const TextStyle(
                          color: Color(0xFFD8B640),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.handle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.score.toString(),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SemesterHeader extends StatelessWidget {
  const _SemesterHeader({required this.semester, required this.progress});

  final SemesterRange semester;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.10 : 0.04,
              ),
              scheme.surface,
            ).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${semester.title} • ${semester.minElo}-${semester.maxElo}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: progress,
                  backgroundColor: scheme.outline.withValues(alpha: 0.22),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6FE7FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PuzzleNodeCard extends StatelessWidget {
  const _PuzzleNodeCard({
    required this.node,
    required this.compact,
    required this.heroTag,
    required this.showGhost,
    required this.showSpeed,
    required this.onTap,
  });

  final EloNodeProgress node;
  final bool compact;
  final String heroTag;
  final bool showGhost;
  final bool showSpeed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !node.unlocked;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cardBase = Color.alphaBlend(
      scheme.primary.withValues(
        alpha: locked
            ? (theme.brightness == Brightness.dark ? 0.05 : 0.02)
            : (theme.brightness == Brightness.dark ? 0.11 : 0.05),
      ),
      scheme.surface,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: locked
                  ? [
                      cardBase.withValues(alpha: 0.94),
                      Color.alphaBlend(
                        scheme.primary.withValues(alpha: 0.02),
                        scheme.surface,
                      ).withValues(alpha: 0.90),
                    ]
                  : [
                      cardBase.withValues(alpha: 0.96),
                      Color.alphaBlend(
                        scheme.secondary.withValues(alpha: 0.05),
                        scheme.surface,
                      ).withValues(alpha: 0.92),
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: locked
                  ? scheme.outline.withValues(alpha: 0.25)
                  : scheme.outline.withValues(alpha: 0.34),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: compact
                  ? _buildCompactContent(context, locked)
                  : _buildPortraitContent(context, locked),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContent(BuildContext context, bool locked) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _HeroBadge(heroTag: heroTag, node: node, locked: locked),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${node.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${node.solvedCount}/${node.masteryTarget} mastered',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _statusCluster(),
          ],
        ),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: node.masteryProgress,
            backgroundColor: scheme.outline.withValues(alpha: 0.22),
            valueColor: AlwaysStoppedAnimation<Color>(
              node.goldCrown
                  ? const Color(0xFFD8B640)
                  : const Color(0xFF6FE7FF),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                locked
                    ? 'Locked until previous Level reaches 100 solves.'
                    : 'Open for training',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.66),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: locked
                    ? Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.28)
                    : const Color(0xFF5AAEE8),
                foregroundColor: locked
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.70)
                    : const Color(0xFF07131F),
              ),
              child: Text(locked ? 'Locked' : 'Train'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortraitContent(BuildContext context, bool locked) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _HeroBadge(heroTag: heroTag, node: node, locked: locked),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Level ${node.title}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: locked
                          ? scheme.onSurface.withValues(alpha: 0.72)
                          : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusCluster(),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${node.solvedCount}/${node.unlockTarget} to unlock next Level • ${node.solvedCount}/${node.masteryTarget} for crown',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.66),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: node.masteryProgress,
                  backgroundColor: scheme.outline.withValues(alpha: 0.22),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    node.goldCrown
                        ? const Color(0xFFD8B640)
                        : const Color(0xFF6FE7FF),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: locked
                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.28)
                : const Color(0xFF5AAEE8),
            foregroundColor: locked
                ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.70)
                : const Color(0xFF07131F),
          ),
          child: Text(locked ? 'Locked' : 'Train'),
        ),
      ],
    );
  }

  Widget _statusCluster() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (node.goldCrown)
          const _Tag(
            text: 'Gold Crown',
            color: Color(0xFFD8B640),
            icon: Icons.workspace_premium,
          ),
        if (showGhost)
          const _Tag(
            text: 'Ghost',
            color: Color(0xFFB8D6F3),
            icon: Icons.history_toggle_off_rounded,
          ),
        if (showSpeed)
          const _Tag(
            text: 'Speed Demon',
            color: Color(0xFF9BE27C),
            icon: Icons.flash_on_rounded,
          ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.heroTag,
    required this.node,
    required this.locked,
  });

  final String heroTag;
  final EloNodeProgress node;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: locked
                  ? [
                      Color.alphaBlend(
                        scheme.primary.withValues(alpha: 0.06),
                        scheme.surface,
                      ),
                      scheme.surface,
                    ]
                  : [
                      Color.alphaBlend(
                        scheme.primary.withValues(alpha: 0.20),
                        scheme.surface,
                      ),
                      Color.alphaBlend(
                        scheme.secondary.withValues(alpha: 0.08),
                        scheme.surface,
                      ),
                    ],
            ),
            border: Border.all(
              color: node.goldCrown
                  ? const Color(0xFFD8B640)
                  : scheme.primary.withValues(alpha: 0.50),
            ),
          ),
          child: Center(
            child: Text(
              '${node.startElo}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color, required this.icon});

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onBuy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.10 : 0.04,
          ),
          scheme.surface,
        ).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.66),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFFD8B640),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onBuy, child: const Text('Buy')),
        ],
      ),
    );
  }
}
