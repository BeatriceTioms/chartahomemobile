import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Charta Home brand tokens, taken from the SaaS (app/globals.css).
///
/// White surfaces, [ink] (the brand onyx) for text and primary actions, and
/// brand azure ([brand]) as the one accent: filters, selected chips and the
/// money cards. Anything placed on azure is white — never blue on blue.
class AppColors {
  AppColors._();

  static const white = Color(0xFFFFFFFF);
  static const onyx = Color(0xFF020202);
  static const ink = Color(0xFF0B0B0C);
  static const charcoal = Color(0xFF26262A); // top of the dark card gradients
  static const brand = Color(0xFF003152); // azure800

  /// Full-width header gradient (Payments). Its top colour is also used for
  /// the status-bar strip, so the two meet without a seam.
  static const brandHeaderTop = Color(0xFF0E5388);
  static const brandHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [brandHeaderTop, Color(0xFF003152)],
  );

  /// Accent card gradient: lighter azure top-left to deep azure bottom-right.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14639B), Color(0xFF003152), Color(0xFF001A2C)],
  );

  /// Neutral surfaces, lightest to darkest.
  static const mist = Color(0xFFF6F6F6);
  static const cloud = Color(0xFFEEEEEE);
  static const silver = Color(0xFFDCDCDC);

  static const azure950 = Color(0xFF001A2C);
  static const azure900 = Color(0xFF00243C);
  static const azure800 = Color(0xFF003152); // brand
  static const azure700 = Color(0xFF0A4A74);
  static const azure600 = Color(0xFF14639B);
  static const azure100 = Color(0xFFD8ECF7);

  static const soft500 = Color(0xFFADDFE1); // logo wedge
  static const soft400 = Color(0xFFADDFF1);
  static const soft200 = Color(0xFFD6EFFA);
  static const soft100 = Color(0xFFEAF5FB);
  static const soft50 = Color(0xFFF4FAFD);

  /// App background: white with the faintest hint of the brand.
  static const canvas = Color(0xFFF8F8F7);
  static const line = Color(0xFFEBEBEB);
  static const muted = Color(0xFF6E6E73);
  static const faint = Color(0xFFA1A1A6);

  static List<BoxShadow> get softShadow => [
    BoxShadow(color: onyx.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 10)),
  ];

  static List<BoxShadow> get liftShadow => [
    BoxShadow(color: onyx.withValues(alpha: 0.16), blurRadius: 40, spreadRadius: -12, offset: const Offset(0, 18)),
  ];
}

class AppRadius {
  AppRadius._();
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 28.0;
  static const xl = 36.0;
}

class AppTheme {
  AppTheme._();

  /// Lora for display type (the SaaS wordmark and headings), Inter for the rest.
  static TextStyle serif({double size = 28, FontWeight weight = FontWeight.w600, Color color = AppColors.onyx}) =>
      GoogleFonts.lora(fontSize: size, fontWeight: weight, color: color, height: 1.15, letterSpacing: -0.4);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.white,
        secondary: AppColors.ink,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.onyx,
        error: AppColors.ink,
      ),
      splashFactory: InkSparkle.splashFactory,
    );

    final text = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: AppColors.onyx, displayColor: AppColors.onyx);

    return base.copyWith(
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
        headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.6),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: text.bodyMedium?.copyWith(color: AppColors.onyx, height: 1.45),
        bodySmall: text.bodySmall?.copyWith(color: AppColors.muted, height: 1.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.onyx,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.onyx),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: GoogleFonts.inter(color: AppColors.faint, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.line,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
