import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/analysis/screens/chess_analysis_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpVsBotSelector(
  WidgetTester tester, {
  required Size size,
  bool monochrome = false,
  Map<String, Object> initialPrefs = const <String, Object>{},
  FakeViewPadding padding = FakeViewPadding.zero,
  FakeViewPadding viewPadding = FakeViewPadding.zero,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'mute_sounds_v1': true,
    'haptics_enabled_v1': false,
    ...initialPrefs,
  });

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.view.padding = padding;
  tester.view.viewPadding = viewPadding;

  final economy = EconomyProvider();
  await economy.refresh(notify: false);
  final theme = AppThemeProvider();
  if (monochrome) {
    await theme.setThemeStyle(AppThemeStyle.monochrome);
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeProvider>.value(value: theme),
        ChangeNotifierProvider<EconomyProvider>.value(value: economy),
      ],
      child: const MaterialApp(home: ChessAnalysisPage()),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));

  final playChess = find.text('PLAY CHESS');
  expect(playChess, findsOneWidget);

  await tester.tap(playChess);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets(
    'vs bot selector keeps avatar square on compact iPhone portrait',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await _pumpVsBotSelector(
        tester,
        size: const Size(390, 844),
        padding: const FakeViewPadding(top: 47, bottom: 34),
        viewPadding: const FakeViewPadding(top: 47, bottom: 34),
      );

      expect(find.text('YOU OPEN'), findsOneWidget);
      expect(find.text('MIXED START'), findsOneWidget);
      expect(find.text('100 ELO'), findsWidgets);
      expect(
        find.text('Win this tier to unlock the next contestant.'),
        findsNothing,
      );
      expect(find.textContaining('unlock Medium.'), findsNothing);
      expect(find.textContaining('unlock Hard.'), findsNothing);

      final avatarFinder = find.byKey(
        const ValueKey<String>('bot_setup_avatar_frame_mochi-gearheart'),
      );
      expect(avatarFinder, findsOneWidget);

      final startButtonFinder = find.byKey(
        const ValueKey<String>('bot_setup_start_button'),
      );
      expect(startButtonFinder, findsOneWidget);

      final backButtonRect = tester.getRect(
        find.byIcon(Icons.arrow_back_rounded),
      );
      final startButtonRect = tester.getRect(startButtonFinder);
      final statusBarInset = tester.view.padding.top;

      final avatarSize = tester.getSize(avatarFinder);
      expect((avatarSize.width - avatarSize.height).abs(), lessThan(0.5));
      expect(backButtonRect.top - statusBarInset, lessThanOrEqualTo(20));
      expect(startButtonRect.bottom, lessThanOrEqualTo(844));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'vs bot selector hides helper guidance on compact iPhone portrait',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await _pumpVsBotSelector(
        tester,
        size: const Size(390, 844),
        initialPrefs: const <String, Object>{
          'vs_bot_completed_tiers_v1': <String>['mochi-gearheart:easy'],
        },
      );

      await tester.tap(find.text('Easy'));
      await tester.pump();

      expect(
        find.textContaining(
          'is already cleared. Replay it or push to the next tier.',
        ),
        findsNothing,
      );
      expect(
        find.text('Win this tier to unlock the next contestant.'),
        findsNothing,
      );

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.textContaining('tiers to unlock'), findsNothing);
      final startButtonRect = tester.getRect(
        find.byKey(const ValueKey<String>('bot_setup_start_button')),
      );
      expect(startButtonRect.bottom, lessThanOrEqualTo(844));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'vs bot selector compresses short iPhone portrait before launch falls below fold',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await _pumpVsBotSelector(
        tester,
        size: const Size(375, 812),
        padding: const FakeViewPadding(top: 47, bottom: 34),
        viewPadding: const FakeViewPadding(top: 47, bottom: 34),
      );

      final startButtonFinder = find.byKey(
        const ValueKey<String>('bot_setup_start_button'),
      );
      final startButtonRect = tester.getRect(startButtonFinder);

      expect(startButtonFinder.hitTestable(), findsOneWidget);
      expect(startButtonRect.bottom, lessThanOrEqualTo(812));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'vs bot selector keeps avatar square on compact iPhone landscape',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await _pumpVsBotSelector(tester, size: const Size(844, 390));

      expect(find.text('YOU OPEN'), findsOneWidget);
      expect(find.text('MIXED START'), findsOneWidget);
      expect(find.text('BOT OPENS'), findsOneWidget);
      expect(find.text('100\nELO'), findsOneWidget);
      expect(find.textContaining('/3 TIERS'), findsOneWidget);
      expect(
        find.text('Win this tier to unlock the next contestant.'),
        findsOneWidget,
      );
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);

      final easyRect = tester.getRect(find.text('Easy'));
      final mediumRect = tester.getRect(find.text('Medium'));
      final hardRect = tester.getRect(find.text('Hard'));
      expect(easyRect.bottom, lessThanOrEqualTo(390));
      expect(mediumRect.bottom, lessThanOrEqualTo(390));
      expect(hardRect.bottom, lessThanOrEqualTo(390));

      final avatarFinder = find.byKey(
        const ValueKey<String>('bot_setup_avatar_frame_mochi-gearheart'),
      );
      expect(avatarFinder, findsOneWidget);

      final selectorPanel = find.byKey(
        const ValueKey<String>('bot_setup_selector_panel'),
      );
      final difficultyPanel = find.byKey(
        const ValueKey<String>('bot_setup_difficulty_panel'),
      );
      final sidePanel = find.byKey(
        const ValueKey<String>('bot_setup_side_panel'),
      );
      expect(selectorPanel, findsOneWidget);
      expect(difficultyPanel, findsOneWidget);
      expect(sidePanel, findsOneWidget);

      final selectorRect = tester.getRect(selectorPanel);
      final difficultyRect = tester.getRect(difficultyPanel);
      final sideRect = tester.getRect(sidePanel);
      expect(selectorRect.left, lessThan(difficultyRect.left));
      expect((selectorRect.top - difficultyRect.top).abs(), lessThan(0.5));
      expect(
        (selectorRect.height - (sideRect.bottom - difficultyRect.top)).abs(),
        lessThan(0.5),
      );

      final avatarSize = tester.getSize(avatarFinder);
      expect((avatarSize.width - avatarSize.height).abs(), lessThan(0.5));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'vs bot selector keeps long progress guidance on compact iPhone landscape',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await _pumpVsBotSelector(
        tester,
        size: const Size(844, 390),
        initialPrefs: const <String, Object>{
          'vs_bot_completed_tiers_v1': <String>['mochi-gearheart:easy'],
        },
      );

      await tester.tap(find.text('Easy'));
      await tester.pump();

      expect(
        find.textContaining(
          'is already cleared. Replay it or push to the next tier.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.textContaining('tiers to unlock'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'vs bot selector switches to right-side controls on smaller landscape phones',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await _pumpVsBotSelector(tester, size: const Size(667, 375));

      final selectorPanel = find.byKey(
        const ValueKey<String>('bot_setup_selector_panel'),
      );
      final difficultyPanel = find.byKey(
        const ValueKey<String>('bot_setup_difficulty_panel'),
      );
      final sidePanel = find.byKey(
        const ValueKey<String>('bot_setup_side_panel'),
      );

      expect(selectorPanel, findsOneWidget);
      expect(difficultyPanel, findsOneWidget);
      expect(sidePanel, findsOneWidget);
      expect(find.textContaining('/3 TIERS'), findsOneWidget);

      final selectorRect = tester.getRect(selectorPanel);
      final difficultyRect = tester.getRect(difficultyPanel);
      expect(selectorRect.left, lessThan(difficultyRect.left));
      expect((selectorRect.top - difficultyRect.top).abs(), lessThan(0.5));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'vs bot selector start button keeps contrast in monochrome theme',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpVsBotSelector(
        tester,
        size: const Size(844, 390),
        monochrome: true,
      );

      final startButtonFinder = find.byKey(
        const ValueKey<String>('bot_setup_start_button'),
      );
      expect(startButtonFinder, findsOneWidget);

      final startButton = tester.widget<ButtonStyleButton>(startButtonFinder);
      final backgroundColor = startButton.style?.backgroundColor?.resolve(
        <WidgetState>{},
      );
      final foregroundColor = startButton.style?.foregroundColor?.resolve(
        <WidgetState>{},
      );

      expect(backgroundColor, isNotNull);
      expect(foregroundColor, isNotNull);
      expect(backgroundColor, isNot(equals(foregroundColor)));
      expect(
        (backgroundColor!.computeLuminance() -
                foregroundColor!.computeLuminance())
            .abs(),
        greaterThan(0.25),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
