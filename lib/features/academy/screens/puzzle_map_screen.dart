import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/services/ad_service.dart';
import 'package:chessiq/core/services/purchase_service.dart';
import 'package:chessiq/core/services/scoreboard_service.dart';
import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/models/puzzle_progress_model.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/academy/screens/puzzle_grid_screen.dart';
import 'package:chessiq/features/academy/screens/puzzle_node_screen.dart';
import 'package:chessiq/features/academy/widgets/academy_theme_settings_sheet.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/country_names.dart';
import '../data/profanity_filter.dart';

part 'package:chessiq/features/academy/widgets/puzzle_map_components.dart';

enum _LeaderboardScope { international, national }

enum _AcademyEntryView { hub, exams }

class _AcademyHubFlightData {
  const _AcademyHubFlightData({
    required this.cardId,
    required this.title,
    required this.imageAsset,
    required this.accent,
    required this.shadowColor,
    required this.icon,
    required this.rect,
  });

  final String cardId;
  final String title;
  final String imageAsset;
  final Color accent;
  final Color shadowColor;
  final IconData icon;
  final Rect rect;
}

class PuzzleMapScreen extends StatefulWidget {
  const PuzzleMapScreen({
    super.key,
    required this.onBack,
    required this.onOpenOpeningQuiz,
    this.cinematicThemeEnabled = false,
    this.onShowCredits,
    this.onOpenMainStore,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenOpeningQuiz;
  final VoidCallback? onShowCredits;
  final VoidCallback? onOpenMainStore;
  final bool cinematicThemeEnabled;

  @override
  State<PuzzleMapScreen> createState() => _PuzzleMapScreenState();
}

class _PuzzleMapScreenState extends State<PuzzleMapScreen>
    with TickerProviderStateMixin {
  static const String _muteSoundsKey = 'mute_sounds_v1';
  static const String _hapticsEnabledKey = 'haptics_enabled_v1';
  static const String _storeStateKey = 'store_state_v1';
  static const String _academyTuitionPassKey = 'academyTuitionPassOwned';

  bool _didPrimeUi = false;
  bool _didShowAcademyProfilePrompt = false;
  bool _pendingEducationInFlight = false;
  bool _postFrameWorkQueued = false;
  bool _dismissedProfileSetupToMenu = false;
  String? _lastCelebrationKey;
  _LeaderboardScope _leaderboardScope = _LeaderboardScope.international;
  late final ConfettiController _confettiController;
  AudioPlayer? _academyStoreSfxPlayer;
  late final Ticker _academyBlueDotTicker;
  late final ValueNotifier<double> _academyBlueDotTime;
  late final double _academyBlueDotPhase;
  late final double _academyBlueDotShapeSeed;
  late final double _academyBlueDotTrajectoryNoise;
  late final double _academyBlueDotRadius;
  late final double _academyYellowDotPhase;
  late final double _academyYellowDotShapeSeed;
  late final double _academyYellowDotTrajectoryNoise;
  late final double _academyYellowDotRadius;
  late final AnimationController _academyHubFlightController;
  Duration _academyBlueDotLastTick = Duration.zero;

  final GlobalKey _academyRootContentKey = GlobalKey();
  final GlobalKey _academyHubExamsCardKey = GlobalKey();
  final GlobalKey _academyHubQuizCardKey = GlobalKey();
  final Set<String> _expandedSemesterTitles = <String>{};
  bool _expandedSemesterInitialized = false;
  _AcademyEntryView _activeView = _AcademyEntryView.hub;
  String? _academyHubLaunchingCardId;
  String? _academyHubHoveredCardId;
  String? _academyHubPressedCardId;
  bool _academyHubLaunchInFlight = false;
  _AcademyHubFlightData? _academyHubFlight;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 2200),
    );

    final random = Random();
    _academyBlueDotPhase = random.nextDouble() * 2 * pi;
    _academyBlueDotShapeSeed = random.nextDouble() * 3.2;
    _academyBlueDotTrajectoryNoise = random.nextDouble();
    _academyBlueDotRadius = 0.58 + random.nextDouble() * 0.12;
    _academyYellowDotPhase = random.nextDouble() * 2 * pi + pi / 3;
    _academyYellowDotShapeSeed = random.nextDouble() * 3.2 + 0.35;
    _academyYellowDotTrajectoryNoise = random.nextDouble();
    _academyYellowDotRadius = 0.56 + random.nextDouble() * 0.14;
    _academyHubFlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _academyBlueDotTime = ValueNotifier<double>(0.0);
    _academyBlueDotTicker = createTicker((elapsed) {
      final delta = elapsed - _academyBlueDotLastTick;
      _academyBlueDotLastTick = elapsed;
      final nextTime =
          (_academyBlueDotTime.value + delta.inMilliseconds / 1000.0) % 1024.0;
      _academyBlueDotTime.value = nextTime;
    })..start();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _academyHubFlightController.dispose();
    _academyBlueDotTicker.dispose();
    _academyBlueDotTime.dispose();
    _academyStoreSfxPlayer?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrimeUi) return;
    _didPrimeUi = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_dismissedProfileSetupToMenu) return;
      final provider = context.read<PuzzleAcademyProvider>();
      try {
        await provider.initialize();
      } catch (e) {
        if (!mounted) return;
        return;
      }
      if (!mounted) return;
      if (_dismissedProfileSetupToMenu) return;
      _didShowAcademyProfilePrompt = true;
      try {
        await _ensureAcademyProfile(provider);
      } finally {
        _didShowAcademyProfilePrompt = false;
      }
      if (!mounted) return;
      await _showPendingEducation(provider);
    });
  }

  Future<void> _ensureAcademyProfile(PuzzleAcademyProvider provider) async {
    if (!mounted || !provider.initialized) return;
    if (_dismissedProfileSetupToMenu) return;
    if (!provider.shouldAskForProfile) {
      // Best-effort sync for existing local profiles created before strict
      // backend registration was enforced.
      unawaited(
        provider.registerAcademyProfile(
          handle: provider.progress.handle,
          country: provider.progress.country,
        ),
      );
      return;
    }
    await _showAcademyProfileDialog(provider, allowExitToMenu: true);
  }

  Future<Map<String, String>?> _promptAcademyProfileDialog({
    required String initialHandle,
    required String initialCountry,
    required bool lockHandle,
    required bool lockCountry,
    bool allowExitToMenu = false,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AcademyProfileDialog(
          initialHandle: initialHandle,
          initialCountry: initialCountry,
          lockHandle: lockHandle,
          lockCountry: lockCountry,
          allowExitToMenu: allowExitToMenu,
        );
      },
    );
  }

  Future<void> _showAcademyProfileDialog(
    PuzzleAcademyProvider provider, {
    bool lockHandle = false,
    bool lockCountry = false,
    bool allowExitToMenu = false,
  }) async {
    var initialHandle = provider.progress.handle;
    var initialCountry = provider.progress.country;

    while (mounted) {
      final result = await _promptAcademyProfileDialog(
        initialHandle: initialHandle,
        initialCountry: initialCountry,
        lockHandle: lockHandle,
        lockCountry: lockCountry,
        allowExitToMenu: allowExitToMenu,
      );

      if (!mounted) return;
      if (result == null) {
        if (allowExitToMenu) {
          _dismissedProfileSetupToMenu = true;
          widget.onBack();
        }
        return;
      }

      final handle = (result['handle'] ?? '').trim();
      final country = (result['country'] ?? '').trim();

      // Keep the latest typed values so transient backend errors do not force
      // the user to re-enter profile details on retry.
      initialHandle = handle;
      initialCountry = country;

      final status = await provider.registerAcademyProfile(
        handle: handle,
        country: country,
      );
      if (!mounted) return;

      if (status == HandleAvailabilityStatus.verificationUnavailable) {
        final errorDetail = provider.lastRegistrationError ?? 'Unknown error';
        final shouldRetry =
            await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Registration Failed'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ChessIQ could not register this profile right now. Please check your connection and try again.',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Details: $errorDetail',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Back to Menu'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!mounted) return;
        if (!shouldRetry) return;
        continue;
      }

      if (status == HandleAvailabilityStatus.taken) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Nickname Already In Use'),
            content: const Text(
              'That nickname is already used on the leaderboard. Please choose a different one.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        initialHandle = handle;
        initialCountry = country;
        continue;
      }

      await provider.updateAcademyProfile(handle: handle, country: country);
      return;
    }
  }

  Future<void> _showPendingEducation(PuzzleAcademyProvider provider) async {
    if (_pendingEducationInFlight) return;
    _pendingEducationInFlight = true;
    try {
      if (!mounted || !provider.initialized) return;
      if (provider.shouldAskForProfile) return;

      final unlockedNodes = provider.orderedNodes.where(
        (node) => node.unlocked,
      );
      final firstUnlocked = unlockedNodes.isEmpty
          ? null
          : unlockedNodes.reduce((a, b) => a.startElo < b.startElo ? a : b);
      if (firstUnlocked != null && provider.semesters.isNotEmpty) {
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
    } finally {
      _pendingEducationInFlight = false;
    }
  }

  Widget _buildScoreboardSection(
    PuzzleAcademyProvider provider,
    bool monochrome,
  ) {
    final selectedInternational =
        _leaderboardScope == _LeaderboardScope.international;
    final selectedNational = _leaderboardScope == _LeaderboardScope.national;
    final internationalTone = _accentCyan(context);
    final nationalTone = _accentGold(context);
    final entries = provider.academyScoreboardEntries;
    final title = _leaderboardScope == _LeaderboardScope.international
        ? 'International Top 10'
        : provider.progress.country.trim().isNotEmpty
        ? '${provider.progress.country.trim()} Top 10'
        : 'National Top 10';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _leaderboardScope = _LeaderboardScope.international;
                  });
                  provider.refreshRemoteScoreboard(national: false);
                },
                style: _academyFilledButtonStyle(
                  backgroundColor: selectedInternational
                      ? internationalTone.withValues(
                          alpha: monochrome ? 0.88 : 0.94,
                        )
                      : internationalTone.withValues(
                          alpha: monochrome ? 0.20 : 0.14,
                        ),
                  foregroundColor: selectedInternational
                      ? const Color(0xFF081517)
                      : internationalTone,
                  monochrome: monochrome,
                  side: BorderSide(
                    color: internationalTone.withValues(
                      alpha: selectedInternational ? 0.92 : 0.42,
                    ),
                  ),
                  radius: 18,
                ),
                child: const Text('International'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _leaderboardScope = _LeaderboardScope.national;
                  });
                  provider.refreshRemoteScoreboard(national: true);
                },
                style: _academyFilledButtonStyle(
                  backgroundColor: selectedNational
                      ? nationalTone.withValues(alpha: monochrome ? 0.88 : 0.94)
                      : nationalTone.withValues(
                          alpha: monochrome ? 0.22 : 0.15,
                        ),
                  foregroundColor: selectedNational
                      ? const Color(0xFF191204)
                      : nationalTone,
                  monochrome: monochrome,
                  side: BorderSide(
                    color: nationalTone.withValues(
                      alpha: selectedNational ? 0.92 : 0.44,
                    ),
                  ),
                  radius: 18,
                ),
                child: const Text('National'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 12),
        _LeaderboardCard(
          entries: entries,
          title: title,
          monochrome: monochrome,
          emptyLabel: 'Complete an exam to post your first Academy score.',
        ),
      ],
    );
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

  void _queuePostFrameWork(PuzzleAcademyProvider provider) {
    if (_postFrameWorkQueued) return;
    _postFrameWorkQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _postFrameWorkQueued = false;
      if (!mounted) return;
      if (_dismissedProfileSetupToMenu) return;

      if (provider.initialized && provider.shouldAskForProfile) {
        if (!_didShowAcademyProfilePrompt) {
          _didShowAcademyProfilePrompt = true;
          try {
            await _ensureAcademyProfile(provider);
          } finally {
            _didShowAcademyProfilePrompt = false;
          }
        }
        return;
      }

      _handleCelebration(provider);
      await _showPendingEducation(provider);
      if (!mounted) return;

      if (!provider.scoreboardLoaded && !provider.scoreboardSyncing) {
        unawaited(
          provider.refreshRemoteScoreboard(
            national: _leaderboardScope == _LeaderboardScope.national,
          ),
        );
      }
    });
  }

  Future<void> _showSemesterIntroDialog(SemesterRange semester) async {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final panelTop = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
      scheme.surface,
    );
    final panelBottom = Color.alphaBlend(
      scheme.secondary.withValues(alpha: isDark ? 0.18 : 0.10),
      scheme.surface,
    );

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
                  colors: [panelTop, panelBottom],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.38),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    semester.title,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    semester.intro,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.82),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
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
    final academyAdFree = await _isAcademyTuitionPassOwned();
    final shown = academyAdFree
        ? true
        : await AdService.instance.showInterstitialAd();
    if (!shown || !mounted) return;

    final economy = context.read<EconomyProvider>();
    await economy.awardAcademyInterstitialCoins();
    await provider.syncCoinsFromStoreState(notify: true);
    if (!mounted) return;
    await _showStatusDialog(
      title: 'Academy Break Complete',
      message: '+10 coins.',
    );
  }

  Future<bool> _isAcademyTuitionPassOwned() async {
    // Check IAP delivery flag first (survives reinstall / restore).
    if (await PurchaseService.instance.isOwned(IapProducts.academyPass)) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeStateKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return false;
    }
    final owned = decoded[_academyTuitionPassKey];
    return owned == true;
  }

  Future<void> _showStatusDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: _academyFilledButtonStyle(
              backgroundColor: Theme.of(dialogContext).colorScheme.primary,
              foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
              monochrome: monochrome,
            ),
            child: const Text('OK'),
          ),
        ],
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

  void _openStore() {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.9,
            ),
            child: Consumer<PuzzleAcademyProvider>(
              builder: (context, liveProvider, _) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    22 + mediaQuery.padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Academy Store',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
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
                        monochrome:
                            context.read<AppThemeProvider>().isMonochrome ||
                            widget.cinematicThemeEnabled,
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
                        monochrome:
                            context.read<AppThemeProvider>().isMonochrome ||
                            widget.cinematicThemeEnabled,
                        onBuy: () async {
                          final ok = await liveProvider.buySkipPack();
                          if (!mounted || !ok) return;
                          unawaited(_playAcademyBuySound());
                        },
                      ),
                      const SizedBox(height: 10),
                      _StoreRow(
                        icon: Icons.person_outline,
                        title: 'New Nickname',
                        subtitle:
                            'Ready for a new identity? Change your nickname.',
                        price: '500 coins',
                        monochrome:
                            context.read<AppThemeProvider>().isMonochrome ||
                            widget.cinematicThemeEnabled,
                        onBuy: () async {
                          final ok = await liveProvider.buyNicknameReset();
                          if (!mounted) return;
                          if (!ok) {
                            await _showStatusDialog(
                              title: 'Not Enough Coins',
                              message: 'Not enough coins to change nickname.',
                            );
                            return;
                          }
                          unawaited(_playAcademyBuySound());
                          _didShowAcademyProfilePrompt = true;
                          try {
                            if (!mounted) return;
                            await _showAcademyProfileDialog(
                              liveProvider,
                              lockCountry: true,
                            );
                          } finally {
                            _didShowAcademyProfilePrompt = false;
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _StoreRow(
                        icon: Icons.flag_outlined,
                        title: 'Change Country',
                        subtitle:
                            'Moved to a new place? Update your country/region.',
                        price: '500 coins',
                        monochrome:
                            context.read<AppThemeProvider>().isMonochrome ||
                            widget.cinematicThemeEnabled,
                        onBuy: () async {
                          final ok = await liveProvider.buyCountryReset();
                          if (!mounted) return;
                          if (!ok) {
                            await _showStatusDialog(
                              title: 'Not Enough Coins',
                              message: 'Not enough coins to change country.',
                            );
                            return;
                          }
                          unawaited(_playAcademyBuySound());
                          _didShowAcademyProfilePrompt = true;
                          try {
                            if (!mounted) return;
                            await _showAcademyProfileDialog(
                              liveProvider,
                              lockHandle: true,
                            );
                          } finally {
                            _didShowAcademyProfilePrompt = false;
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: widget.onOpenMainStore,
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Open Store'),
                        style: _academyFilledButtonStyle(
                          backgroundColor: scheme.surface,
                          foregroundColor: scheme.onSurface,
                          monochrome:
                              context.read<AppThemeProvider>().isMonochrome ||
                              widget.cinematicThemeEnabled,
                          side: BorderSide(
                            color: scheme.outline.withValues(alpha: 0.30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          radius: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _playAcademyBuySound() async {
    final prefs = await SharedPreferences.getInstance();
    final muted = prefs.getBool(_muteSoundsKey) ?? false;
    if (muted) {
      return;
    }

    try {
      final player = _academyStoreSfxPlayer ??= AudioPlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.play(
        AssetSource('sounds/academybuy.mp3'),
        mode: PlayerMode.lowLatency,
        volume: 1.0,
      );
    } catch (_) {
      // Keep purchases smooth even if audio playback fails.
    }
  }

  void _openAcademyExams() {
    if (_activeView == _AcademyEntryView.exams) {
      return;
    }
    setState(() {
      _activeView = _AcademyEntryView.exams;
    });
  }

  void _handleAcademyBack() {
    if (_activeView == _AcademyEntryView.exams) {
      setState(() {
        _activeView = _AcademyEntryView.hub;
      });
      return;
    }
    widget.onBack();
  }

  GlobalKey _academyHubCardKeyFor(String cardId) {
    return cardId == 'quiz' ? _academyHubQuizCardKey : _academyHubExamsCardKey;
  }

  void _setAcademyHubHoveredCard(String? cardId) {
    if (_academyHubLaunchInFlight || _academyHubHoveredCardId == cardId) {
      return;
    }
    setState(() {
      _academyHubHoveredCardId = cardId;
    });
  }

  void _setAcademyHubPressedCard(String? cardId) {
    if (_academyHubLaunchInFlight || _academyHubPressedCardId == cardId) {
      return;
    }
    setState(() {
      _academyHubPressedCardId = cardId;
    });
  }

  _AcademyHubFlightData? _captureAcademyHubFlight({
    required String cardId,
    required String title,
    required String imageAsset,
    required Color accent,
    required Color shadowColor,
    required IconData icon,
  }) {
    final stackContext = _academyRootContentKey.currentContext;
    final cardContext = _academyHubCardKeyFor(cardId).currentContext;
    if (stackContext == null || cardContext == null) {
      return null;
    }

    final stackBox = stackContext.findRenderObject() as RenderBox?;
    final cardBox = cardContext.findRenderObject() as RenderBox?;
    if (stackBox == null || cardBox == null) {
      return null;
    }

    final topLeft = cardBox.localToGlobal(Offset.zero, ancestor: stackBox);
    return _AcademyHubFlightData(
      cardId: cardId,
      title: title,
      imageAsset: imageAsset,
      accent: accent,
      shadowColor: shadowColor,
      icon: icon,
      rect: topLeft & cardBox.size,
    );
  }

  Future<void> _runAcademyHubLaunchAnimation({
    required String cardId,
    required String title,
    required String imageAsset,
    required Color accent,
    required Color shadowColor,
    required IconData icon,
    required VoidCallback onComplete,
  }) async {
    if (_academyHubLaunchInFlight) {
      return;
    }

    final flight = _captureAcademyHubFlight(
      cardId: cardId,
      title: title,
      imageAsset: imageAsset,
      accent: accent,
      shadowColor: shadowColor,
      icon: icon,
    );
    if (flight == null) {
      onComplete();
      return;
    }

    setState(() {
      _academyHubLaunchInFlight = true;
      _academyHubLaunchingCardId = cardId;
      _academyHubHoveredCardId = null;
      _academyHubPressedCardId = null;
      _academyHubFlight = flight;
    });

    try {
      await _academyHubFlightController.forward(from: 0.0);
      if (mounted) {
        onComplete();
      }
    } finally {
      if (mounted) {
        _academyHubFlightController.value = 0.0;
        setState(() {
          _academyHubLaunchInFlight = false;
          _academyHubLaunchingCardId = null;
          _academyHubFlight = null;
          _academyHubPressedCardId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<PuzzleAcademyProvider>(
        builder: (context, provider, _) {
          final materialTheme = Theme.of(context);
          final scheme = materialTheme.colorScheme;
          final isDark = materialTheme.brightness == Brightness.dark;
          final themeProvider = context.watch<AppThemeProvider>();
          final monochrome =
              themeProvider.isMonochrome || widget.cinematicThemeEnabled;

          if (provider.isLoading || !provider.initialized) {
            return Center(child: _buildAcademyLoadingIndicator(materialTheme));
          }

          _queuePostFrameWork(provider);

          return OrientationBuilder(
            builder: (context, orientation) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final leadTone = monochrome
                      ? const Color(0xFF808080)
                      : scheme.primary;
                  final altTone = monochrome
                      ? const Color(0xFFA6A6A6)
                      : scheme.secondary;
                  final rootContent = Stack(
                    key: _academyRootContentKey,
                    children: [
                      Positioned.fill(
                        child: _buildAtmosphere(
                          monochrome,
                          includeYellow: _activeView == _AcademyEntryView.hub,
                        ),
                      ),
                      if (_activeView == _AcademyEntryView.hub)
                        _buildAcademyHub(
                          constraints: constraints,
                          themeProvider: themeProvider,
                          monochrome: monochrome,
                        )
                      else
                        _buildAcademyExamsView(
                          provider,
                          constraints: constraints,
                          themeProvider: themeProvider,
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
                      if (_academyHubFlight != null)
                        Positioned.fill(
                          child: _buildAcademyHubFlightOverlay(isDark: isDark),
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
                            leadTone.withValues(alpha: isDark ? 0.16 : 0.12),
                            scheme.surface,
                          ),
                          scheme.surface,
                          Color.alphaBlend(
                            altTone.withValues(alpha: isDark ? 0.10 : 0.08),
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
      ),
    );
  }

  Widget _buildAcademyHub({
    required BoxConstraints constraints,
    required AppThemeProvider themeProvider,
    required bool monochrome,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final sideBySide = constraints.maxWidth >= 920;
    final maxContentWidth = sideBySide ? 1180.0 : 760.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        max(24, 20 + media.padding.bottom),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxContentWidth,
            minHeight: max(0.0, constraints.maxHeight - 36),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _handleAcademyBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Back to menu',
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: widget.onShowCredits,
                        child: Image.asset(
                          'assets/ChessIQ.png',
                          width: 150,
                          height: 42,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Settings',
                            onPressed: () =>
                                _openQuickThemeSettings(themeProvider),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: _openStore,
                            icon: const Icon(Icons.storefront_outlined),
                            tooltip: 'Academy store',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildAcademyHubSelector(
                sideBySide: sideBySide,
                monochrome: monochrome,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcademyHubSelector({
    required bool sideBySide,
    required bool monochrome,
    required bool isDark,
  }) {
    final examsAccent = monochrome
        ? const Color(0xFFE2E6EC)
        : const Color(0xFF6FE7FF);
    final quizAccent = monochrome
        ? const Color(0xFFF0E9DC)
        : const Color(0xFFD8B640);
    final activeAccent = switch (_academyHubLaunchingCardId) {
      'exams' => examsAccent,
      'quiz' => quizAccent,
      _ => Color.lerp(examsAccent, quizAccent, 0.5)!,
    };
    final examsCard = _buildAcademyHubCard(
      cardId: 'exams',
      title: 'Puzzle Academy Exams',
      imageAsset: 'assets/academy/exam.png',
      accent: examsAccent,
      shadowColor: monochrome
          ? const Color(0xFF9FA7B3)
          : const Color(0xFF137A9A),
      icon: Icons.extension_outlined,
      monochrome: monochrome,
      isDark: isDark,
      onTap: () => unawaited(
        _runAcademyHubLaunchAnimation(
          cardId: 'exams',
          title: 'Puzzle Academy Exams',
          imageAsset: 'assets/academy/exam.png',
          accent: examsAccent,
          shadowColor: monochrome
              ? const Color(0xFF9FA7B3)
              : const Color(0xFF137A9A),
          icon: Icons.extension_outlined,
          onComplete: _openAcademyExams,
        ),
      ),
    );
    final quizCard = _buildAcademyHubCard(
      cardId: 'quiz',
      title: 'Opening Quiz',
      imageAsset: 'assets/academy/quiz.png',
      accent: quizAccent,
      shadowColor: monochrome
          ? const Color(0xFFB4AB9B)
          : const Color(0xFF8A6714),
      icon: Icons.menu_book_outlined,
      monochrome: monochrome,
      isDark: isDark,
      onTap: () => unawaited(
        _runAcademyHubLaunchAnimation(
          cardId: 'quiz',
          title: 'Opening Quiz',
          imageAsset: 'assets/academy/quiz.png',
          accent: quizAccent,
          shadowColor: monochrome
              ? const Color(0xFFB4AB9B)
              : const Color(0xFF8A6714),
          icon: Icons.menu_book_outlined,
          onComplete: widget.onOpenOpeningQuiz,
        ),
      ),
    );

    final selectorBody = sideBySide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -10),
                  child: examsCard,
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, 10),
                  child: quizCard,
                ),
              ),
            ],
          )
        : Column(
            children: [
              Transform.rotate(angle: -0.012, child: examsCard),
              const SizedBox(height: 28),
              Transform.rotate(angle: 0.012, child: quizCard),
            ],
          );

    return AnimatedBuilder(
      animation: _academyBlueDotTime,
      builder: (context, child) {
        final pulse = 0.5 + 0.5 * sin(_academyBlueDotTime.value * 0.8);
        final radius = BorderRadius.circular(sideBySide ? 38 : 32);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: sideBySide ? 22 : 10,
              top: sideBySide ? 6 : 4,
              child: IgnorePointer(
                child: Container(
                  width: sideBySide ? 180 : 124,
                  height: sideBySide ? 104 : 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: RadialGradient(
                      colors: [
                        examsAccent.withValues(alpha: monochrome ? 0.10 : 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: sideBySide ? 18 : 10,
              bottom: sideBySide ? 10 : 6,
              child: IgnorePointer(
                child: Container(
                  width: sideBySide ? 190 : 132,
                  height: sideBySide ? 112 : 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: RadialGradient(
                      colors: [
                        quizAccent.withValues(alpha: monochrome ? 0.10 : 0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    sideBySide ? 22 : 14,
                    sideBySide ? 28 : 20,
                    sideBySide ? 22 : 14,
                    sideBySide ? 28 : 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(
                          alpha: monochrome
                              ? (isDark ? 0.14 : 0.24)
                              : (isDark ? 0.08 : 0.20),
                        ),
                        activeAccent.withValues(
                          alpha: monochrome
                              ? (isDark ? 0.05 : 0.08)
                              : (isDark
                                    ? 0.06 + pulse * 0.03
                                    : 0.10 + pulse * 0.04),
                        ),
                        Colors.white.withValues(
                          alpha: monochrome
                              ? (isDark ? 0.10 : 0.18)
                              : (isDark ? 0.06 : 0.13),
                        ),
                      ],
                    ),
                    borderRadius: radius,
                    border: Border.all(
                      color: Color.alphaBlend(
                        activeAccent.withValues(alpha: 0.14 + pulse * 0.08),
                        Colors.white.withValues(alpha: 0.30),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeAccent.withValues(
                          alpha: 0.07 + pulse * 0.04,
                        ),
                        blurRadius: 32,
                        spreadRadius: 0.5,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.30 : 0.10,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: monochrome ? 0.05 : 0.14,
                                  ),
                                  Colors.white.withValues(alpha: 0.01),
                                  activeAccent.withValues(
                                    alpha: monochrome ? 0.02 : 0.05,
                                  ),
                                ],
                                stops: const [0.0, 0.38, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -50,
                        top: 12 + sin(_academyBlueDotTime.value * 0.55) * 12,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: -0.42,
                            child: Container(
                              width: 160,
                              height: 240,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    examsAccent.withValues(
                                      alpha: monochrome ? 0.04 : 0.08,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -40,
                        bottom: -8 + cos(_academyBlueDotTime.value * 0.48) * 10,
                        child: IgnorePointer(
                          child: Transform.rotate(
                            angle: 0.38,
                            child: Container(
                              width: 180,
                              height: 250,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    quizAccent.withValues(
                                      alpha: monochrome ? 0.04 : 0.08,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 26,
                        right: 26,
                        top: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 1.1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.60),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      selectorBody,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAcademyHubCard({
    required String cardId,
    required String title,
    required String imageAsset,
    required Color accent,
    required Color shadowColor,
    required IconData icon,
    required bool monochrome,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final cardKey = _academyHubCardKeyFor(cardId);
    final isHovered = _academyHubHoveredCardId == cardId;
    final isPressed = _academyHubPressedCardId == cardId;
    final isLaunching = _academyHubLaunchingCardId == cardId;
    final isDimmed =
        _academyHubLaunchingCardId != null &&
        _academyHubLaunchingCardId != cardId;
    final cardScale = isLaunching
        ? 1.038
        : isPressed
        ? 0.992
        : isHovered
        ? 1.018
        : 1.0;
    final cardOffset = isLaunching
        ? const Offset(0, -0.028)
        : isPressed
        ? const Offset(0, 0.010)
        : isHovered
        ? const Offset(0, -0.014)
        : Offset.zero;
    final cardTurns = isLaunching
        ? 0.003
        : isHovered
        ? (cardId == 'exams' ? -0.0016 : 0.0016)
        : 0.0;
    final imageScale = isLaunching
        ? 1.16
        : isPressed
        ? 1.02
        : isHovered
        ? 1.05
        : 1.0;
    final imageOffset = isLaunching
        ? (cardId == 'exams'
              ? const Offset(-0.02, -0.03)
              : const Offset(0.02, -0.03))
        : isHovered
        ? (cardId == 'exams' ? const Offset(-0.01, 0) : const Offset(0.01, 0))
        : Offset.zero;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final slide = (1 - value) * 16;
          return Transform.translate(
            offset: Offset(0, slide),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: RepaintBoundary(
          key: cardKey,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => _setAcademyHubHoveredCard(cardId),
            onExit: (_) => _setAcademyHubHoveredCard(null),
            child: Semantics(
              button: true,
              label: title,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                opacity: isDimmed ? 0.74 : 1.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  scale: cardScale,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    offset: cardOffset,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      turns: cardTurns,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor.withValues(
                                alpha: isLaunching
                                    ? (isDark ? 0.34 : 0.30)
                                    : isHovered
                                    ? (isDark ? 0.30 : 0.27)
                                    : (isDark ? 0.26 : 0.22),
                              ),
                              blurRadius: isLaunching
                                  ? 42
                                  : isHovered
                                  ? 38
                                  : 34,
                              spreadRadius: isLaunching
                                  ? 4
                                  : isHovered
                                  ? 3
                                  : 2,
                              offset: Offset(
                                0,
                                isLaunching
                                    ? 24
                                    : isHovered
                                    ? 22
                                    : 18,
                              ),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.28 : 0.12,
                              ),
                              blurRadius: isLaunching ? 30 : 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _academyHubLaunchInFlight ? null : onTap,
                            onTapDown: (_) => _setAcademyHubPressedCard(cardId),
                            onTapCancel: () => _setAcademyHubPressedCard(null),
                            borderRadius: BorderRadius.circular(30),
                            splashColor: accent.withValues(alpha: 0.20),
                            highlightColor: accent.withValues(alpha: 0.08),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: accent.withValues(
                                    alpha: isLaunching
                                        ? 0.86
                                        : isHovered
                                        ? 0.74
                                        : 0.62,
                                  ),
                                ),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          accent.withValues(
                                            alpha: monochrome ? 0.10 : 0.16,
                                          ),
                                          Colors.black.withValues(
                                            alpha: monochrome ? 0.18 : 0.24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: AnimatedScale(
                                        duration: const Duration(
                                          milliseconds: 240,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        scale: imageScale,
                                        child: AnimatedSlide(
                                          duration: const Duration(
                                            milliseconds: 240,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          offset: imageOffset,
                                          child: Image.asset(
                                            imageAsset,
                                            fit: BoxFit.contain,
                                            alignment: Alignment.center,
                                            filterQuality: FilterQuality.high,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.black.withValues(
                                            alpha: monochrome ? 0.08 : 0.04,
                                          ),
                                          Colors.black.withValues(
                                            alpha: monochrome ? 0.22 : 0.10,
                                          ),
                                          Colors.black.withValues(
                                            alpha: monochrome ? 0.54 : 0.48,
                                          ),
                                        ],
                                        stops: const [0.0, 0.42, 1.0],
                                      ),
                                    ),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.72, -0.82),
                                        radius: 1.12,
                                        colors: [
                                          accent.withValues(
                                            alpha: monochrome ? 0.12 : 0.18,
                                          ),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 220),
                                    opacity: isLaunching ? 1.0 : 0.0,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: const Alignment(0.72, -0.68),
                                          radius: 1.0,
                                          colors: [
                                            accent.withValues(alpha: 0.28),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  AnimatedBuilder(
                                    animation: _academyBlueDotTime,
                                    builder: (context, child) {
                                      final highlightPulse =
                                          0.84 +
                                          0.16 *
                                              sin(
                                                _academyBlueDotTime.value *
                                                        0.34 +
                                                    (cardId == 'exams'
                                                        ? 0.3
                                                        : 1.7),
                                              );
                                      return IgnorePointer(
                                        child: Opacity(
                                          opacity: highlightPulse.clamp(
                                            0.70,
                                            1.0,
                                          ),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: -26,
                                          top: -38,
                                          child: Transform.rotate(
                                            angle: -0.34,
                                            child: Container(
                                              width: 170,
                                              height: 250,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.white.withValues(
                                                      alpha: 0.00,
                                                    ),
                                                    Colors.white.withValues(
                                                      alpha: monochrome
                                                          ? 0.08
                                                          : 0.12,
                                                    ),
                                                    Colors.white.withValues(
                                                      alpha: 0.00,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 12,
                                          top: 10,
                                          child: Container(
                                            width: 110,
                                            height: 86,
                                            decoration: BoxDecoration(
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: monochrome
                                                        ? 0.10
                                                        : 0.16,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      22,
                                      20,
                                      22,
                                      20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              width: isLaunching ? 52 : 46,
                                              height: isLaunching ? 52 : 46,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.28,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: accent.withValues(
                                                    alpha: isLaunching
                                                        ? 0.78
                                                        : 0.56,
                                                  ),
                                                ),
                                                boxShadow: isLaunching
                                                    ? [
                                                        BoxShadow(
                                                          color: accent
                                                              .withValues(
                                                                alpha: 0.32,
                                                              ),
                                                          blurRadius: 16,
                                                          spreadRadius: 1,
                                                        ),
                                                      ]
                                                    : const <BoxShadow>[],
                                              ),
                                              child: Icon(icon, color: accent),
                                            ),
                                            const Spacer(),
                                            AnimatedSlide(
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              offset: isLaunching
                                                  ? const Offset(0.14, 0)
                                                  : Offset.zero,
                                              child: AnimatedRotation(
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                turns: isLaunching ? 0.02 : 0.0,
                                                child: Container(
                                                  width: 46,
                                                  height: 46,
                                                  decoration: BoxDecoration(
                                                    color: accent.withValues(
                                                      alpha: monochrome
                                                          ? 0.18
                                                          : 0.22,
                                                    ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: accent.withValues(
                                                        alpha: isLaunching
                                                            ? 0.80
                                                            : 0.62,
                                                      ),
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Align(
                                          alignment: Alignment.bottomLeft,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            width: isLaunching ? 78 : 52,
                                            height: isLaunching ? 5 : 4,
                                            decoration: BoxDecoration(
                                              color: accent,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: accent.withValues(
                                                    alpha: isLaunching
                                                        ? 0.70
                                                        : 0.50,
                                                  ),
                                                  blurRadius: isLaunching
                                                      ? 18
                                                      : 12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcademyHubFlightOverlay({required bool isDark}) {
    final flight = _academyHubFlight;
    if (flight == null) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.sizeOf(context);
    final destinationRect = Rect.fromLTWH(
      -size.width * 0.06,
      -size.height * 0.05,
      size.width * 1.12,
      size.height * 1.10,
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _academyHubFlightController,
        builder: (context, child) {
          final raw = _academyHubFlightController.value;
          final t = Curves.easeInOutCubic.transform(raw);
          final currentRect = Rect.lerp(flight.rect, destinationRect, t)!;
          final fadeStart = 0.58;
          final fadeProgress = ((raw - fadeStart) / (1 - fadeStart)).clamp(
            0.0,
            1.0,
          );
          final opacity = 1.0 - Curves.easeOut.transform(fadeProgress);
          final radius = lerpDouble(30, 6, t) ?? 6;
          final scale = 1.0 + raw * 0.02;

          return Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          flight.accent.withValues(alpha: 0.10 + raw * 0.08),
                          Colors.black.withValues(alpha: raw * 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: currentRect,
                  child: Transform.scale(
                    scale: scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        boxShadow: [
                          BoxShadow(
                            color: flight.shadowColor.withValues(
                              alpha: isDark ? 0.42 : 0.36,
                            ),
                            blurRadius: lerpDouble(34, 58, t) ?? 58,
                            spreadRadius: lerpDouble(2, 10, t) ?? 10,
                            offset: Offset(0, lerpDouble(18, 28, t) ?? 28),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    flight.accent.withValues(alpha: 0.18),
                                    Colors.black.withValues(alpha: 0.24),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(
                                lerpDouble(8, 18, t) ?? 18,
                              ),
                              child: Image.asset(
                                flight.imageAsset,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.04),
                                    Colors.black.withValues(alpha: 0.10),
                                    Colors.black.withValues(alpha: 0.48),
                                  ],
                                  stops: const [0.0, 0.42, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: -36,
                              child: Transform.rotate(
                                angle: -0.34,
                                child: Container(
                                  height: 260,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        Colors.white.withValues(alpha: 0.14),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                lerpDouble(22, 28, t) ?? 28,
                                lerpDouble(20, 28, t) ?? 28,
                                lerpDouble(22, 28, t) ?? 28,
                                lerpDouble(20, 28, t) ?? 28,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: lerpDouble(46, 64, t) ?? 64,
                                        height: lerpDouble(46, 64, t) ?? 64,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.28,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: flight.accent.withValues(
                                              alpha: 0.80,
                                            ),
                                          ),
                                        ),
                                        child: Icon(
                                          flight.icon,
                                          color: flight.accent,
                                          size: lerpDouble(24, 30, t) ?? 30,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        width: lerpDouble(46, 66, t) ?? 66,
                                        height: lerpDouble(46, 66, t) ?? 66,
                                        decoration: BoxDecoration(
                                          color: flight.accent.withValues(
                                            alpha: 0.22,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: flight.accent.withValues(
                                              alpha: 0.82,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: lerpDouble(52, 110, t) ?? 110,
                                    height: lerpDouble(4, 7, t) ?? 7,
                                    decoration: BoxDecoration(
                                      color: flight.accent,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: flight.accent.withValues(
                                            alpha: 0.70,
                                          ),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAcademyExamsView(
    PuzzleAcademyProvider provider, {
    required BoxConstraints constraints,
    required AppThemeProvider themeProvider,
    required bool monochrome,
  }) {
    final wide = constraints.maxWidth >= 980;
    final aspectRatio = constraints.maxWidth / max(1.0, constraints.maxHeight);
    final useDualPaneLayout = wide || aspectRatio >= 1.0;
    final grouped = _groupBySemester(provider);

    if (useDualPaneLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            flex: 3,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: min(360, constraints.maxWidth * 0.34),
              ),
              child: _buildMasteryDashboard(provider, monochrome: monochrome),
            ),
          ),
          Flexible(
            flex: 7,
            child: _buildLandscapeMap(
              provider,
              grouped,
              themeProvider: themeProvider,
              monochrome: monochrome,
            ),
          ),
        ],
      );
    }

    return _buildPortraitMap(
      provider,
      grouped,
      themeProvider: themeProvider,
      monochrome: monochrome,
    );
  }

  Widget _buildAtmosphere(bool cinematic, {required bool includeYellow}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                        .withValues(
                          alpha: cinematic
                              ? (isDark ? 0.06 : 0.09)
                              : (isDark ? 0.10 : 0.32),
                        ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (cinematic
                                ? const Color(0xFFB6BCC5)
                                : const Color(0xFF0E7490))
                            .withValues(
                              alpha: cinematic
                                  ? (isDark ? 0.12 : 0.16)
                                  : (isDark ? 0.22 : 0.45),
                            ),
                    blurRadius: cinematic ? 110 : (isDark ? 110 : 140),
                  ),
                ],
              ),
            ),
          ),
          if (includeYellow)
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
                          .withValues(
                            alpha: cinematic
                                ? (isDark ? 0.06 : 0.09)
                                : (isDark ? 0.08 : 0.28),
                          ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (cinematic
                                  ? const Color(0xFF9DA3AD)
                                  : const Color(0xFFBF8C00))
                              .withValues(
                                alpha: cinematic
                                    ? (isDark ? 0.10 : 0.14)
                                    : (isDark ? 0.16 : 0.42),
                              ),
                      blurRadius: cinematic ? 90 : (isDark ? 90 : 120),
                    ),
                  ],
                ),
              ),
            ),
          ValueListenableBuilder<double>(
            valueListenable: _academyBlueDotTime,
            builder: (context, time, child) {
              if (!includeYellow) {
                return Align(
                  alignment: _academyDotAlignment(
                    _academyBlueDotPhase,
                    0.52,
                    _academyBlueDotRadius,
                    time,
                    _academyBlueDotTrajectoryNoise,
                    _academyBlueDotShapeSeed,
                  ),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5AAEE8).withValues(alpha: 0.92),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF5AAEE8,
                          ).withValues(alpha: isDark ? 0.45 : 0.80),
                          blurRadius: isDark ? 18 : 28,
                          spreadRadius: isDark ? 3 : 6,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final alignments = _academyRepellingDotAlignments(time);
              return Stack(
                children: [
                  Align(
                    alignment: alignments.blue,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF5AAEE8).withValues(alpha: 0.92),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF5AAEE8,
                            ).withValues(alpha: isDark ? 0.45 : 0.80),
                            blurRadius: isDark ? 18 : 28,
                            spreadRadius: isDark ? 3 : 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: alignments.yellow,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD8B640).withValues(alpha: 0.94),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD8B640,
                            ).withValues(alpha: isDark ? 0.38 : 0.74),
                            blurRadius: isDark ? 18 : 26,
                            spreadRadius: isDark ? 3 : 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  ({Alignment blue, Alignment yellow}) _academyRepellingDotAlignments(
    double pulse,
  ) {
    var blue = _academyDotOffset(
      _academyBlueDotPhase,
      0.52,
      _academyBlueDotRadius,
      pulse,
      _academyBlueDotTrajectoryNoise,
      _academyBlueDotShapeSeed,
    );
    var yellow = _academyDotOffset(
      _academyYellowDotPhase,
      0.48,
      _academyYellowDotRadius,
      pulse,
      _academyYellowDotTrajectoryNoise,
      _academyYellowDotShapeSeed,
    );

    final delta = blue - yellow;
    final distance = delta.distance;
    const repelThreshold = 0.34;
    if (distance < repelThreshold) {
      final proximity = (repelThreshold - distance) / repelThreshold;
      final fallback = Offset(
        cos(pulse * 0.86 + _academyBlueDotPhase),
        sin(pulse * 0.92 + _academyYellowDotPhase),
      );
      final fallbackDistance = fallback.distance == 0 ? 1.0 : fallback.distance;
      final direction = distance < 0.001
          ? fallback / fallbackDistance
          : delta / distance;
      final tangent = Offset(-direction.dy, direction.dx);
      final swirlSign =
          sin(pulse * 1.4 + _academyBlueDotPhase - _academyYellowDotPhase) >= 0
          ? 1.0
          : -1.0;
      final push = proximity * 0.06;
      final swirl = proximity * proximity * 0.11;
      blue = blue + direction * push + tangent * swirl * swirlSign;
      yellow = yellow - direction * push - tangent * swirl * swirlSign;
    }

    blue = _academyClampDotOffset(blue);
    yellow = _academyClampDotOffset(yellow);

    return (
      blue: Alignment(blue.dx, blue.dy),
      yellow: Alignment(yellow.dx, yellow.dy),
    );
  }

  Alignment _academyDotAlignment(
    double phase,
    double speed,
    double radius,
    double pulse,
    double trajectoryNoise,
    double shapeSeed,
  ) {
    final offset = _academyDotOffset(
      phase,
      speed,
      radius,
      pulse,
      trajectoryNoise,
      shapeSeed,
    );
    return Alignment(offset.dx, offset.dy);
  }

  Offset _academyDotOffset(
    double phase,
    double speed,
    double radius,
    double pulse,
    double trajectoryNoise,
    double shapeSeed,
  ) {
    final time = pulse * 1.26 * speed + phase + shapeSeed;
    final x =
        sin(time * (1.25 + shapeSeed * 0.14)) * radius +
        sin(time * (2.6 + shapeSeed * 0.22) + 1.3 + shapeSeed * 0.9) * 0.09 +
        sin(time * (3.5 + shapeSeed * 0.35) + 2.1) * 0.035;
    final y =
        cos(time * (1.77 + shapeSeed * 0.18) + 0.4) * radius * 0.88 +
        cos(time * (2.35 + shapeSeed * 0.15) - 0.8) * 0.09 +
        sin(time * (3.5 + shapeSeed * 0.28) + 0.6) * 0.035;
    final driftX = sin(time * (0.64 + shapeSeed * 0.04) + 1.2) * 0.015;
    final driftY = cos(time * (0.71 + shapeSeed * 0.03) - 0.7) * 0.015;
    final jitterX =
        sin(
          time * (0.92 + trajectoryNoise * 0.18 + shapeSeed * 0.06) +
              trajectoryNoise * 3.7,
        ) *
        (trajectoryNoise * 0.025 + shapeSeed * 0.015);
    final jitterY =
        cos(
          time * (1.08 + trajectoryNoise * 0.22 - shapeSeed * 0.07) -
              trajectoryNoise * 2.9,
        ) *
        (trajectoryNoise * 0.025 + shapeSeed * 0.015);
    return _academyClampDotOffset(
      Offset(x + driftX + jitterX, y + driftY + jitterY),
    );
  }

  Offset _academyClampDotOffset(Offset raw) {
    final distance = raw.distance;
    const limit = 1.35;
    final returnFactor = distance > limit ? limit / distance : 1.0;
    return Offset(raw.dx * returnFactor, raw.dy * returnFactor);
  }

  Widget _buildAcademyLoadingIndicator(ThemeData theme) {
    const blue = Color(0xFF5AAEE8);
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blue.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.10 : 0.08,
              ),
              border: Border.all(color: blue.withValues(alpha: 0.24), width: 4),
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _academyBlueDotTime,
            builder: (context, time, child) {
              final alignment = _academyDotAlignment(
                _academyBlueDotPhase,
                0.72,
                0.70,
                time,
                _academyBlueDotTrajectoryNoise,
                _academyBlueDotShapeSeed,
              );
              return Align(alignment: alignment, child: child);
            },
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blue,
                boxShadow: [
                  BoxShadow(
                    color: blue.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
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
    required AppThemeProvider themeProvider,
    required bool monochrome,
  }) {
    _ensureExpandedSemester(provider, autoExpandFirstUnlocked: false);
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(
          provider,
          themeProvider: themeProvider,
          monochrome: monochrome,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildHeroStatsBar(provider),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _DailyChallengeCard(
              total: provider.dailyPuzzles.length,
              completed: provider.completedTodayDailyCount,
              hasTodayPuzzle: provider.hasTodayDailyPuzzle,
              monochrome: monochrome,
              onTap: () => _openTodayDailyPuzzle(provider, monochrome),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _buildScoreboardSection(provider, monochrome),
          ),
        ),
        for (final entry in grouped.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: _SemesterHeader(
                semester: entry.key,
                progress: provider.semesterProgress(entry.key),
                expanded: _expandedSemesterTitles.contains(entry.key.title),
                nodeCount: entry.value.length,
                monochrome: monochrome,
                onTap: () {
                  setState(() {
                    final title = entry.key.title;
                    if (_expandedSemesterTitles.contains(title)) {
                      _expandedSemesterTitles.remove(title);
                    } else {
                      _expandedSemesterTitles.add(title);
                    }
                  });
                },
              ),
            ),
          ),
          if (_expandedSemesterTitles.contains(entry.key.title))
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildNodeTile(
                      provider,
                      entry.value[index],
                      compact: true,
                      monochrome: monochrome,
                    ),
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
    required AppThemeProvider themeProvider,
    required bool monochrome,
  }) {
    _ensureExpandedSemester(provider);
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 28.0;
        const gridSpacing = 10.0;
        const minTwoColumnTileWidth = 150.0;
        final usableWidth = max(
          220.0,
          constraints.maxWidth - horizontalPadding,
        );
        final crossAxisCount =
            usableWidth >= (minTwoColumnTileWidth * 2) + gridSpacing ? 2 : 1;
        final totalSpacing = (crossAxisCount - 1) * gridSpacing;
        final tileWidth = (usableWidth - totalSpacing) / crossAxisCount;
        final targetTileHeight = crossAxisCount == 1 ? 190.0 : 228.0;
        final childAspectRatio = tileWidth / targetTileHeight;

        return CustomScrollView(
          slivers: [
            _buildSliverAppBar(
              provider,
              themeProvider: themeProvider,
              monochrome: monochrome,
            ),
            for (final entry in grouped.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: _SemesterHeader(
                    semester: entry.key,
                    progress: provider.semesterProgress(entry.key),
                    expanded: _expandedSemesterTitles.contains(entry.key.title),
                    nodeCount: entry.value.length,
                    monochrome: monochrome,
                    onTap: () {
                      setState(() {
                        final title = entry.key.title;
                        if (_expandedSemesterTitles.contains(title)) {
                          _expandedSemesterTitles.remove(title);
                        } else {
                          _expandedSemesterTitles.add(title);
                        }
                      });
                    },
                  ),
                ),
              ),
              if (_expandedSemesterTitles.contains(entry.key.title))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: childAspectRatio,
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
      },
    );
  }

  SliverAppBar _buildSliverAppBar(
    PuzzleAcademyProvider provider, {
    required AppThemeProvider themeProvider,
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
      ).withValues(alpha: 0.90),
      leading: IconButton(
        onPressed: _handleAcademyBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      actions: [
        IconButton(
          tooltip: 'Settings',
          onPressed: () => _openQuickThemeSettings(themeProvider),
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
        expandedTitleScale: 1.0,
        titlePadding: const EdgeInsetsDirectional.only(bottom: 12),
        title: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: widget.onShowCredits,
                child: Image.asset(
                  'assets/ChessIQ.png',
                  width: 120,
                  height: 34,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Puzzle Academy',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: monochrome ? 0.22 : 0,
                  shadows: _academyMonoTextGlow(
                    monochrome ? const Color(0xFFDCE5EE) : scheme.primary,
                    monochrome: monochrome,
                    strength: 1.1,
                  ),
                ),
              ),
            ],
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
                onPressed: _handleAcademyBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Mastery Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: monochrome ? 0.24 : 0,
                    shadows: _academyMonoTextGlow(
                      monochrome
                          ? const Color(0xFFE7E2DA)
                          : Theme.of(context).colorScheme.primary,
                      monochrome: monochrome,
                      strength: 1.15,
                    ),
                  ),
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
            monochrome: monochrome,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.progress.handle.isNotEmpty
                      ? provider.progress.handle
                      : provider.currentTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (provider.progress.handle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      provider.currentTitle,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DashboardPanel(
            title: 'Semester Progress',
            accent: const Color(0xFF6FE7FF),
            monochrome: monochrome,
            child: Column(
              children: provider.semesters.map((semester) {
                final pct = (provider.semesterProgress(semester) * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              semester.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              color: Color(0xFF6FE7FF),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: provider.semesterProgress(semester),
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6FE7FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          _DailyChallengeCard(
            total: provider.dailyPuzzles.length,
            completed: provider.completedTodayDailyCount,
            hasTodayPuzzle: provider.hasTodayDailyPuzzle,
            monochrome: monochrome,
            onTap: () => _openTodayDailyPuzzle(provider, monochrome),
          ),
          const SizedBox(height: 12),
          _buildScoreboardSection(provider, monochrome),
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
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              scheme.primary.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.12 : 0.04,
              ),
              scheme.surface,
            ).withValues(alpha: 0.70),
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

    final bestExamResult = provider.bestExamResultForNode(node.key);
    return _PuzzleNodeCard(
      node: node,
      compact: compact,
      heroTag: heroTag,
      showGhost: solvedFeatured,
      showExamButton: provider.canTakeExam(node),
      bestExamScore: bestExamResult?.score,
      bestExamGrade: bestExamResult?.grade,
      lockedRequirementText: provider.unlockRequirementText(node),
      previousSolveRequirementText: provider.previousNodeSolveRequirementText(
        node,
      ),
      requiresPreviousSolveTarget: provider.requiresPreviousNodeSolveTarget(
        node,
      ),
      requiresPreviousSemesterExamGate: provider
          .requiresPreviousSemesterExamGate(node),
      onExamTap: !provider.canTakeExam(node)
          ? null
          : () => _startExamForNode(provider, node, heroTag, monochrome),
      completedCount: provider.completedPuzzleCountForNode(
        node,
        provider.progress,
      ),
      masteryProgress: provider.completedProgressForNode(
        node,
        provider.progress,
      ),
      monochrome: monochrome,
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
    final sequence = provider.dailyPuzzles;
    if (sequence.isEmpty) return;
    final dailyNode =
        provider.progress.nodes[provider.keyForRating(daily.rating)];
    if (dailyNode == null) return;
    final dailyIndex = provider.todayDailyPuzzleIndex;
    if (dailyIndex < 0 || dailyIndex >= sequence.length) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PuzzleNodeScreen(
          node: dailyNode,
          heroTag: provider.heroTagForNode(dailyNode),
          initialPuzzle: daily,
          initialPuzzleIndex: dailyIndex,
          puzzleSequence: sequence,
          sequenceTitle: 'Daily Challenge',
          cinematicThemeEnabled: monochrome,
        ),
      ),
    );
  }

  void _ensureExpandedSemester(
    PuzzleAcademyProvider provider, {
    bool autoExpandFirstUnlocked = true,
  }) {
    if (_expandedSemesterInitialized) return;
    _expandedSemesterInitialized = true;

    if (!autoExpandFirstUnlocked) {
      return;
    }

    final unlockedNodes = provider.orderedNodes.where((node) => node.unlocked);
    if (unlockedNodes.isEmpty) {
      if (provider.semesters.isNotEmpty) {
        _expandedSemesterTitles.add(provider.semesters.first.title);
      }
      return;
    }

    if (provider.semesters.isEmpty) {
      return;
    }

    final firstUnlocked = unlockedNodes.reduce(
      (a, b) => a.startElo < b.startElo ? a : b,
    );
    _expandedSemesterTitles.add(provider.semesterForNode(firstUnlocked).title);
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
        ),
      ),
    );
  }

  Future<void> _openQuickThemeSettings(AppThemeProvider themeProvider) async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = !(prefs.getBool(_muteSoundsKey) ?? false);
    final hapticsEnabled = prefs.getBool(_hapticsEnabledKey) ?? true;

    if (!mounted) return;
    try {
      await showAcademyThemeSettingsSheet(
        context: context,
        themeProvider: themeProvider,
        soundEnabled: soundEnabled,
        hapticsEnabled: hapticsEnabled,
        onSoundEnabledChanged: (enabled) async {
          await prefs.setBool(_muteSoundsKey, !enabled);
        },
        onHapticsEnabledChanged: (enabled) async {
          await prefs.setBool(_hapticsEnabledKey, enabled);
        },
      );
    } catch (_) {
      if (!mounted) return;
      await _showStatusDialog(
        title: 'Settings Unavailable',
        message: 'Academy settings could not be opened right now.',
      );
    }
  }

  Map<SemesterRange, List<EloNodeProgress>> _groupBySemester(
    PuzzleAcademyProvider provider,
  ) {
    final grouped = <SemesterRange, List<EloNodeProgress>>{};
    for (final semester in provider.semesters) {
      grouped[semester] = <EloNodeProgress>[];
    }

    if (provider.semesters.isEmpty) {
      // No semester metadata yet; keep the map stable by placing all nodes
      // into a single fallback bucket.
      grouped[SemesterRange(
        id: 'fallback',
        title: 'Academy',
        minElo: 0,
        maxElo: 9999,
        intro: 'All available academy puzzles',
      )] = List<EloNodeProgress>.from(
        provider.orderedNodes,
      );
      return grouped;
    }

    for (final node in provider.orderedNodes) {
      final semester = provider.semesterForNode(node);
      grouped.putIfAbsent(semester, () => <EloNodeProgress>[]).add(node);
    }

    grouped.removeWhere((_, nodes) => nodes.isEmpty);

    // Defensive fallback: keep portrait map stable even if semester metadata
    // and node ranges are temporarily out-of-sync during provider refresh.
    if (grouped.isEmpty && provider.orderedNodes.isNotEmpty) {
      final fallback = provider.semesters.first;
      grouped[fallback] = List<EloNodeProgress>.from(provider.orderedNodes);
    }

    return grouped;
  }
}

class _AcademyProfileDialog extends StatefulWidget {
  const _AcademyProfileDialog({
    required this.initialHandle,
    required this.initialCountry,
    this.lockHandle = false,
    this.lockCountry = false,
    this.allowExitToMenu = false,
  });

  final String initialHandle;
  final String initialCountry;
  final bool lockHandle;
  final bool lockCountry;
  final bool allowExitToMenu;

  @override
  State<_AcademyProfileDialog> createState() => _AcademyProfileDialogState();
}

class _AcademyProfileDialogState extends State<_AcademyProfileDialog> {
  late final TextEditingController _handleController;
  TextEditingController? _countryController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _handleController = TextEditingController(text: widget.initialHandle);
  }

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Academy Leaderboard Setup'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a nickname and country so you can appear on global and local leaderboards.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _handleController,
                enabled: !widget.lockHandle,
                decoration: InputDecoration(
                  labelText: 'Nickname',
                  hintText: 'e.g. TacticTiger',
                  counterText: '',
                  suffixIcon: widget.lockHandle ? const Icon(Icons.lock) : null,
                ),
                maxLength: 20,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Please enter a nickname.';
                  }
                  if (text.length < 3) {
                    return 'Nickname needs at least 3 characters.';
                  }
                  if (containsProfanity(text)) {
                    return 'Nickname contains inappropriate language.';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: widget.initialCountry),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.trim().isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return countrySuggestions(textEditingValue.text.trim());
                },
                onSelected: (selection) {},
                fieldViewBuilder:
                    (
                      BuildContext context,
                      TextEditingController countryController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      _countryController = countryController;
                      return TextFormField(
                        controller: countryController,
                        focusNode: focusNode,
                        enabled: !widget.lockCountry,
                        decoration: InputDecoration(
                          labelText: 'Country / Region',
                          hintText: 'e.g. Brazil',
                          suffixIcon: widget.lockCountry
                              ? const Icon(Icons.lock)
                              : null,
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'Please enter a country or region.';
                          }
                          if (canonicalCountryName(text) == null) {
                            return 'Please select a valid country from the list.';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => onFieldSubmitted(),
                      );
                    },
                optionsViewBuilder:
                    (
                      BuildContext context,
                      AutocompleteOnSelected<String> onSelected,
                      Iterable<String> options,
                    ) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
              ),
              const SizedBox(height: 16),
              Text(
                'This information is only used for leaderboard display. No email, account details, or precise location are collected.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.allowExitToMenu ? 'Back to Menu' : 'Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            final handle = _handleController.text.trim();
            final countryText = _countryController?.text.trim() ?? '';
            final country = canonicalCountryName(countryText) ?? countryText;
            Navigator.of(
              context,
            ).pop(<String, String>{'handle': handle, 'country': country});
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
