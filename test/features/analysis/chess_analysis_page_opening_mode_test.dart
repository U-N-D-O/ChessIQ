import 'dart:convert';

import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/analysis/screens/chess_analysis_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpAnalysisPage(
  WidgetTester tester, {
  required Size size,
  bool sacrificeOwned = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'mute_sounds_v1': true,
    'haptics_enabled_v1': false,
    'store_state_v1': jsonEncode(<String, Object>{
      if (sacrificeOwned) 'sacrificeModeOwned': true,
    }),
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

  final analysisLauncher = find.text('ANALYSIS');
  expect(analysisLauncher, findsWidgets);
  await tester.tap(analysisLauncher.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1600));
}

Finder _openingModeButton() {
  return find.byKey(const ValueKey<String>('analysis_opening_mode_button'));
}

Finder _openingModeFeedbackLabel() {
  return find.byKey(
    const ValueKey<String>('analysis_opening_mode_feedback_label'),
  );
}

String _feedbackText(WidgetTester tester) {
  return tester.widget<Text>(_openingModeFeedbackLabel()).data ?? '';
}

Future<void> _tapOpeningModeButton(WidgetTester tester) async {
  expect(_openingModeButton(), findsOneWidget);
  await tester.ensureVisible(_openingModeButton());
  await tester.tap(_openingModeButton());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _dismissSheet(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('opening mode cycles through sacrifice when unlocked', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpAnalysisPage(
      tester,
      size: const Size(390, 844),
      sacrificeOwned: true,
    );

    await _tapOpeningModeButton(tester);
    expect(_openingModeFeedbackLabel(), findsOneWidget);
    expect(_feedbackText(tester), 'select');

    await _tapOpeningModeButton(tester);
    expect(_feedbackText(tester), 'possible');
    expect(find.text('All Possible Openings'), findsOneWidget);

    await _dismissSheet(tester);

    await _tapOpeningModeButton(tester);
    expect(_feedbackText(tester), 'gambit');

    await _tapOpeningModeButton(tester);
    expect(_feedbackText(tester), 'sacrifice');

    await _tapOpeningModeButton(tester);
    expect(_feedbackText(tester), 'select');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('locked sacrifice mode opens the analysis store', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpAnalysisPage(tester, size: const Size(390, 844));

    await _tapOpeningModeButton(tester);
    expect(_feedbackText(tester), 'select');

    await _tapOpeningModeButton(tester);
    expect(_feedbackText(tester), 'possible');

    await _dismissSheet(tester);

    await _tapOpeningModeButton(tester);
    expect(_feedbackText(tester), 'gambit');

    await _tapOpeningModeButton(tester);
    expect(_feedbackText(tester), 'sacrifice');
    expect(
      find.byKey(
        const ValueKey<String>('analysis_store_sacrifice_mode_card'),
      ),
      findsOneWidget,
    );
    expect(find.text('Sacrifice Mode'), findsWidgets);
    expect(find.text('2850 c'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}