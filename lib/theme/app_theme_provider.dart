import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeStyle { standard, monochrome }

class AppBoardPalette {
  final Color darkSquare;
  final Color lightSquare;

  const AppBoardPalette({required this.darkSquare, required this.lightSquare});
}

class AppThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode_v1';
  static const String _themeStyleKey = 'app_theme_style_v1';
  static const String _savedDefaultSnapshotKey = 'saved_default_snapshot_v1';
  static const String _legacyCinematicThemeKey = 'cinematic_theme_enabled_v1';

  ThemeMode _themeMode = ThemeMode.dark;
  AppThemeStyle _themeStyle = AppThemeStyle.standard;
  int _boardThemeIndex = 0;
  int _pieceThemeIndex = 0;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  AppThemeStyle get themeStyle => _themeStyle;
  int get boardThemeIndex => _boardThemeIndex;
  int get pieceThemeIndex => _pieceThemeIndex;
  bool get isLoaded => _loaded;
  bool get isMonochrome => _themeStyle == AppThemeStyle.monochrome;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themeModeKey);
    final savedThemeStyle = prefs.getString(_themeStyleKey);
    final rawSnapshot = prefs.getString(_savedDefaultSnapshotKey);
    final legacyCinematic = prefs.getBool(_legacyCinematicThemeKey) ?? false;

    _themeMode = switch (savedThemeMode) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };

    _themeStyle =
        savedThemeStyle == 'monochrome' ||
            (savedThemeStyle == null && legacyCinematic)
        ? AppThemeStyle.monochrome
        : AppThemeStyle.standard;

    if (rawSnapshot != null && rawSnapshot.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSnapshot);
        if (decoded is Map<String, dynamic>) {
          final boardTheme = decoded['boardTheme'];
          final pieceTheme = decoded['pieceTheme'];
          if (boardTheme is int) {
            _boardThemeIndex = boardTheme.clamp(0, 4);
          }
          if (pieceTheme is int) {
            _pieceThemeIndex = pieceTheme.clamp(0, 2);
          }
        }
      } catch (_) {}
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (_themeMode == value) return;
    _themeMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value.name);
    notifyListeners();
  }

  Future<void> setThemeStyle(AppThemeStyle value) async {
    final changed = _themeStyle != value;
    _themeStyle = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeStyleKey,
      value == AppThemeStyle.monochrome ? 'monochrome' : 'standard',
    );
    await prefs.setBool(
      _legacyCinematicThemeKey,
      value == AppThemeStyle.monochrome,
    );
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> setBoardThemeIndex(int value) async {
    _boardThemeIndex = value.clamp(0, 4);
    await _persistSnapshotThemeIndices();
    notifyListeners();
  }

  Future<void> setPieceThemeIndex(int value) async {
    _pieceThemeIndex = value.clamp(0, 2);
    await _persistSnapshotThemeIndices();
    notifyListeners();
  }

  Future<void> syncLegacySettings({
    bool? cinematicEnabled,
    int? boardThemeIndex,
    int? pieceThemeIndex,
    bool notify = true,
  }) async {
    var changed = false;
    if (cinematicEnabled != null) {
      final nextStyle = cinematicEnabled
          ? AppThemeStyle.monochrome
          : AppThemeStyle.standard;
      if (_themeStyle != nextStyle) {
        _themeStyle = nextStyle;
        changed = true;
      }
    }
    if (boardThemeIndex != null && _boardThemeIndex != boardThemeIndex) {
      _boardThemeIndex = boardThemeIndex.clamp(0, 4);
      changed = true;
    }
    if (pieceThemeIndex != null && _pieceThemeIndex != pieceThemeIndex) {
      _pieceThemeIndex = pieceThemeIndex.clamp(0, 2);
      changed = true;
    }
    if (!changed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeStyleKey,
      _themeStyle == AppThemeStyle.monochrome ? 'monochrome' : 'standard',
    );
    await prefs.setBool(
      _legacyCinematicThemeKey,
      _themeStyle == AppThemeStyle.monochrome,
    );
    await _persistSnapshotThemeIndices();
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _persistSnapshotThemeIndices() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSnapshot = prefs.getString(_savedDefaultSnapshotKey);
    if (rawSnapshot == null || rawSnapshot.isEmpty) return;
    try {
      final decoded = jsonDecode(rawSnapshot);
      if (decoded is! Map<String, dynamic>) return;
      decoded['boardTheme'] = _boardThemeIndex;
      decoded['pieceTheme'] = _pieceThemeIndex;
      await prefs.setString(_savedDefaultSnapshotKey, jsonEncode(decoded));
    } catch (_) {}
  }

  ThemeData buildTheme(Brightness brightness) {
    final isDark = switch (_themeMode) {
      ThemeMode.light => false,
      ThemeMode.dark => true,
      ThemeMode.system => brightness == Brightness.dark,
    };

    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final isMono = isMonochrome;

    final scaffold = isMono
        ? (isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5))
        : (isDark ? const Color(0xFF090B12) : const Color(0xFFF4F7FB));
    final surface = isMono
        ? (isDark ? const Color(0xFF171717) : const Color(0xFFFFFFFF))
        : (isDark ? const Color(0xFF10131D) : const Color(0xFFFFFFFF));
    final appBar = isMono
        ? (isDark ? const Color(0xFF101010) : const Color(0xFFEDEDED))
        : (isDark ? const Color(0xFF0E111A) : const Color(0xFFEFF3F9));
    final primary = isMono ? const Color(0xFF808080) : const Color(0xFFB9A46A);
    final secondary = isMono
        ? const Color(0xFFA6A6A6)
        : const Color(0xFF3F6ED8);
    final tertiary = isMono ? const Color(0xFF5E5E5E) : const Color(0xFF5CCB8A);
    final onSurface = isDark
        ? const Color(0xFFEDEEF1)
        : const Color(0xFF111318);
    final onPrimary = isMono
        ? (isDark ? const Color(0xFF101010) : Colors.white)
        : (isDark ? const Color(0xFF111318) : Colors.white);
    final buttonShadowColor = isDark
        ? primary.withValues(alpha: 0.36)
        : Colors.black.withValues(alpha: 0.22);

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          headlineSmall: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w400,
            color: onSurface,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w300,
            color: onSurface.withValues(alpha: 0.74),
          ),
        );

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      cardColor: surface,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        onSurface: onSurface,
        onPrimary: onPrimary,
        surfaceTint: primary.withValues(alpha: isDark ? 0.10 : 0.08),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 6 : 2,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.34)
            : Colors.black.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: onSurface,
        elevation: 0,
      ),
      iconTheme: IconThemeData(
        color: isMono
            ? onSurface.withValues(alpha: isDark ? 0.88 : 0.76)
            : (isDark ? const Color(0xFFC7CBD6) : const Color(0xFF333844)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: isDark ? 8 : 3,
          shadowColor: buttonShadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  AppBoardPalette boardPalette() {
    return switch (_boardThemeIndex) {
      1 => const AppBoardPalette(
        darkSquare: Color(0xFFB58863),
        lightSquare: Color(0xFFF0D9B5),
      ),
      2 => const AppBoardPalette(
        darkSquare: Color(0xFF1A1A1A),
        lightSquare: Color(0xFFF0F0F0),
      ),
      3 => const AppBoardPalette(
        darkSquare: Color(0xFF6B2D1A),
        lightSquare: Color(0xFFF2C08D),
      ),
      4 => const AppBoardPalette(
        darkSquare: Color(0xFF1E5F74),
        lightSquare: Color(0xFFBFE6D8),
      ),
      _ => const AppBoardPalette(
        darkSquare: Color(0xFF2C3E50),
        lightSquare: Color(0xFF95A5A6),
      ),
    };
  }

  Color pieceTintColor(String piece) {
    final isWhitePiece = piece.endsWith('_w');
    return switch (_pieceThemeIndex) {
      1 => isWhitePiece ? const Color(0xFFFFD38A) : const Color(0xFF8B3A1B),
      2 => isWhitePiece ? const Color(0xFFDDF7FF) : const Color(0xFF4D6F94),
      _ => Colors.white,
    };
  }

  bool get useClassicPieces => _pieceThemeIndex == 0;
}
