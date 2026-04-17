import 'package:chessiq/core/navigation/app_routes.dart';
import 'package:chessiq/core/providers/economy_provider.dart';
import 'package:chessiq/core/services/purchase_service.dart';
import 'package:chessiq/core/theme/app_theme_provider.dart';
import 'package:chessiq/features/academy/providers/puzzle_academy_provider.dart';
import 'package:chessiq/features/analysis/screens/chess_analysis_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChessIQApp extends StatelessWidget {
  const ChessIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeProvider>(
          create: (_) => AppThemeProvider()..load(),
        ),
        ChangeNotifierProvider<EconomyProvider>(
          create: (_) {
            final economy = EconomyProvider()..load();
            PurchaseService.instance.attachEconomy(economy);
            return economy;
          },
        ),
        ChangeNotifierProxyProvider<EconomyProvider, PuzzleAcademyProvider>(
          create: (_) => PuzzleAcademyProvider(),
          update: (_, economy, academy) {
            final resolvedAcademy = academy ?? PuzzleAcademyProvider();
            resolvedAcademy.attachEconomyProvider(economy);
            return resolvedAcademy;
          },
        ),
      ],
      child: Consumer<AppThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.buildTheme(Brightness.light),
            darkTheme: themeProvider.buildTheme(Brightness.dark),
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.analysis,
            routes: {AppRoutes.analysis: (_) => const ChessAnalysisPage()},
          );
        },
      ),
    );
  }
}
