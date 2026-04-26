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
import 'package:chessiq/features/academy/widgets/puzzle_academy_surface.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
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

class _AcademyHubQuizSnapshot {
  const _AcademyHubQuizSnapshot({
    this.studiedOpenings = 0,
    this.studyReps = 0,
    this.totalAnswered = 0,
    this.correctAnswers = 0,
    this.bestStreak = 0,
  });

  factory _AcademyHubQuizSnapshot.fromRawStats(String? rawStats) {
    if (rawStats == null || rawStats.isEmpty) {
      return const _AcademyHubQuizSnapshot();
    }

    final decoded = jsonDecode(rawStats);
    if (decoded is! Map<String, dynamic>) {
      return const _AcademyHubQuizSnapshot();
    }

    final studyCounts = decoded['studyCounts'];
    final studiedOpenings = studyCounts is Map ? studyCounts.keys.length : 0;
    final studyReps = studyCounts is Map
        ? studyCounts.values.fold<int>(
            0,
            (sum, value) => sum + (value is num ? max(0, value.toInt()) : 0),
          )
        : 0;
    final totalAnswered = decoded['totalAnswered'];
    final correctAnswers = decoded['correctAnswers'];
    final bestStreak = decoded['bestStreak'];

    return _AcademyHubQuizSnapshot(
      studiedOpenings: studiedOpenings,
      studyReps: studyReps,
      totalAnswered: totalAnswered is num ? max(0, totalAnswered.toInt()) : 0,
      correctAnswers: correctAnswers is num
          ? max(0, correctAnswers.toInt())
          : 0,
      bestStreak: bestStreak is num ? max(0, bestStreak.toInt()) : 0,
    );
  }

  final int studiedOpenings;
  final int studyReps;
  final int totalAnswered;
  final int correctAnswers;
  final int bestStreak;

  bool get hasProgress =>
      studiedOpenings > 0 || studyReps > 0 || totalAnswered > 0;

  double get accuracy =>
      totalAnswered <= 0 ? 0 : correctAnswers / totalAnswered;
}

class _AcademyHubCardBadge {
  const _AcademyHubCardBadge({
    required this.label,
    required this.icon,
    required this.accent,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool filled;
}

enum _AcademyHubSelectorLayoutMode {
  phonePortrait,
  phoneLandscapeRail,
  tabletTwoUp,
}

class _AcademyHubSelectorLayoutSpec {
  const _AcademyHubSelectorLayoutSpec({
    required this.mode,
    required this.selectorGap,
  });

  factory _AcademyHubSelectorLayoutSpec.fromConstraints(
    BoxConstraints constraints,
    MediaQueryData media,
  ) {
    final safeHeight = max(0.0, constraints.maxHeight - media.padding.vertical);
    final isLandscape = constraints.maxWidth > safeHeight;
    final shortLandscape = isLandscape && safeHeight <= 500;
    if (shortLandscape) {
      return const _AcademyHubSelectorLayoutSpec(
        mode: _AcademyHubSelectorLayoutMode.phoneLandscapeRail,
        selectorGap: 12,
      );
    }

    final tabletTwoUp =
        constraints.maxWidth >= 920 ||
        (constraints.maxWidth >= 760 && safeHeight >= 720);
    if (tabletTwoUp) {
      return const _AcademyHubSelectorLayoutSpec(
        mode: _AcademyHubSelectorLayoutMode.tabletTwoUp,
        selectorGap: 14,
      );
    }

    return const _AcademyHubSelectorLayoutSpec(
      mode: _AcademyHubSelectorLayoutMode.phonePortrait,
      selectorGap: 10,
    );
  }

  final _AcademyHubSelectorLayoutMode mode;
  final double selectorGap;

  bool get isTablet => mode == _AcademyHubSelectorLayoutMode.tabletTwoUp;

  bool get usesRail => mode == _AcademyHubSelectorLayoutMode.phoneLandscapeRail;

  String get testKey => switch (mode) {
    _AcademyHubSelectorLayoutMode.phonePortrait =>
      'academy_hub_selector_phonePortrait',
    _AcademyHubSelectorLayoutMode.phoneLandscapeRail =>
      'academy_hub_selector_phoneLandscapeRail',
    _AcademyHubSelectorLayoutMode.tabletTwoUp =>
      'academy_hub_selector_tabletTwoUp',
  };
}

class _AcademyHubCardModel {
  const _AcademyHubCardModel({
    required this.cardId,
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.description,
    required this.inlineDetails,
    required this.artLabel,
    required this.imageAsset,
    required this.imageAlignment,
    required this.imagePadding,
    required this.accent,
    required this.shadowColor,
    required this.icon,
    required this.ctaLabel,
    required this.progressLabel,
    required this.progressValue,
    required this.progress,
    required this.badges,
    required this.onTap,
  });

  final String cardId;
  final String eyebrow;
  final String title;
  final String summary;
  final String description;
  final List<String> inlineDetails;
  final String artLabel;
  final String imageAsset;
  final Alignment imageAlignment;
  final EdgeInsets imagePadding;
  final Color accent;
  final Color shadowColor;
  final IconData icon;
  final String ctaLabel;
  final String progressLabel;
  final String progressValue;
  final double progress;
  final List<_AcademyHubCardBadge> badges;
  final VoidCallback onTap;
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
  static const String _quizStatsStorageKey = 'quiz_stats_v1';

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
  _AcademyHubQuizSnapshot _academyHubQuizSnapshot =
      const _AcademyHubQuizSnapshot();
  bool _compactDashboardOverviewExpanded = false;
  bool _compactDashboardStatsExpanded = false;

  bool get _useReducedWindowsVisualEffects =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

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
    unawaited(_loadAcademyHubQuizSnapshot());
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
      } catch (_) {
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
          cinematicThemeEnabled: widget.cinematicThemeEnabled,
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
          provider.setShowAcademyExamsDashboard(false);
          widget.onBack();
        }
        return;
      }

      final handle = (result['handle'] ?? '').trim();
      final country = (result['country'] ?? '').trim();

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

  Future<void> _openAcademyProfileEditor(PuzzleAcademyProvider provider) async {
    if (!mounted || _didShowAcademyProfilePrompt) {
      return;
    }
    _didShowAcademyProfilePrompt = true;
    try {
      await _showAcademyProfileDialog(provider);
    } finally {
      _didShowAcademyProfilePrompt = false;
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
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final profileMissing = provider.shouldAskForProfile;
    final scoreboardLoading =
        !provider.scoreboardLoaded || provider.scoreboardSyncing;
    final scoreboardError = provider.lastScoreboardError;
    final helperText = scoreboardError != null
        ? 'The live board is temporarily unavailable. Retry the sync without leaving the Academy.'
        : scoreboardLoading
        ? 'Syncing the live Academy board and preserving your selected scope.'
        : profileMissing
        ? 'Set up your academy profile to appear on the live board.'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Retro Scoreboard',
                style: puzzleAcademyDisplayStyle(
                  palette: palette,
                  size: 16,
                  color: palette.cyan,
                ),
              ),
            ),
            if (provider.scoreboardSyncing)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PuzzleAcademyTag(
                  label: 'SYNCING',
                  accent: palette.amber,
                  icon: Icons.sync_rounded,
                ),
              ),
            PuzzleAcademyInfoButton(
              title: 'Scoreboard Scope',
              message:
                  'International compares every submitted academy exam. National filters the same board to your selected country or region. Leaderboard scoring uses your best recorded exam results, not daily challenge progress.',
              accent: palette.cyan,
              monochromeOverride: monochrome,
            ),
          ],
        ),
        if (helperText != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            helperText,
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: 11.8,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
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
                radius: 8,
              ),
              child: const Text('International'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _leaderboardScope = _LeaderboardScope.national;
                });
                provider.refreshRemoteScoreboard(national: true);
              },
              style: _academyFilledButtonStyle(
                backgroundColor: selectedNational
                    ? nationalTone.withValues(alpha: monochrome ? 0.88 : 0.94)
                    : nationalTone.withValues(alpha: monochrome ? 0.22 : 0.15),
                foregroundColor: selectedNational
                    ? const Color(0xFF191204)
                    : nationalTone,
                monochrome: monochrome,
                side: BorderSide(
                  color: nationalTone.withValues(
                    alpha: selectedNational ? 0.92 : 0.44,
                  ),
                ),
                radius: 8,
              ),
              child: const Text('National'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LeaderboardCard(
          entries: entries,
          title: title,
          monochrome: monochrome,
          isLoading: scoreboardLoading,
          errorMessage: scoreboardError,
          onRetry: () => provider.refreshRemoteScoreboard(
            national: _leaderboardScope == _LeaderboardScope.national,
          ),
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
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final palette = puzzleAcademyPalette(
          dialogContext,
          monochromeOverride: monochrome,
        );
        return PuzzleAcademyDialogShell(
          title: semester.title,
          subtitle: 'Semester briefing',
          accent: palette.amber,
          icon: Icons.school_outlined,
          monochromeOverride: monochrome,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: puzzleAcademyFilledButtonStyle(
                palette: palette,
                backgroundColor: palette.amber,
                foregroundColor: const Color(0xFF191204),
              ),
              child: const Text('ENTER SEMESTER'),
            ),
          ],
          child: Text(
            semester.intro,
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: 12.3,
              weight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        );
      },
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
      builder: (dialogContext) {
        final palette = puzzleAcademyPalette(
          dialogContext,
          monochromeOverride: monochrome,
        );
        return PuzzleAcademyDialogShell(
          title: title,
          accent: palette.cyan,
          icon: Icons.info_outline_rounded,
          monochromeOverride: monochrome,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: puzzleAcademyFilledButtonStyle(
                palette: palette,
                backgroundColor: palette.cyan,
                foregroundColor: const Color(0xFF081517),
              ),
              child: const Text('OK'),
            ),
          ],
          child: Text(
            message,
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: 12.2,
              weight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showGrandmasterOracleDialog() async {
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final palette = puzzleAcademyPalette(
          dialogContext,
          monochromeOverride: monochrome,
        );
        return PuzzleAcademyDialogShell(
          title: 'Neural Constraints Lifted',
          subtitle: 'Stockfish Depth 35 Unlocked',
          accent: palette.amber,
          icon: Icons.auto_awesome,
          monochromeOverride: monochrome,
          maxWidth: 680,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: puzzleAcademyFilledButtonStyle(
                palette: palette,
                backgroundColor: palette.amber,
                foregroundColor: const Color(0xFF191204),
              ),
              child: const Text('ACCEPT UPGRADE'),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  PuzzleAcademyTag(
                    label: 'ORACLE SEMESTER',
                    accent: palette.cyan,
                    icon: Icons.extension_outlined,
                  ),
                  PuzzleAcademyTag(
                    label: 'DEPTH 33-35',
                    accent: palette.amber,
                    icon: Icons.memory_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'The final academy seal is broken. Analysis Mode now has permanent access to Depth 33-35.',
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: 12.3,
                  weight: FontWeight.w600,
                  height: 1.45,
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

  Future<void> _loadAcademyHubQuizSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawStats = prefs.getString(_quizStatsStorageKey);
      if (!mounted) {
        return;
      }
      setState(() {
        _academyHubQuizSnapshot = _AcademyHubQuizSnapshot.fromRawStats(
          rawStats,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _academyHubQuizSnapshot = const _AcademyHubQuizSnapshot();
      });
    }
  }

  void _openAcademyExams() {
    final provider = context.read<PuzzleAcademyProvider>();
    if (provider.showAcademyExamsDashboard) {
      return;
    }
    provider.setShowAcademyExamsDashboard(true);
  }

  void _handleAcademyBack() {
    final provider = context.read<PuzzleAcademyProvider>();
    if (provider.showAcademyExamsDashboard) {
      provider.setShowAcademyExamsDashboard(false);
      return;
    }
    provider.setShowAcademyExamsDashboard(false);
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
    if (_useReducedWindowsVisualEffects) {
      onComplete();
      return;
    }

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
          _activeView = provider.showAcademyExamsDashboard
              ? _AcademyEntryView.exams
              : _AcademyEntryView.hub;
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
                  final useReducedWindowsVisuals =
                      _useReducedWindowsVisualEffects;
                  final rootContent = Stack(
                    key: _academyRootContentKey,
                    children: [
                      if (_activeView == _AcademyEntryView.hub)
                        Positioned.fill(
                          child: _buildAcademyHubBackdrop(
                            monochrome: monochrome,
                          ),
                        )
                      else if (!useReducedWindowsVisuals)
                        Positioned.fill(
                          child: _buildAtmosphere(
                            monochrome,
                            includeYellow: false,
                          ),
                        ),
                      if (_activeView == _AcademyEntryView.hub)
                        _buildAcademyHub(
                          provider: provider,
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
                      if (!useReducedWindowsVisuals)
                        Align(
                          alignment: Alignment.topCenter,
                          child: IgnorePointer(
                            child: ConfettiWidget(
                              confettiController: _confettiController,
                              blastDirectionality:
                                  BlastDirectionality.explosive,
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
                      if (!useReducedWindowsVisuals &&
                          _academyHubFlight != null)
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
    required PuzzleAcademyProvider provider,
    required BoxConstraints constraints,
    required AppThemeProvider themeProvider,
    required bool monochrome,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final selectorLayout = _AcademyHubSelectorLayoutSpec.fromConstraints(
      constraints,
      media,
    );
    final compactHub = constraints.maxHeight < 420;
    final horizontalPadding = selectorLayout.isTablet ? 20.0 : 4.0;
    final topPadding = compactHub ? 8.0 : 10.0;
    final bottomPadding = max(14.0, 14.0 + media.padding.bottom);
    final contentHeight = max(
      0.0,
      constraints.maxHeight - topPadding - bottomPadding,
    );
    final maxContentWidth = selectorLayout.isTablet ? 1180.0 : 940.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: SizedBox(
            height: contentHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAcademyHubTopBar(
                  monochrome: monochrome,
                  compact: compactHub,
                  themeProvider: themeProvider,
                ),
                SizedBox(height: compactHub ? 8 : 10),
                _buildAcademyHubOverview(
                  monochrome: monochrome,
                  compact: compactHub || !selectorLayout.isTablet,
                ),
                SizedBox(height: compactHub ? 10 : 14),
                Expanded(
                  child: _buildAcademyHubSelector(
                    provider: provider,
                    layout: selectorLayout,
                    monochrome: monochrome,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcademyHubTopBar({
    required bool monochrome,
    required bool compact,
    required AppThemeProvider themeProvider,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final hubLabel = puzzleAcademyHudStyle(
      palette: palette,
      size: compact ? 8.8 : 9.6,
      weight: FontWeight.w800,
      color: palette.textMuted,
      letterSpacing: 1.04,
      height: 1.0,
    );

    return SizedBox(
      height: compact ? 74 : 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildAcademyHubTopActionButton(
              key: const ValueKey<String>('academy_hub_back_button'),
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back to menu',
              accent: palette.text,
              monochrome: monochrome,
              onPressed: _handleAcademyBack,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              key: const ValueKey<String>('academy_hub_logo'),
              onTap: widget.onShowCredits,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/ChessIQ.png',
                    width: compact ? 108 : 128,
                    height: compact ? 28 : 34,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  Text('ACADEMY', style: hubLabel),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAcademyHubTopActionButton(
                  key: const ValueKey<String>('academy_hub_theme_button'),
                  icon: Icons.palette_outlined,
                  tooltip: widget.cinematicThemeEnabled
                      ? 'Theme locked by cinematic mode'
                      : 'Toggle academy theme',
                  accent: themeProvider.themeStyle == AppThemeStyle.monochrome
                      ? palette.amber
                      : palette.cyan,
                  monochrome: monochrome,
                  onPressed: widget.cinematicThemeEnabled
                      ? () => _openQuickThemeSettings(themeProvider)
                      : () => unawaited(_toggleAcademyHubTheme(themeProvider)),
                ),
                const SizedBox(width: 8),
                _buildAcademyHubTopActionButton(
                  key: const ValueKey<String>('academy_hub_settings_button'),
                  icon: Icons.settings_outlined,
                  tooltip: 'Settings',
                  accent: palette.amber,
                  monochrome: monochrome,
                  onPressed: () => _openQuickThemeSettings(themeProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademyHubTopActionButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required Color accent,
    required bool monochrome,
    required VoidCallback onPressed,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              accent.withValues(alpha: monochrome ? 0.14 : 0.18),
              palette.panel,
            ),
            Color.alphaBlend(
              accent.withValues(alpha: monochrome ? 0.06 : 0.10),
              palette.panelAlt,
            ),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: monochrome ? 0.52 : 0.72),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: monochrome ? 0.14 : 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        key: key,
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        color: accent,
        splashRadius: 22,
      ),
    );
  }

  Widget _buildAcademyHubOverview({
    required bool monochrome,
    required bool compact,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 440 : 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  palette.cyan.withValues(alpha: monochrome ? 0.10 : 0.14),
                  palette.panel,
                ),
                Color.alphaBlend(
                  palette.amber.withValues(alpha: monochrome ? 0.08 : 0.12),
                  palette.panelAlt,
                ),
              ],
            ),
            border: Border.all(
              color: Color.alphaBlend(
                palette.cyan.withValues(alpha: monochrome ? 0.40 : 0.58),
                palette.amber.withValues(alpha: monochrome ? 0.28 : 0.44),
              ),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.cyan.withValues(alpha: monochrome ? 0.10 : 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 18,
              vertical: compact ? 10 : 12,
            ),
            child: Column(
              key: const ValueKey<String>('academy_hub_overview_badge'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Your Curriculum',
                  textAlign: TextAlign.center,
                  style: puzzleAcademyDisplayStyle(
                    palette: palette,
                    size: compact ? 13.6 : 15.8,
                    color: palette.text,
                    letterSpacing: monochrome ? 0.24 : 0.18,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Puzzle Academy drives exam promotion. Opening Study sharpens your pattern memory before the next run.',
                    textAlign: TextAlign.center,
                    style: puzzleAcademyCompactStyle(
                      palette: palette,
                      size: 10.6,
                      color: palette.textMuted,
                      height: 1.28,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcademyHubBackdrop({required bool monochrome}) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: ValueListenableBuilder<double>(
          valueListenable: _academyBlueDotTime,
          builder: (context, time, _) {
            return CustomPaint(
              painter: _AcademyHubBackdropPainter(
                monochrome: monochrome,
                time: time,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAcademyHubProgressBar({
    required Color accent,
    required double progress,
    required bool monochrome,
    double height = 8,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Color.alphaBlend(
          accent.withValues(alpha: monochrome ? 0.12 : 0.08),
          palette.panelAlt,
        ),
        border: Border.all(
          color: accent.withValues(alpha: monochrome ? 0.22 : 0.16),
          width: 1.2,
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: clampedProgress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  accent.withValues(alpha: monochrome ? 0.82 : 0.94),
                  Color.alphaBlend(
                    Colors.white.withValues(alpha: monochrome ? 0.10 : 0.18),
                    accent,
                  ),
                ],
              ),
              boxShadow: clampedProgress <= 0
                  ? const <BoxShadow>[]
                  : [
                      BoxShadow(
                        color: accent.withValues(
                          alpha: monochrome ? 0.18 : 0.24,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  EloNodeProgress _academyHubFrontierNode(PuzzleAcademyProvider provider) {
    final unlockedNodes = provider.orderedNodes
        .where((node) => node.unlocked)
        .toList(growable: false);
    if (unlockedNodes.isNotEmpty) {
      return unlockedNodes.last;
    }
    return provider.orderedNodes.first;
  }

  String _academySemesterShortTitle(SemesterRange semester) {
    return semester.title.replaceAll(' Semester', '');
  }

  _AcademyHubCardModel _buildAcademyExamsHubCardModel({
    required PuzzleAcademyProvider provider,
    required bool monochrome,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final accent = monochrome
        ? const Color(0xFFE2E6EC)
        : const Color(0xFF6FE7FF);
    final shadowColor = monochrome
        ? const Color(0xFF9FA7B3)
        : const Color(0xFF137A9A);
    final frontierNode = _academyHubFrontierNode(provider);
    final rankNode = provider.displayRankNode;
    final semester = provider.semesterForNode(frontierNode);
    final semesterNodes = provider.orderedNodes
        .where((node) => semester.includes(node.startElo))
        .toList(growable: false);
    final semesterCrowns = semesterNodes.where((node) => node.goldCrown).length;
    final semesterProgress = provider.semesterProgress(semester);
    final solveTarget = provider.examUnlockSolveTarget(frontierNode);
    final solveRemaining = max(0, solveTarget - frontierNode.solvedCount);
    final examReady = provider.canTakeExam(frontierNode);
    final completedExams = provider.completedExamCountInSemester(semester);
    final readinessAccent = examReady ? palette.emerald : palette.amber;
    final summary = examReady
        ? completedExams > 0
              ? '$completedExams ${completedExams == 1 ? 'score' : 'scores'} logged in ${_academySemesterShortTitle(semester)}.'
              : '${frontierNode.title} exam board is ready.'
        : solveRemaining > 0
        ? 'Solve $solveRemaining more ${solveRemaining == 1 ? 'puzzle' : 'puzzles'} to unlock exams.'
        : 'Review unlocked exams and promotion gates.';

    final description = examReady
        ? completedExams > 0
              ? '$completedExams ${completedExams == 1 ? 'exam is' : 'exams are'} already logged in ${_academySemesterShortTitle(semester)}. Step in to post your next score.'
              : 'Your ${frontierNode.title} exam board is live. Enter the semester and bank your first recorded score.'
        : solveRemaining > 0
        ? 'Solve $solveRemaining more ${solveRemaining == 1 ? 'puzzle' : 'puzzles'} in ${frontierNode.title} to unlock its exam board.'
        : 'Open the semester board to review unlocked exams and promotion gates.';
    final inlineDetails = <String>[
      'Frontier node: ${frontierNode.title}',
      '$semesterCrowns/${semesterNodes.length} crowns secured this semester',
    ];

    return _AcademyHubCardModel(
      cardId: 'exams',
      eyebrow: _academySemesterShortTitle(semester).toUpperCase(),
      title: 'Puzzle Academy Exams',
      summary: summary,
      description: description,
      inlineDetails: inlineDetails,
      artLabel: examReady ? 'LIVE BOARD' : 'PROMOTION GATE',
      imageAsset: 'assets/academy/exam.png',
      imageAlignment: Alignment.center,
      imagePadding: const EdgeInsets.all(4),
      accent: accent,
      shadowColor: shadowColor,
      icon: Icons.extension_outlined,
      ctaLabel: examReady ? 'Enter Exams' : 'Open Semester',
      progressLabel: 'Semester mastery',
      progressValue: '${(semesterProgress * 100).round()}%',
      progress: semesterProgress,
      badges: [
        _AcademyHubCardBadge(
          label: rankNode.title,
          icon: Icons.bolt_rounded,
          accent: accent,
        ),
        _AcademyHubCardBadge(
          label: '$semesterCrowns/${semesterNodes.length} crowns',
          icon: Icons.workspace_premium_outlined,
          accent: palette.emerald,
        ),
        _AcademyHubCardBadge(
          label: examReady
              ? 'Exam Ready'
              : '${frontierNode.solvedCount}/$solveTarget solved',
          icon: examReady ? Icons.task_alt_rounded : Icons.timelapse_rounded,
          accent: readinessAccent,
          filled: examReady,
        ),
      ],
      onTap: () => unawaited(
        _runAcademyHubLaunchAnimation(
          cardId: 'exams',
          title: 'Puzzle Academy Exams',
          imageAsset: 'assets/academy/exam.png',
          accent: accent,
          shadowColor: shadowColor,
          icon: Icons.extension_outlined,
          onComplete: _openAcademyExams,
        ),
      ),
    );
  }

  _AcademyHubCardModel _buildAcademyQuizHubCardModel({
    required bool monochrome,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final accent = monochrome
        ? const Color(0xFFF0E9DC)
        : const Color(0xFFD8B640);
    final shadowColor = monochrome
        ? const Color(0xFFB4AB9B)
        : const Color(0xFF8A6714);
    final snapshot = _academyHubQuizSnapshot;
    final usesAccuracy = snapshot.totalAnswered > 0;
    final accuracyPercent = (snapshot.accuracy * 100).round();
    final activityProgress = usesAccuracy
        ? snapshot.accuracy
        : snapshot.studyReps > 0
        ? min(1.0, snapshot.studyReps / 18)
        : 0.0;
    final summary = usesAccuracy
        ? '$accuracyPercent% accuracy on ${snapshot.totalAnswered} quiz answers.'
        : snapshot.studyReps > 0
        ? snapshot.studiedOpenings > 0
              ? '${snapshot.studyReps} reps across ${snapshot.studiedOpenings} openings.'
              : '${snapshot.studyReps} study reps banked.'
        : 'Review opening families before the next exam block.';

    final description = snapshot.hasProgress
        ? snapshot.studiedOpenings > 0
              ? 'You have reviewed ${snapshot.studiedOpenings} openings, logged ${snapshot.studyReps} study rep${snapshot.studyReps == 1 ? '' : 's'}, and built a ${snapshot.bestStreak}-best streak.'
              : 'You have answered ${snapshot.totalAnswered} opening questions with $accuracyPercent% accuracy. Jump back in and keep promoting the ladder.'
        : 'Study opening families, replay lines, and build recognition before the next exam block.';
    final inlineDetails = <String>[
      snapshot.studiedOpenings > 0
          ? '${snapshot.studiedOpenings} openings reviewed'
          : 'Study library ready to explore',
      snapshot.bestStreak > 0
          ? 'Best streak: ${snapshot.bestStreak}'
          : usesAccuracy
          ? 'Quiz accuracy: $accuracyPercent%'
          : '${snapshot.studyReps} warmup reps logged',
    ];

    return _AcademyHubCardModel(
      cardId: 'quiz',
      eyebrow: snapshot.hasProgress ? 'OPENING LADDER' : 'OPENING STUDY',
      title: 'Opening Study',
      summary: summary,
      description: description,
      inlineDetails: inlineDetails,
      artLabel: usesAccuracy ? 'QUIZ LADDER' : 'STUDY FILES',
      imageAsset: 'assets/academy/openings_study.png',
      imageAlignment: Alignment.center,
      imagePadding: const EdgeInsets.all(4),
      accent: accent,
      shadowColor: shadowColor,
      icon: Icons.menu_book_outlined,
      ctaLabel: snapshot.hasProgress ? 'Resume Study' : 'Open Study',
      progressLabel: usesAccuracy
          ? 'Quiz accuracy'
          : snapshot.studyReps > 0
          ? 'Study activity'
          : 'Opening study',
      progressValue: usesAccuracy
          ? '$accuracyPercent%'
          : snapshot.studyReps > 0
          ? '${snapshot.studyReps} reps'
          : 'Ready',
      progress: activityProgress,
      badges: [
        _AcademyHubCardBadge(
          label: snapshot.studiedOpenings > 0
              ? '${snapshot.studiedOpenings} openings'
              : 'Study library',
          icon: Icons.library_books_outlined,
          accent: palette.cyan,
        ),
        _AcademyHubCardBadge(
          label: usesAccuracy ? '$accuracyPercent% accuracy' : 'Quiz ladder',
          icon: Icons.insights_rounded,
          accent: usesAccuracy && accuracyPercent >= 80
              ? palette.emerald
              : accent,
          filled: usesAccuracy && accuracyPercent >= 80,
        ),
        _AcademyHubCardBadge(
          label: snapshot.bestStreak > 0
              ? '${snapshot.bestStreak} best streak'
              : snapshot.studyReps > 0
              ? '${snapshot.studyReps} reps'
              : 'Warmup ready',
          icon: snapshot.bestStreak > 0
              ? Icons.local_fire_department_outlined
              : Icons.repeat_rounded,
          accent: snapshot.bestStreak > 0 ? palette.amber : accent,
          filled: snapshot.bestStreak >= 5,
        ),
      ],
      onTap: () => unawaited(
        _runAcademyHubLaunchAnimation(
          cardId: 'quiz',
          title: 'Opening Quiz',
          imageAsset: 'assets/academy/openings_study.png',
          accent: accent,
          shadowColor: shadowColor,
          icon: Icons.menu_book_outlined,
          onComplete: widget.onOpenOpeningQuiz,
        ),
      ),
    );
  }

  Widget _buildAcademyHubSelector({
    required PuzzleAcademyProvider provider,
    required _AcademyHubSelectorLayoutSpec layout,
    required bool monochrome,
    required bool isDark,
  }) {
    final examsModel = _buildAcademyExamsHubCardModel(
      provider: provider,
      monochrome: monochrome,
    );
    final quizModel = _buildAcademyQuizHubCardModel(monochrome: monochrome);

    Widget buildCard(_AcademyHubCardModel model) {
      return _buildAcademyHubCard(
        model: model,
        layout: layout,
        monochrome: monochrome,
        isDark: isDark,
      );
    }

    return KeyedSubtree(
      key: ValueKey<String>(layout.testKey),
      child: switch (layout.mode) {
        _AcademyHubSelectorLayoutMode.phonePortrait => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: buildCard(examsModel)),
            SizedBox(height: layout.selectorGap),
            Expanded(child: buildCard(quizModel)),
          ],
        ),
        _AcademyHubSelectorLayoutMode.tabletTwoUp => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: buildCard(examsModel)),
            SizedBox(width: layout.selectorGap),
            Expanded(child: buildCard(quizModel)),
          ],
        ),
        _AcademyHubSelectorLayoutMode.phoneLandscapeRail => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: buildCard(examsModel)),
            SizedBox(width: layout.selectorGap),
            Expanded(child: buildCard(quizModel)),
          ],
        ),
      },
    );
  }

  Widget _buildAcademyHubCardArtFrame({
    required _AcademyHubCardModel model,
    required bool monochrome,
    required bool horizontal,
    required bool isLaunching,
    required double imageScale,
    required Offset imageOffset,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    return SizedBox.expand(
      key: ValueKey<String>('academy_hub_art_frame_${model.cardId}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Padding(
              padding: model.imagePadding,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                scale: imageScale,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: imageOffset,
                  child: Image.asset(
                    model.imageAsset,
                    fit: BoxFit.contain,
                    alignment: model.imageAlignment,
                    filterQuality: _useReducedWindowsVisualEffects
                        ? FilterQuality.medium
                        : FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: horizontal ? 34 : 42,
                          color: palette.textMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isLaunching ? 1.0 : 0.0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    model.accent.withValues(alpha: monochrome ? 0.12 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademyHubCardBody({
    required _AcademyHubCardModel model,
    required _AcademyHubSelectorLayoutSpec layout,
    required bool monochrome,
    required bool isLaunching,
    required double imageScale,
    required Offset imageOffset,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final radius = layout.usesRail ? 18.0 : 22.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              model.accent.withValues(alpha: monochrome ? 0.10 : 0.14),
              palette.panel,
            ),
            Color.alphaBlend(
              model.shadowColor.withValues(alpha: monochrome ? 0.10 : 0.14),
              palette.panelAlt,
            ),
          ],
        ),
        border: Border.all(
          color: model.accent.withValues(alpha: monochrome ? 0.58 : 0.82),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: model.shadowColor.withValues(
              alpha: monochrome ? 0.16 : 0.28,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(layout.usesRail ? 6 : 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: monochrome ? 0.06 : 0.10),
                      Colors.transparent,
                      Colors.black.withValues(alpha: monochrome ? 0.08 : 0.16),
                    ],
                    stops: const [0.0, 0.38, 1.0],
                  ),
                ),
              ),
              _buildAcademyHubCardArtFrame(
                model: model,
                monochrome: monochrome,
                horizontal: layout.usesRail,
                isLaunching: isLaunching,
                imageScale: imageScale,
                imageOffset: imageOffset,
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: layout.usesRail ? 66 : 84,
                  height: 4,
                  decoration: BoxDecoration(
                    color: model.accent.withValues(alpha: 0.92),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: layout.usesRail ? 72 : 94,
                  height: 4,
                  decoration: BoxDecoration(
                    color: model.accent.withValues(
                      alpha: monochrome ? 0.56 : 0.82,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcademyHubCard({
    required _AcademyHubCardModel model,
    required _AcademyHubSelectorLayoutSpec layout,
    required bool monochrome,
    required bool isDark,
  }) {
    final cardKey = _academyHubCardKeyFor(model.cardId);
    final isHovered = _academyHubHoveredCardId == model.cardId;
    final isPressed = _academyHubPressedCardId == model.cardId;
    final isLaunching = _academyHubLaunchingCardId == model.cardId;
    final isDimmed =
        _academyHubLaunchingCardId != null &&
        _academyHubLaunchingCardId != model.cardId;
    final cardScale = isLaunching
        ? 1.032
        : isPressed
        ? 0.992
        : isHovered
        ? 1.016
        : 1.0;
    final cardOffset = isLaunching
        ? const Offset(0, -0.026)
        : isPressed
        ? const Offset(0, 0.010)
        : isHovered
        ? const Offset(0, -0.012)
        : Offset.zero;
    final cardTurns = isLaunching
        ? 0.002
        : isHovered
        ? (model.cardId == 'exams' ? -0.0012 : 0.0012)
        : 0.0;
    final imageScale = isLaunching
        ? 1.08
        : isPressed
        ? 1.01
        : isHovered
        ? 1.02
        : 1.0;
    final imageOffset = isLaunching
        ? (model.cardId == 'exams'
              ? const Offset(-0.02, -0.02)
              : const Offset(0.02, -0.02))
        : isHovered
        ? (model.cardId == 'exams'
              ? const Offset(-0.01, 0.0)
              : const Offset(0.01, 0.0))
        : Offset.zero;

    return SizedBox.expand(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final slide = (1 - value) * 14;
          return Transform.translate(
            offset: Offset(0, slide),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: RepaintBoundary(
          key: cardKey,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => _setAcademyHubHoveredCard(model.cardId),
            onExit: (_) => _setAcademyHubHoveredCard(null),
            child: Semantics(
              key: ValueKey<String>('academy_hub_card_${model.cardId}'),
              button: true,
              label: model.title,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                opacity: isDimmed ? 0.74 : 1.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  scale: cardScale,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    offset: cardOffset,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      turns: cardTurns,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _academyHubLaunchInFlight ? null : model.onTap,
                        onTapDown: (_) =>
                            _setAcademyHubPressedCard(model.cardId),
                        onTapUp: (_) => _setAcademyHubPressedCard(null),
                        onTapCancel: () => _setAcademyHubPressedCard(null),
                        child: _buildAcademyHubCardBody(
                          model: model,
                          layout: layout,
                          monochrome: monochrome,
                          isLaunching: isLaunching,
                          imageScale: imageScale,
                          imageOffset: imageOffset,
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
                                filterQuality: _useReducedWindowsVisualEffects
                                    ? FilterQuality.medium
                                    : FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 46,
                                      color: Colors.white70,
                                    ),
                                  );
                                },
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
    final media = MediaQuery.of(context);
    final safeHeight = max(0.0, constraints.maxHeight - media.padding.vertical);
    final aspectRatio = constraints.maxWidth / max(1.0, constraints.maxHeight);
    final useDualPaneLayout = aspectRatio >= 0.95;
    final compactDashboard =
        useDualPaneLayout && (constraints.maxWidth < 760 || safeHeight <= 500);
    final grouped = _groupBySemester(provider);

    if (useDualPaneLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            flex: 3,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: compactDashboard
                    ? min(196, constraints.maxWidth * 0.38)
                    : min(360, constraints.maxWidth * 0.34),
              ),
              child: _buildMasteryDashboard(
                provider,
                monochrome: monochrome,
                compact: compactDashboard,
              ),
            ),
          ),
          Flexible(
            flex: 7,
            child: _buildLandscapeMap(
              provider,
              grouped,
              themeProvider: themeProvider,
              monochrome: monochrome,
              compactHeader: compactDashboard,
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

  Widget _buildAcademyExamsOverview(
    PuzzleAcademyProvider provider, {
    required bool monochrome,
    required bool compact,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final frontierNode = _academyHubFrontierNode(provider);
    final rankNode = provider.displayRankNode;
    final semester = provider.semesterForNode(frontierNode);
    final semesterProgress = provider.semesterProgress(semester);
    final overallProgress = provider.overallMasteryProgress;
    final completedExams = provider.completedExamCountInSemester(semester);
    final totalLoggedExams = provider.totalLoggedExamCount;
    final examReady = provider.canTakeExam(frontierNode);
    final requirementSummary = _academyExamGateSummary(provider, frontierNode);
    final examLogLabel = completedExams > 0
        ? '$completedExams ${completedExams == 1 ? 'exam' : 'exams'} logged'
        : totalLoggedExams > 0
        ? '$totalLoggedExams ${totalLoggedExams == 1 ? 'exam' : 'exams'} logged overall'
        : 'No exams logged yet';
    final hasLoggedExams = completedExams > 0 || totalLoggedExams > 0;

    return PuzzleAcademyPanel(
      accent: palette.amber,
      fillColor: Color.alphaBlend(
        palette.amber.withValues(alpha: monochrome ? 0.08 : 0.05),
        palette.panel,
      ),
      radius: compact ? 20 : 24,
      borderWidth: 2.4,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 18,
        compact ? 16 : 18,
        compact ? 16 : 18,
        compact ? 16 : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...<Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PuzzleAcademyTag(
                  label: 'ACADEMY',
                  icon: Icons.home_outlined,
                  accent: palette.cyan,
                  compact: true,
                  filled: true,
                  monochromeOverride: monochrome,
                ),
                PuzzleAcademyTag(
                  label: 'EXAMS',
                  icon: Icons.extension_outlined,
                  accent: palette.amber,
                  compact: true,
                  filled: true,
                  monochromeOverride: monochrome,
                ),
                OutlinedButton.icon(
                  onPressed: _handleAcademyBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back to Hub'),
                  style: _academyOutlinedButtonStyle(
                    accent: palette.textMuted,
                    monochrome: monochrome,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          PuzzleAcademySectionHeader(
            title: 'Puzzle Academy Exams',
            subtitle:
                '${_academySemesterShortTitle(semester)} is your active semester. ${examReady ? 'The next board is ready to enter.' : 'The next exam gate is still locked.'}',
            accent: palette.amber,
            icon: Icons.extension_outlined,
            titleSize: compact ? 13.2 : 14,
            subtitleSize: compact ? 11.4 : 12.2,
            monochromeOverride: monochrome,
          ),
          SizedBox(height: compact ? 10 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PuzzleAcademyTag(
                label: _academySemesterShortTitle(semester).toUpperCase(),
                icon: Icons.school_outlined,
                accent: palette.cyan,
                compact: true,
                monochromeOverride: monochrome,
              ),
              PuzzleAcademyTag(
                label: rankNode.title,
                icon: Icons.flag_rounded,
                accent: palette.amber,
                compact: true,
                monochromeOverride: monochrome,
              ),
              PuzzleAcademyTag(
                label: examLogLabel,
                icon: Icons.fact_check_outlined,
                accent: hasLoggedExams ? palette.emerald : palette.textMuted,
                compact: true,
                filled: hasLoggedExams,
                monochromeOverride: monochrome,
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          Text(
            'NEXT EXAM GATE',
            style: puzzleAcademyHudStyle(
              palette: palette,
              size: compact ? 10.0 : 10.4,
              weight: FontWeight.w800,
              color: palette.textMuted,
              letterSpacing: 0.96,
              height: 1.0,
            ),
          ),
          SizedBox(height: compact ? 5 : 6),
          Text(
            requirementSummary,
            style: puzzleAcademyCompactStyle(
              palette: palette,
              size: compact ? 12.0 : 12.4,
              weight: FontWeight.w700,
              color: palette.text,
              height: 1.3,
            ),
          ),
          SizedBox(height: compact ? 12 : 14),
          compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAcademyExamsProgressMetric(
                      label: 'Overall mastery',
                      value: '${(overallProgress * 100).round()}%',
                      progress: overallProgress,
                      accent: palette.cyan,
                      monochrome: monochrome,
                    ),
                    const SizedBox(height: 12),
                    _buildAcademyExamsProgressMetric(
                      label: '${_academySemesterShortTitle(semester)} progress',
                      value: '${(semesterProgress * 100).round()}%',
                      progress: semesterProgress,
                      accent: palette.amber,
                      monochrome: monochrome,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildAcademyExamsProgressMetric(
                        label: 'Overall mastery',
                        value: '${(overallProgress * 100).round()}%',
                        progress: overallProgress,
                        accent: palette.cyan,
                        monochrome: monochrome,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildAcademyExamsProgressMetric(
                        label:
                            '${_academySemesterShortTitle(semester)} progress',
                        value: '${(semesterProgress * 100).round()}%',
                        progress: semesterProgress,
                        accent: palette.amber,
                        monochrome: monochrome,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildAcademyExamsProgressMetric({
    required String label,
    required String value,
    required double progress,
    required Color accent,
    required bool monochrome,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: 10.2,
                  weight: FontWeight.w800,
                  color: palette.textMuted,
                  letterSpacing: 0.92,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: puzzleAcademyDisplayStyle(
                palette: palette,
                size: 14,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildAcademyHubProgressBar(
          accent: accent,
          progress: progress,
          monochrome: monochrome,
        ),
      ],
    );
  }

  String _academyExamGateSummary(
    PuzzleAcademyProvider provider,
    EloNodeProgress frontierNode,
  ) {
    if (provider.canTakeExam(frontierNode)) {
      return '${frontierNode.title} is exam-ready. Open the semester board and start the next timed run.';
    }

    if (provider.requiresPreviousSemesterExamGate(frontierNode)) {
      return 'Clear the previous semester exam gate before ${frontierNode.title} can open its own board.';
    }

    final previousSolve = provider.previousNodeSolveRequirementText(
      frontierNode,
    );
    if (previousSolve != null && previousSolve.trim().isNotEmpty) {
      return previousSolve;
    }

    final solveTarget = provider.examUnlockSolveTarget(frontierNode);
    final solveRemaining = max(0, solveTarget - frontierNode.solvedCount);
    if (solveRemaining > 0) {
      return 'Solve $solveRemaining more ${solveRemaining == 1 ? 'puzzle' : 'puzzles'} in ${frontierNode.title} to unlock the next exam board.';
    }

    return 'Review the semester board to check the remaining promotion gates for ${frontierNode.title}.';
  }

  Widget _buildCompactDashboardToggle({
    required String keyName,
    required String label,
    required IconData icon,
    required Color accent,
    required bool monochrome,
    required bool expanded,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        key: ValueKey<String>(keyName),
        onPressed: onPressed,
        style: _academyOutlinedButtonStyle(
          accent: accent,
          monochrome: monochrome,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDashboardSections(
    PuzzleAcademyProvider provider, {
    required bool monochrome,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompactDashboardToggle(
          keyName: 'academy_exams_compact_dashboard_toggle',
          label: 'Mastery Dashboard',
          icon: Icons.extension_outlined,
          accent: palette.amber,
          monochrome: monochrome,
          expanded: _compactDashboardOverviewExpanded,
          onPressed: () {
            setState(() {
              _compactDashboardOverviewExpanded =
                  !_compactDashboardOverviewExpanded;
            });
          },
        ),
        PuzzleAcademyAnimatedSwap(
          child: _compactDashboardOverviewExpanded
              ? Padding(
                  key: const ValueKey<String>(
                    'academy_exams_compact_dashboard_panel',
                  ),
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildAcademyExamsOverview(
                    provider,
                    monochrome: monochrome,
                    compact: true,
                  ),
                )
              : const SizedBox(
                  key: ValueKey<String>(
                    'academy_exams_compact_dashboard_collapsed',
                  ),
                ),
        ),
        const SizedBox(height: 10),
        _buildCompactDashboardToggle(
          keyName: 'academy_exams_compact_stats_toggle',
          label: 'Academy Stats',
          icon: Icons.stacked_bar_chart_rounded,
          accent: palette.cyan,
          monochrome: monochrome,
          expanded: _compactDashboardStatsExpanded,
          onPressed: () {
            setState(() {
              _compactDashboardStatsExpanded = !_compactDashboardStatsExpanded;
            });
          },
        ),
        PuzzleAcademyAnimatedSwap(
          child: _compactDashboardStatsExpanded
              ? Padding(
                  key: const ValueKey<String>(
                    'academy_exams_compact_stats_panel',
                  ),
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildHeroStatsBar(provider, compact: true),
                )
              : const SizedBox(
                  key: ValueKey<String>(
                    'academy_exams_compact_stats_collapsed',
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPortraitMap(
    PuzzleAcademyProvider provider,
    Map<SemesterRange, List<EloNodeProgress>> grouped, {
    required AppThemeProvider themeProvider,
    required bool monochrome,
  }) {
    _ensureExpandedSemester(provider);
    final media = MediaQuery.of(context);
    final safeHeight = max(0.0, media.size.height - media.padding.vertical);
    final compactPhoneLayout = media.size.width <= 430 || safeHeight <= 780;
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(
          provider,
          themeProvider: themeProvider,
          monochrome: monochrome,
          compact: compactPhoneLayout,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: compactPhoneLayout
                ? _buildCompactDashboardSections(
                    provider,
                    monochrome: monochrome,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mastery Dashboard',
                        style: puzzleAcademyDisplayStyle(
                          palette: puzzleAcademyPalette(
                            context,
                            monochromeOverride: monochrome,
                          ),
                          size: 18,
                          color: _accentGold(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildAcademyExamsOverview(
                        provider,
                        monochrome: monochrome,
                        compact: true,
                      ),
                    ],
                  ),
          ),
        ),
        if (!compactPhoneLayout)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              isLoading:
                  provider.dailyPuzzleLoading || !provider.dailyPuzzleLoaded,
              errorMessage: provider.lastDailyPuzzleError,
              onRetry: provider.refreshDailyPuzzle,
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
    required bool compactHeader,
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
              compact: compactHeader,
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
    bool compact = false,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );

    final titleContent = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: widget.onShowCredits,
            child: Image.asset(
              'assets/ChessIQ.png',
              width: compact ? 58 : 72,
              height: compact ? 18 : 20,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            'Puzzle Academy',
            style: puzzleAcademyDisplayStyle(
              palette: palette,
              size: compact ? 11.8 : 13.6,
              color: palette.cyan,
            ),
          ),
        ],
      ),
    );

    if (compact) {
      return SliverAppBar(
        pinned: true,
        toolbarHeight: 64,
        backgroundColor: palette.panel.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: _handleAcademyBack,
          tooltip: 'Back to Academy hub',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: KeyedSubtree(
          key: const ValueKey<String>('academy_exams_compact_appbar_title'),
          child: titleContent,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _openQuickThemeSettings(themeProvider),
            icon: const Icon(Icons.settings_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: _openStore,
              icon: const Icon(Icons.storefront_outlined),
            ),
          ),
        ],
      );
    }

    return SliverAppBar(
      pinned: true,
      expandedHeight: 136,
      backgroundColor: palette.panel.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: _handleAcademyBack,
        tooltip: 'Back to Academy hub',
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
        title: Center(child: titleContent),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.shell,
                palette.panelAlt,
                palette.backdrop.withValues(alpha: 0.0),
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
    bool compact = false,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    return SafeArea(
      right: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 18, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (compact) ...<Widget>[
                _buildCompactDashboardSections(
                  provider,
                  monochrome: monochrome,
                ),
                const SizedBox(height: 12),
              ] else ...<Widget>[
                Row(
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _handleAcademyBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Academy'),
                      style: _academyOutlinedButtonStyle(
                        accent: palette.textMuted,
                        monochrome: monochrome,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Academy > Exams',
                            style: puzzleAcademyHudStyle(
                              palette: palette,
                              size: 10.8,
                              weight: FontWeight.w800,
                              color: palette.textMuted,
                              letterSpacing: 0.96,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mastery Dashboard',
                            style: puzzleAcademyDisplayStyle(
                              palette: palette,
                              size: 22,
                              color: palette.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAcademyExamsOverview(
                  provider,
                  monochrome: monochrome,
                  compact: false,
                ),
                const SizedBox(height: 12),
                _buildHeroStatsBar(provider),
                const SizedBox(height: 12),
                _buildCurrentTitlePanel(provider, monochrome: monochrome),
                const SizedBox(height: 12),
                _buildSemesterProgressPanel(provider, monochrome: monochrome),
                const SizedBox(height: 12),
              ],
              _DailyChallengeCard(
                total: provider.dailyPuzzles.length,
                completed: provider.completedTodayDailyCount,
                hasTodayPuzzle: provider.hasTodayDailyPuzzle,
                isLoading:
                    provider.dailyPuzzleLoading || !provider.dailyPuzzleLoaded,
                errorMessage: provider.lastDailyPuzzleError,
                onRetry: provider.refreshDailyPuzzle,
                monochrome: monochrome,
                onTap: () => _openTodayDailyPuzzle(provider, monochrome),
              ),
              const SizedBox(height: 12),
              _buildScoreboardSection(provider, monochrome),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTitlePanel(
    PuzzleAcademyProvider provider, {
    required bool monochrome,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final handle = provider.progress.handle.trim();
    final needsProfile = handle.isEmpty || provider.shouldAskForProfile;

    return _DashboardPanel(
      title: 'Current Title',
      accent: const Color(0xFFD8B640),
      monochrome: monochrome,
      child: PuzzleAcademyAnimatedSwap(
        child: KeyedSubtree(
          key: ValueKey<String>(
            needsProfile ? 'current-title-empty' : 'current-title-filled',
          ),
          child: needsProfile
              ? _DashboardStateNotice(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile setup recommended',
                  message:
                      'Set up your Academy identity to track your title cleanly on the live board and keep exam standings attached to one name.',
                  accent: palette.amber,
                  actionLabel: 'Set Up Profile',
                  onAction: () =>
                      unawaited(_openAcademyProfileEditor(provider)),
                  monochrome: monochrome,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      handle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: puzzleAcademyIdentityStyle(
                        palette: palette,
                        size: 13.4,
                        color: palette.text,
                        withGlow: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      provider.currentTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: puzzleAcademyIdentityStyle(
                        palette: palette,
                        size: 10.2,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PuzzleAcademyTag(
                          label: '${provider.totalSolved} solved',
                          icon: Icons.bolt_rounded,
                          accent: palette.cyan,
                          compact: true,
                          monochromeOverride: monochrome,
                        ),
                        PuzzleAcademyTag(
                          label: '${provider.masteredNodeCount} crowns',
                          icon: Icons.workspace_premium_outlined,
                          accent: palette.amber,
                          compact: true,
                          monochromeOverride: monochrome,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSemesterProgressPanel(
    PuzzleAcademyProvider provider, {
    required bool monochrome,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    final semesters = provider.semesters;
    final frontierNode = provider.orderedNodes.isEmpty
        ? null
        : _academyHubFrontierNode(provider);
    final activeSemester = frontierNode == null
        ? null
        : provider.semesterForNode(frontierNode);

    return _DashboardPanel(
      title: 'Semester Progress',
      accent: const Color(0xFF6FE7FF),
      monochrome: monochrome,
      child: PuzzleAcademyAnimatedSwap(
        child: KeyedSubtree(
          key: ValueKey<String>(
            semesters.isEmpty
                ? 'semester-progress-empty'
                : 'semester-progress-filled',
          ),
          child: semesters.isEmpty
              ? _DashboardStateNotice(
                  icon: Icons.school_outlined,
                  title: 'Semester map unavailable',
                  message:
                      'Semester progress will appear here once the Academy map is ready and synced.',
                  accent: palette.cyan,
                  monochrome: monochrome,
                )
              : Column(
                  children: semesters
                      .map((semester) {
                        final pct = (provider.semesterProgress(semester) * 100)
                            .round();
                        final examsLogged = provider
                            .completedExamCountInSemester(semester);
                        final isActive = activeSemester?.id == semester.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          semester.title,
                                          style: puzzleAcademyCompactStyle(
                                            palette: palette,
                                            size: 13.6,
                                            weight: FontWeight.w700,
                                            color: palette.text,
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            if (isActive)
                                              PuzzleAcademyTag(
                                                label: 'ACTIVE',
                                                icon: Icons.flag_rounded,
                                                accent: palette.amber,
                                                compact: true,
                                                filled: true,
                                                monochromeOverride: monochrome,
                                              ),
                                            PuzzleAcademyTag(
                                              label: '$examsLogged exams',
                                              icon: Icons.fact_check_outlined,
                                              accent: examsLogged > 0
                                                  ? palette.emerald
                                                  : palette.textMuted,
                                              compact: true,
                                              filled: examsLogged > 0,
                                              monochromeOverride: monochrome,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$pct%',
                                    style: puzzleAcademyCompactStyle(
                                      palette: palette,
                                      size: 13.2,
                                      weight: FontWeight.w700,
                                      color: palette.cyan,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildAcademyHubProgressBar(
                                accent: isActive ? palette.amber : palette.cyan,
                                progress: provider.semesterProgress(semester),
                                monochrome: monochrome,
                                height: 6,
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
        ),
      ),
    );
  }

  Widget _buildHeroStatsBar(
    PuzzleAcademyProvider provider, {
    bool compact = false,
  }) {
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride:
          context.read<AppThemeProvider>().isMonochrome ||
          widget.cinematicThemeEnabled,
    );
    return PuzzleAcademyPanel(
      accent: palette.cyan,
      radius: 10,
      padding: EdgeInsets.all(compact ? 12 : 16),
      monochromeOverride:
          context.read<AppThemeProvider>().isMonochrome ||
          widget.cinematicThemeEnabled,
      child: Wrap(
        spacing: compact ? 8 : 10,
        runSpacing: compact ? 8 : 10,
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

  Future<void> _toggleAcademyHubTheme(AppThemeProvider themeProvider) async {
    final nextStyle = themeProvider.themeStyle == AppThemeStyle.monochrome
        ? AppThemeStyle.standard
        : AppThemeStyle.monochrome;
    await themeProvider.setThemeStyle(nextStyle);
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

class _AcademyHubBackdropPainter extends CustomPainter {
  const _AcademyHubBackdropPainter({
    required this.monochrome,
    required this.time,
  });

  final bool monochrome;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = min(size.width, size.height);
    final pixel = max(4.0, shortestSide / 92);
    final skyTop = monochrome
        ? const Color(0xFF2F3238)
        : const Color(0xFF16264F);
    final skyBottom = monochrome
        ? const Color(0xFF181A20)
        : const Color(0xFF11172E);
    final horizonGlow = monochrome
        ? const Color(0xFFCACED7)
        : const Color(0xFFE6C45B);
    final skylineBase = monochrome
        ? const Color(0xFF626771)
        : const Color(0xFF27456A);
    final skylineAccent = monochrome
        ? const Color(0xFF8C919C)
        : const Color(0xFF4F7EC1);
    final floorBase = monochrome
        ? const Color(0xFF1D2128)
        : const Color(0xFF101B34);
    final gridLine = monochrome
        ? const Color(0xFF7D818A)
        : const Color(0xFF4ED3FF);
    final starColor = monochrome
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF91EBFF);
    final cloudColor = monochrome
        ? const Color(0xFF9FA4AE)
        : const Color(0xFF75C9FF);

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[skyTop, skyBottom],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final glowCenter = Offset(
      size.width * 0.5,
      size.height * 0.19 + sin(time * 0.22) * pixel * 1.4,
    );
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (glowCenter.dx / size.width) * 2 - 1,
          (glowCenter.dy / size.height) * 2 - 1,
        ),
        radius:
            min(size.width * 0.46, size.height * 0.34) /
            max(size.width, size.height),
        colors: <Color>[
          horizonGlow.withValues(alpha: monochrome ? 0.16 : 0.22),
          horizonGlow.withValues(alpha: monochrome ? 0.04 : 0.08),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glowPaint);

    _drawSun(canvas, size, pixel, horizonGlow);
    _drawStars(canvas, size, pixel, starColor);
    _drawCloud(
      canvas,
      size,
      pixel,
      Offset(
        ((size.width * 0.16) + time * pixel * 2.6) % (size.width + 18 * pixel) -
            12 * pixel,
        size.height * 0.17,
      ),
      cloudColor,
    );
    _drawCloud(
      canvas,
      size,
      pixel,
      Offset(
        size.width -
            ((((size.width * 0.24) + time * pixel * 2.1) %
                    (size.width + 22 * pixel)) -
                10 * pixel),
        size.height * 0.26,
      ),
      cloudColor.withValues(alpha: monochrome ? 0.66 : 0.78),
    );
    _drawSkyline(canvas, size, pixel, skylineBase, skylineAccent);
    _drawFloor(canvas, size, pixel, floorBase, gridLine);
    _drawScanlines(canvas, size, pixel);
  }

  void _drawSun(Canvas canvas, Size size, double pixel, Color color) {
    final centerX = size.width * 0.5;
    final baseY = size.height * 0.11 + sin(time * 0.24) * pixel * 1.2;
    final stripePaint = Paint()
      ..color = color.withValues(alpha: monochrome ? 0.28 : 0.46);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: monochrome ? 0.06 : 0.10);

    for (var row = 0; row < 8; row++) {
      final inset = row * pixel * 1.2;
      final width = min(size.width * 0.32, pixel * 30) - inset * 1.4;
      final top = baseY + row * pixel * 1.28;
      final rect = Rect.fromCenter(
        center: Offset(centerX, top),
        width: width,
        height: pixel,
      );
      canvas.drawRect(rect.shift(Offset(0, pixel * 0.3)), shadowPaint);
      canvas.drawRect(rect, stripePaint);
    }
  }

  void _drawStars(Canvas canvas, Size size, double pixel, Color color) {
    final starPaint = Paint();
    for (var index = 0; index < 26; index++) {
      final x = (((index * 37) % 100) / 100.0) * size.width;
      final y = ((((index * 29) + 11) % 40) / 100.0) * size.height;
      final twinkle = 0.42 + 0.34 * sin(time * 1.6 + index * 0.9).abs();
      starPaint.color = color.withValues(alpha: twinkle);
      final extent = index % 3 == 0 ? pixel * 0.9 : pixel * 0.65;
      canvas.drawRect(Rect.fromLTWH(x, y, extent, extent), starPaint);
    }
  }

  void _drawCloud(
    Canvas canvas,
    Size size,
    double pixel,
    Offset anchor,
    Color color,
  ) {
    final blocks = <Offset>[
      const Offset(0, 1),
      const Offset(1, 0),
      const Offset(2, 0),
      const Offset(3, 1),
      const Offset(4, 1),
      const Offset(1, 1),
      const Offset(2, 1),
      const Offset(3, 0),
      const Offset(2, 2),
      const Offset(3, 2),
    ];
    final cloudPaint = Paint()..color = color.withValues(alpha: 0.20);
    for (final block in blocks) {
      final left = anchor.dx + block.dx * pixel * 3.2;
      final top = anchor.dy + block.dy * pixel * 2.2;
      if (left > size.width + pixel * 8 || left < -pixel * 16) {
        continue;
      }
      canvas.drawRect(
        Rect.fromLTWH(left, top, pixel * 3.2, pixel * 2.2),
        cloudPaint,
      );
    }
  }

  void _drawSkyline(
    Canvas canvas,
    Size size,
    double pixel,
    Color base,
    Color accent,
  ) {
    final basePaint = Paint()..color = base.withValues(alpha: 0.54);
    final accentPaint = Paint()..color = accent.withValues(alpha: 0.30);
    final buildingWidths = <double>[8, 11, 6, 10, 7, 12, 8, 9, 6, 10];
    final buildingHeights = <double>[18, 26, 14, 22, 16, 28, 20, 24, 15, 19];
    var x = -pixel * 2;
    for (var i = 0; x < size.width + pixel * 8; i++) {
      final width = buildingWidths[i % buildingWidths.length] * pixel;
      final height = buildingHeights[i % buildingHeights.length] * pixel;
      final rect = Rect.fromLTWH(x, size.height * 0.56 - height, width, height);
      canvas.drawRect(rect, basePaint);
      final windowSize = pixel * 0.9;
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          if ((row + col + i) % 2 == 0) {
            final left = rect.left + pixel * 1.4 + col * pixel * 2.2;
            final top = rect.top + pixel * 1.8 + row * pixel * 2.2;
            canvas.drawRect(
              Rect.fromLTWH(left, top, windowSize, windowSize),
              accentPaint,
            );
          }
        }
      }
      x += width - pixel * 0.8;
    }
  }

  void _drawFloor(
    Canvas canvas,
    Size size,
    double pixel,
    Color base,
    Color grid,
  ) {
    final floorTop = size.height * 0.58;
    canvas.drawRect(
      Rect.fromLTWH(0, floorTop, size.width, size.height - floorTop),
      Paint()..color = base.withValues(alpha: 0.80),
    );

    final horizontalPaint = Paint()
      ..color = grid.withValues(alpha: monochrome ? 0.08 : 0.14)
      ..strokeWidth = pixel * 0.4;
    for (var index = 0; index < 8; index++) {
      final t = index / 7;
      final y = lerpDouble(floorTop, size.height, t * t)!;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), horizontalPaint);
    }

    final verticalPaint = Paint()
      ..color = grid.withValues(alpha: monochrome ? 0.06 : 0.12)
      ..strokeWidth = pixel * 0.34;
    for (var index = -6; index <= 6; index++) {
      final bottomX = size.width * 0.5 + index * pixel * 10;
      canvas.drawLine(
        Offset(size.width * 0.5, floorTop),
        Offset(bottomX, size.height),
        verticalPaint,
      );
    }
  }

  void _drawScanlines(Canvas canvas, Size size, double pixel) {
    final scanlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: monochrome ? 0.028 : 0.038);
    final spacing = pixel * 2.1;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, pixel * 0.28),
        scanlinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AcademyHubBackdropPainter oldDelegate) {
    return oldDelegate.monochrome != monochrome || oldDelegate.time != time;
  }
}

class _AcademyProfileDialog extends StatefulWidget {
  const _AcademyProfileDialog({
    required this.initialHandle,
    required this.initialCountry,
    this.lockHandle = false,
    this.lockCountry = false,
    this.allowExitToMenu = false,
    this.cinematicThemeEnabled = false,
  });

  final String initialHandle;
  final String initialCountry;
  final bool lockHandle;
  final bool lockCountry;
  final bool allowExitToMenu;
  final bool cinematicThemeEnabled;

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
    final monochrome =
        context.read<AppThemeProvider>().isMonochrome ||
        widget.cinematicThemeEnabled;
    final palette = puzzleAcademyPalette(
      context,
      monochromeOverride: monochrome,
    );
    return PuzzleAcademyDialogShell(
      title: 'Academy Leaderboard Setup',
      subtitle:
          'Choose the handle and country shown on global and local boards.',
      accent: palette.cyan,
      icon: Icons.leaderboard_rounded,
      monochromeOverride: monochrome,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: puzzleAcademyOutlinedButtonStyle(
            palette: palette,
            accent: palette.cyan,
          ),
          child: Text(widget.allowExitToMenu ? 'BACK TO MENU' : 'CANCEL'),
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
          style: puzzleAcademyFilledButtonStyle(
            palette: palette,
            backgroundColor: palette.cyan,
            foregroundColor: const Color(0xFF07131F),
          ),
          child: const Text('SAVE'),
        ),
      ],
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This information is only used for leaderboard display. No email, account details, or precise location are collected.',
                style: puzzleAcademyHudStyle(
                  palette: palette,
                  size: 12.0,
                  weight: FontWeight.w600,
                  height: 1.45,
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
            ],
          ),
        ),
      ),
    );
  }
}
