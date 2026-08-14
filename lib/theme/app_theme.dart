import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Modern Slate & Teal Palette
  static const Color primaryDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color primaryTeal = Color(0xFF0D9488); // Teal 600
  static const Color primaryTealLight = Color(0xFFCCFBF1); // Teal 100
  static const Color secondaryTeal = Color(0xFF14B8A6); // Teal 500
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan 500
  static const Color accentIndigo = Color(0xFF6366F1); // Indigo 500
  
  // Background & Neutral Colors
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color bgSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textBody = Color(0xFF334155); // Slate 700
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textSubtle = Color(0xFF94A3B8); // Slate 400
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9); // Slate 100

  // Semantic Status Colors
  static const Color successGreen = Color(0xFF10B981); // Emerald 500
  static const Color successGreenLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color warningOrange = Color(0xFFF59E0B); // Amber 500
  static const Color warningOrangeLight = Color(0xFFFEF3C7); // Amber 100
  static const Color dangerRed = Color(0xFFEF4444); // Red 500
  static const Color dangerRedLight = Color(0xFFFEE2E2); // Red 100
  static const Color infoBlue = Color(0xFF3B82F6); // Blue 500

  // Helper method for Indonesian Rupiah formatting
  static String formatRupiah(double amount) {
    final String priceStr = amount.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = priceStr.replaceAllMapped(reg, (Match match) => '${match[1]}.');
    return 'Rp $result';
  }

  // Soft shadow token
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get elevationShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.07),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        surface: bgLight,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: bgLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSubtle, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
        backgroundColor: primaryDark,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  static IconData getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'sembako':
        return Icons.rice_bowl_rounded;
      case 'mie_makanan':
        return Icons.ramen_dining_rounded;
      case 'minuman':
        return Icons.local_drink_rounded;
      case 'bumbu':
        return Icons.soup_kitchen_rounded;
      case 'rokok':
        return Icons.smoking_rooms_rounded;
      case 'sabun_rumah':
        return Icons.cleaning_services_rounded;
      case 'gas_galon':
        return Icons.propane_tank_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  static Color getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'sembako':
        return const Color(0xFFF59E0B);
      case 'mie_makanan':
        return const Color(0xFFEA580C);
      case 'minuman':
        return const Color(0xFF06B6D4);
      case 'bumbu':
        return const Color(0xFF10B981);
      case 'rokok':
        return const Color(0xFFEF4444);
      case 'sabun_rumah':
        return const Color(0xFF6366F1);
      case 'gas_galon':
        return const Color(0xFF0284C7);
      default:
        return primaryTeal;
    }
  }
}
