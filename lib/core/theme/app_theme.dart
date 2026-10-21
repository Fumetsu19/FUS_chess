import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _darkBg = Color(0xFF121315);
  static const _darkSurface = Color(0xFF1A1B1E);
  static const _darkSurfaceHigh = Color(0xFF25262A);
  static const _darkText = Color(0xFFF4F0E8);
  static const _darkMuted = Color(0xFFABA69C);
  static const _amber = Color(0xFFE8A45B);
  static const _amberDeep = Color(0xFFA85F27);

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: _darkBg,
        surface: _darkSurface,
        surfaceHigh: _darkSurfaceHigh,
        text: _darkText,
        muted: _darkMuted,
        primary: _amber,
        onPrimary: const Color(0xFF24180A),
        primaryContainer: const Color(0xFF3B2A17),
        secondary: const Color(0xFFA8B58F),
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: const Color(0xFFF5F1E8),
        surface: const Color(0xFFFDFBF6),
        surfaceHigh: const Color(0xFFEAE3D6),
        text: const Color(0xFF1E1C18),
        muted: const Color(0xFF6E685F),
        primary: _amberDeep,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFF3DFC8),
        secondary: const Color(0xFF617252),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceHigh,
    required Color text,
    required Color muted,
    required Color primary,
    required Color onPrimary,
    required Color primaryContainer,
    required Color secondary,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: text,
      secondary: secondary,
      onSecondary: brightness == Brightness.dark
          ? const Color(0xFF17200F)
          : Colors.white,
      secondaryContainer: surfaceHigh,
      onSecondaryContainer: text,
      tertiary: const Color(0xFFC77D6B),
      onTertiary: Colors.white,
      error: const Color(0xFFE06C63),
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceHigh,
      onSurfaceVariant: muted,
      outline: brightness == Brightness.dark
          ? const Color(0xFF3C3A36)
          : const Color(0xFFD2C9BA),
      outlineVariant: brightness == Brightness.dark
          ? const Color(0xFF2B2A27)
          : const Color(0xFFE4DCCE),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: text,
      onInverseSurface: background,
      inversePrimary: primary,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontSize: 44,
        height: 1.02,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.6,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        fontSize: 36,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontSize: 30,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.55,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14.5,
        height: 1.5,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 12.5,
        height: 1.4,
        color: muted,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: text),
        iconTheme: IconThemeData(color: text, size: 22),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: text,
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        hintStyle: TextStyle(color: muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh,
        contentTextStyle: TextStyle(color: text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceHigh,
      ),
    );
  }

  static BoardTheme boardTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return BoardTheme(
      lightSquareColor:
          dark ? const Color(0xFFE6DECD) : const Color(0xFFF0E5CF),
      darkSquareColor:
          dark ? const Color(0xFF8C8272) : const Color(0xFFB58D68),
      selectionColor: const Color(0x80E8A45B),
      lastMoveHighlightColor: const Color(0x55E8A45B),
      legalDestinationColor: const Color(0x4D1A1B1E),
      coordinateLabelColor: dark ? const Color(0xFF4E483E) : null,
      kingCheckmateColor: const Color(0x99D65B4A),
      kingCheckColor: const Color(0x55D65B4A),
      hintArrowColor: const Color(0xCCE8A45B),
      dragLegalRingColor: const Color(0xCCF4F0E8),
      dragIllegalTintColor: const Color(0x33D65B4A),
    );
  }
}

class AppSpacing {
  const AppSpacing._();

  static const page = EdgeInsets.fromLTRB(20, 8, 20, 28);
  static const gap = SizedBox(height: 16);
  static const smallGap = SizedBox(height: 8);
}
