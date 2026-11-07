import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Palette « Bénin premium » : noirs profonds, vert signature, jaune rare.
class AppColors {
  static const green = Color(0xFF2FB36D);
  static const greenBright = Color(0xFF5ADB96);
  static const greenDeep = Color(0xFF0B3A26);
  static const yellow = Color(0xFFFCD116);
  static const red = Color(0xFFE8112D);

  static const bg = Color(0xFF070A09);
  static const bgSoft = Color(0xFF0D1210);
  static const surface = Color(0xFF121816);
  static const surfaceHigh = Color(0xFF1A211E);

  static const stroke = Color(0x1FFFFFFF);
  static const text = Color(0xFFF4F7F5);
  static const muted = Color(0xA8FFFFFF);
  static const faint = Color(0x70FFFFFF);

  /// Bouton de lecture principal (blanc, façon Apple Music).
  static const playButton = Color(0xFFF4F7F5);
}

/// Échelle typographique Outfit.
class AppText {
  static const eyebrow = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.9,
    color: AppColors.faint,
  );
  static const display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.1,
    height: 1.08,
    color: AppColors.text,
  );
  static const title = TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
    height: 1.12,
    color: AppColors.text,
  );
  static const cardTitle = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.1,
    color: AppColors.text,
  );
  static const section = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.muted,
  );
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.faint,
  );
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.green,
    onPrimary: Colors.black,
    secondary: AppColors.yellow,
    onSecondary: Colors.black,
    surface: AppColors.bgSoft,
    onSurface: AppColors.text,
    error: AppColors.red,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Outfit',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
  );

  return base.copyWith(
    canvasColor: AppColors.bg,
    splashFactory: InkRipple.splashFactory,
    textTheme: base.textTheme.apply(
      fontFamily: 'Outfit',
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    iconTheme: const IconThemeData(color: AppColors.text),
    dividerTheme: const DividerThemeData(
      color: AppColors.stroke,
      thickness: 0.6,
      space: 0.6,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.text,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: Color(0xCC000000),
      showDragHandle: false,
    ),
    sliderTheme: base.sliderTheme.copyWith(
      trackHeight: 3,
      activeTrackColor: AppColors.green,
      inactiveTrackColor: Color(0x26FFFFFF),
      thumbColor: AppColors.text,
      overlayColor: AppColors.green.withAlpha(28),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.text,
      unselectedLabelColor: AppColors.faint,
      indicatorColor: AppColors.green,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withAlpha(12),
      hintStyle: AppText.caption,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.green, width: 1.2),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.green,
      selectionColor: AppColors.green.withAlpha(60),
      selectionHandleColor: AppColors.green,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        side: const BorderSide(color: Color(0x552FB36D)),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.text,
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
