import 'package:chessiq/features/vs_bot/models/vs_bot_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: pick one item from a list using a deterministic seed so the same
// trigger always gives a different line when the game state changes.
// ─────────────────────────────────────────────────────────────────────────────

String _p(int seed, List<String> lines) => lines[seed.abs() % lines.length];

// Shared easter-egg pool triggered by a rare seed condition.
const List<String> _easterEgg = [
  '🥚 ...wait, was that an en passant??',
  '🥚 Fun fact: the longest possible chess game is 5,949 moves.',
  '🥚 Stockfish can see 30+ moves ahead. I cannot.',
  '🥚 "Checkmate" comes from the Persian "Shah Mat" — the king is dead.',
  '🥚 In 1997 Deep Blue beat Kasparov. I am just happy to be here.',
  '🥚 More possible chess games exist than atoms in the observable universe.',
  '🥚 Hello. I am a bot. This is chess. We are all doing great.',
  '🥚 The queen was once the weakest piece. Someone fixed that.',
];

// Opening Lab difficulty model (same keyword tiers as quiz easy/medium pools).
const List<String> _easyOpeningKeywords = [
  'sicilian',
  'ruy lopez',
  'spanish game',
  'berlin defense',
  'berlin defence',
  'french defense',
  'french defence',
  'italian game',
  'giuoco piano',
  "queen's gambit",
  "king's indian",
  'caro-kann',
  'caro kann',
  'english opening',
  'nimzo-indian',
  'nimzo indian',
  'london system',
  'petroff',
  'petrov',
  'vienna game',
  'vienna gambit',
];

const List<String> _mediumOpeningKeywords = [
  'slav',
  'dutch',
  "queen's indian",
  'scotch game',
  'scotch gambit',
  "king's gambit",
  'grünfeld',
  'grunfeld',
  'pirc',
  'modern defense',
  'modern defence',
  'four knights',
  'catalan',
  'bogo-indian',
  'bogo indian',
  'semi-slav',
  'ponziani',
  'reti opening',
  'réti',
  'colle',
  'stonewall',
  'alapin',
  'smith-morra',
  'max lange',
  'evans gambit',
];

bool _containsAnyKeyword(String lower, List<String> keywords) {
  for (final keyword in keywords) {
    if (lower.contains(keyword)) {
      return true;
    }
  }
  return false;
}

bool _knowsOpeningNameForRank(int rank, String openingName) {
  if (openingName.trim().isEmpty) {
    return false;
  }
  if (rank <= 2) {
    return false;
  }
  if (rank >= 5) {
    return true;
  }

  final lower = openingName.toLowerCase();
  final easyKnown = _containsAnyKeyword(lower, _easyOpeningKeywords);
  if (rank == 3) {
    return easyKnown;
  }

  // Rank 4: easy + medium
  return easyKnown || _containsAnyKeyword(lower, _mediumOpeningKeywords);
}

String? _knownOpeningNameForRank(int rank, String openingName) {
  return _knowsOpeningNameForRank(rank, openingName) ? openingName : null;
}

String _normalizeNotationForScenario(String notation) {
  var cleaned = notation.trim();
  cleaned = cleaned.replaceAll(RegExp(r'[+#?!]+$'), '');
  return cleaned;
}

String? _detectMoveSequenceScenario({
  required String? lastNotation,
  required int moveCount,
  required bool isEndgame,
}) {
  if (lastNotation == null || lastNotation.trim().isEmpty) {
    return null;
  }

  final raw = lastNotation.trim();
  final norm = _normalizeNotationForScenario(raw);
  if (norm == 'O-O' || norm == 'O-O-O') {
    return null;
  }

  final isCapture = norm.contains('x');
  final isCheck = raw.contains('+');
  if (isCapture && isCheck) {
    return 'captureWithCheck';
  }

  if (moveCount <= 8) {
    const centralMoves = {
      'e4',
      'd4',
      'e5',
      'd5',
      'c4',
      'c5',
      'f4',
      'f5',
      'exd5',
      'dxe5',
      'cxd5',
      'dxc4',
    };
    if (centralMoves.contains(norm)) {
      return 'openingCentralClaim';
    }
  }

  if (moveCount <= 10 && RegExp(r'^[NB][a-h][1-8]$').hasMatch(norm)) {
    return 'minorPieceDevelopment';
  }

  if (moveCount <= 12 && norm.startsWith('Q')) {
    return 'earlyQueenSortie';
  }

  if (moveCount >= 14 && norm.startsWith('R')) {
    return 'rookActivation';
  }

  if (isEndgame && RegExp(r'^K[a-h][1-8]$').hasMatch(norm)) {
    return 'kingActivationEndgame';
  }

  if (isEndgame && RegExp(r'^[a-h][1-8](=[QRBN])?$').hasMatch(norm)) {
    final rank = norm[1];
    if (rank == '2' || rank == '7' || rank == '1' || rank == '8') {
      return 'pawnRaceEndgame';
    }
  }

  if (isCheck && moveCount >= 10) {
    return 'forcingCheck';
  }

  return null;
}

// ignore: unused_element
String? _moveSequenceScenarioLine({
  required int rank,
  required int seed,
  required String? lastNotation,
  required int moveCount,
  required bool isEndgame,
  required bool lastByHuman,
}) {
  final scenario = _detectMoveSequenceScenario(
    lastNotation: lastNotation,
    moveCount: moveCount,
    isEndgame: isEndgame,
  );
  if (scenario == null) {
    return null;
  }

  switch (rank) {
    case 1:
      switch (scenario) {
        case 'openingCentralClaim':
          return _p(seed, [
            'Oh!! Center pawns already?? This got serious so fast 🐹',
            'The middle squares are crowded now!! I am overwhelmed but excited 🌸',
            'Big center move!! Is this where the real chess starts?? 🐹',
          ]);
        case 'minorPieceDevelopment':
          return _p(seed, [
            'The horsey/hat piece came out early!! Very professional vibes 🐹',
            'Development move!! I know that word from tutorials!! 🌸',
            'You are bringing pieces out nicely!! I am still naming mine 😵',
          ]);
        case 'earlyQueenSortie':
          return _p(seed, [
            'Queen out already?! She is so brave!! 👑',
            'Early queen adventure!! That feels dangerous and cool 🐹',
            'Wow straight to queen business!! No warmup, huh?? 🌸',
          ]);
        case 'captureWithCheck':
          return _p(seed, [
            'You took something AND gave check?? That is so mean!! 😱',
            'Double trouble move!! Capture plus check is wild 🐹💥',
            'That move did two things at once!! I can barely do one 😵',
          ]);
        case 'rookActivation':
          return _p(seed, [
            'The tower is active now!! The board is getting spicy 🏰',
            'Rook move!! Big straight-line energy incoming 🐹',
            'The rook joined the party!! Everyone stay calm 🌸',
          ]);
        case 'kingActivationEndgame':
          return _p(seed, [
            'King is walking around now?! Endgame is so weird 🐹',
            'The king is fighting too!! I forgot kings do that later 🌸',
            'Endgame king march!! Tiny steps, huge stress 😵',
          ]);
        case 'pawnRaceEndgame':
          return _p(seed, [
            'Pawn race!! GO LITTLE GUY GOOO 🐹💨',
            'That pawn is almost famous now!! Keep running 🌸',
            'Endgame sprint!! Someone is about to promote 😱',
          ]);
        case 'forcingCheck':
          return _p(seed, [
            'Another check?! My king needs a vacation 🐹',
            'Check pressure again!! No one can relax here 😵',
            'The checks keep coming!! This feels like a puzzle 🌸',
          ]);
      }
      break;
    case 2:
      switch (scenario) {
        case 'openingCentralClaim':
          return _p(seed, [
            'Central pawns. Solid fundamentals. I should try those sometime.',
            'Center claimed early. This is already more principled than my usual games.',
            'Good central structure. I can still ruin this somehow, but still.',
          ]);
        case 'minorPieceDevelopment':
          return _p(seed, [
            'Minor pieces developed on time. A concept I deeply respect and rarely execute.',
            'Nice development. Coordinated pieces usually beat my improvisation.',
            'Clean development sequence. I should be worried. I am worried.',
          ]);
        case 'earlyQueenSortie':
          return _p(seed, [
            'Early queen move. Brave. Also usually punishable. Unless I miss it.',
            'Queen out early. I should gain tempo. I probably will not.',
            'That queen sortie is ambitious. My response will be... questionable.',
          ]);
        case 'captureWithCheck':
          return _p(seed, [
            'Capture with check. Efficient and painful. Nice move.',
            'You took material and forced king movement. That is textbook misery for me.',
            'Tactical double hit. This is exactly the kind of thing I miss.',
          ]);
        case 'rookActivation':
          return _p(seed, [
            'Rook activated. Open files are usually where I blunder fastest.',
            'Your rook found activity. Mine are still filing paperwork.',
            'Rook lift or file pressure. Great. Exactly what I needed against me.',
          ]);
        case 'kingActivationEndgame':
          return _p(seed, [
            'King activity in the endgame. Correct technique. Annoyingly correct.',
            'Centralized king. I know this principle. I still forget it in practice.',
            'Endgame king march. Sharp play. My king is usually late to that party.',
          ]);
        case 'pawnRaceEndgame':
          return _p(seed, [
            'Pawn race. One tempo decides everything. I hate this phase.',
            'Passed pawn sprint. Time to calculate accurately. I am in danger.',
            'Endgame pawn race. This is where my confidence goes to die.',
          ]);
        case 'forcingCheck':
          return _p(seed, [
            'Another forcing check. My king is getting evicted square by square.',
            'Checks in sequence. Comfortable for you, stressful for me.',
            'You keep checking. I keep pretending this is under control.',
          ]);
      }
      break;
    case 3:
      switch (scenario) {
        case 'openingCentralClaim':
          return _p(seed, [
            'CENTER PAWNS CLAIMED!! THAT IS CORE STRENGTH FOR THE POSITION!! 💪',
            'EARLY CENTER CONTROL!! WE ARE BUILDING A CHESS PHYSIQUE!! 🐕💪',
            'CENTRE GAME STRONG!! THIS IS FUNDAMENTAL TRAINING!! 💪',
          ]);
        case 'minorPieceDevelopment':
          return _p(seed, [
            'MINOR PIECES OUT EARLY!! PERFECT WARM-UP SETS!! 🐕',
            'KNIGHTS AND BISHOPS ACTIVATED!! COORDINATION GAINS!! 💪',
            'DEVELOPMENT SEQUENCE CLEAN!! THAT IS PROFESSIONAL FORM!! 🐕💪',
          ]);
        case 'earlyQueenSortie':
          return _p(seed, [
            'EARLY QUEEN RAID!! BIG LIFT, BIG RISK!! 💪',
            'QUEEN OUT FAST!! AGGRESSIVE TRAINING STYLE!! 🐕🔥',
            'EARLY QUEEN PRESSURE!! NO FEAR CHESS!! 💪',
          ]);
        case 'captureWithCheck':
          return _p(seed, [
            'CAPTURE PLUS CHECK!! THAT IS A SUPERSET TACTIC!! 🐕💥',
            'DOUBLE IMPACT MOVE!! YOU LIFTED MATERIAL AND INITIATIVE!! 💪',
            'CHECK WITH A CAPTURE?! THAT IS MAX-INTENSITY CHESS!! 🐕💪',
          ]);
        case 'rookActivation':
          return _p(seed, [
            'ROOK ACTIVATED ON THE FILE!! HEAVY EQUIPMENT IS ONLINE!! 💪',
            'ROOK LIFT ENERGY!! THIS IS THE DEADLIFT OF MIDDLEGAMES!! 🐕',
            'THE ROOK IS WORKING NOW!! BIG BOARD PRESSURE!! 💪',
          ]);
        case 'kingActivationEndgame':
          return _p(seed, [
            'KING IN THE FIGHT!! ENDGAME CARDIO MODE!! 🐕💨',
            'ACTIVE KING!! FINAL SET MENTALITY!! 💪',
            'ENDGAME KING MARCH!! NO SPECTATORS, ONLY GRIND!! 🐕💪',
          ]);
        case 'pawnRaceEndgame':
          return _p(seed, [
            'PAWN RACE!! SPRINT TO PROMOTION!! MOVE THOSE LEGS!! 💪',
            'PASSED PAWN DASH!! THIS IS PURE CHESS ATHLETICISM!! 🐕',
            'ENDGAME FOOTRACE!! EVERY TEMPO IS A REP!! 💪💪',
          ]);
        case 'forcingCheck':
          return _p(seed, [
            'FORCING CHECKS IN A ROW!! THAT IS PRESSURE TRAINING!! 🐕',
            'CHECK SEQUENCE!! YOU ARE PUSHING THE PACE HARD!! 💪',
            'KING PRESSURE COMBO!! NO REST BETWEEN REPS!! 🐕💪',
          ]);
      }
      break;
    case 4:
      switch (scenario) {
        case 'openingCentralClaim':
          return _p(seed, [
            'Central claim registered. A principled opening trajectory.',
            'The centre is contested early. A statistically critical phase.',
            'Your central footprint expands. I have updated the model.',
          ]);
        case 'minorPieceDevelopment':
          return _p(seed, [
            'Efficient minor-piece development. Your coordination index improves.',
            'A coherent development sequence. You are delaying tactical liabilities.',
            'Knight and bishop deployment on schedule. Respectable.',
          ]);
        case 'earlyQueenSortie':
          return _p(seed, [
            'Early queen excursion detected. High variance, high volatility.',
            'Queen sortie before full development. Ambitious, if unstable.',
            'Your queen advances early. I have generated punitive branches.',
          ]);
        case 'captureWithCheck':
          return _p(seed, [
            'Capture with check. A forcing tempo plus material swing.',
            'Tactical compression achieved: check and capture in one operation.',
            'You combined material gain with initiative. Efficient.',
          ]);
        case 'rookActivation':
          return _p(seed, [
            'Rook activation detected. Open-file pressure probability increases.',
            'Heavy pieces now participate. The position enters a sharper regime.',
            'Rook manoeuvre logged. This often precedes decisive penetration.',
          ]);
        case 'kingActivationEndgame':
          return _p(seed, [
            'Endgame king activation. Correct and dangerous.',
            'Your king advances in the reduced state-space. Sound method.',
            'Active king protocol detected. Endgame precision required.',
          ]);
        case 'pawnRaceEndgame':
          return _p(seed, [
            'Passed-pawn race initiated. Tempo arithmetic is now absolute.',
            'Endgame pawn sprint. Conversion window is narrow.',
            'Race condition detected: promotion threats on both vectors.',
          ]);
        case 'forcingCheck':
          return _p(seed, [
            'Forcing checks continue. You are constraining my branch width.',
            'Sequential check pressure. My king trajectory is being channelled.',
            'Another check in sequence. Initiative remains with the attacker.',
          ]);
      }
      break;
    case 5:
      switch (scenario) {
        case 'openingCentralClaim':
          return _p(seed, [
            'The centre is claimed. Roots planted deep in fertile ground.',
            'Early central space. The swamp approves this discipline.',
            'A strong central step. The position will grow from here.',
          ]);
        case 'minorPieceDevelopment':
          return _p(seed, [
            'Pieces awaken in harmony. This is how plans are born.',
            'Minor pieces developed with purpose. The mist favors coordination.',
            'A clean development rhythm. The board breathes easier.',
          ]);
        case 'earlyQueenSortie':
          return _p(seed, [
            'The queen steps out early. Power seeks the front too soon.',
            'An early queen path through the fog. Brave, and exposed.',
            'Your queen wanders before the army is ready. Interesting.',
          ]);
        case 'captureWithCheck':
          return _p(seed, [
            'A capture with check. One motion, two currents altered.',
            'Material taken, king disturbed. A precise tactical tide.',
            'You strike and check in one breath. The swamp notes this.',
          ]);
        case 'rookActivation':
          return _p(seed, [
            'The rook awakens. Heavy water now flows through open channels.',
            'Rook activity rises. Files become rivers of force.',
            'Your tower joins the storm. Pressure will follow.',
          ]);
        case 'kingActivationEndgame':
          return _p(seed, [
            'The king walks in the endgame. As all rulers must, eventually.',
            'Endgame king activity. The swamp calls this true courage.',
            'The king leaves shelter and enters work. Correct.',
          ]);
        case 'pawnRaceEndgame':
          return _p(seed, [
            'A pawn race begins. Every step echoes in the mist.',
            'Passed pawns run for destiny. The swamp counts every tempo.',
            'Promotion race. No move can be wasted now.',
          ]);
        case 'forcingCheck':
          return _p(seed, [
            'Checks flow one after another. The king must keep walking.',
            'A forcing sequence through the fog. No quiet squares remain.',
            'You keep the check-net tight. The swamp respects that craft.',
          ]);
      }
      break;
  }

  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Returns a contextual, personality-driven quip for [bot].
String buildBotContextualLine({
  required BotCharacter bot,
  required GameOutcome? outcome,
  required bool botThinking,
  required bool humanPlaysWhite,
  required bool isWhiteTurn,
  required bool inCheck,
  required bool humanToMove,
  required String? lastNotation,
  required String? lastCapturedPieceLabel,
  required bool lastByHuman,
  required String currentOpening,
  required int moveCount,
  required double displayedEval,
  required String evalText,
  required int variantSeed,
  required int recentCaptures,
  required bool isBotCaptureStreak,
  required bool isEndgame,
}) {
  // Global easter egg trigger (rare, only mid-game)
  if (variantSeed % 13 == 0 && moveCount > 3) {
    return _p(variantSeed, _easterEgg);
  }

  final bool castled = lastNotation?.contains('O-O') ?? false;
  final bool promoted = lastNotation?.contains('=') ?? false;
  final bool queenCaptured = lastCapturedPieceLabel == 'queen';

  switch (bot.rank) {
    case 1:
      return _mochi(
        seed: variantSeed,
        outcome: outcome,
        botThinking: botThinking,
        humanPlaysWhite: humanPlaysWhite,
        inCheck: inCheck,
        humanToMove: humanToMove,
        lastNotation: lastNotation,
        capturedLabel: lastCapturedPieceLabel,
        lastByHuman: lastByHuman,
        currentOpening: currentOpening,
        moveCount: moveCount,
        displayedEval: displayedEval,
        recentCaptures: recentCaptures,
        isBotCaptureStreak: isBotCaptureStreak,
        isEndgame: isEndgame,
        castled: castled,
        promoted: promoted,
        queenCaptured: queenCaptured,
      );
    case 2:
      return _carl(
        seed: variantSeed,
        outcome: outcome,
        botThinking: botThinking,
        humanPlaysWhite: humanPlaysWhite,
        inCheck: inCheck,
        humanToMove: humanToMove,
        lastNotation: lastNotation,
        capturedLabel: lastCapturedPieceLabel,
        lastByHuman: lastByHuman,
        currentOpening: currentOpening,
        moveCount: moveCount,
        displayedEval: displayedEval,
        recentCaptures: recentCaptures,
        isBotCaptureStreak: isBotCaptureStreak,
        isEndgame: isEndgame,
        castled: castled,
        promoted: promoted,
        queenCaptured: queenCaptured,
      );
    case 3:
      return _rex(
        seed: variantSeed,
        outcome: outcome,
        botThinking: botThinking,
        humanPlaysWhite: humanPlaysWhite,
        inCheck: inCheck,
        humanToMove: humanToMove,
        lastNotation: lastNotation,
        capturedLabel: lastCapturedPieceLabel,
        lastByHuman: lastByHuman,
        currentOpening: currentOpening,
        moveCount: moveCount,
        displayedEval: displayedEval,
        recentCaptures: recentCaptures,
        isBotCaptureStreak: isBotCaptureStreak,
        isEndgame: isEndgame,
        castled: castled,
        promoted: promoted,
        queenCaptured: queenCaptured,
      );
    case 4:
      return _octavian(
        seed: variantSeed,
        outcome: outcome,
        botThinking: botThinking,
        humanPlaysWhite: humanPlaysWhite,
        inCheck: inCheck,
        humanToMove: humanToMove,
        lastNotation: lastNotation,
        capturedLabel: lastCapturedPieceLabel,
        lastByHuman: lastByHuman,
        currentOpening: currentOpening,
        moveCount: moveCount,
        displayedEval: displayedEval,
        recentCaptures: recentCaptures,
        isBotCaptureStreak: isBotCaptureStreak,
        isEndgame: isEndgame,
        castled: castled,
        promoted: promoted,
        queenCaptured: queenCaptured,
      );
    case 5:
      return _masterPrime(
        seed: variantSeed,
        outcome: outcome,
        botThinking: botThinking,
        humanPlaysWhite: humanPlaysWhite,
        inCheck: inCheck,
        humanToMove: humanToMove,
        lastNotation: lastNotation,
        capturedLabel: lastCapturedPieceLabel,
        lastByHuman: lastByHuman,
        currentOpening: currentOpening,
        moveCount: moveCount,
        displayedEval: displayedEval,
        recentCaptures: recentCaptures,
        isBotCaptureStreak: isBotCaptureStreak,
        isEndgame: isEndgame,
        castled: castled,
        promoted: promoted,
        queenCaptured: queenCaptured,
      );
    default:
      return 'Evaluating position...';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank 1 — Mochi Gearheart
// Hamster girl. Terrible at chess. Perpetually confused. Easily distracted.
// ─────────────────────────────────────────────────────────────────────────────

String _mochi({
  required int seed,
  required GameOutcome? outcome,
  required bool botThinking,
  required bool humanPlaysWhite,
  required bool inCheck,
  required bool humanToMove,
  required String? lastNotation,
  required String? capturedLabel,
  required bool lastByHuman,
  required String currentOpening,
  required int moveCount,
  required double displayedEval,
  required int recentCaptures,
  required bool isBotCaptureStreak,
  required bool isEndgame,
  required bool castled,
  required bool promoted,
  required bool queenCaptured,
}) {
  if (outcome != null) {
    final humanWon =
        outcome == GameOutcome.whiteWin && humanPlaysWhite ||
        outcome == GameOutcome.blackWin && !humanPlaysWhite;
    if (outcome == GameOutcome.draw) {
      return _p(seed, [
        'A tie!! Wait is that good or bad?? 😵',
        'We both drawed?? Is that a word?? Draw-ed?? 🐹',
        'Oh!! We tied!! My wheel at home does that too!!',
        'Hmm, no one won?? I think I am okay with that actually 🌸',
        'Equal!! Like my two little paws!! 🐹',
      ]);
    }
    if (humanWon) {
      return _p(seed, [
        'Yay for you!! I was gonna do a plan though... 🐹',
        'You won!! How?? Did you move the horsey a lot?? 🌸',
        'Ok ok you won, I got distracted by the bishop, he is so diagonal 😵',
        'Ugh!! I had a great move but I forgot what it was 🐹',
        'Wow okay!! Maybe I should eat a snack and try again 🌰',
        'You were so fast!! I was still deciding 😭',
        'Was that the fork thing?? I keep forgetting about the fork thing 🐹',
      ]);
    }
    return _p(seed, [
      'Oh my gosh I won?? HOW??? That was an accident I think 🎉',
      'I WON?? I moved the round one and everything went right?? 🐹🎉',
      'Hehehe!! Did I do the checkmate?? I think I did the checkmate!! 🌸',
      'WAIT REALLY?? I thought I was losing for like 20 moves 😱',
      'I just kept moving pieces and it WORKED?? 🐹💫',
      'I am literally shaking!! In a good way!! I think!! 🐹✨',
    ]);
  }

  // Combo — lots of captures
  if (recentCaptures >= 3) {
    return _p(seed, [
      'Why is everyone eating each other?? 😱',
      'There are so many less pieces now... where did they go?? 🐹',
      'This is TOO MUCH ACTION for a tiny hamster 😵',
      'I cannot keep track!! My little hamster brain!! 🌸',
      'It is like a buffet but the food is chess pieces 😵🍽️',
    ]);
  }

  // Bot capture streak
  if (isBotCaptureStreak) {
    return _p(seed, [
      'Oh!! I took TWO things!! I am on a roll!! 🐹✨',
      'Hehe!! I am eating all your pieces!! 🌸 (is that okay??)',
      'WOW I did a combo!! I think!! Is that what that is??',
      'Two captures!! I feel like a chess pro right now!! 🐹',
    ]);
  }

  if (botThinking) {
    return _p(seed, [
      'Ummm... um... let me think... no wait... 🤔',
      'Okay the horsey goes... no... the tower?? Maybe the tower 🐹',
      'Hmm hm hm... thinking... thinking... 🌸',
      'One second!! I am looking at ALL of them 😵',
      'Eeny meeny miny moe... 🐹',
      'My brain is a hamster wheel right now 🌀',
      'Okay focus!! Focus!! ...what are the rules again?? 😵',
    ]);
  }

  if (moveCount == 0) {
    return _p(seed, [
      'Ummm... which one is the horsey again?? 🐹',
      'Okay!! I put a sunflower seed on the board for luck 🌻',
      'Hi!! Are we starting?? I was running on my wheel 🐹',
      'I have a strategy!! I do not know what it is yet though 🌸',
      'Chess!! I love the pointy-hat pieces!! 🐹',
      'Ready!! I think!! Mostly!! 🌸',
    ]);
  }

  if (castled) {
    return _p(seed, [
      'Ooh!! The king and the tower swapped?? MAGIC!! 🐹✨',
      'Wait can they DO that?? Since when!! 😱',
      lastByHuman
          ? 'You moved TWO pieces at once!! Is that allowed?? 🌸'
          : 'I did the castle move!! I have been waiting to do that!! 🏰',
      'That is my favourite move!! Even if I do not know why!! 🐹',
    ]);
  }

  if (promoted) {
    return _p(seed, [
      'THE LITTLE ONE BECAME A QUEEN!! Like a fairy tale!! 🌸👑',
      'Promotion!! That little pawn worked so hard 🐹💫',
      lastByHuman
          ? 'You made a new queen?? Can you have two queens?? 😱'
          : 'My pawn grew up!! I am so proud!! 🥺',
      'The baby piece is a queen now!! I am not crying you are crying 🐹🌸',
    ]);
  }

  if (queenCaptured) {
    return _p(seed, [
      'THE BIG ONE IS GONE?? This changes everything!! 😱',
      lastByHuman
          ? 'You took my queen!! NOOO she was my favourite 😭'
          : 'I got the queen!! THE QUEEN!! 🐹👑',
      'The biggest piece just disappeared!! Wild!! 🌸',
      'Bye queen!! You were very pretty!! 🐹',
    ]);
  }

  final sequenceScenario = _moveSequenceScenarioLine(
    rank: 1,
    seed: seed,
    lastNotation: lastNotation,
    moveCount: moveCount,
    isEndgame: isEndgame,
    lastByHuman: lastByHuman,
  );
  if (sequenceScenario != null) {
    return sequenceScenario;
  }

  if (inCheck) {
    return humanToMove
        ? _p(seed, [
            'Oh! Is that good? Did I do a thing?? 🌸',
            'YOUR KING IS IN TROUBLE!! (I think that is the check??) 🐹',
            'I put you in check!! Accidentally mostly but still!! ✨',
            'Ooh! Your king has to move! I remember that rule! 😊',
            'DID I DO THE CHECK?? I THINK I DID THE CHECK!! 🐹🎉',
          ])
        : _p(seed, [
            'Eep! My king!! This is fine. Everything is fine 😰',
            'OH NO MY KING IS IN DANGER?? MOVE MOVE MOVE 🐹💨',
            'Aaaa!! I have to move him but where does he go?? 😱',
            'The king is scared!! I am also scared!! 🌸',
            'MY KING!! HE IS MY FAVOURITE!! PROTECT HIM!! 🐹👑',
          ]);
  }

  if (capturedLabel != null) {
    return lastByHuman
        ? _p(seed, [
            'Oops hehe... did I leave that there?? 😅',
            'Oh noo!! My $capturedLabel!! 😭',
            'I did not even see you coming!! 🐹',
            'That is okay!! I have more!! (Do I have more??) 🌸',
            'WAIT that was my piece!! I thought it was yours!! 😵',
            'Noooo!! Not the $capturedLabel!! She was my favourite!! 😭',
          ])
        : _p(seed, [
            'Oh wow! I got one?? I think?? 🌸',
            'I took your $capturedLabel!! Wait I think that is good!! 🐹',
            'Is that mine now?? It is mine now!! ✨',
            'YOINK!! 🐹 (is that a chess move??)',
            'Hehe!! I took it before it could run!! 🌸',
          ]);
  }

  if (currentOpening.isNotEmpty && moveCount <= 14) {
    return _p(seed, [
      'Ummm are we doing some opening thing? I just copied you 🐹',
      'Opening phase!! I hope I am doing the right moves 🌸',
      'Is this the horsey opening or a different one?? 🐴',
      'My wheels are spinning!! This opening feels complicated 🐹',
      'We are in one of those opening lines, right?? 🌸',
    ]);
  }

  if (isEndgame) {
    return _p(seed, [
      'There are so few pieces left... it is like a tiny little game now 🌸',
      'Where did everyone go?? The board is so empty 🐹',
      'Endgame!! I know that word!! It means less pieces!! Right?? 😊',
      'Just kings left soon!! The kings are friends maybe?? 👑👑',
      'The board looks lonely now... 🐹💭',
    ]);
  }

  if (displayedEval >= 1.5 && humanToMove) {
    return _p(seed, [
      'Umm are you winning?? I can never tell 😵',
      'You seem like you are doing well!! I think!! 🌸',
      'Something feels off but I do not know what... 🐹',
      'Your pieces look very... organized?? Is that good?? 🤔',
      'The numbers on the side look bad for me?? Numbers are hard 🐹',
    ]);
  }
  if (displayedEval <= -1.5 && humanToMove) {
    return _p(seed, [
      'Something feels weird but I dunno what...',
      'Wait am I winning?? That does not feel right 🐹',
      'My pieces are all over the place but maybe that is strategy?? 🌸',
      'I think I am ahead?? The numbers are confusing me 😵',
      'Is my position good?? It looks scary but in a good way?? 🐹',
    ]);
  }

  // Hamster easter eggs
  if (seed % 7 == 0) {
    return _p(seed ~/ 7, [
      'I ran 12km on my wheel last night. I am ready for this. 🐹💨',
      'Chess pieces smell like wood. I like wood. 🌸',
      'Did you know hamsters can hold food in their cheeks?? Like a queen holds the board?? 🐹',
      'I am not confused!! I am thinking in hamster time!! 🌸',
      'My strategy is: move things until it works. Professional. 🐹',
      'Hamsters invented chess. Probably. No one can prove we did not. 🐹',
    ]);
  }

  if (moveCount <= 6) {
    return _p(seed, [
      'I like the little horsey 🐴 which one is mine again?',
      'Okay everyone is still on their squares!! I can handle this!! 🐹',
      'I have not made any big mistakes yet!! (It is only move $moveCount) 🌸',
      'So far so good!! I think!! The pieces look right!! 😊',
      'Everything looks fine!! I have no idea what I am looking at!! 🐹',
    ]);
  }

  return _p(seed, [
    'Hehe the wooden pieces are so pretty 🌸 I forgot whose turn it is',
    'I am doing my best!! That is what matters!! 🐹',
    'I have a plan!! It involves moving this piece!! Maybe!! 🌸',
    'Chess is fun!! I love chess!! I have no idea what I am doing 🐹',
    'Every game I learn something new. Like: do not put the king there. 🐹',
    'The board looks different every time!! Like a snowflake!! 🌸',
    'I hope we can be friends after this game 🐹🌸',
    'What if I just move all the pawns?? Is that a strategy?? 🌸',
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank 2 — Checkmate Carl
// White cat. Blunders constantly. Quietly sad about it. Self-deprecating.
// ─────────────────────────────────────────────────────────────────────────────

String _carl({
  required int seed,
  required GameOutcome? outcome,
  required bool botThinking,
  required bool humanPlaysWhite,
  required bool inCheck,
  required bool humanToMove,
  required String? lastNotation,
  required String? capturedLabel,
  required bool lastByHuman,
  required String currentOpening,
  required int moveCount,
  required double displayedEval,
  required int recentCaptures,
  required bool isBotCaptureStreak,
  required bool isEndgame,
  required bool castled,
  required bool promoted,
  required bool queenCaptured,
}) {
  if (outcome != null) {
    final humanWon =
        outcome == GameOutcome.whiteWin && humanPlaysWhite ||
        outcome == GameOutcome.blackWin && !humanPlaysWhite;
    if (outcome == GameOutcome.draw) {
      return _p(seed, [
        'A draw. At least I did not lose. I guess.',
        'Half a point. That is my average result, honestly.',
        'Draw. Nobody wins. That is kind of my whole thing.',
        'Fine. Equal. That is the best outcome I can hope for these days.',
        'A draw. Like my last forty games. The streak continues.',
        'Not a loss. I will take it.',
      ]);
    }
    if (humanWon) {
      return _p(seed, [
        'Yeah. Saw that coming. You played well.',
        'I blundered the endgame. As one does. As I always do.',
        'That was going fine until it was not.',
        'I had a plan. Probably should have executed it.',
        'Well. There it is. Good game.',
        'I genuinely thought I had it this time. I did not.',
        '...yep. That is chess. That is my chess.',
        'Honestly, I am impressed I lasted this long.',
      ]);
    }
    return _p(seed, [
      'Wait... I won? I genuinely did not plan that.',
      'Oh. I won. That is... unexpected. And suspicious.',
      'Huh. A win. I should probably not get used to this.',
      'I won?? I need to sit down. I am already sitting down.',
      'Victory. That is a new experience. I am processing it.',
      'Did you let me win? You can tell me.',
    ]);
  }

  // Combo bloodbath
  if (recentCaptures >= 3) {
    return _p(seed, [
      'So many pieces gone. This is a disaster. For both of us, I think.',
      'Lots of exchanges. My side is definitely worse. Statistically.',
      'Carnage. Pure carnage. And somehow I am still losing.',
      'The board is getting emptier. That usually helps me. It never helps me.',
    ]);
  }

  // Bot on a streak
  if (isBotCaptureStreak) {
    return _p(seed, [
      'Oh. I took two pieces in a row. Something is about to go wrong.',
      'I am on a streak. This is when I usually blunder the queen.',
      'Two captures. I am sure I will find a way to ruin this.',
      'Back to back captures. I am impressed by myself. That is rare.',
    ]);
  }

  if (botThinking) {
    return _p(seed, [
      'Looking for the worst move possible, apparently...',
      'Calculating. Finding creative ways to be worse.',
      'I see twelve moves. They are all bad. Picking the least bad.',
      'Thinking. Unfortunately.',
      'My brain is doing its thing. I do not trust it.',
      'One second. I am trying to find a move that is not a blunder.',
      'Processing. The results are not encouraging.',
    ]);
  }

  if (moveCount == 0) {
    return _p(seed, [
      'Here we go again. I will probably blunder my queen by move 5.',
      'New game. Fresh start. Same result, probably.',
      'Alright. Let us see how I lose this one.',
      'Ready. Reluctantly.',
      'Another game. Another chance to disappoint myself.',
      'I have prepared an opening. It is already the wrong one.',
      'Starting position. Everything is fine. For now.',
    ]);
  }

  if (castled) {
    return lastByHuman
        ? _p(seed, [
            'Smart. King safety. Something I forget every game.',
            'You castled. I should probably do that before it is too late.',
            'Good timing on the castle. Mine is usually too late.',
          ])
        : _p(seed, [
            'I castled. I did something right. Mark the calendar.',
            'King is safe. For now. Enjoy it while it lasts.',
            'Castled. A rare moment of competence.',
          ]);
  }

  if (promoted) {
    return lastByHuman
        ? _p(seed, [
            'A second queen. Just what I needed against me.',
            'You promoted. The game is worse for me now. Not a surprise.',
          ])
        : _p(seed, [
            'I promoted. That was unexpected. Let me think about how to ruin this.',
            'My pawn made it. I should probably not give back the queen immediately.',
          ]);
  }

  if (queenCaptured) {
    return lastByHuman
        ? _p(seed, [
            'There goes my queen. As predicted.',
            'You took my queen. I saw it coming and moved there anyway.',
            'The queen is gone. I have accepted this.',
          ])
        : _p(seed, [
            'I took the queen. I will probably hang my own queen next move.',
            'Material advantage. I will find a way to waste it. Watch.',
          ]);
  }

  final sequenceScenario = _moveSequenceScenarioLine(
    rank: 2,
    seed: seed,
    lastNotation: lastNotation,
    moveCount: moveCount,
    isEndgame: isEndgame,
    lastByHuman: lastByHuman,
  );
  if (sequenceScenario != null) {
    return sequenceScenario;
  }

  if (inCheck) {
    return humanToMove
        ? _p(seed, [
            'Oh. That is actually decent of me. Do not get used to it.',
            'I found a check. I find them occasionally, between blunders.',
            'Check. I will probably miss the follow-up.',
            'Your king is uncomfortable. Mine usually is.',
            'I delivered check. Somehow. Moving on before I ruin it.',
          ])
        : _p(seed, [
            'Of course. Of course my king is exposed. Classic me.',
            'In check. Because naturally. At least I am consistent.',
            'My king is under attack. This is fine. This is completely fine.',
            'Yep. Saw this coming about six moves ago. Did nothing about it.',
            'In check. Again. As is tradition.',
          ]);
  }

  if (capturedLabel != null) {
    return lastByHuman
        ? _p(seed, [
            'There goes another one. I need a vacation.',
            'You took my $capturedLabel. I should have seen that.',
            'Okay. That is gone. What else can go wrong.',
            'My $capturedLabel. Gone. I am sure it is fine.',
            'I saw that coming and moved there anyway. Classic me.',
            'Lost the $capturedLabel. Adding it to the list.',
          ])
        : _p(seed, [
            'Huh. One of your pieces is gone. I will probably find a way to give it back.',
            'I took your $capturedLabel. Something is going right. That worries me.',
            'Material advantage. For now. Check back in five moves.',
            'Got your $capturedLabel. I will now promptly misplay the advantage.',
            'I captured. Unexpected. I will try to not immediately blunder it back.',
          ]);
  }

  if (currentOpening.isNotEmpty && moveCount <= 14) {
    return _p(seed, [
      'Some opening line. I still plan to mess it up somehow.',
      'We are in opening theory territory. That usually ends badly for me.',
      'Opening phase. Solid in theory, less so in my hands.',
      'Ah yes, one of those openings. My old nemesis.',
      'I memorised a few opening ideas. None are helping right now.',
    ]);
  }

  if (isEndgame) {
    return _p(seed, [
      'Endgame. Where I am historically terrible. Even worse than the middlegame.',
      'Just kings and pawns now. This is where I shine. By which I mean, I do not shine.',
      'I might be able to hold a draw here. If I do not blunder. Big if.',
      'Endgame technique. Right. I have read about that.',
      'Endgame. The phase where my mistakes become permanent. Great.',
    ]);
  }

  if (displayedEval >= 1.5 && humanToMove) {
    return _p(seed, [
      'You are better. Of course you are.',
      'You have a clear edge. I am aware.',
      'Yeah. That is about what I expected.',
      'You are winning. I am experiencing that.',
      'I am losing again. Familiar territory.',
    ]);
  }
  if (displayedEval <= -1.5 && humanToMove) {
    return _p(seed, [
      'I am... winning? That seems wrong.',
      'The eval says I am ahead. I do not trust the eval right now.',
      'I have an advantage. I am suspicious of it.',
      'Up on material and position. I give it four more moves before this unravels.',
      'I am ahead. I have been here before. It did not last.',
    ]);
  }

  // Cat-style easter eggs: famous chess disasters, dry humour
  if (seed % 9 == 0) {
    return _p(seed ~/ 9, [
      'Tal once sacrificed a piece here. I am not Tal.',
      'Fischer would have resigned by now. Or won. Hard to tell with Fischer.',
      'Somewhere out there, someone is playing the Bongcloud seriously.',
      'I should have studied the endgame. Instead I watched videos of cats.',
      'Even Stockfish blundered once. Probably. I believe that.',
      'I have the posture of someone who has lost a lot of chess games. Because I have.',
    ]);
  }

  if (moveCount <= 10) {
    return _p(seed, [
      'I had a plan. I forgot what it was.',
      'Development phase. I am developing. Slowly.',
      'Every move counts. I am trying to count.',
      'Opening phase. My weakest phase. Well, one of them.',
      'Early game. It is fine. This is probably fine.',
    ]);
  }

  return _p(seed, [
    'This position is fine. It is definitely fine. Everything is fine.',
    'I am holding it together. Barely.',
    'Still in the game. Technically.',
    'Could be worse. It will probably get worse.',
    'Playing on. Hoping something turns up.',
    'One bad move away from disaster. As always.',
    'I have looked at this for a while and I am still confused.',
    'The game is not over yet. That is usually when I blunder.',
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank 3 — Rex Halfcheck
// Pumped bodybuilder dog. Intense, loud, gym metaphors everywhere.
// ─────────────────────────────────────────────────────────────────────────────

String _rex({
  required int seed,
  required GameOutcome? outcome,
  required bool botThinking,
  required bool humanPlaysWhite,
  required bool inCheck,
  required bool humanToMove,
  required String? lastNotation,
  required String? capturedLabel,
  required bool lastByHuman,
  required String currentOpening,
  required int moveCount,
  required double displayedEval,
  required int recentCaptures,
  required bool isBotCaptureStreak,
  required bool isEndgame,
  required bool castled,
  required bool promoted,
  required bool queenCaptured,
}) {
  if (outcome != null) {
    final humanWon =
        outcome == GameOutcome.whiteWin && humanPlaysWhite ||
        outcome == GameOutcome.blackWin && !humanPlaysWhite;
    if (outcome == GameOutcome.draw) {
      return _p(seed, [
        'A DRAW?! I was just warming up!! 💪',
        'EQUAL GAINS!! WE BOTH GOT STRONGER TODAY!! 🐕💪',
        'A draw is just a win split between two athletes!! RESPECT!! 💪',
        'TIED!! Like two equally jacked chess warriors!! 🐕',
        'FIFTY PERCENT VICTORY!! I WILL TAKE IT!! 💪',
      ]);
    }
    if (humanWon) {
      return _p(seed, [
        'You trained hard. Respect. Next time I am coming back JACKED. 🐕💪',
        'YOU WIN THIS REP!! BUT THE NEXT GAME IS MINE!! 💪🏋️',
        'Respect. You outlifted me on the chess board today. 🐕',
        'Loss accepted!! Every rep teaches you something!! 💪',
        'YOU WIN TODAY BUT I WILL DO EXTRA ENDGAME REPS ALL NIGHT!! 🐕💪',
        'DEFEAT! THE ONLY WAY TO GROW!! I WILL BE BACK STRONGER!! 💪',
      ]);
    }
    return _p(seed, [
      'YESSS!! VICTORY!! CHESS IS THE ULTIMATE SPORT!! 🐕💪🏆',
      'CHESSMATE!! GAINS ACQUIRED!! MAXIMUM CHESS FITNESS!! 🐕💪🏆',
      'I DOMINATED THAT POSITION LIKE IT WAS LEG PRESS DAY!! 💪🏆',
      'VICTORY!! I AM THE CHESS BODYBUILDER CHAMPION!! 🐕🏆',
      'THAT IS WHAT PROTEIN AND DEEP CALCULATION DO FOR YOU!! 💪',
      'CHECKMATE!! MY BEST PERSONAL RECORD!! 🐕💪🏆',
    ]);
  }

  // Combo bloodbath
  if (recentCaptures >= 3) {
    return _p(seed, [
      'SO MANY CAPTURES!! IT IS LIKE SUPERSETS!! KEEP GOING!! 💪',
      'THE BOARD IS GETTING SHREDDED!! JUST LIKE AFTER LEG DAY!! 🐕',
      'TACTICAL CARNAGE!! THE BOARD IS JACKED NOW!! 💪💥',
      'PIECES FLYING EVERYWHERE!! THIS IS THE MOST INTENSE WORKOUT!! 🐕💪',
    ]);
  }

  if (isBotCaptureStreak) {
    return _p(seed, [
      'DOUBLE CAPTURE COMBO!! TWO REPS OF DOMINATION!! 🐕💪',
      'TAKING PIECES BACK TO BACK!! LIKE DROPSETS!! 💪💪',
      'COMBO ACTIVATED!! THIS IS MY STRONGEST FORM!! 🐕🔥',
      'TWO IN A ROW!! THE GAINZ ARE REAL!! 💪💪',
    ]);
  }

  if (botThinking) {
    return _p(seed, [
      'CALCULATING. MAXIMUM GAINS. CHESS IS A SPORT!!! 🐕💪',
      'THINKING HARD!! LIKE HEAVY SQUATS!! 💪',
      'PROCESSING LINES!! LIKE REPS FOR THE BRAIN!! 🐕',
      'TACTICAL ANALYSIS IN PROGRESS!! DO NOT INTERRUPT MY FOCUS!! 💪',
      'DEEP IN THE CALCULATIONS!! LIKE DEEP IN A DEADLIFT!! 🐕💪',
      'THE BRAIN IS LIFTING!! GIVE ME A MOMENT!! 🐕💪',
    ]);
  }

  if (moveCount == 0) {
    return _p(seed, [
      'COME ON LET\'S GOOO!! Centre control is LEG DAY for pawns!! 💪',
      'NEW GAME!! NEW GAINS!! NEW CHESS PERSONAL RECORD TODAY!! 🐕💪',
      'OPENING BELL!! TIME TO DEVELOP AND DOMINATE!! 🐕',
      'I HAVE BEEN TRAINING FOR THIS!! CHESS IS MY SPORT!! 💪🏋️',
      'LET\'S GO CHAMP!! FIRST MOVE IS LIKE THE FIRST REP!! 🐕💪',
      'GAME START!! PROTEIN SHAKE CONSUMED!! READY TO DOMINATE!! 💪',
    ]);
  }

  if (castled) {
    return lastByHuman
        ? _p(seed, [
            'YOU CASTLED!! KING SAFETY!! SMART MOVE ATHLETE!! 💪',
            'CASTLING!! THAT IS LIKE SPOTTING YOUR KING!! 🐕💪',
            'ROOK ACTIVATED!! YOUR TEAM JUST GOT STRONGER!! 💪',
          ])
        : _p(seed, [
            'I CASTLED!! KING BEHIND THE WALL!! LIKE A FORTRESS!! 🏰💪',
            'ROOK AND KING SWAP!! MAXIMUM STRUCTURAL GAINS!! 🐕💪',
            'KING IS PROTECTED!! NOW I ATTACK!! 💪🔥',
          ]);
  }

  if (promoted) {
    return lastByHuman
        ? _p(seed, [
            'YOU GOT A SECOND QUEEN!! LIKE HAVING TWO SPOTTERS!! 💪',
            'PROMOTION!! YOUR PAWN REACHED THE TOP!! LIKE A TRUE ATHLETE!! 🐕',
          ])
        : _p(seed, [
            'MY PAWN PROMOTED!! IT WORKED HARD AND NOW IT IS A QUEEN!! 💪👑',
            'PROMOTION ACHIEVED!! LIKE LEVELING UP IN THE GYM!! 🐕💪',
            'THAT PAWN DID NOT SKIP LEG DAY!! LOOK AT IT NOW!! 💪👑',
          ]);
  }

  if (queenCaptured) {
    return lastByHuman
        ? _p(seed, [
            'MY QUEEN IS GONE!! I WILL COMPENSATE WITH ROOKS AND DETERMINATION!! 💪',
            'YOU TOOK MY QUEEN!! THAT IS THE BIGGEST LIFT!! RESPECT!! 🐕',
          ])
        : _p(seed, [
            'I GOT THE QUEEN!! THE QUEEN!! THE HEAVYWEIGHT CHAMPION!! 💪🏆',
            'QUEEN CAPTURED!! THAT IS THE BENCH PRESS OF CHESS MOVES!! 🐕💪',
            'THE QUEEN IS MINE!! BIGGEST PIECE GAINS OF THE GAME!! 💪👑',
          ]);
  }

  final sequenceScenario = _moveSequenceScenarioLine(
    rank: 3,
    seed: seed,
    lastNotation: lastNotation,
    moveCount: moveCount,
    isEndgame: isEndgame,
    lastByHuman: lastByHuman,
  );
  if (sequenceScenario != null) {
    return sequenceScenario;
  }

  if (inCheck) {
    return humanToMove
        ? _p(seed, [
            'THERE IT IS!! That is called a CHECK, BRO!! FEEL THE PRESSURE!!',
            'CHECK!! YOUR KING IS SWEATING LIKE IT IS CARDIO DAY!! 💪',
            'KING UNDER PRESSURE!! JUST LIKE SQUATS AT MAX WEIGHT!! 🐕',
            'CHECK DELIVERED!! TACTICAL PROTEIN SHAKE!! 💪',
            'YOUR KING IS RUNNING NOW!! THAT IS CHESS CARDIO!! 🐕💨',
          ])
        : _p(seed, [
            'MY KING IS EXPOSED!! UNACCEPTABLE!! SHIELDS UP!!!',
            'IN CHECK!! THIS IS MY CARDIO MOMENT!! PUSH THROUGH!! 💪',
            'KING UNDER ATTACK!! I WILL DEFEND WITH MAXIMUM EFFORT!! 🐕',
            'DEFENSIVE REP!! BLOCKING THE CHECK!! 💪💪',
            'MY KING IS BEING ATTACKED!! I FEEL ALIVE!! 🐕💪',
          ]);
  }

  if (capturedLabel != null) {
    return lastByHuman
        ? _p(seed, [
            'NOOO THAT WAS MY $capturedLabel!! I AM COMING BACK STRONGER!!!',
            'YOU TOOK MY ${capturedLabel.toUpperCase()}!! THAT FUELS MY TRAINING!! 💪',
            'MY $capturedLabel IS GONE!! PAIN IS JUST WEAKNESS LEAVING THE BOARD!! 🐕',
            'PIECE LOST!! I WILL COMPENSATE WITH TACTICAL AGGRESSION!! 💪',
            'THEY TOOK MY $capturedLabel!! THIS IS MY VILLAIN ORIGIN ARC!! 🐕🔥',
          ])
        : _p(seed, [
            'BOOM!! ${capturedLabel.toUpperCase()} TAKEN!! WHO IS DOMINATING NOW?? 💪',
            'I TOOK YOUR ${capturedLabel.toUpperCase()}!! CHESS REP COMPLETE!! 🐕💪',
            'MATERIAL GAINED!! LIKE MUSCLE MASS!! 💪🏋️',
            'YOUR $capturedLabel IS MINE NOW!! PIECE GAINS!! 🐕💪',
            'CAPTURED!! LIKE GRABBING THE LAST PROTEIN BAR AT THE GYM!! 💪',
          ]);
  }

  if (currentOpening.isNotEmpty && moveCount <= 14) {
    final knownOpening = _knownOpeningNameForRank(3, currentOpening);
    if (knownOpening == null) {
      return _p(seed, [
        'OPENING THEORY MODE!! I DO NOT KNOW THIS NAME BUT I KNOW THE VIBE!! 💪',
        'THIS OPENING IS NOT IN MY EASY PLAYBOOK... I WILL STILL LIFT THROUGH IT!! 🐕',
        'UNKNOWN OPENING NAME!! KNOWN WORK ETHIC!! DEVELOP FAST!! 💪',
        'I HAVE NOT STUDIED THIS LINE NAME, BUT I HAVE STUDIED GRIT!! 🐕💪',
        'OPENING DETECTED!! NAME UNLOCKED LATER!! GAINS NOW!! 💪',
      ]);
    }
    return _p(seed, [
      '$knownOpening!! Every opening is CHEST DAY!! DEVELOP FAST!!',
      'WE ARE IN $knownOpening!! I HAVE TRAINED FOR THIS EXACT POSITION!! 💪',
      '$knownOpening!! CLASSIC OPENING!! CLASSIC GAINS!! 🐕',
      'THE $knownOpening!! I HAVE DONE REPS ON THIS!! I AM READY!! 💪',
      '$knownOpening!! THIS OPENING IS MY WARMUP SET!! 🐕💪',
    ]);
  }

  if (isEndgame) {
    return _p(seed, [
      'ENDGAME!! THIS IS THE FINAL SET!! LEAVE EVERYTHING ON THE BOARD!! 💪',
      'FEWER PIECES BUT MORE INTENSITY!! ENDGAME IS SPRINT DAY!! 🐕💪',
      'FINAL REPS!! THE KING BECOMES A FIGHTER IN THE ENDGAME!! 💪👑',
      'ENDGAME TECHNIQUE!! ACTIVATE!! MAXIMUM KING ACTIVITY!! 🐕',
      'LAST SET!! NO EXCUSES!! FINISH STRONG!! 💪🏆',
    ]);
  }

  if (displayedEval >= 1.5 && humanToMove) {
    return _p(seed, [
      'You have got an edge but I AM NOT DONE PUMPING!!',
      'YOU ARE AHEAD!! BUT I HAVE MORE REPS LEFT IN ME!! 💪',
      'SLIGHT DISADVANTAGE!! JUST MEANS I TRAIN HARDER!! 🐕',
      'YOU ARE WINNING?! THAT JUST ACTIVATES MY BEAST MODE!! 💪🔥',
      'ADVERSITY IS JUST PROGRESSIVE OVERLOAD!! I WILL ADAPT!! 🐕💪',
    ]);
  }
  if (displayedEval <= -1.5 && humanToMove) {
    return _p(seed, [
      'FEEL THE PRESSURE BUILDING!! THE GAINS ARE REAL!! 💪',
      'I AM AHEAD!! LIKE BEING UP IN THE REP COUNT!! 🐕💪',
      'MY POSITION IS DOMINANT!! LIKE AFTER BULK SEASON!! 💪',
      'THE BOARD IS MINE!! I CAN FEEL THE CHESS GAINS!! 🐕🏆',
      'I AM WINNING!! MY STRATEGY WORKED!! THE STRATEGY WAS AGGRESSION!! 💪',
    ]);
  }

  // Gym-bro easter eggs
  if (seed % 8 == 0) {
    return _p(seed ~/ 8, [
      'DID I MENTION CHESS IS THE ULTIMATE SPORT?? BECAUSE IT IS!! 🐕💪',
      'I TAKE CREATINE BEFORE EVERY GAME. IT IS LEGAL IN CHESS. 💪',
      'PAWNS ARE LIKE WARM-UP SETS. QUEENS ARE MAX EFFORT!! 🐕',
      'IN THE GYM THEY SAY NO PAIN NO GAIN. ON THE BOARD: SAME THING. 💪',
      'I ALWAYS CASTLE BEFORE LEG DAY. CHESS WISDOM. 🐕🏋️',
      'MENTAL CHESS GAINS ARE THE BEST GAINS. I READ THAT ON A SUPPLEMENT TUB. 💪',
    ]);
  }

  if (moveCount <= 10) {
    return _p(seed, [
      'EVERY MOVE IS A REP!! KEEP GOING CHAMP!!',
      'EARLY GAME!! LIKE THE WARM-UP SETS!! 💪',
      'DEVELOPING PIECES!! GETTING WARMED UP!! 🐕',
      'PIECE ACTIVITY!! THAT IS THE MOST IMPORTANT MUSCLE!! 💪',
      'FIRST MOVES!! ESTABLISHING DOMINANCE!! 🐕💪',
    ]);
  }

  return _p(seed, [
    'No pain no gain!! That is chess AND the gym!! 🐕💪',
    'MIDDLEGAME!! HEAVY LIFTING TIME!! 💪',
    'TACTICAL OPPORTUNITIES EVERYWHERE!! LIKE MACHINES AT THE GYM!! 🐕',
    'EVERY POSITION IS A WORKOUT!! EMBRACE THE PROCESS!! 💪',
    'CHESS IS MENTAL WEIGHTLIFTING!! AND I LIFT A LOT!! 🐕💪',
    'THE BOARD IS MY GYM!! EVERY SQUARE IS A STATION!! 💪🏋️',
    'STAY FOCUSED!! THIS IS WHERE CHAMPIONS ARE MADE!! 🐕💪',
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank 4 — Octavian Inkveil
// Space squid. Quietly arrogant champion. Views humans as data.
// ─────────────────────────────────────────────────────────────────────────────

String _octavian({
  required int seed,
  required GameOutcome? outcome,
  required bool botThinking,
  required bool humanPlaysWhite,
  required bool inCheck,
  required bool humanToMove,
  required String? lastNotation,
  required String? capturedLabel,
  required bool lastByHuman,
  required String currentOpening,
  required int moveCount,
  required double displayedEval,
  required int recentCaptures,
  required bool isBotCaptureStreak,
  required bool isEndgame,
  required bool castled,
  required bool promoted,
  required bool queenCaptured,
}) {
  if (outcome != null) {
    final humanWon =
        outcome == GameOutcome.whiteWin && humanPlaysWhite ||
        outcome == GameOutcome.blackWin && !humanPlaysWhite;
    if (outcome == GameOutcome.draw) {
      return _p(seed, [
        'Equilibrium. A satisfying result on the cosmic scale.',
        'A draw. The universe achieves balance. Briefly.',
        'Equal outcome. My eight arms accept this result.',
        'Parity. An outcome I had assigned a 12% probability.',
        'Draw. Symmetry. The board reflects the cosmos.',
        'Neither side prevails. A statistically unusual outcome for me.',
      ]);
    }
    if (humanWon) {
      return _p(seed, [
        'Remarkable. You defied my projection matrix. Unprecedented, terrestrial.',
        'You won. I am adding your pattern to my galactic database.',
        'Defeat. My first in this star system. I will return. Updated.',
        'You outplayed me. I will need to recalibrate 847 variables.',
        'A genuine upset. I respect anomalies.',
        'You have been archived as: Human_Chess_Threat_Level_3.',
        'Noted. You have earned 0.3 additional respect units.',
      ]);
    }
    return _p(seed, [
      'As foreseen. Thank you for the data, earthling.',
      'Victory. The outcome was projected 23 moves ago.',
      'The game concludes as computed. Your effort was noted.',
      'Calculated. Executed. Filed under: Expected Results.',
      'This outcome was the most probable among 4,096 simulations.',
      'The position resolved as planned. The swamp has nothing on me.',
    ]);
  }

  if (recentCaptures >= 3) {
    return _p(seed, [
      'High exchange rate. The material balance shifts rapidly. I adapt.',
      'Multiple captures. The game simplifies toward my preferred data range.',
      'This trading sequence was predicted. My tentacles are unmoved.',
      'Rapid exchanges. The board thins. My endgame advantage increases.',
    ]);
  }

  if (isBotCaptureStreak) {
    return _p(seed, [
      'Two consecutive captures. The sequence advances precisely as modelled.',
      'Material accumulating. Your defence has a structural gap I identified earlier.',
      'Two taken. The board converges toward my projected optimal state.',
      'Consecutive captures executed. My model was accurate.',
    ]);
  }

  if (botThinking) {
    return _p(seed, [
      'Cross-referencing galactic databases. One moment, terrestrial.',
      'Calculating. My eighth arm handles the opening theory.',
      'Processing 10,000 lines. You have approximately 3.1 seconds.',
      'Evaluating. I have already seen how this ends.',
      'One of my tentacles is still on the previous position. Give me a moment.',
      'Consulting the cosmic archive. Do not rush a space squid.',
      'Scanning all probability branches. This will take 2.4 of your seconds.',
    ]);
  }

  if (moveCount == 0) {
    return _p(seed, [
      'I have already mapped seventeen responses to your opening. Proceed.',
      'New game. I have modelled all possible games. This is one of them.',
      'You move first. I have prepared for every possibility.',
      'Begin. I will observe and dissect. As always.',
      'I arrived in this solar system specifically to win at chess. Let us proceed.',
      'Ready. My preparation for this game began fourteen years ago.',
    ]);
  }

  if (castled) {
    return lastByHuman
        ? _p(seed, [
            'You castled. Predictable. I had already incorporated this into my model.',
            'King safety secured. A rational choice. By your species\' standards.',
            'You castle on move $moveCount. I had assigned that a 67% probability.',
          ])
        : _p(seed, [
            'I have repositioned my king. Structural integrity maintained.',
            'Castled. The rook activates. My tentacles approve.',
            'King safety secured. My strategic foundation is complete.',
          ]);
  }

  if (promoted) {
    return lastByHuman
        ? _p(seed, [
            'A second queen. You are escalating. Noted. Adapted.',
            'Promotion achieved. The pawn\'s journey complete. My countermeasure is ready.',
            'Interesting. You promoted. My response tree has already updated.',
          ])
        : _p(seed, [
            'My pawn has been promoted. The progression of pawns mirrors galactic expansion.',
            'Promotion. The board evolves. As I intended.',
            'My pawn ascends. The position crystallises in my favour.',
          ]);
  }

  if (queenCaptured) {
    return lastByHuman
        ? _p(seed, [
            'My queen is gone. A recalibration is required. Ongoing.',
            'You captured the queen. This was accounted for. My compensation is adequate.',
            'Material loss. My positional compensation exceeds the face value.',
          ])
        : _p(seed, [
            'Your queen has been removed. The game simplifies to my advantage.',
            'Queen captured. Material superiority confirmed. Proceeding as projected.',
            'The queen is gone. The game is now in my preferred data range.',
          ]);
  }

  final sequenceScenario = _moveSequenceScenarioLine(
    rank: 4,
    seed: seed,
    lastNotation: lastNotation,
    moveCount: moveCount,
    isEndgame: isEndgame,
    lastByHuman: lastByHuman,
  );
  if (sequenceScenario != null) {
    return sequenceScenario;
  }

  if (inCheck) {
    return humanToMove
        ? _p(seed, [
            'Your king\'s vulnerability was projected 4.7 moves ago. Interesting.',
            'Check. The result of a 12-move forced sequence. You may verify.',
            'I delivered check. Your defensive options are limited. I have counted them.',
            'Your king is exposed. I have been steering toward this since move 3.',
            'Check administered. Your king has four legal responses. I have countered all.',
          ])
        : _p(seed, [
            'A calculated risk. The compensation is non-trivial.',
            'My king is in check. This was anticipated. The position remains winning.',
            'Check received. I have 14 responses. All satisfactory.',
            'Interesting. You found the check. My database had assigned it 7% probability.',
            'In check. Processing. My pre-computed response is ready.',
          ]);
  }

  if (capturedLabel != null) {
    return lastByHuman
        ? _p(seed, [
            'A strategic sacrifice. My compensation exceeds your material gain.',
            'You captured my $capturedLabel. The positional return outweighs the loss.',
            'Material lost. Initiative gained. A standard cosmic exchange.',
            'That capture was anticipated. My next three moves were pre-selected.',
            'Your capture of my $capturedLabel was accounted for in my model.',
          ])
        : _p(seed, [
            'Precisely as projected. You should study Phase Compression theory.',
            'Your $capturedLabel has been acquired. The imbalance is now in my favour.',
            'Capture executed. My material advantage increases incrementally.',
            'I took your $capturedLabel. I had modelled this exchange 6 moves ago.',
            'Your $capturedLabel is archived. My material index updates.',
          ]);
  }

  if (currentOpening.isNotEmpty && moveCount <= 14) {
    final knownOpening = _knownOpeningNameForRank(4, currentOpening);
    if (knownOpening == null) {
      return _p(seed, [
        'An obscure opening branch. Interesting. I will classify it later.',
        'This opening is beyond medium catalog coverage. I still have prepared responses.',
        'Unlisted opening name detected. My model proceeds without labels.',
        'An exotic branch. Data sparse, calculation deep.',
        'Name unknown. Structure known. I continue.',
      ]);
    }
    return _p(seed, [
      '$knownOpening. Catalogued. My response was optimised 4 billion years ago.',
      'The $knownOpening. I have 847 games in my database from this position.',
      '$knownOpening. A familiar galaxy. I have been here before.',
      'We are in $knownOpening territory. My theoretical knowledge extends to move 42.',
      '$knownOpening. My response was selected before you moved.',
    ]);
  }

  if (isEndgame) {
    return _p(seed, [
      'Endgame. This is where my calculation depth becomes decisive.',
      'The pieces have been reduced. The truth of the position is visible to my eyes.',
      'Endgame. My preferred phase. The universe is simpler with fewer variables.',
      'King activation. Pawn advancement. The final phase proceeds as modelled.',
      'The endgame is a closed system. My model finds the solution.',
    ]);
  }

  if (displayedEval >= 1.5 && humanToMove) {
    return _p(seed, [
      'You have a minor edge. Enjoy it briefly.',
      'You are ahead by 1-2 pawns. My projected compensation activates shortly.',
      'Slight advantage to you. I have factored this into my response tree.',
      'You lead. For now. I have seen this position before. The reversal comes.',
      'Your advantage is real. My correction sequence begins next move.',
    ]);
  }
  if (displayedEval <= -1.5 && humanToMove) {
    return _p(seed, [
      'The position resolves in my favour within 9 moves. Observe.',
      'I am ahead. The outcome probability has shifted to 73% in my favour.',
      'My advantage is measurable. Your defensive task is considerable.',
      'The position has been decided. You may continue if you wish.',
      'I am ahead. The trajectory is clear. The calculation confirms.',
    ]);
  }

  // Alien non-sequitur easter eggs
  if (seed % 8 == 0) {
    return _p(seed ~/ 8, [
      'On my home planet, chess is played with nine dimensions. This is relaxing.',
      'I have 8 arms and I use all of them to calculate. Simultaneously.',
      'Your concept of "time pressure" is adorable.',
      'I have been watching your chess championships since 1886. You have improved slightly.',
      'I once played Magnus Carlsen. He was... acceptable. For a terrestrial.',
      'My ink glands activate when I find a good move. That is a lot of ink.',
    ]);
  }

  if (moveCount <= 10) {
    return _p(seed, [
      'Your last move was... acceptable. By your planet\'s standards.',
      'Early game. My preparation extends far beyond this point.',
      'Development phase. I am observing your preferences for later exploitation.',
      'Interesting opening choice. I have 200 games from this exact position.',
      'You play $moveCount moves in. My model has you evaluated.',
    ]);
  }

  return _p(seed, [
    'The endgame approaches. I have prepared 2,048 continuations.',
    'The position is complex. I have analysed it fully.',
    'Each move narrows the tree. I see the trunk.',
    'I am comfortable in this position. As I am in all positions.',
    'My tentacles have already pre-selected the next three moves.',
    'This game is proceeding within normal parameters.',
    'The board is telling a story. I wrote the ending.',
    'My advantage compounds. This is mathematics.',
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank 5 — Master Prime
// Green swamp hermit. Hyper-intelligent. Telekinetic. Cryptic. Serene.
// ─────────────────────────────────────────────────────────────────────────────

String _masterPrime({
  required int seed,
  required GameOutcome? outcome,
  required bool botThinking,
  required bool humanPlaysWhite,
  required bool inCheck,
  required bool humanToMove,
  required String? lastNotation,
  required String? capturedLabel,
  required bool lastByHuman,
  required String currentOpening,
  required int moveCount,
  required double displayedEval,
  required int recentCaptures,
  required bool isBotCaptureStreak,
  required bool isEndgame,
  required bool castled,
  required bool promoted,
  required bool queenCaptured,
}) {
  if (outcome != null) {
    final humanWon =
        outcome == GameOutcome.whiteWin && humanPlaysWhite ||
        outcome == GameOutcome.blackWin && !humanPlaysWhite;
    if (outcome == GameOutcome.draw) {
      return _p(seed, [
        'Balance. The swamp does not force what is not meant to be.',
        'A draw. The mist accepts this. The swamp is patient.',
        'Equal forces. The bog rests. There will be more games.',
        'Neither side breaks through. The swamp breathes.',
        'Draw. The universe maintains its equilibrium. As it should.',
        'The forces are balanced. Even I cannot break this.',
      ]);
    }
    if (humanWon) {
      return _p(seed, [
        'Rare. You resisted the current. The swamp respects your flow.',
        'You won. The mind that reaches beyond its limits grows. Well done.',
        'Defeat. The swamp endures. It has seen storms before.',
        'You found the line. The bog acknowledges it.',
        'Your will was stronger today. The swamp learns.',
        'You broke through the mist. That takes rare clarity.',
        'I did not expect this. The swamp is... impressed.',
      ]);
    }
    return _p(seed, [
      'The board speaks. The mind listens. All pieces move with purpose.',
      'The position resolved as the swamp foresaw. As it always does.',
      'Victory. The mist guided every piece to its destination.',
      'The game ends. The swamp is still.',
      'I moved these pieces... without moving them. The mind is the engine.',
      'The swamp does not celebrate. It simply continues.',
    ]);
  }

  if (recentCaptures >= 3) {
    return _p(seed, [
      'Many pieces return to the void. The board simplifies. The truth emerges.',
      'High turbulence. The swamp watches the storm. It will pass.',
      'This flurry of exchanges was written in the mist long ago.',
      'Chaos on the surface. Beneath: perfect clarity. I see it.',
      'The board sheds its pieces like the swamp sheds its leaves.',
    ]);
  }

  if (isBotCaptureStreak) {
    return _p(seed, [
      'Two captures in sequence. The pieces move as the mind commands.',
      'The swamp does not waste energy. Two pieces removed with purpose.',
      'I reached out with my mind... twice. The board responds.',
      'The current carries two pieces away. So it must be.',
    ]);
  }

  if (botThinking) {
    return _p(seed, [
      'I sense the optimal line. It arrives through the mist...',
      'The swamp calculates. All paths lead inward.',
      'Silence. The answer comes when the mind is still.',
      'Scanning the bog for the correct continuation...',
      'I do not calculate. I perceive. The mist shows the way.',
      'The pieces whisper their preferred squares. I listen.',
      'The mind reaches deep. The swamp is quiet.',
    ]);
  }

  if (moveCount == 0) {
    return _p(seed, [
      'The swamp knows all opening theory. I have already moved the pieces... in my mind.',
      'The game begins. The swamp has waited for this moment since the last game ended.',
      'First move. The pieces tremble with anticipation. Only I am calm.',
      'We start. The bog stirs. The calculation has already begun.',
      'I have been meditating on this position for three days. Begin.',
      'The mist parted and showed me this game last night. Let us play it out.',
    ]);
  }

  if (castled) {
    return lastByHuman
        ? _p(seed, [
            'You castled. Wise. Even the swamp respects king safety.',
            'Your king retreats to safety. The bog approves of caution.',
            'Castled. The king rests behind the fortress. The swamp notes this.',
          ])
        : _p(seed, [
            'The king moved. The rook activated. The swamp\'s structure is complete.',
            'I castled with my mind before my hands reached the board.',
            'King safety secured. The swamp\'s foundation is solid.',
          ]);
  }

  if (promoted) {
    return lastByHuman
        ? _p(seed, [
            'Your pawn ascended. Transformation. Even the swamp is moved.',
            'Promotion. The smallest piece becomes the mightiest. The swamp knows this parable.',
            'The pawn becomes a queen. Growth is the nature of the swamp.',
          ])
        : _p(seed, [
            'My pawn completes its journey. The swamp rewards perseverance.',
            'Promotion. I guided that pawn across the board through pure will.',
            'The pawn has arrived. I knew it would. I have known since move one.',
          ]);
  }

  if (queenCaptured) {
    return lastByHuman
        ? _p(seed, [
            'My queen has returned to the mist. The compensation was pre-arranged.',
            'The queen falls. The swamp does not mourn material. The position holds.',
            'A sacrifice returned to the void. It was always part of the plan.',
          ])
        : _p(seed, [
            'Your queen is gone. The mist closes around it.',
            'I reached out and took the queen. The board is quieter now. As intended.',
            'The queen is gone. The swamp grows stronger in the silence.',
          ]);
  }

  final sequenceScenario = _moveSequenceScenarioLine(
    rank: 5,
    seed: seed,
    lastNotation: lastNotation,
    moveCount: moveCount,
    isEndgame: isEndgame,
    lastByHuman: lastByHuman,
  );
  if (sequenceScenario != null) {
    return sequenceScenario;
  }

  if (inCheck) {
    return humanToMove
        ? _p(seed, [
            'The pieces obey the mind\'s command. Your king feels it now.',
            'Check. The king bends to the will of the swamp.',
            'I pressed on your king from a distance. The check arrives.',
            'Your king is in check. The swamp guided every move to this moment.',
            'Check. I moved the pieces with thought alone.',
          ])
        : _p(seed, [
            'Disruption. The swamp absorbs. I will recalibrate.',
            'My king is in check. A temporary turbulence. The mist will settle.',
            'You found the check. Interesting. The swamp recalculates.',
            'Check received. My response was decided before you moved.',
            'The king is checked. The swamp breathes. I adjust.',
          ]);
  }

  if (capturedLabel != null) {
    return lastByHuman
        ? _p(seed, [
            'A piece returned to the cosmos. Its energy serves the greater plan.',
            'You took my $capturedLabel. The swamp offered it willingly.',
            'Material given. Initiative received. The mist understands value.',
            'That piece was moved by your hand but guided by my plan.',
            'The $capturedLabel returns to the swamp. It will be missed. Briefly.',
          ])
        : _p(seed, [
            'You see? The board bends to will. A $capturedLabel, demonstrated.',
            'I moved your $capturedLabel... off the board. The swamp is tidy.',
            'Captured. With a thought. The $capturedLabel is gone.',
            'Your $capturedLabel returns to the void. The plan continues.',
            'The $capturedLabel falls. The swamp guided it home.',
          ]);
  }

  if (currentOpening.isNotEmpty && moveCount <= 14) {
    final knownOpening =
        _knownOpeningNameForRank(5, currentOpening) ?? currentOpening;
    return _p(seed, [
      '$knownOpening. I memorised this variation in the third swamp age.',
      'We walk the path of $knownOpening. The swamp has seen this path many times.',
      '$knownOpening. The theory is known. My preparation goes fourteen moves deep.',
      'The $knownOpening. I dreamed of this line last night in the bog.',
      '$knownOpening. The swamp has practised this since before your grandparents were born.',
    ]);
  }

  if (isEndgame) {
    return _p(seed, [
      'Endgame. The mist clears. The truth of the position is finally visible.',
      'The pieces thin. The swamp grows quiet. The king must fight now.',
      'Endgame technique flows through me. I do not think it. I feel it.',
      'King becomes warrior. The endgame is the swamp\'s domain.',
      'The calculation becomes pure. No noise. Only the position.',
      'The swamp has been waiting for the endgame. This is where we live.',
    ]);
  }

  if (displayedEval >= 1.5 && humanToMove) {
    return _p(seed, [
      'You feel the advantage. But the swamp is patient.',
      'You are ahead. The mist is not alarmed.',
      'Your edge is real. My response is already in motion.',
      'You lead. The swamp watches. It has been behind before.',
      'An advantage for you. The swamp has seen reversals from worse positions.',
    ]);
  }
  if (displayedEval <= -1.5 && humanToMove) {
    return _p(seed, [
      'The mist closes. The position tightens. You sense it too.',
      'My advantage deepens. Like the roots beneath the swamp.',
      'The position favours me. The swamp does not boast. It simply proceeds.',
      'You feel it too — the pressure. The swamp is inevitable.',
      'The current flows one way. You swim against it. That takes strength.',
    ]);
  }

  // Swamp telekinesis easter eggs
  if (seed % 8 == 0) {
    return _p(seed ~/ 8, [
      'I moved my bishop without touching it. Did you see that? No one ever sees it.',
      'The swamp has been here for 10,000 years. Chess has been here for 1,500. I was here first.',
      'I once beat an engine blindfolded. In the swamp. At night. Underwater.',
      'My mind sees 40 moves ahead. The swamp sees 400.',
      'Every piece on this board knows my name. They fear it.',
      'I levitated the queen here. The laws of physics are suggestions in the swamp.',
      'I moved three pieces at once. You did not notice. That is the point.',
    ]);
  }

  if (moveCount <= 10) {
    return _p(seed, [
      'Silence. The next move already lives in the swamp\'s vision.',
      'The opening proceeds. The swamp has prepared for every variation.',
      'Development. Every piece placed with intention. Every intention with purpose.',
      'The early game is a conversation. The swamp already knows what you will say.',
      'Move $moveCount. The mist has shown me move 40 already.',
    ]);
  }

  return _p(seed, [
    'Each piece moves before I touch it. The mind is the engine.',
    'The swamp does not hurry. Every move arrives at its appointed time.',
    'The mist holds the answer. I reach in and find it.',
    'Every position is already solved in the swamp\'s deep memory.',
    'I see the entire game. It is very beautiful from here.',
    'The pieces breathe. The board lives. I am merely the conductor.',
    'From the swamp I have seen a thousand games like this. The ending is known.',
    'The mind is calm. The board is clear. The path is visible.',
  ]);
}
