import 'dart:math' as math;

import 'package:flutter/material.dart';

const double moveQualityOptimalLossEpsilon = 0.005;
const double moveQualityNonLosingWinProbability = 0.4;
const double moveQualityWinningWinProbability = 0.6;
const double moveQualityOversightCaptureThreshold = 0.35;
const double moveQualityMasterstrokeEvalCapPawns = 4.0;
const int moveQualityOpeningEquivalentCpGap = 35;
const int moveQualityEqualPositionEquivalentCpGap = 25;
const int moveQualityObviousBestMoveCpGap = 10;
const int moveQualityReasonableAlternativeCpGap = 35;
const int moveQualityRelativeTieCpGap = 15;
const double moveQualityNearEqualEvalBandPawns = 0.9;
const double moveQualityMaterialImbalanceBandPawns = 1.5;

enum MoveQualityConfidence { low, medium, high }

enum MoveQualityScoringSuppressionReason { openingFeedbackOnly, obviousMove }

enum MoveQuality {
  optimal,
  book,
  strong,
  solid,
  slip,
  error,
  criticalFailure,
  crucial,
  masterstroke,
  oversight,
}

class MoveQualityPresentation {
  const MoveQualityPresentation({
    required this.label,
    required this.explanation,
    required this.displaySymbol,
    required this.icon,
    required this.color,
    required this.chargeDelta,
  });

  final String label;
  final String explanation;
  final String displaySymbol;
  final IconData icon;
  final Color color;
  final int chargeDelta;

  String get badgeLabel => '$label ($displaySymbol)';
}

class MoveQualityAssessment {
  const MoveQualityAssessment({
    required this.quality,
    required this.explanation,
    required this.confidence,
    this.moveRank,
    this.cpGapFromBest,
    this.scoringSuppressedReason,
  });

  final MoveQuality quality;
  final String explanation;
  final MoveQualityConfidence confidence;
  final int? moveRank;
  final int? cpGapFromBest;
  final MoveQualityScoringSuppressionReason? scoringSuppressedReason;

  bool get isScoringSuppressed => scoringSuppressedReason != null;
}

class MoveQualityThresholds {
  const MoveQualityThresholds({
    required this.optimal,
    required this.strong,
    required this.solid,
    required this.slip,
    required this.error,
  });

  final double optimal;
  final double strong;
  final double solid;
  final double slip;
  final double error;

  MoveQualityThresholds scale(double factor) {
    return MoveQualityThresholds(
      optimal: optimal * factor,
      strong: strong * factor,
      solid: solid * factor,
      slip: slip * factor,
      error: error * factor,
    );
  }
}

class MoveQualityClassificationContext {
  const MoveQualityClassificationContext({
    required this.deltaWpLoss,
    required this.preMoveMoverWinProbability,
    required this.postMoveMoverWinProbability,
    required this.preMoveMoverEvalPawns,
    this.cpGapFromBest,
    this.cpGapFromNextBetter,
    this.playedMoveRank,
    this.totalLegalMoveCount,
    this.analyzedLegalMoveCount,
    this.insideOpeningExemption = false,
    this.confidence = MoveQualityConfidence.high,
    this.playerStrengthEstimate,
    this.isSacrifice = false,
    this.preservingNonLosingContinuationCount,
    this.preservingWinningContinuationCount,
    this.previousOpponentQuality,
    this.availableReplySwing,
    this.capturedReplySwing,
  });

  final double deltaWpLoss;
  final double preMoveMoverWinProbability;
  final double postMoveMoverWinProbability;
  final double preMoveMoverEvalPawns;
  final int? cpGapFromBest;
  final int? cpGapFromNextBetter;
  final int? playedMoveRank;
  final int? totalLegalMoveCount;
  final int? analyzedLegalMoveCount;
  final bool insideOpeningExemption;
  final MoveQualityConfidence confidence;
  final int? playerStrengthEstimate;
  final bool isSacrifice;
  final int? preservingNonLosingContinuationCount;
  final int? preservingWinningContinuationCount;
  final MoveQuality? previousOpponentQuality;
  final double? availableReplySwing;
  final double? capturedReplySwing;

  bool get isLowConfidence => confidence == MoveQualityConfidence.low;

  bool get hasFullLegalMoveCoverage =>
      totalLegalMoveCount != null &&
      analyzedLegalMoveCount != null &&
      totalLegalMoveCount! > 0 &&
      analyzedLegalMoveCount! >= totalLegalMoveCount!;

  bool get isBottomRankedCoveredMove =>
      hasFullLegalMoveCoverage &&
      playedMoveRank != null &&
      totalLegalMoveCount != null &&
      playedMoveRank! >= totalLegalMoveCount!;

  bool get isEffectivelyTiedToNextBetterMove =>
      cpGapFromNextBetter != null &&
      cpGapFromNextBetter! <= moveQualityRelativeTieCpGap;

  bool get isInferiorBottomRankedCoveredMove =>
      isBottomRankedCoveredMove && !isEffectivelyTiedToNextBetterMove;

  bool get isNearEqualPosition =>
      preMoveMoverEvalPawns.abs() <= moveQualityNearEqualEvalBandPawns &&
      preMoveMoverWinProbability >= 0.42 &&
      preMoveMoverWinProbability <= 0.58;

  bool get isMateriallyUnbalanced =>
      preMoveMoverEvalPawns.abs() >= moveQualityMaterialImbalanceBandPawns ||
      preMoveMoverWinProbability <= 0.32 ||
      preMoveMoverWinProbability >= 0.68;

  bool get isEquivalentMoveRank =>
      playedMoveRank != null &&
      playedMoveRank! <= (insideOpeningExemption ? 3 : 2);

  bool get isEquivalentCpGap =>
      cpGapFromBest != null &&
      cpGapFromBest! <=
          (insideOpeningExemption
              ? moveQualityOpeningEquivalentCpGap
              : moveQualityEqualPositionEquivalentCpGap);

  bool get isReasonableAlternative =>
      (playedMoveRank != null && playedMoveRank! <= 3) ||
      (cpGapFromBest != null &&
          cpGapFromBest! <= moveQualityReasonableAlternativeCpGap);

  bool get isEquivalentBandPosition =>
      !isMateriallyUnbalanced &&
      isNearEqualPosition &&
      (isEquivalentMoveRank || isEquivalentCpGap);

  bool get allowSpecialLabels =>
      !insideOpeningExemption && confidence != MoveQualityConfidence.low;

  bool get isObviousBestMove =>
      !insideOpeningExemption &&
      !isMateriallyUnbalanced &&
      isNearEqualPosition &&
      ((cpGapFromBest != null &&
              cpGapFromBest! <= moveQualityObviousBestMoveCpGap) ||
          (playedMoveRank != null &&
              playedMoveRank == 1 &&
              cpGapFromBest != null &&
              cpGapFromBest! <= moveQualityEqualPositionEquivalentCpGap));

  bool get isMasterstrokeCandidate =>
      allowSpecialLabels &&
      confidence == MoveQualityConfidence.high &&
      deltaWpLoss <= moveQualityOptimalLossEpsilon &&
      isSacrifice &&
      preMoveMoverEvalPawns < moveQualityMasterstrokeEvalCapPawns &&
      postMoveMoverWinProbability - preMoveMoverWinProbability >= 0.08 &&
      (cpGapFromBest == null || cpGapFromBest! <= 20);

  bool get isOnlyWinningPreserver =>
      isWinningWinProbability(postMoveMoverWinProbability) &&
      preservingWinningContinuationCount == 1;

  bool get isOnlyNonLosingPreserver =>
      isNonLosingWinProbability(postMoveMoverWinProbability) &&
      preservingNonLosingContinuationCount == 1;

  bool get isCrucialSwing =>
      preMoveMoverWinProbability < moveQualityNonLosingWinProbability &&
      postMoveMoverWinProbability > moveQualityWinningWinProbability;

  bool get isCrucialCandidate =>
      allowSpecialLabels &&
      (isOnlyWinningPreserver || isOnlyNonLosingPreserver || isCrucialSwing) &&
      (playedMoveRank == null || playedMoveRank! <= 2);

  bool get hadPreviousOpponentBlunder =>
      previousOpponentQuality == MoveQuality.error ||
      previousOpponentQuality == MoveQuality.criticalFailure;

  double? get oversightCaptureRatio {
    final available = availableReplySwing;
    final captured = capturedReplySwing;
    if (available == null || captured == null) {
      return null;
    }
    if (available <= moveQualityOptimalLossEpsilon) {
      return 1.0;
    }
    return (captured / available).clamp(0.0, 1.0).toDouble();
  }

  bool get isOversightCandidate {
    final ratio = oversightCaptureRatio;
    return allowSpecialLabels &&
        hadPreviousOpponentBlunder &&
        ratio != null &&
        ratio < moveQualityOversightCaptureThreshold;
  }
}

const MoveQualityThresholds moveQualityBaseThresholds = MoveQualityThresholds(
  optimal: moveQualityOptimalLossEpsilon,
  strong: 0.02,
  solid: 0.05,
  slip: 0.10,
  error: 0.20,
);

const Map<MoveQuality, MoveQualityPresentation>
_moveQualityPresentations = <MoveQuality, MoveQualityPresentation>{
  MoveQuality.optimal: MoveQualityPresentation(
    label: 'Best',
    explanation: 'You matched the engine\'s best continuation.',
    displaySymbol: '*',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF1F9D72),
    chargeDelta: 15,
  ),
  MoveQuality.book: MoveQualityPresentation(
    label: 'Book',
    explanation:
        'A registered opening move that keeps the game inside known theory.',
    displaySymbol: 'Bk',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF4C8BFF),
    chargeDelta: 0,
  ),
  MoveQuality.strong: MoveQualityPresentation(
    label: 'Strong',
    explanation: 'You stayed extremely close to the engine\'s preferred line.',
    displaySymbol: '!',
    icon: Icons.trending_up_rounded,
    color: Color(0xFF2D88FF),
    chargeDelta: 15,
  ),
  MoveQuality.solid: MoveQualityPresentation(
    label: 'Solid',
    explanation: 'You kept the position healthy with a reliable continuation.',
    displaySymbol: '=',
    icon: Icons.shield_rounded,
    color: Color(0xFF6AA84F),
    chargeDelta: 5,
  ),
  MoveQuality.slip: MoveQualityPresentation(
    label: 'Slip',
    explanation:
        'The move drifted away from the best chances but kept the game alive.',
    displaySymbol: '?!',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFFF2B134),
    chargeDelta: -10,
  ),
  MoveQuality.error: MoveQualityPresentation(
    label: 'Error',
    explanation:
        'The move gave away a significant share of the position\'s winning chances.',
    displaySymbol: '?',
    icon: Icons.error_outline_rounded,
    color: Color(0xFFF28C28),
    chargeDelta: -25,
  ),
  MoveQuality.criticalFailure: MoveQualityPresentation(
    label: 'Critical Failure',
    explanation:
        'The move collapsed the position and cost a decisive amount of win probability.',
    displaySymbol: '??',
    icon: Icons.cancel_rounded,
    color: Color(0xFFE04F5F),
    chargeDelta: -25,
  ),
  MoveQuality.crucial: MoveQualityPresentation(
    label: 'Crucial',
    explanation: 'You found the one move that kept the game within reach.',
    displaySymbol: 'Only',
    icon: Icons.priority_high_rounded,
    color: Color(0xFF00A6A6),
    chargeDelta: 25,
  ),
  MoveQuality.masterstroke: MoveQualityPresentation(
    label: 'Masterstroke',
    explanation:
        'You found a winning sacrifice without giving up the position\'s edge.',
    displaySymbol: '!!',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFFFD166),
    chargeDelta: 50,
  ),
  MoveQuality.oversight: MoveQualityPresentation(
    label: 'Oversight',
    explanation:
        'You let a big chance slip after the opponent already cracked the position.',
    displaySymbol: 'Miss',
    icon: Icons.visibility_off_rounded,
    color: Color(0xFF8A6AAE),
    chargeDelta: 0,
  ),
};

extension MoveQualityX on MoveQuality {
  MoveQualityPresentation get presentation => _moveQualityPresentations[this]!;

  String get label => presentation.label;

  String get explanation => presentation.explanation;

  String get displaySymbol => presentation.displaySymbol;

  IconData get icon => presentation.icon;

  Color get color => presentation.color;

  int get chargeDelta => presentation.chargeDelta;

  bool get isMajorMistake =>
      this == MoveQuality.error || this == MoveQuality.criticalFailure;
}

double centipawnsToWinProbability(num centipawns) {
  final cp = centipawns.toDouble();
  return 0.5 + 0.5 * (2 / (1 + math.exp(-0.0036 * cp)) - 1);
}

double whiteCentipawnsToMoverCentipawns(
  num whiteCentipawns, {
  required bool moverIsWhite,
}) {
  final cp = whiteCentipawns.toDouble();
  return moverIsWhite ? cp : -cp;
}

double whiteCentipawnsToMoverWinProbability(
  num whiteCentipawns, {
  required bool moverIsWhite,
}) {
  return centipawnsToWinProbability(
    whiteCentipawnsToMoverCentipawns(
      whiteCentipawns,
      moverIsWhite: moverIsWhite,
    ),
  );
}

double normalizeWinProbabilityLoss(double loss) {
  if (loss.abs() <= moveQualityOptimalLossEpsilon) {
    return 0.0;
  }
  return loss;
}

double deltaWpLoss({
  required double bestContinuationMoverWinProbability,
  required double playedMoveMoverWinProbability,
}) {
  final rawLoss =
      bestContinuationMoverWinProbability - playedMoveMoverWinProbability;
  return normalizeWinProbabilityLoss(math.max(0.0, rawLoss));
}

MoveQualityThresholds scaledMoveQualityThresholds({
  int? playerStrengthEstimate,
}) {
  if (playerStrengthEstimate != null && playerStrengthEstimate < 1000) {
    return moveQualityBaseThresholds.scale(1.2);
  }
  return moveQualityBaseThresholds;
}

bool isNonLosingWinProbability(double winProbability) {
  return winProbability >= moveQualityNonLosingWinProbability;
}

bool isWinningWinProbability(double winProbability) {
  return winProbability >= moveQualityWinningWinProbability;
}

MoveQuality classifyBaselineMoveQuality(
  double deltaWpLossValue, {
  int? playerStrengthEstimate,
}) {
  final thresholds = scaledMoveQualityThresholds(
    playerStrengthEstimate: playerStrengthEstimate,
  );
  final normalizedLoss = normalizeWinProbabilityLoss(deltaWpLossValue);
  if (normalizedLoss <= thresholds.optimal) {
    return MoveQuality.optimal;
  }
  if (normalizedLoss < thresholds.strong) {
    return MoveQuality.strong;
  }
  if (normalizedLoss < thresholds.solid) {
    return MoveQuality.solid;
  }
  if (normalizedLoss < thresholds.slip) {
    return MoveQuality.slip;
  }
  if (normalizedLoss < thresholds.error) {
    return MoveQuality.error;
  }
  return MoveQuality.criticalFailure;
}

MoveQualityAssessment _assessment(
  MoveQuality quality,
  MoveQualityClassificationContext context, {
  String? explanation,
  MoveQualityScoringSuppressionReason? scoringSuppressedReason,
}) {
  return MoveQualityAssessment(
    quality: quality,
    explanation: explanation ?? quality.explanation,
    confidence: context.confidence,
    moveRank: context.playedMoveRank,
    cpGapFromBest: context.cpGapFromBest,
    scoringSuppressedReason: context.insideOpeningExemption
        ? MoveQualityScoringSuppressionReason.openingFeedbackOnly
        : scoringSuppressedReason,
  );
}

String _equivalenceExplanation(MoveQualityClassificationContext context) {
  if (context.insideOpeningExemption) {
    return 'Book move. This line still follows registered opening theory, so it is shown as opening feedback only and does not change charge.';
  }
  if (context.isObviousBestMove) {
    return 'Obvious equal-position move. It keeps the game on track, but simple top-line moves do not build charge.';
  }
  if (context.playedMoveRank == 1) {
    return 'Near-best move in an equal position.';
  }
  if (context.playedMoveRank != null && context.playedMoveRank! <= 3) {
    return 'Acceptable top-line alternative in an equal position.';
  }
  return 'Acceptable move in an equal position.';
}

String _coveredBottomMoveExplanation(MoveQualityClassificationContext context) {
  final totalMoves = context.totalLegalMoveCount;
  if (totalMoves != null && totalMoves > 1) {
    return 'This was the weakest move among the $totalMoves fully evaluated legal options.';
  }
  return 'This was the weakest move among the fully evaluated legal options.';
}

bool _allowsStrongPromotion(MoveQuality baseline) {
  return baseline != MoveQuality.criticalFailure;
}

bool _allowsSolidPromotion(MoveQuality baseline) {
  return baseline != MoveQuality.error &&
      baseline != MoveQuality.criticalFailure;
}

MoveQualityAssessment? _engineLineAssessment(
  MoveQualityClassificationContext context,
  MoveQuality baseline,
) {
  final playedMoveRank = context.playedMoveRank;
  final cpGapFromBest = context.cpGapFromBest;

  if (playedMoveRank == 1) {
    return _assessment(
      context.insideOpeningExemption ? MoveQuality.book : MoveQuality.optimal,
      context,
      explanation: context.insideOpeningExemption || context.isObviousBestMove
          ? _equivalenceExplanation(context)
          : null,
      scoringSuppressedReason: context.isObviousBestMove
          ? MoveQualityScoringSuppressionReason.obviousMove
          : null,
    );
  }

  if (context.insideOpeningExemption &&
      playedMoveRank != null &&
      playedMoveRank <= 3) {
    return _assessment(
      MoveQuality.book,
      context,
      explanation: _equivalenceExplanation(context),
    );
  }

  if (context.isInferiorBottomRankedCoveredMove) {
    return null;
  }

  if (playedMoveRank == 2 &&
      _allowsStrongPromotion(baseline) &&
      (cpGapFromBest == null ||
          cpGapFromBest <= moveQualityEqualPositionEquivalentCpGap)) {
    return _assessment(MoveQuality.strong, context);
  }

  if (playedMoveRank != null &&
      playedMoveRank <= 3 &&
      _allowsSolidPromotion(baseline) &&
      (cpGapFromBest == null ||
          cpGapFromBest <= moveQualityReasonableAlternativeCpGap)) {
    return _assessment(MoveQuality.solid, context);
  }

  if (cpGapFromBest != null &&
      _allowsStrongPromotion(baseline) &&
      cpGapFromBest <= moveQualityEqualPositionEquivalentCpGap) {
    return _assessment(MoveQuality.strong, context);
  }

  if (cpGapFromBest != null &&
      _allowsSolidPromotion(baseline) &&
      cpGapFromBest <= moveQualityReasonableAlternativeCpGap) {
    return _assessment(MoveQuality.solid, context);
  }

  return null;
}

MoveQualityAssessment classifyMoveQuality(
  MoveQualityClassificationContext context,
) {
  if (context.isMasterstrokeCandidate) {
    return _assessment(MoveQuality.masterstroke, context);
  }
  if (context.isCrucialCandidate) {
    return _assessment(MoveQuality.crucial, context);
  }
  if (context.isOversightCandidate) {
    return _assessment(MoveQuality.oversight, context);
  }

  final baseline = classifyBaselineMoveQuality(
    context.deltaWpLoss,
    playerStrengthEstimate: context.playerStrengthEstimate,
  );

  final engineLineAssessment = _engineLineAssessment(context, baseline);
  if (engineLineAssessment != null) {
    return engineLineAssessment;
  }

  if (context.isInferiorBottomRankedCoveredMove) {
    final downgradedQuality = switch (baseline) {
      MoveQuality.optimal ||
      MoveQuality.strong ||
      MoveQuality.solid => MoveQuality.slip,
      _ => baseline,
    };
    return _assessment(
      context.insideOpeningExemption ? MoveQuality.book : downgradedQuality,
      context,
      explanation: context.insideOpeningExemption
          ? _equivalenceExplanation(context)
          : downgradedQuality == MoveQuality.slip
          ? _coveredBottomMoveExplanation(context)
          : null,
    );
  }

  if (context.isEquivalentBandPosition && _allowsSolidPromotion(baseline)) {
    return _assessment(
      context.insideOpeningExemption ? MoveQuality.book : MoveQuality.solid,
      context,
      explanation: _equivalenceExplanation(context),
      scoringSuppressedReason: context.isObviousBestMove
          ? MoveQualityScoringSuppressionReason.obviousMove
          : null,
    );
  }

  if (context.insideOpeningExemption &&
      !context.isMateriallyUnbalanced &&
      (baseline == MoveQuality.optimal || baseline == MoveQuality.strong)) {
    return _assessment(
      MoveQuality.book,
      context,
      explanation: _equivalenceExplanation(context),
    );
  }

  if (context.isLowConfidence &&
      !context.isMateriallyUnbalanced &&
      _allowsSolidPromotion(baseline)) {
    return _assessment(
      context.insideOpeningExemption ? MoveQuality.book : MoveQuality.solid,
      context,
    );
  }

  if (!context.isMateriallyUnbalanced &&
      context.isReasonableAlternative &&
      !context.isInferiorBottomRankedCoveredMove &&
      baseline == MoveQuality.slip) {
    return _assessment(
      context.insideOpeningExemption ? MoveQuality.book : MoveQuality.solid,
      context,
      explanation: _equivalenceExplanation(context),
    );
  }

  return _assessment(baseline, context);
}

int updatedMoveQualityCharge({
  required int current,
  MoveQuality? quality,
  MoveQualityAssessment? assessment,
  int minimum = 0,
  int maximum = 100,
}) {
  final effectiveAssessment = assessment;
  if (effectiveAssessment != null && effectiveAssessment.isScoringSuppressed) {
    return current;
  }
  final effectiveQuality = effectiveAssessment?.quality ?? quality;
  if (effectiveQuality == null) {
    return current;
  }
  return (current + effectiveQuality.chargeDelta)
      .clamp(minimum, maximum)
      .toInt();
}
