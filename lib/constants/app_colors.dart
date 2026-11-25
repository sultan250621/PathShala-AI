import 'package:flutter/material.dart';

/// App color palette. AppColors.isDark true hole dark rong dekhabe.
/// theme_service.dart theke isDark set hoy.
class AppColors {
  static bool isDark = false;

  static Color _c(int light, int dark) => isDark ? Color(dark) : Color(light);

  // Brand & Semantic
  static Color get primary => _c(0xFF2563EB, 0xFF3B82F6);
  static Color get primaryLight => _c(0xFF3B82F6, 0xFF60A5FA);
  static Color get primaryDark => _c(0xFF1D4ED8, 0xFF1D4ED8);
  static Color get accent => _c(0xFFF59E0B, 0xFFFBBF24);
  static Color get success => _c(0xFF16A34A, 0xFF22C55E);
  static Color get error => _c(0xFFDC2626, 0xFFEF4444);

  // Background & Surface
  static Color get background => _c(0xFFF8FAFC, 0xFF121212);
  static Color get surface => _c(0xFFFFFFFF, 0xFF1E1E1E);
  static Color get cardBorder => _c(0xFFE2E8F0, 0xFF334155);

  // Soft Feedback Tints
  static Color get successLight => _c(0xFFDCFCE7, 0xFF14532D);
  static Color get errorLight => _c(0xFFFEE2E2, 0xFF7F1D1D);
  static Color get accentLight => _c(0xFFFEF3C7, 0xFF78350F);
  static Color get primarySubtle => _c(0xFFEFF6FF, 0xFF1E3A8A);

  // Text Colors
  static Color get textPrimary => _c(0xFF1E293B, 0xFFF1F5F9);
  static Color get textSecondary => _c(0xFF64748B, 0xFF94A3B8);
  static Color get textMuted => _c(0xFF94A3B8, 0xFF64748B);
}