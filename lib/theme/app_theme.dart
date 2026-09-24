import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Daily Utility — design tokens.
///
/// Two themes (light + dark) are built from a single seed and exposed via
/// `Theme.of(context).colorScheme` / `textTheme`. Code should prefer
/// `colorScheme.onSurface` / `onSurfaceVariant` / `outline` over the
/// `AppColors.text*` constants — those constants are kept only for
/// brand-coloured sections and named gradient presets.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3D5AFE);
  static const Color primaryDeep = Color(0xFF1E2BD0);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFE1493D);
  static const Color warning = Color(0xFFE0A628);

  static const Color todo = Color(0xFF6366F1);
  static const Color notes = Color(0xFFF59E0B);
  static const Color finance = Color(0xFF10B981);
  static const Color bakiKhata = Color(0xFF8B5CF6);
  static const Color loan = Color(0xFFEF4444);
  static const Color calculator = Color(0xFF06B6D4);
  static const Color converter = Color(0xFF22D3EE);
  static const Color shopping = Color(0xFFEC4899);
  static const Color dateTools = Color(0xFF818CF8);
  static const Color reminders = Color(0xFFFBBF24);
  static const Color prayer = Color(0xFF059669);
  static const Color habits = Color(0xFF14B8A6);
  static const Color mood = Color(0xFFF472B6);
  static const Color vault = Color(0xFF0EA5E9);
  static const Color quiz = Color(0xFFA855F7);
  static const Color subscription = Color(0xFFEC4899);
  static const Color subscriptionDeep = Color(0xFFBE185D);
  static const Color post = Color(0xFFE11D48);
  static const Color postDeep = Color(0xFF9F1239);

  static const List<Color> heroGradientLight = [Color(0xFF3D5AFE), Color(0xFF6366F1)];
  static const List<Color> heroGradientDark = [Color(0xFF1E2BD0), Color(0xFF0E1453)];

  // Legacy light-mode defaults. The new theme drives surface/text via
  // `Theme.of(context).colorScheme`; these remain so the rest of the
  // codebase keeps compiling. Widgets that need theme-reactive colours
  // should migrate to colorScheme tokens (preferred) or to `AppTextColors`.
  //
  // `textMuted` / `textDim` are now mid-tone greys picked to remain
  // legible on both light and dark surfaces — they intentionally sit
  // between the two extremes rather than being optimised for light alone.
  static const Color bg = Color(0xFFF7F8FA);
  static const Color bgAlt = Color(0xFFEDF0F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F1F4);
  static const Color text = Color(0xFF1A1B1F);
  static const Color textMuted = Color(0xFF8A8E96);
  static const Color textDim = Color(0xFFA6A9B0);
  static const Color line = Color(0xFFE7E8EC);

  static const List<Color> bgGradientLight = [Color(0xFFF7F8FA), Color(0xFFEDF0F5)];
  static const List<Color> bgGradientDark = [Color(0xFF0F1117), Color(0xFF161922)];

  /// Tinted card gradient (kept for backwards compatibility).
  static List<Color> cardGradient(Color c) => [c.withValues(alpha: 0.10), c.withValues(alpha: 0.02)];

  static const List<Color> successGradient = [Color(0xFF16A34A), Color(0xFF15803D)];
  static const List<Color> dangerGradient = [Color(0xFFE1493D), Color(0xFFB91C1C)];
  static const List<Color> warningGradient = [Color(0xFFE0A628), Color(0xFFCA8A04)];
}

/// Theme-aware muted/dim text colours. Use these instead of the legacy
/// `AppColors.textMuted` / `AppColors.textDim` constants when you have a
/// `BuildContext` available — they switch to readable values in dark mode.
class AppTextColors {
  AppTextColors._();

  /// Secondary body text — readable on the surface in both themes.
  static Color muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;

  /// Disabled / very-low-emphasis text and icons (placeholder outlines etc).
  static Color dim(BuildContext context) => Theme.of(context).colorScheme.outline;
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

class AppAnimations {
  AppAnimations._();
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration counter = Duration(milliseconds: 700);
  static const Curve curve = Curves.easeOutCubic;
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> soft(Color tint) => [BoxShadow(color: tint.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))];
  static List<BoxShadow> elevated(Color tint) => [BoxShadow(color: tint.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 8))];
  static List<BoxShadow> hero(Color tint) => [BoxShadow(color: tint.withValues(alpha: 0.32), blurRadius: 24, offset: const Offset(0, 12))];
}

class AppTheme {
  AppTheme._();

  static const _seed = AppColors.primary;

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFFFFFFF),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF7F8FA),
      surfaceContainer: const Color(0xFFEFF1F5),
      surfaceContainerHigh: const Color(0xFFE7E9EE),
      surfaceContainerHighest: const Color(0xFFDFE2E8),
      onSurface: const Color(0xFF1A1B1F),
      onSurfaceVariant: const Color(0xFF5C6072),
      outline: Colors.transparent,
      outlineVariant: Colors.transparent,
      primary: const Color(0xFF3D5AFE),
      primaryContainer: const Color(0xFFE2E7FF),
      onPrimaryContainer: const Color(0xFF141B6B),
    );
    return _build(base, brightness: Brightness.light);
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF15171C),
      surfaceContainerLowest: const Color(0xFF101218),
      surfaceContainerLow: const Color(0xFF1B1E24),
      surfaceContainer: const Color(0xFF222630),
      surfaceContainerHigh: const Color(0xFF2A2E38),
      surfaceContainerHighest: const Color(0xFF333843),
      onSurface: const Color(0xFFF1F2F5),
      onSurfaceVariant: const Color(0xFFC2C6D2),
      outline: Colors.transparent,
      outlineVariant: Colors.transparent,
      primary: const Color(0xFF8A98FF),
      primaryContainer: const Color(0xFF2A3480),
      onPrimaryContainer: const Color(0xFFD8DEFF),
    );
    return _build(base, brightness: Brightness.dark);
  }

  static ThemeData _build(ColorScheme scheme, {required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final onSurface = scheme.onSurface;
    final onSurfaceVariant = scheme.onSurfaceVariant;

    final textTheme = TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -1.0, height: 1.1),
      displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -0.8, height: 1.15),
      displaySmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -0.6, height: 1.2),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -0.4, height: 1.2),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: onSurface, letterSpacing: -0.3, height: 1.25),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: onSurface, letterSpacing: -0.2, height: 1.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: onSurface, letterSpacing: -0.1, height: 1.3),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: onSurface, letterSpacing: -0.1, height: 1.35),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: onSurface, height: 1.35),
      bodyLarge: TextStyle(fontSize: 15.5, color: onSurface, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, color: onSurface, height: 1.45),
      bodySmall: TextStyle(fontSize: 12.5, color: onSurfaceVariant, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: onSurface, height: 1.3),
      labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: onSurfaceVariant, height: 1.3, letterSpacing: 0.2),
      labelSmall: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: onSurfaceVariant, height: 1.3, letterSpacing: 0.4),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      fontFamily: 'Roboto',
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: onSurface, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainer : scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: onSurfaceVariant, fontSize: 14),
        labelStyle: TextStyle(color: onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          side: BorderSide.none,
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm + 20)),
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface),
        secondaryLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(color: Colors.transparent, thickness: 0, space: 0),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? scheme.primary : onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? scheme.primary : onSurfaceVariant, size: 24);
        }),
        height: 68,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide.none,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          side: BorderSide.none,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        dividerColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      iconTheme: IconThemeData(color: onSurface),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? scheme.primaryContainer : scheme.surfaceContainerHigh),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
