import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color bgPrimary = Color(0xFF0A0E1A);
  static const Color bgSecondary = Color(0xFF0F1420);
  static const Color borderPrimary = Color(0xFF1A1F2E);
  static const Color borderSecondary = Color(0xFF2A2F3E);
  
  static const Color primary = Color(0xFF06B6D4); // Cyan
  static const Color secondary = Color(0xFF3B82F6); // Blue
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Spacing (8px base unit)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;
  
  // Sidebar
  static const double sidebarWidth = 240.0;
  static const double sidebarWidthMobile = 0.0;
  
  // Border radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  
  // Breakpoints
  static const double mobileBreakpoint = 640.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;
  
  // Helper method to check if mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }
  
  // Helper method to check if desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
}
