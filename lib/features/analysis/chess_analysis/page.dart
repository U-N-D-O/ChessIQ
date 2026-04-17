part of '../screens/chess_analysis_page.dart';

class ChessAnalysisPage extends StatefulWidget {
  const ChessAnalysisPage({super.key});

  @override
  State<ChessAnalysisPage> createState() => _ChessAnalysisPageState();
}

abstract class _ChessAnalysisPageStateCore extends _ChessAnalysisPageStateBase
    with _VsBotCore {}

class _ChessAnalysisPageState extends _ChessAnalysisPageStateCore
    with
        _StoreState,
        _VsBotState,
        _AnalysisPageShared,
        _QuizScreen,
        _QuizComponents {}
