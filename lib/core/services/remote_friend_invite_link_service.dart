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

  static const String appScheme = 'chessiq';
  static const String appHost = 'invite';
  static const String hostedScheme = 'https';
  static const String hostedHost = 'modus.qila.gl';
  static const List<String> hostedPathSegments = <String>['ChessIQ', 'invite'];
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
      scheme: hostedScheme,
      host: hostedHost,
      pathSegments: hostedPathSegments,
      queryParameters: <String, String>{inviteCodeParameter: normalized},
    );
  }

  Uri buildAppInviteUri(String inviteCode) {
    final normalized = normalizeInviteCode(inviteCode);
    if (normalized == null) {
      throw ArgumentError.value(
        inviteCode,
        'inviteCode',
        'Remote friend invites require a 6-character code.',
      );
    }

    return Uri(
      scheme: appScheme,
      host: appHost,
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
    final normalizedScheme = uri.scheme.toLowerCase();
    final normalizedHost = uri.host.toLowerCase();
    final normalizedPathSegments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .map((segment) => segment.toLowerCase())
        .toList(growable: false);

    final matchesCustomScheme =
        normalizedScheme == appScheme && normalizedHost == appHost;
    final matchesHostedInvite =
        normalizedScheme == hostedScheme &&
        normalizedHost == hostedHost &&
        normalizedPathSegments.length == hostedPathSegments.length &&
        _pathSegmentsMatch(normalizedPathSegments, hostedPathSegments);

    if (!matchesCustomScheme && !matchesHostedInvite) {
      return null;
    }
    return normalizeInviteCode(uri.queryParameters[inviteCodeParameter]);
  }

  bool _pathSegmentsMatch(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (int index = 0; index < left.length; index += 1) {
      if (left[index].toLowerCase() != right[index].toLowerCase()) {
        return false;
      }
    }
    return true;
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
