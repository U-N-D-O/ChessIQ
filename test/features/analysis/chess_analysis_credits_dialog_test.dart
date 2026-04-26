import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/analysis/screens/chess_analysis_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<EconomyProvider> _pumpCreditsDialog(
  WidgetTester tester, {
  required Size size,
}) async {
  SharedPreferences.setMockInitialValues(const <String, Object>{
    'mute_sounds_v1': true,
    'haptics_enabled_v1': false,
  });

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  final economy = EconomyProvider();
  await economy.refresh(notify: false);
  final theme = AppThemeProvider();

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

  final triggers = find.byKey(
    const ValueKey<String>('analysis_credits_trigger'),
  );
  expect(triggers, findsWidgets);
  await tester.ensureVisible(triggers.first);
  await tester.tap(triggers.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));

  return economy;
}

ScrollController _creditsDialogScrollController(WidgetTester tester) {
  final scrollView = tester.widget<SingleChildScrollView>(
    find.byKey(const ValueKey<String>('credits_dialog_scroll_view')),
  );
  return scrollView.controller!;
}

double _normalizedScrollOffset(ScrollController controller) {
  if (!controller.hasClients || controller.position.maxScrollExtent <= 0) {
    return 0.0;
  }
  return controller.offset / controller.position.maxScrollExtent;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets(
    'credits dialog opens on compact portrait without exposing CVR summary text',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpCreditsDialog(tester, size: const Size(390, 844));

      final shell = find.byKey(const ValueKey<String>('credits_dialog_shell'));
      final title = find.byKey(const ValueKey<String>('credits_dialog_title'));
      final ownership = find.byKey(
        const ValueKey<String>('credits_ownership_copy'),
      );

      expect(shell, findsOneWidget);
      expect(title, findsOneWidget);
      expect(ownership, findsOneWidget);
      expect(
        find.descendant(
          of: ownership,
          matching: find.textContaining('CVR no. 42666297'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('credits_legal_link_copyright')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('credits_legal_link_third_party')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('credits_legal_link_license')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('credits dialog coin button grants 50000 coins', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final economy = await _pumpCreditsDialog(
      tester,
      size: const Size(390, 844),
    );

    expect(economy.coins, 120);

    final grantButton = find.byKey(
      const ValueKey<String>('credits_add_coins_button'),
    );
    expect(grantButton, findsOneWidget);

    await tester.tap(grantButton);
    await tester.pump();

    expect(economy.coins, 50120);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'credits dialog keeps scroll position through the glitch style swap',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpCreditsDialog(tester, size: const Size(390, 844));

      final controller = _creditsDialogScrollController(tester);
      expect(controller.hasClients, isTrue);

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();

      final before = _normalizedScrollOffset(controller);
      expect(before, greaterThan(0.9));

      await tester.pump(const Duration(milliseconds: 4300));
      await tester.pump();

      final after = _normalizedScrollOffset(controller);
      expect(after, greaterThan(0.78));
      expect(after, closeTo(before, 0.16));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('credits dialog stays stable on wide landscape viewport', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpCreditsDialog(tester, size: const Size(844, 390));

    final shell = find.byKey(const ValueKey<String>('credits_dialog_shell'));
    expect(shell, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('credits_legal_link_copyright')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('credits_legal_link_third_party')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('credits_legal_link_license')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
