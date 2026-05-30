enum RemoteFriendSeat { white, black }

extension RemoteFriendSeatWire on RemoteFriendSeat {
  String get wireName {
    switch (this) {
      case RemoteFriendSeat.white:
        return 'white';
      case RemoteFriendSeat.black:
        return 'black';
    }
  }
}

RemoteFriendSeat? remoteFriendSeatFromWire(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'white':
      return RemoteFriendSeat.white;
    case 'black':
      return RemoteFriendSeat.black;
  }
  return null;
}

enum RemoteFriendSeatPreference { random, white, black }

extension RemoteFriendSeatPreferenceWire on RemoteFriendSeatPreference {
  String get wireName {
    switch (this) {
      case RemoteFriendSeatPreference.random:
        return 'random';
      case RemoteFriendSeatPreference.white:
        return 'white';
      case RemoteFriendSeatPreference.black:
        return 'black';
    }
  }
}

enum RemoteFriendMatchStatus { pending, active, completed, expired, cancelled }

extension RemoteFriendMatchStatusWire on RemoteFriendMatchStatus {
  String get wireName {
    switch (this) {
      case RemoteFriendMatchStatus.pending:
        return 'pending';
      case RemoteFriendMatchStatus.active:
        return 'active';
      case RemoteFriendMatchStatus.completed:
        return 'completed';
      case RemoteFriendMatchStatus.expired:
        return 'expired';
      case RemoteFriendMatchStatus.cancelled:
        return 'cancelled';
    }
  }
}

RemoteFriendMatchStatus remoteFriendMatchStatusFromWire(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'active':
      return RemoteFriendMatchStatus.active;
    case 'completed':
      return RemoteFriendMatchStatus.completed;
    case 'expired':
      return RemoteFriendMatchStatus.expired;
    case 'cancelled':
      return RemoteFriendMatchStatus.cancelled;
    case 'pending':
    default:
      return RemoteFriendMatchStatus.pending;
  }
}

enum RemoteFriendMatchAction {
  resign,
  offerDraw,
  acceptDraw,
  declineDraw,
  cancelPending,
}

extension RemoteFriendMatchActionWire on RemoteFriendMatchAction {
  String get wireName {
    switch (this) {
      case RemoteFriendMatchAction.resign:
        return 'resign';
      case RemoteFriendMatchAction.offerDraw:
        return 'offerDraw';
      case RemoteFriendMatchAction.acceptDraw:
        return 'acceptDraw';
      case RemoteFriendMatchAction.declineDraw:
        return 'declineDraw';
      case RemoteFriendMatchAction.cancelPending:
        return 'cancelPending';
    }
  }
}

enum RemoteFriendOutcomeCode { whiteWin, blackWin, draw, aborted }

extension RemoteFriendOutcomeCodeWire on RemoteFriendOutcomeCode {
  String get wireName {
    switch (this) {
      case RemoteFriendOutcomeCode.whiteWin:
        return 'whiteWin';
      case RemoteFriendOutcomeCode.blackWin:
        return 'blackWin';
      case RemoteFriendOutcomeCode.draw:
        return 'draw';
      case RemoteFriendOutcomeCode.aborted:
        return 'aborted';
    }
  }
}

RemoteFriendOutcomeCode? remoteFriendOutcomeCodeFromWire(String? value) {
  switch ((value ?? '').trim()) {
    case 'whiteWin':
      return RemoteFriendOutcomeCode.whiteWin;
    case 'blackWin':
      return RemoteFriendOutcomeCode.blackWin;
    case 'draw':
      return RemoteFriendOutcomeCode.draw;
    case 'aborted':
      return RemoteFriendOutcomeCode.aborted;
  }
  return null;
}

class RemoteFriendTimeControl {
  const RemoteFriendTimeControl({
    required this.initialSeconds,
    required this.incrementSeconds,
  });

  factory RemoteFriendTimeControl.fromMap(Map<String, dynamic> map) {
    return RemoteFriendTimeControl(
      initialSeconds: _intFromDynamic(map['initialSeconds']),
      incrementSeconds: _intFromDynamic(map['incrementSeconds']),
    );
  }

  final int initialSeconds;
  final int incrementSeconds;

  bool get isUntimed => initialSeconds <= 0;

  Duration get initialDuration =>
      Duration(seconds: initialSeconds.clamp(0, 1 << 20));

  Duration get incrementDuration =>
      Duration(seconds: incrementSeconds.clamp(0, 1 << 20));

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'initialSeconds': initialSeconds,
      'incrementSeconds': incrementSeconds,
    };
  }
}

class RemoteFriendInvite {
  const RemoteFriendInvite({
    required this.matchId,
    required this.inviteCode,
    required this.hostUid,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory RemoteFriendInvite.fromMap(Map<String, dynamic> map) {
    return RemoteFriendInvite(
      matchId: map['matchId']?.toString().trim() ?? '',
      inviteCode: map['inviteCode']?.toString().trim() ?? '',
      hostUid: map['hostUid']?.toString().trim() ?? '',
      status: remoteFriendMatchStatusFromWire(map['status']?.toString()),
      createdAt: _dateTimeFromDynamic(map['createdAtMs'] ?? map['createdAt']),
      expiresAt: _dateTimeFromDynamic(map['expiresAtMs'] ?? map['expiresAt']),
    );
  }

  final String matchId;
  final String inviteCode;
  final String hostUid;
  final RemoteFriendMatchStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'matchId': matchId,
      'inviteCode': inviteCode,
      'hostUid': hostUid,
      'status': status.wireName,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
      'expiresAtMs': expiresAt.millisecondsSinceEpoch,
    };
  }
}

class RemoteFriendMoveRecord {
  const RemoteFriendMoveRecord({
    required this.ply,
    required this.uci,
    required this.san,
    required this.fen,
    required this.playedByUid,
    required this.playedAt,
  });

  factory RemoteFriendMoveRecord.fromMap(Map<String, dynamic> map) {
    return RemoteFriendMoveRecord(
      ply: _intFromDynamic(map['ply']),
      uci: map['uci']?.toString().trim() ?? '',
      san: map['san']?.toString().trim() ?? '',
      fen: map['fen']?.toString().trim() ?? '',
      playedByUid: map['playedByUid']?.toString().trim() ?? '',
      playedAt: _dateTimeFromDynamic(map['playedAtMs'] ?? map['playedAt']),
    );
  }

  final int ply;
  final String uci;
  final String san;
  final String fen;
  final String playedByUid;
  final DateTime playedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ply': ply,
      'uci': uci,
      'san': san,
      'fen': fen,
      'playedByUid': playedByUid,
      'playedAtMs': playedAt.millisecondsSinceEpoch,
    };
  }
}

class RemoteFriendOutcome {
  const RemoteFriendOutcome({
    required this.code,
    required this.reason,
    required this.concludedAt,
    this.winnerUid,
  });

  factory RemoteFriendOutcome.fromMap(Map<String, dynamic> map) {
    return RemoteFriendOutcome(
      code:
          remoteFriendOutcomeCodeFromWire(map['code']?.toString()) ??
          RemoteFriendOutcomeCode.aborted,
      reason: map['reason']?.toString().trim() ?? '',
      concludedAt: _dateTimeFromDynamic(
        map['concludedAtMs'] ?? map['concludedAt'],
      ),
      winnerUid: _nullableTrimmedString(map['winnerUid']),
    );
  }

  final RemoteFriendOutcomeCode code;
  final String reason;
  final DateTime concludedAt;
  final String? winnerUid;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code.wireName,
      'reason': reason,
      'winnerUid': winnerUid,
      'concludedAtMs': concludedAt.millisecondsSinceEpoch,
    };
  }
}

class RemoteFriendReaction {
  const RemoteFriendReaction({
    required this.emoji,
    required this.sentByUid,
    required this.sentAt,
  });

  factory RemoteFriendReaction.fromMap(Map<String, dynamic> map) {
    return RemoteFriendReaction(
      emoji: map['emoji']?.toString().trim() ?? '',
      sentByUid: map['sentByUid']?.toString().trim() ?? '',
      sentAt: _dateTimeFromDynamic(map['sentAtMs'] ?? map['sentAt']),
    );
  }

  final String emoji;
  final String sentByUid;
  final DateTime sentAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'emoji': emoji,
      'sentByUid': sentByUid,
      'sentAtMs': sentAt.millisecondsSinceEpoch,
    };
  }
}

class RemoteFriendMatchSnapshot {
  const RemoteFriendMatchSnapshot({
    required this.matchId,
    required this.inviteCode,
    required this.status,
    required this.hostUid,
    required this.fen,
    required this.pgn,
    required this.nextPly,
    required this.whiteToMove,
    required this.timeControl,
    required this.whiteTimeRemainingMs,
    required this.blackTimeRemainingMs,
    required this.whitePieceThemeIndex,
    required this.blackPieceThemeIndex,
    required this.lastTickStartedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.moves,
    this.guestUid,
    this.whiteUid,
    this.blackUid,
    this.activeClockSeat,
    this.drawOfferByUid,
    this.startedAt,
    this.expiresAt,
    this.pieceSelectionDeadlineAt,
    this.outcome,
    this.reaction,
    this.whiteLastReactionAt,
    this.blackLastReactionAt,
  });

  factory RemoteFriendMatchSnapshot.fromMap(Map<String, dynamic> map) {
    final rawTimeControl = map['timeControl'];
    final rawMoves = map['moves'];
    final rawOutcome = map['outcome'];
    final rawReaction = map['reaction'];
    final clockMap = map['clocks'] is Map
        ? (map['clocks'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    return RemoteFriendMatchSnapshot(
      matchId: map['matchId']?.toString().trim() ?? '',
      inviteCode: map['inviteCode']?.toString().trim() ?? '',
      status: remoteFriendMatchStatusFromWire(map['status']?.toString()),
      hostUid: map['hostUid']?.toString().trim() ?? '',
      guestUid: _nullableTrimmedString(map['guestUid']),
      whiteUid: _nullableTrimmedString(map['whiteUid']),
      blackUid: _nullableTrimmedString(map['blackUid']),
      fen: map['fen']?.toString().trim() ?? '',
      pgn: map['pgn']?.toString().trim() ?? '',
      nextPly: _intFromDynamic(map['nextPly']),
      whiteToMove: _boolFromDynamic(map['whiteToMove'], fallback: true),
      timeControl: rawTimeControl is Map
          ? RemoteFriendTimeControl.fromMap(
              rawTimeControl.cast<String, dynamic>(),
            )
          : const RemoteFriendTimeControl(
              initialSeconds: 0,
              incrementSeconds: 0,
            ),
      whitePieceThemeIndex: _intFromDynamic(map['whitePieceThemeIndex']),
      blackPieceThemeIndex: _intFromDynamic(map['blackPieceThemeIndex']),
      whiteTimeRemainingMs: _intFromDynamic(
        clockMap['whiteMsRemaining'] ?? map['whiteMsRemaining'],
      ),
      blackTimeRemainingMs: _intFromDynamic(
        clockMap['blackMsRemaining'] ?? map['blackMsRemaining'],
      ),
      lastTickStartedAt: _nullableDateTimeFromDynamic(
        clockMap['lastTickStartedAtMs'] ?? map['lastTickStartedAtMs'],
      ),
      activeClockSeat: remoteFriendSeatFromWire(
        clockMap['activeSeat']?.toString() ??
            map['activeClockSeat']?.toString(),
      ),
      drawOfferByUid: _nullableTrimmedString(map['drawOfferByUid']),
      createdAt: _dateTimeFromDynamic(map['createdAtMs'] ?? map['createdAt']),
      updatedAt: _dateTimeFromDynamic(map['updatedAtMs'] ?? map['updatedAt']),
      startedAt: _nullableDateTimeFromDynamic(
        map['startedAtMs'] ?? map['startedAt'],
      ),
      expiresAt: _nullableDateTimeFromDynamic(
        map['expiresAtMs'] ?? map['expiresAt'],
      ),
      pieceSelectionDeadlineAt: _nullableDateTimeFromDynamic(
        map['pieceSelectionDeadlineMs'],
      ),
      outcome: rawOutcome is Map
          ? RemoteFriendOutcome.fromMap(rawOutcome.cast<String, dynamic>())
          : null,
      reaction: rawReaction is Map
          ? RemoteFriendReaction.fromMap(rawReaction.cast<String, dynamic>())
          : null,
      whiteLastReactionAt: _nullableDateTimeFromDynamic(
        map['whiteLastReactionAtMs'] ?? map['whiteLastReactionAt'],
      ),
      blackLastReactionAt: _nullableDateTimeFromDynamic(
        map['blackLastReactionAtMs'] ?? map['blackLastReactionAt'],
      ),
      moves: _parseRemoteFriendMoves(rawMoves),
    );
  }

  final String matchId;
  final String inviteCode;
  final RemoteFriendMatchStatus status;
  final String hostUid;
  final String? guestUid;
  final String? whiteUid;
  final String? blackUid;
  final String fen;
  final String pgn;
  final int nextPly;
  final bool whiteToMove;
  final RemoteFriendTimeControl timeControl;
  final int whiteTimeRemainingMs;
  final int blackTimeRemainingMs;
  final int whitePieceThemeIndex;
  final int blackPieceThemeIndex;
  final DateTime? lastTickStartedAt;
  final RemoteFriendSeat? activeClockSeat;
  final String? drawOfferByUid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final DateTime? pieceSelectionDeadlineAt;
  final RemoteFriendOutcome? outcome;
  final RemoteFriendReaction? reaction;
  final DateTime? whiteLastReactionAt;
  final DateTime? blackLastReactionAt;
  final List<RemoteFriendMoveRecord> moves;

  bool get hasOpponent => (guestUid ?? '').isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'matchId': matchId,
      'inviteCode': inviteCode,
      'status': status.wireName,
      'hostUid': hostUid,
      'guestUid': guestUid,
      'whiteUid': whiteUid,
      'blackUid': blackUid,
      'fen': fen,
      'pgn': pgn,
      'nextPly': nextPly,
      'whiteToMove': whiteToMove,
      'timeControl': timeControl.toMap(),
      'whitePieceThemeIndex': whitePieceThemeIndex,
      'blackPieceThemeIndex': blackPieceThemeIndex,
      'clocks': <String, dynamic>{
        'whiteMsRemaining': whiteTimeRemainingMs,
        'blackMsRemaining': blackTimeRemainingMs,
        'lastTickStartedAtMs': lastTickStartedAt?.millisecondsSinceEpoch,
        'activeSeat': activeClockSeat?.wireName,
      },
      'drawOfferByUid': drawOfferByUid,
      'createdAtMs': createdAt.millisecondsSinceEpoch,
      'updatedAtMs': updatedAt.millisecondsSinceEpoch,
      'startedAtMs': startedAt?.millisecondsSinceEpoch,
      'expiresAtMs': expiresAt?.millisecondsSinceEpoch,
      'pieceSelectionDeadlineMs':
          pieceSelectionDeadlineAt?.millisecondsSinceEpoch,
      'outcome': outcome?.toMap(),
      'reaction': reaction?.toMap(),
      'whiteLastReactionAtMs': whiteLastReactionAt?.millisecondsSinceEpoch,
      'blackLastReactionAtMs': blackLastReactionAt?.millisecondsSinceEpoch,
      'moves': moves.map((move) => move.toMap()).toList(growable: false),
    };
  }
}

class RemoteFriendInviteSession {
  const RemoteFriendInviteSession({
    required this.invite,
    required this.snapshot,
  });

  factory RemoteFriendInviteSession.fromMap(Map<String, dynamic> map) {
    final inviteMap = map['invite'];
    final snapshotMap = map['snapshot'];
    if (inviteMap is! Map || snapshotMap is! Map) {
      throw StateError(
        'Invite session response is missing invite or snapshot data.',
      );
    }
    return RemoteFriendInviteSession(
      invite: RemoteFriendInvite.fromMap(inviteMap.cast<String, dynamic>()),
      snapshot: RemoteFriendMatchSnapshot.fromMap(
        snapshotMap.cast<String, dynamic>(),
      ),
    );
  }

  final RemoteFriendInvite invite;
  final RemoteFriendMatchSnapshot snapshot;
}

List<RemoteFriendMoveRecord> _parseRemoteFriendMoves(dynamic rawMoves) {
  final moves = <RemoteFriendMoveRecord>[];
  if (rawMoves is List) {
    for (final entry in rawMoves) {
      if (entry is Map) {
        moves.add(
          RemoteFriendMoveRecord.fromMap(entry.cast<String, dynamic>()),
        );
      }
    }
  } else if (rawMoves is Map) {
    for (final entry in rawMoves.values) {
      if (entry is Map) {
        moves.add(
          RemoteFriendMoveRecord.fromMap(entry.cast<String, dynamic>()),
        );
      }
    }
  }
  moves.sort((a, b) => a.ply.compareTo(b.ply));
  return List<RemoteFriendMoveRecord>.unmodifiable(moves);
}

int _intFromDynamic(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

bool _boolFromDynamic(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return fallback;
}

DateTime _dateTimeFromDynamic(dynamic value) {
  return _nullableDateTimeFromDynamic(value) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _nullableDateTimeFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final asInt = int.tryParse(trimmed);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
    return DateTime.tryParse(trimmed);
  }
  return null;
}

String? _nullableTrimmedString(dynamic value) {
  final trimmed = value?.toString().trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
