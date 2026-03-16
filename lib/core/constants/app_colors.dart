import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ───────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF2F80ED);
  static const Color primaryLight = Color(0xFF5BA3F5);
  static const Color primaryDark  = Color(0xFF1A5BB8);

  // ── Obsidian backgrounds ─────────────────────────────────────────────────
  static const Color backgroundDark   = Color(0xFF080D18);
  static const Color backgroundMid    = Color(0xFF0D1525);
  static const Color surfaceDark      = Color(0xFF111B2E);
  static const Color cardDark         = Color(0xFF141F33);
  static const Color cardElevated     = Color(0xFF1A2740);
  static const Color backgroundLight  = Color(0xFFF4F6FB);

  // ── Glass ────────────────────────────────────────────────────────────────
  static const Color glass      = Color(0x0DFFFFFF);   // 5% white
  static const Color glassBorder = Color(0x1AFFFFFF);  // 10% white
  static const Color glassDeep  = Color(0x14FFFFFF);   // 8% white

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF8899AA);
  static const Color textMuted     = Color(0xFF4A5568);
  static const Color textHint      = Color(0xFF6B7A8D);
  static const Color textOnDark    = Color(0xFFEDF2FF);
  static const Color textOnPrimary = Colors.white;
  static const Color textSubDark   = Color(0xFF8899BB);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success  = Color(0xFF00C896);
  static const Color warning  = Color(0xFFF5A623);
  static const Color error    = Color(0xFFFF4D6A);
  static const Color orange   = Color(0xFFFF7A45);
  static const Color gold     = Color(0xFFFFBE45);

  // ── Safety / Trust ────────────────────────────────────────────────────────
  static const Color safetyGold   = Color(0xFFF5A623);
  static const Color safetyGreen  = Color(0xFF00C896);
  static const Color shieldBlue   = Color(0xFF3D8EF0);

  // ── Divider / Border ──────────────────────────────────────────────────────
  static const Color divider    = Color(0xFFE8EDF5);
  static const Color border     = Color(0xFFDDE3EE);
  static const Color borderDark = Color(0xFF1E2E45);

  // ── Map ───────────────────────────────────────────────────────────────────
  static const Color routeLine   = primary;
  static const Color mapDarkTile = Color(0xFF0D1828);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color statusPending   = warning;
  static const Color statusActive    = success;
  static const Color statusCompleted = primary;
  static const Color statusCancelled = error;
  static const Color online  = success;
  static const Color offline = textSecondary;

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2F80ED), Color(0xFF1A5BB8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF080D18), Color(0xFF0D1A30), Color(0xFF080D18)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [Color(0x402F80ED), Color(0x002F80ED)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient safetyGradient = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFFF7A45)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF00A37A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF141F33), Color(0xFF1A2740)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> primaryGlow = [
    BoxShadow(color: primary.withOpacity(0.35), blurRadius: 24, spreadRadius: 0),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
  ];
}
