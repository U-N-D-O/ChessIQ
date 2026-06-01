import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

bool get _supportsRemoteFriendInviteLinks =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class RemoteFriendInviteLinkService {
  RemoteFriendInviteLinkService._();

  static final RemoteFriendInviteLinkService instance =
      RemoteFriendInviteLinkService._();

  static const String scheme = 'chessiq';
  static const String host = 'invite';
  static const String inviteCodeParameter = 'code';
  static final RegExp _inviteCodePattern = RegExp(r'^[A-Z0-9]{6}$');

  final StreamController<String> _inviteCodeController =
      StreamController<String>.broadcast();

  Future<void>? _initializeFuture;
  String? _pendingInviteCode;

  Stream<String> get inviteCodes => _inviteCodeController.stream;

  Future<void> initialize() async {
    if (!_supportsRemoteFriendInviteLinks) {
      return;
    }

    return _initializeFuture ??= _initializeInternal();
  }

  Uri buildInviteUri(String inviteCode) {
    final normalized = normalizeInviteCode(inviteCode);
    if (normalized == null) {
      throw ArgumentError.value(
        inviteCode,
        'inviteCode',
        'Remote friend invites require a 6-character code.',
      );
    }

    return Uri(
      scheme: scheme,
      host: host,
      queryParameters: <String, String>{inviteCodeParameter: normalized},
    );
  }

  String? takePendingInviteCode() {
    final pendingInviteCode = _pendingInviteCode;
    _pendingInviteCode = null;
    return pendingInviteCode;
  }

  static String? normalizeInviteCode(String? inviteCode) {
    final normalized = inviteCode?.trim().toUpperCase();
    if (normalized == null || !_inviteCodePattern.hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  Future<void> _initializeInternal() async {
    final appLinks = AppLinks();

    try {
      final initialLink = await appLinks.getInitialLink();
      _queueInviteCode(_inviteCodeFromUri(initialLink));
    } catch (error, stackTrace) {
      debugPrint(
        '[RemoteFriendInviteLinkService] Initial invite link lookup failed: '
        '$error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }

    appLinks.uriLinkStream.listen(
      (uri) {
        _queueInviteCode(_inviteCodeFromUri(uri));
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          '[RemoteFriendInviteLinkService] Invite link stream failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      },
    );
  }

  String? _inviteCodeFromUri(Uri? uri) {
    if (uri == null) {
      return null;
    }
    if (uri.scheme.toLowerCase() != scheme || uri.host.toLowerCase() != host) {
      return null;
    }
    return normalizeInviteCode(uri.queryParameters[inviteCodeParameter]);
  }

  void _queueInviteCode(String? inviteCode) {
    final normalized = normalizeInviteCode(inviteCode);
    if (normalized == null) {
      return;
    }

    _pendingInviteCode = normalized;
    if (!_inviteCodeController.isClosed) {
      _inviteCodeController.add(normalized);
    }
  }
}