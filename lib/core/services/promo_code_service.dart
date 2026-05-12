import 'dart:convert';

import 'package:chessiq/core/services/firebase_auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum PromoCodeErrorType {
  invalidCode,
  notFound,
  alreadyRedeemed,
  inactive,
  expired,
  exhausted,
  unauthenticated,
  unavailable,
  invalidConfig,
  unknown,
}

class PromoCodeException implements Exception {
  const PromoCodeException({required this.type, required this.message});

  final PromoCodeErrorType type;
  final String message;

  @override
  String toString() => message;
}

class PromoCodeRedemptionResult {
  const PromoCodeRedemptionResult({
    required this.code,
    required this.coinAmount,
    required this.unlockKey,
    required this.claimedAt,
  });

  final String code;
  final int coinAmount;
  final String? unlockKey;
  final DateTime claimedAt;
}

class PromoCodeService {
  PromoCodeService._();

  static final PromoCodeService instance = PromoCodeService._();

  static const String _redeemPromoCodeFunction = 'redeemPromoCode';
  static const String _cfBase =
      'https://us-central1-chessiq-89b45.cloudfunctions.net';

  String? _lastError;

  String? get lastError => _lastError;

  Future<PromoCodeRedemptionResult> redeemCode(String rawCode) async {
    final normalizedCode = rawCode.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedCode.isEmpty) {
      throw const PromoCodeException(
        type: PromoCodeErrorType.invalidCode,
        message: 'Enter a promo code before redeeming.',
      );
    }

    final result = await _callFunction(_redeemPromoCodeFunction, {
      'code': normalizedCode,
    });

    final reward = result['reward'];
    if (reward is! Map<String, dynamic>) {
      throw const PromoCodeException(
        type: PromoCodeErrorType.invalidConfig,
        message: 'This promo code is not set up correctly yet.',
      );
    }

    final code = result['code']?.toString().trim() ?? normalizedCode;
    final coinAmount = (reward['coinAmount'] as num?)?.toInt() ?? 0;
    final unlockKey = reward['unlockKey']?.toString().trim();
    final claimedAtRaw = result['claimedAt']?.toString().trim() ?? '';
    final claimedAt = DateTime.tryParse(claimedAtRaw);
    if (claimedAt == null) {
      throw const PromoCodeException(
        type: PromoCodeErrorType.invalidConfig,
        message: 'This promo code is not set up correctly yet.',
      );
    }

    return PromoCodeRedemptionResult(
      code: code,
      coinAmount: coinAmount,
      unlockKey: unlockKey == null || unlockKey.isEmpty ? null : unlockKey,
      claimedAt: claimedAt,
    );
  }

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    _lastError = null;

    final token = await FirebaseAuthService.instance.getIdToken();
    if (token == null || token.isEmpty) {
      final authError = FirebaseAuthService.instance.lastError;
      final message = authError != null && authError.isNotEmpty
          ? 'Promo codes need a valid sign-in. $authError'
          : 'Promo codes need a valid sign-in. Reopen the app and try again.';
      _lastError = message;
      throw PromoCodeException(
        type: PromoCodeErrorType.unauthenticated,
        message: message,
      );
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$_cfBase/$name');
    debugPrint('[PromoCodeService] Calling Cloud Function: $uri');

    try {
      final bodyPayload = jsonEncode({'data': data});
      http.Response? response;
      Object? lastTimeoutError;

      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          response = await http
              .post(uri, headers: headers, body: bodyPayload)
              .timeout(
                const Duration(seconds: 20),
                onTimeout: () {
                  throw Exception('Cloud Function request timed out');
                },
              );
          break;
        } catch (error) {
          if (error.toString().toLowerCase().contains('timed out') &&
              attempt == 0) {
            lastTimeoutError = error;
            continue;
          }
          rethrow;
        }
      }

      if (response == null) {
        throw lastTimeoutError ?? Exception('Cloud Function request timed out');
      }

      Map<String, dynamic> body = const <String, dynamic>{};
      final trimmedBody = response.body.trim();
      final contentType = response.headers['content-type'] ?? '';
      final looksLikeJson =
          trimmedBody.startsWith('{') || trimmedBody.startsWith('[');

      if (trimmedBody.isNotEmpty && looksLikeJson) {
        final decoded = jsonDecode(trimmedBody);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      }

      if (response.statusCode != 200) {
        final error = body['error'];
        final message = error is Map<String, dynamic>
            ? (error['message']?.toString().trim() ?? '')
            : '';
        final fallbackMessage = _fallbackHttpMessage(
          statusCode: response.statusCode,
          contentType: contentType,
          body: trimmedBody,
        );
        final resolvedMessage = message.isNotEmpty ? message : fallbackMessage;
        _lastError = resolvedMessage;
        throw _mapException(resolvedMessage);
      }

      if (trimmedBody.isNotEmpty && !looksLikeJson) {
        final message = contentType.contains('text/html')
            ? 'Promo code service is unavailable right now.'
            : 'Could not redeem promo code right now.';
        _lastError = message;
        throw _mapException(message);
      }

      return (body['result'] as Map<String, dynamic>?) ?? const {};
    } on PromoCodeException {
      rethrow;
    } catch (error) {
      final message = error.toString();
      _lastError ??= message;
      debugPrint('[PromoCodeService] Exception: $error');
      throw _mapException(message);
    }
  }

  String _fallbackHttpMessage({
    required int statusCode,
    required String contentType,
    required String body,
  }) {
    if (statusCode == 404) {
      return 'Promo code service is not live yet. Try again shortly.';
    }
    if (contentType.contains('text/html')) {
      return 'Promo code service is unavailable right now.';
    }
    return 'Could not redeem promo code right now.';
  }

  PromoCodeException _mapException(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('already been redeemed') ||
        normalized.contains('already used on this account')) {
      return const PromoCodeException(
        type: PromoCodeErrorType.alreadyRedeemed,
        message: 'Promo code already used on this account.',
      );
    }
    if (normalized.contains('not active') || normalized.contains('inactive')) {
      return const PromoCodeException(
        type: PromoCodeErrorType.inactive,
        message: 'This promo code is inactive.',
      );
    }
    if (normalized.contains('expired')) {
      return const PromoCodeException(
        type: PromoCodeErrorType.expired,
        message: 'This promo code has expired.',
      );
    }
    if (normalized.contains('no remaining redemptions') ||
        normalized.contains('no uses left')) {
      return const PromoCodeException(
        type: PromoCodeErrorType.exhausted,
        message: 'This promo code has no uses left.',
      );
    }
    if (normalized.contains('incorrect promo code') ||
        normalized.contains('promo code was not found')) {
      return const PromoCodeException(
        type: PromoCodeErrorType.notFound,
        message: 'Incorrect promo code.',
      );
    }
    if (normalized.contains('valid sign-in') ||
        normalized.contains('authentication required')) {
      return const PromoCodeException(
        type: PromoCodeErrorType.unauthenticated,
        message:
            'Promo codes need a valid sign-in. Reopen the app and try again.',
      );
    }
    if (normalized.contains('service is not live yet') ||
        normalized.contains('returned html (404)') ||
        normalized.contains('cloud function error 404')) {
      return const PromoCodeException(
        type: PromoCodeErrorType.unavailable,
        message: 'Promo code service is not live yet. Try again shortly.',
      );
    }
    if (normalized.contains('configuration is invalid') ||
        normalized.contains('reward data is incomplete') ||
        normalized.contains('timestamp is invalid') ||
        normalized.contains('not set up correctly')) {
      return const PromoCodeException(
        type: PromoCodeErrorType.invalidConfig,
        message: 'This promo code is not set up correctly yet.',
      );
    }
    if (normalized.contains('timed out') ||
        normalized.contains('returned html') ||
        normalized.contains('non-json response') ||
        normalized.contains('cloud function error') ||
        normalized.contains('service is unavailable')) {
      return const PromoCodeException(
        type: PromoCodeErrorType.unavailable,
        message: 'Could not reach promo code service right now.',
      );
    }

    return const PromoCodeException(
      type: PromoCodeErrorType.unknown,
      message: 'Could not redeem promo code right now.',
    );
  }
}
