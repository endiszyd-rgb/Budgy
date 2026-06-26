import 'package:flutter/material.dart';

/// Surowe tokeny kolorów — paleta slate (neutralne) / indigo (marka).
class AppPalette {
  AppPalette._();

  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo300 = Color(0xFFA5B4FC);
  static const indigo400 = Color(0xFF818CF8);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo700 = Color(0xFF4338CA);

  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF020617);

  static const emerald400 = Color(0xFF34D399);
  static const emerald600 = Color(0xFF059669);
  static const rose400 = Color(0xFFFB7185);
  static const rose600 = Color(0xFFE11D48);
  static const amber400 = Color(0xFFFBBF24);
  static const amber600 = Color(0xFFD97706);
}

class AppTheme {
  AppTheme._();

  static const Color primary = AppPalette.indigo600;
  static const Color incomeColor = AppPalette.emerald600;
  static const Color expenseColor = AppPalette.rose600;
  static const Color pendingColor = AppPalette.amber600;

  static ThemeData get theme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = isDark
        ? const ColorScheme.dark(
            brightness: Brightness.dark,
            primary: AppPalette.indigo400,
            onPrimary: AppPalette.slate950,
            primaryContainer: AppPalette.indigo700,
            onPrimaryContainer: AppPalette.indigo300,
            secondary: AppPalette.indigo300,
            onSecondary: AppPalette.slate950,
            surface: AppPalette.slate900,
            onSurface: AppPalette.slate100,
            surfaceContainerHighest: AppPalette.slate800,
            onSurfaceVariant: AppPalette.slate400,
            outline: AppPalette.slate700,
            outlineVariant: AppPalette.slate800,
            error: AppPalette.rose400,
            onError: AppPalette.slate950,
          )
        : const ColorScheme.light(
            brightness: Brightness.light,
            primary: AppPalette.indigo600,
            onPrimary: Colors.white,
            primaryContainer: AppPalette.indigo100,
            onPrimaryContainer: AppPalette.indigo700,
            secondary: AppPalette.indigo500,
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: AppPalette.slate900,
            surfaceContainerHighest: AppPalette.slate100,
            onSurfaceVariant: AppPalette.slate500,
            outline: AppPalette.slate200,
            outlineVariant: AppPalette.slate100,
            error: AppPalette.rose600,
            onError: Colors.white,
          );

    final onSurfaceMuted = isDark ? AppPalette.slate400 : AppPalette.slate500;
    final dividerColor = isDark ? AppPalette.slate800 : AppPalette.slate200;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppPalette.slate950
          : AppPalette.slate50,
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppPalette.slate800 : Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: dividerColor),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppPalette.slate950 : AppPalette.slate50,
        foregroundColor: isDark ? AppPalette.slate100 : AppPalette.slate900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? AppPalette.slate100 : AppPalette.slate900,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppPalette.slate800 : AppPalette.slate100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: onSurfaceMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppPalette.slate800 : AppPalette.slate100,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: TextStyle(
          color: isDark ? AppPalette.slate100 : AppPalette.slate800,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      iconTheme: IconThemeData(
        color: isDark ? AppPalette.slate300 : AppPalette.slate600,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: scheme.onSurface),
        bodyMedium: TextStyle(fontSize: 14, color: scheme.onSurface),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
