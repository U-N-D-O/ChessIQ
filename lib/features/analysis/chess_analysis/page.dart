part of '../screens/chess_analysis_page.dart';

class _GhostArrow {
  final int id;
  final EngineLine line;
  double opacity;

  _GhostArrow({required this.id, required this.line}) : opacity = 1.0;
}

class ChessAnalysisPage extends StatefulWidget {
  const ChessAnalysisPage({super.key});

  @override
  State<ChessAnalysisPage> createState() => _ChessAnalysisPageState();
}

class _ChessAnalysisPageState extends _ChessAnalysisPageStateBase
    with _AnalysisPageShared, _QuizScreen, _QuizComponents {}
