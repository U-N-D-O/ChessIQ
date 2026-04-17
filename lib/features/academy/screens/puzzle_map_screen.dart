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

class PuzzleMapScreen extends StatefulWidget {
  const PuzzleMapScreen({
    super.key,
    required this.onBack,
    this.cinematicThemeEnabled = false,
    this.onShowCredits,
    this.onOpenMainStore,
  });

  final VoidCallback onBack;
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
  Duration _academyBlueDotLastTick = Duration.zero;

  final Set<String> _expandedSemesterTitles = <String>{};
  bool _expandedSemesterInitialized = false;

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
                  final wide = constraints.maxWidth >= 980;
                  final aspectRatio =
                      constraints.maxWidth / max(1.0, constraints.maxHeight);
                  final useDualPaneLayout = wide || aspectRatio >= 1.0;
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
                      if (useDualPaneLayout)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Flexible(
                              flex: 3,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: min(
                                    360,
                                    constraints.maxWidth * 0.34,
                                  ),
                                ),
                                child: _buildMasteryDashboard(
                                  provider,
                                  monochrome: monochrome,
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
                              ),
                            ),
                          ],
                        )
                      else
                        _buildPortraitMap(
                          provider,
                          grouped,
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

  Widget _buildAtmosphere(bool cinematic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: Stack(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _academyBlueDotTime,
            builder: (context, time, child) {
              return Align(
                alignment: _academyDotAlignment(
                  _academyBlueDotPhase,
                  0.52,
                  _academyBlueDotRadius,
                  time,
                  _academyBlueDotTrajectoryNoise,
                  _academyBlueDotShapeSeed,
                ),
                child: child,
              );
            },
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
        ],
      ),
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
    final raw = Offset(x + driftX + jitterX, y + driftY + jitterY);
    final distance = raw.distance;
    const limit = 1.35;
    final returnFactor = distance > limit ? limit / distance : 1.0;
    return Alignment(raw.dx * returnFactor, raw.dy * returnFactor);
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
        onPressed: widget.onBack,
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
                onPressed: widget.onBack,
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
