import 'dart:convert';

import 'package:chessiq/core/services/firebase_auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum EconomyRewardKey {
  analysisInterstitial,
  academyInterstitial,
  academyExamBonus,
  academyDailyPuzzle,
  academyRewardedAd,
  academyDailyChallenge,
  purchaseCoinPackS,
  purchaseCoinPackL,
}

extension on EconomyRewardKey {
  String get wireName {
    switch (this) {
      case EconomyRewardKey.analysisInterstitial:
        return 'analysisInterstitial';
      case EconomyRewardKey.academyInterstitial:
        return 'academyInterstitial';
      case EconomyRewardKey.academyExamBonus:
        return 'academyExamBonus';
      case EconomyRewardKey.academyDailyPuzzle:
        return 'academyDailyPuzzle';
      case EconomyRewardKey.academyRewardedAd:
        return 'academyRewardedAd';
      case EconomyRewardKey.academyDailyChallenge:
        return 'academyDailyChallenge';
      case EconomyRewardKey.purchaseCoinPackS:
        return 'purchaseCoinPackS';
      case EconomyRewardKey.purchaseCoinPackL:
        return 'purchaseCoinPackL';
    }
  }
}

class EconomySnapshot {
  const EconomySnapshot({
    required this.coins,
    required this.lastStoreRewardAdAt,
    required this.watchCountToday,
    required this.lastWatchDay,
  });

  final int coins;
  final DateTime? lastStoreRewardAdAt;
  final int watchCountToday;
  final String lastWatchDay;
}

class EconomyMutationResult {
  const EconomyMutationResult({
    required this.success,
    required this.snapshot,
    this.reason,
    this.remainingCooldown = Duration.zero,
  });

  final bool success;
  final EconomySnapshot snapshot;
  final String? reason;
  final Duration remainingCooldown;
}

class EconomyRemoteService {
  EconomyRemoteService._();

  static final EconomyRemoteService instance = EconomyRemoteService._();

  static const String _cfBase =
      'https://us-central1-chessiq-89b45.cloudfunctions.net';
  static const String _getEconomyStateFunction = 'getEconomyState';
  static const String _claimStoreRewardAdFunction = 'claimStoreRewardAd';
  static const String _spendCoinsFunction = 'spendEconomyCoins';
  static const String _grantRewardFunction = 'grantEconomyReward';

  Future<EconomySnapshot> fetchState({int? migrationCoins}) async {
    final data = <String, dynamic>{};
    if (migrationCoins != null) {
      data['migrationCoins'] = migrationCoins;
    }
    final result = await _callFunction(_getEconomyStateFunction, data);
    return _parseSnapshot(result);
  }

  Future<EconomyMutationResult> claimStoreRewardAd() async {
    final result = await _callFunction(
      _claimStoreRewardAdFunction,
      const <String, dynamic>{},
    );
    return _parseMutationResult(result);
  }

  Future<EconomyMutationResult> spendCoins(int amount) async {
    final result = await _callFunction(_spendCoinsFunction, {'amount': amount});
    return _parseMutationResult(result);
  }

  Future<EconomyMutationResult> grantReward(
    EconomyRewardKey rewardKey, {
    String? claimKey,
    String? fingerprint,
  }) async {
    final data = <String, dynamic>{'rewardKey': rewardKey.wireName};
    if (claimKey != null && claimKey.trim().isNotEmpty) {
      data['claimKey'] = claimKey.trim();
    }
    if (fingerprint != null && fingerprint.trim().isNotEmpty) {
      data['fingerprint'] = fingerprint.trim();
    }
    final result = await _callFunction(_grantRewardFunction, data);
    return _parseMutationResult(result);
  }

  EconomySnapshot _parseSnapshot(Map<String, dynamic> result) {
    final state = result['state'];
    if (state is! Map<String, dynamic>) {
      throw StateError('Economy response did not include a state payload.');
    }
    final storeReward = state['storeReward'];
    final storeRewardMap = storeReward is Map<String, dynamic>
        ? storeReward
        : const <String, dynamic>{};
    final lastClaimAtMs = (storeRewardMap['lastClaimAtMs'] as num?)?.toInt();
    return EconomySnapshot(
      coins: (state['coins'] as num?)?.toInt() ?? 0,
      lastStoreRewardAdAt: lastClaimAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastClaimAtMs),
      watchCountToday:
          (storeRewardMap['watchCountToday'] as num?)?.toInt() ?? 0,
      lastWatchDay: storeRewardMap['dayKey']?.toString().trim() ?? '',
    );
  }

  EconomyMutationResult _parseMutationResult(Map<String, dynamic> result) {
    final remainingMs = (result['remainingMs'] as num?)?.toInt() ?? 0;
    return EconomyMutationResult(
      success: result['success'] != false,
      snapshot: _parseSnapshot(result),
      reason: result['reason']?.toString().trim(),
      remainingCooldown: Duration(milliseconds: remainingMs.clamp(0, 1 << 31)),
    );
  }

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    await FirebaseAuthService.instance.initialize();

    final token = await FirebaseAuthService.instance.getIdToken();
    if (token == null || token.isEmpty) {
      final authError = FirebaseAuthService.instance.lastError;
      final message = authError != null && authError.isNotEmpty
          ? 'Economy sync needs a valid sign-in. $authError'
          : 'Economy sync needs a valid sign-in. Reopen the app and try again.';
      throw Exception(message);
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('$_cfBase/$name');
    debugPrint('[EconomyRemoteService] Calling Cloud Function: $uri');

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
        throw Exception(
          message.isNotEmpty
              ? message
              : 'Economy service returned ${response.statusCode}.',
        );
      }

      return (body['result'] as Map<String, dynamic>?) ?? const {};
    } catch (error) {
      debugPrint('[EconomyRemoteService] Exception: $error');
      rethrow;
    }
  }
}
