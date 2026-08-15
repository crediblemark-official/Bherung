import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors - Luxury Obsidian Black & Rich Gold Palette
  static const Color primaryDark = Color(0xFF0A0D14); // Obsidian Black
  static const Color surfaceDark = Color(0xFF141824); // Charcoal Surface
  static const Color surfaceDarker = Color(0xFF080A0F); // Deep Black
  static const Color cardDark = Color(0xFF1A1F2C); // Dark Card Bg
  
  // Gold Accents
  static const Color primaryGold = Color(0xFFD4AF37); // Rich Metallic Gold
  static const Color secondaryGold = Color(0xFFE5B842); // Warm Vibrant Gold
  static const Color goldAccent = Color(0xFFF5CD6D); // Bright Gold Highlight
  static const Color goldLight = Color(0xFFFDF8E7); // Subtle Gold Tint
  static const Color goldMuted = Color(0xFF9E7C28); // Muted Dark Gold

  // Backwards compatibility aliases
  static const Color primaryTeal = primaryGold;
  static const Color primaryTealLight = goldLight;
  static const Color secondaryTeal = secondaryGold;
  static const Color accentCyan = primaryGold;
  static const Color accentIndigo = Color(0xFF8B5CF6);
  
  // Background & Neutral Colors
  static const Color bgLight = Color(0xFFF8F9FB); // Clean Off-white
  static const Color bgSubtle = Color(0xFFEFF2F6); // Soft Grey
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF0A0D14); // High-contrast Charcoal Black
  static const Color textBody = Color(0xFF2D3748); // Deep Slate
  static const Color textMuted = Color(0xFF64748B); // Cool Slate Muted
  static const Color textSubtle = Color(0xFF94A3B8); // Slate 400
  static const Color borderColor = Color(0xFFE2E8F0); // Crisp Border
  static const Color borderDark = Color(0xFF232938); // Dark Surface Border
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // Semantic Status Colors
  static const Color successGreen = Color(0xFF10B981); // Emerald 500
  static const Color successGreenLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color warningOrange = Color(0xFFF59E0B); // Amber 500
  static const Color warningOrangeLight = Color(0xFFFEF3C7); // Amber 100
  static const Color dangerRed = Color(0xFFEF4444); // Red 500
  static const Color dangerRedLight = Color(0xFFFEE2E2); // Red 100
  static const Color infoBlue = Color(0xFF3B82F6); // Blue 500

  // Luxury Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5CD6D), Color(0xFFD4AF37), Color(0xFFB8860B)],
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F2C), Color(0xFF11141D)],
  );

  // Helper method for Indonesian Rupiah formatting
  static String formatRupiah(double amount) {
    final String priceStr = amount.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String result = priceStr.replaceAllMapped(reg, (Match match) => '${match[1]}.');
    return 'Rp $result';
  }

  // Soft modern shadow tokens
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0A0D14).withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0A0D14).withValues(alpha: 0.08),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevationShadow => [
    BoxShadow(
      color: const Color(0xFF0A0D14).withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: primaryGold.withValues(alpha: 0.28),
      blurRadius: 14,
      spreadRadius: 1,
      offset: const Offset(0, 3),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGold,
        primary: primaryGold,
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
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGold, width: 1.8),
        ),
        hintStyle: const TextStyle(color: textSubtle, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: 0.2,
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
        return const Color(0xFFD4AF37); // Rich Gold
      case 'mie_makanan':
        return const Color(0xFFEA580C);
      case 'minuman':
        return const Color(0xFF0284C7);
      case 'bumbu':
        return const Color(0xFF10B981);
      case 'rokok':
        return const Color(0xFFEF4444);
      case 'sabun_rumah':
        return const Color(0xFF8B5CF6);
      case 'gas_galon':
        return const Color(0xFF0D9488);
      default:
        return primaryGold;
    }
  }
}
