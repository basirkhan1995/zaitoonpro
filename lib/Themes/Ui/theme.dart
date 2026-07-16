import "package:flutter/material.dart";

class AppThemes {
  final TextTheme textTheme;
  const AppThemes(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff005994),       // Keep professional blue
      surfaceTint: Color(0xff005994),   // Match primary for consistency
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffe3f2ff), // Softer, more modern container
      onPrimaryContainer: Color(0xff001e3a), // Higher contrast
      secondary: Color(0xff4a5c7c),     // Desaturated blue-grey
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffe8eef7), // Softer secondary container
      onSecondaryContainer: Color(0xff0f1d33),
      tertiary: Color(0xff7c4d80),      // More balanced purple
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xfff5e5f7), // Warmer, softer container
      onTertiaryContainer: Color(0xff2d1330),
      error: Color(0xffc62828),         // More vibrant error red
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffebee), // Softer error container
      onErrorContainer: Color(0xff4a0002),
      surface: Color(0xFFFDFCFF),       // Warmer, softer white
      onSurface: Color(0xff1a1b1e),     // Slightly darker for better readability
      onSurfaceVariant: Color(0xff43474e), // Better contrast ratio
      outline: Color(0xff73777f),       // More neutral outline
      outlineVariant: Color(0xffc3c7d0), // Softer variant
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3033),
      inversePrimary: Color(0xffb3d4ff), // More vibrant inverse primary
      primaryFixed: Color(0xffe3f2ff),
      onPrimaryFixed: Color(0xff001e3a),
      primaryFixedDim: Color(0xffb3d4ff),
      onPrimaryFixedVariant: Color(0xff294677),
      secondaryFixed: Color(0xffe8eef7),
      onSecondaryFixed: Color(0xff0f1d33),
      secondaryFixedDim: Color(0xffc8d0e0),
      onSecondaryFixedVariant: Color(0xff38465c),
      tertiaryFixed: Color(0xfff5e5f7),
      onTertiaryFixed: Color(0xff2d1330),
      tertiaryFixedDim: Color(0xffd8c2db),
      onTertiaryFixedVariant: Color(0xff614265),
      surfaceDim: Color(0xffdddfe3),     // Softer dim
      surfaceBright: Color(0xFFFDFCFF),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f8fc), // Warmer low container
      surfaceContainer: Color(0xfff1f3f7),   // Better background for cards
      surfaceContainerHigh: Color(0xffebedf1), // Nicer hierarchy
      surfaceContainerHighest: Color(0xffe5e7eb),
    );
  }

  ThemeData light() {
    return theme(lightScheme(), true);
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff5db3ff),       // Brighter, more vibrant blue
      surfaceTint: Color(0xff5db3ff),   // Match vibrant primary
      onPrimary: Color(0xff003258),
      primaryContainer: Color(0xff004a83), // Deeper container
      onPrimaryContainer: Color(0xffd3e7ff),
      secondary: Color(0xffb2c7e8),     // Softer secondary
      onSecondary: Color(0xff1d2c43),
      secondaryContainer: Color(0xff344356), // Better contrast
      onSecondaryContainer: Color(0xffd8e4f8),
      tertiary: Color(0xffe8b9ec),      // More vibrant tertiary
      onTertiary: Color(0xff452a49),
      tertiaryContainer: Color(0xff5d4161), // Deeper container
      onTertiaryContainer: Color(0xfff7e1f9),
      error: Color(0xffff8a80),         // Brighter error
      onError: Color(0xff5f0003),
      errorContainer: Color(0xff8c0009),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff121418),       // True black for OLED
      onSurface: Color(0xffe6e7eb),     // Softer on-surface
      onSurfaceVariant: Color(0xffc2c6cf), // Better readability
      outline: Color(0xff8d919a),       // More visible
      outlineVariant: Color(0xff444850), // Better separation
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe6e7eb),
      inversePrimary: Color(0xff005994), // More contrast
      primaryFixed: Color(0xffd3e7ff),
      onPrimaryFixed: Color(0xff001e3a),
      primaryFixedDim: Color(0xffa3cfff),
      onPrimaryFixedVariant: Color(0xff004a83),
      secondaryFixed: Color(0xffd8e4f8),
      onSecondaryFixed: Color(0xff0f1d33),
      secondaryFixedDim: Color(0xffbcc8dc),
      onSecondaryFixedVariant: Color(0xff3a495e),
      tertiaryFixed: Color(0xfff7e1f9),
      onTertiaryFixed: Color(0xff2d1330),
      tertiaryFixedDim: Color(0xffd9c1dc),
      onTertiaryFixedVariant: Color(0xff614265),
      surfaceDim: Color(0xff121418),
      surfaceBright: Color(0xff383a3f),
      surfaceContainerLowest: Color(0xff0c0d11),
      surfaceContainerLow: Color(0xff1a1b1f),
      surfaceContainer: Color(0xff1e2024), // Better depth
      surfaceContainerHigh: Color(0xff292b2f),
      surfaceContainerHighest: Color(0xff34363a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme(), false);
  }

  ThemeData theme(ColorScheme colorScheme, bool isLight) => ThemeData(
    useMaterial3: true,
    fontFamily: "NotoSans",
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    // Enhanced AppBar with elevation and shadow
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: isLight ? 1 : 0,
      shadowColor: isLight ? Colors.black12 : Colors.black38,
      surfaceTintColor: colorScheme.surface,
    ),
    // Enhanced text theme with better typography
    textTheme: textTheme.apply(
      fontFamily: "NotoSans",
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
    canvasColor: colorScheme.surface,
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      barrierColor: Colors.black.withValues(alpha: 0.3),

    ),
    // Elevated buttons with better styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: isLight ? 2 : 1,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Filled button styling
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Outlined button styling
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // Chip theming
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // List tile theming
    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // Divider theming
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 0.5,
      space: 8,
    ),

    // Floating action button theming
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // Bottom sheet theming
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // Navigation bar/rail theming
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      elevation: 2,
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    ),

    // Snack bar theming
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Progress indicator theming
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      circularTrackColor: colorScheme.surfaceContainerHigh,
      linearTrackColor: colorScheme.surfaceContainerHigh,
    ),
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}

