import 'package:material_ui/material_ui.dart';

/// Color palette and typography tokens inspired by Vietnamese lacquerware
/// (sơn mài), Dong Son bronze drums (trống đồng), and traditional woodboards.
class VietTheme {
  const VietTheme._();

  static const Color lacquerDark = Color(0xFF1F0A0A);
  static const Color lacquerRed = Color(0xFF661417);
  static const Color lacquerMid = Color(0xFF3E1112);

  static const Color bronzeGold = Color(0xFFD8A648);
  static const Color bronzeGoldLight = Color(0xFFF3D58D);
  static const Color bronzeGoldDark = Color(0xFF8C621D);

  static const Color parchment = Color(0xFFF8EFE0);
  static const Color parchmentSoft = Color(0xFFEBDAC0);

  static const Color boardWoodLight = Color(0xFFF1DAB1);
  static const Color boardWoodDark = Color(0xFFD9B67E);
  static const Color boardFrameDark = Color(0xFF3F1F0F);
  static const Color boardFrameLight = Color(0xFF65351A);
  static const Color boardInk = Color(0xFF4B2713);

  static const Color sideARed = Color(0xFFC62828);
  static const Color sideARedLight = Color(0xFFEF5350);
  static const Color sideARedDark = Color(0xFF7B1010);

  static const Color sideBBlue = Color(0xFF156978);
  static const Color sideBBlueLight = Color(0xFF359BAE);
  static const Color sideBBlueDark = Color(0xFF0A3C46);

  static const Color legalHighlight = Color(0xFF1D9E6C);
  static const Color legalHighlightGlow = Color(0xFF53E0A4);
  static const Color captureHighlight = Color(0xFFE53935);
  static const Color captureHighlightGlow = Color(0xFFFFCA28);

  static ThemeData buildTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: lacquerRed,
      brightness: Brightness.dark,
      primary: bronzeGold,
      onPrimary: lacquerDark,
      secondary: sideBBlueLight,
      surface: lacquerMid,
      onSurface: parchment,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: lacquerDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: parchment,
        titleTextStyle: TextStyle(
          color: parchment,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2D1210),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: bronzeGold.withValues(alpha: 0.4)),
        ),
        titleTextStyle: const TextStyle(
          color: bronzeGoldLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: parchmentSoft,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}

