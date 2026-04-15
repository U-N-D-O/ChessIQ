import 'dart:convert';

class SignedMapResult {
  const SignedMapResult({
    required this.data,
    required this.isSigned,
    required this.isValid,
  });

  final Map<String, dynamic>? data;
  final bool isSigned;
  final bool isValid;
}

class LocalIntegrityService {
  LocalIntegrityService._();

  static const int _envelopeVersion = 1;
  static const String _pepper = 'ChessIQ::LocalIntegrity::v1::2026-04';

  static String wrapJson(Map<String, dynamic> data, {required String scope}) {
    return jsonEncode(<String, dynamic>{
      'v': _envelopeVersion,
      'data': data,
      'sig': _signatureFor(data, scope: scope),
    });
  }

  static SignedMapResult decodeJson(String? raw, {required String scope}) {
    if (raw == null || raw.trim().isEmpty) {
      return const SignedMapResult(data: null, isSigned: false, isValid: false);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const SignedMapResult(
          data: null,
          isSigned: false,
          isValid: false,
        );
      }

      final map = decoded.map((key, value) => MapEntry(key.toString(), value));
      final data = map['data'];
      final sig = map['sig'];
      final version = map['v'];

      if (version == _envelopeVersion && data is Map && sig is String) {
        final payload = data.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final valid = _signatureFor(payload, scope: scope) == sig;
        return SignedMapResult(data: payload, isSigned: true, isValid: valid);
      }

      return SignedMapResult(data: map, isSigned: false, isValid: true);
    } catch (_) {
      return const SignedMapResult(data: null, isSigned: false, isValid: false);
    }
  }

  static String _signatureFor(
    Map<String, dynamic> data, {
    required String scope,
  }) {
    final canonical = _canonicalize(data);
    final input = '$scope|$_pepper|$canonical';
    var hash = 0x811C9DC5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _canonicalize(Object? value) {
    if (value == null) return 'null';
    if (value is bool || value is num) return value.toString();
    if (value is String) return jsonEncode(value);
    if (value is List) {
      return '[${value.map(_canonicalize).join(',')}]';
    }
    if (value is Map) {
      final entries =
          value.entries
              .map((entry) => MapEntry(entry.key.toString(), entry.value))
              .toList(growable: false)
            ..sort((a, b) => a.key.compareTo(b.key));
      final parts = entries
          .map(
            (entry) => '${jsonEncode(entry.key)}:${_canonicalize(entry.value)}',
          )
          .join(',');
      return '{$parts}';
    }
    return jsonEncode(value.toString());
  }
}
