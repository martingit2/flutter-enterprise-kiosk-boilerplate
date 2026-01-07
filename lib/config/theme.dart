import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF3F4F6);
  static const Color sidebar = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFF111827);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
}

class AppConfig {
  static const String appTitle = 'Taskhamster Hub';
  static const String adminPin = '1234';

  // Test-tid (endre til 5 minutter senere)
  static const Duration idleTimeout = Duration(seconds: 10);
  
  // 1.0 = Fullt lys (100%)
  // 0.5 = Halvt lys (50%)
  // 0.15 = Dimmet (15%) <- Prøv denne nå som det svarte filteret er borte
  // 0.01 = Nesten av (1%)

  static const double dimmedBrightness = 0.15;
}