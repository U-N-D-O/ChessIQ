part of '../screens/chess_analysis_page.dart';

const String _viewedGambitsKey = 'viewed_gambits_v1';
const String _quizStatsKey = 'quiz_stats_v1';

class _QuizRoundReview {
  final GambitQuizMode mode;
  final String prompt;
  final String promptFocus;
  final List<String> options;
  final int correctIndex;
  final int selectedIndex;
  final String feedback;
  final Map<String, String> boardState;
  final List<EngineLine> continuation;
  final bool whiteToMove;
  final int shownPly;
  final bool skipped;

  const _QuizRoundReview({
    required this.mode,
    required this.prompt,
    required this.promptFocus,
    required this.options,
    required this.correctIndex,
    required this.selectedIndex,
    required this.feedback,
    required this.boardState,
    required this.continuation,
    required this.whiteToMove,
    required this.shownPly,
    required this.skipped,
  });
}
