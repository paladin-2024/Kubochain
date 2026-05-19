import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ───────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark  = Color(0xFF1D4ED8);

  // ── Light surfaces (names kept for code compatibility) ──────────────────
  static const Color backgroundDark   = Color(0xFFF5F8FF);  // main bg
  static const Color backgroundMid    = Color(0xFFEBF0FE);  // section bg
  static const Color surfaceDark      = Color(0xFFFFFFFF);  // sheets/modals
  static const Color cardDark         = Color(0xFFFFFFFF);  // cards
  static const Color cardElevated     = Color(0xFFF8FAFF);  // elevated cards
  static const Color backgroundLight  = Color(0xFFF4F6FB);

  // ── Glass ────────────────────────────────────────────────────────────────
  static const Color glass       = Color(0x0A000000);
  static const Color glassBorder = Color(0x1A2563EB);
  static const Color glassDeep   = Color(0x14000000);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0D1629);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted     = Color(0xFF94A3B8);
  static const Color textHint      = Color(0xFFB0BBCC);
  static const Color textOnDark    = Color(0xFF0D1629);   // main text on light bg
  static const Color textOnPrimary = Colors.white;
  static const Color textSubDark   = Color(0xFF64748B);

  // ── Status ───────────────────────────────────────────────────────────────
  static const Color success  = Color(0xFF10B981);
  static const Color warning  = Color(0xFFD97706);
  static const Color error    = Color(0xFFEF4444);
  static const Color orange   = Color(0xFFF97316);
  static const Color gold     = Color(0xFFF59E0B);

  // ── Safety / Trust ────────────────────────────────────────────────────────
  static const Color safetyGold   = Color(0xFFD97706);
  static const Color safetyGreen  = Color(0xFF10B981);
  static const Color shieldBlue   = Color(0xFF2563EB);

  // ── Divider / Border ──────────────────────────────────────────────────────
  static const Color divider    = Color(0xFFE8EDF5);
  static const Color border     = Color(0xFFDDE3EE);
  static const Color borderDark = Color(0xFFE2E8F0);

  // ── Map ───────────────────────────────────────────────────────────────────
  static const Color routeLine   = primary;
  static const Color mapDarkTile = Color(0xFFF5F8FF);

  // ── Status aliases ────────────────────────────────────────────────────────
  static const Color statusPending   = warning;
  static const Color statusActive    = success;
  static const Color statusCompleted = primary;
  static const Color statusCancelled = error;
  static const Color online          = success;
  static const Color offline         = textSecondary;

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFF5F8FF), Color(0xFFEFF6FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [Color(0x402563EB), Color(0x002563EB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient safetyGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> primaryGlow = [
    BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 0),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF1E3A8A).withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
  ];

  static List<BoxShadow> navShadow = [
    BoxShadow(
      color: const Color(0xFF2563EB).withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 8,
      offset: const Offset(0, -2),
    ),
  ];
}
