import 'package:flutter/material.dart';

/// UI Theme Colors
class AppColors {
  static const Color background = Color(0xFFF3F4F6);
  static const Color sidebar = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFF111827);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
}

/// Application Configuration
class AppConfig {
  // Application Metadata
  static const String appTitle = 'Taskhamster Hub';
  static const String appVersion = '2.0.0';

  // Kiosk Behavior
  static const Duration idleTimeout = Duration(minutes: 5); // Produksjon: 5 minutter
  static const Duration demoIdleTimeout = Duration(seconds: 15); // Demo/Testing: 15 sekunder

  // Display Settings
  static const double dimmedBrightness = 0.15; // 15% brightness når idle
  static const double activeBrightness = 1.0; // 100% brightness når aktiv

  // Security Settings (for FlutterSecureStorage keys)
  static const String secureStorageKeyAdminPin = 'admin_pin';
  static const String secureStorageKeyDeviceId = 'device_id';
  static const String secureStorageKeyApiToken = 'api_token';

  // Default PIN (kun brukt første gang, deretter lagret kryptert)
  static const String defaultAdminPin = '1234';

  // Session Management
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const bool clearCacheOnLogout = true;

  // WebView Settings
  static const bool enableWebViewDebugging = false; // Sett til false i produksjon
  static const bool enableJavaScript = true;
  static const bool enableDomStorage = true;
  static const bool enableZoom = false;

  // Development/Testing Overrides
  static bool get isDemoMode => const bool.fromEnvironment('DEMO_MODE', defaultValue: false);
  static Duration get effectiveIdleTimeout => isDemoMode ? demoIdleTimeout : idleTimeout;
}

/// UI Dimensions
class AppDimensions {
  static const double sidebarWidth = 250;
  static const double cardElevation = 2;
  static const double cardBorderRadius = 12;
  static const double buttonBorderRadius = 8;
  static const double iconSize = 24;
  static const double largeIconSize = 48;
}

/// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryDark,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textDark,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );
}