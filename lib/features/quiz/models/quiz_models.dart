import 'package:chessiq/features/analysis/models/analysis_models.dart';

enum GambitQuizMode { guessName, guessLine }

enum QuizDifficulty { easy, medium, hard }

enum QuizTrendFilter { both, guessName, guessLine }

class QuizAccuracyPoint {
  final String dayLabel;
  final double value;

  const QuizAccuracyPoint({required this.dayLabel, required this.value});
}

class QuizBoardSnapshot {
  final Map<String, String> boardState;
  final bool whiteToMove;
  final int shownPly;
  final List<EngineLine> continuation;

  QuizBoardSnapshot({
    required this.boardState,
    required this.whiteToMove,
    required this.shownPly,
    required this.continuation,
  });
}
