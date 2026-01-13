import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

class AppConfig {
  static String get applicationId {
    final id = dotenv.env['APPLICATION_ID'];
    if (id == null || id.isEmpty) {
      throw Exception('APPLICATION_ID must be set in .env file');
    }
    return id;
  }

  static String get appTitle {
    final title = dotenv.env['APP_TITLE'];
    if (title == null || title.isEmpty) {
      throw Exception('APP_TITLE must be set in .env file');
    }
    return title;
  }

  static String get appVersion {
    final version = dotenv.env['APP_VERSION'];
    if (version == null || version.isEmpty) {
      throw Exception('APP_VERSION must be set in .env file');
    }
    return version;
  }

  static const Duration idleTimeout = Duration(minutes: 5);
  static const Duration demoIdleTimeout = Duration(seconds: 15);
  static const double dimmedBrightness = 0.15;
  static const double activeBrightness = 1.0;
  static const String secureStorageKeyDeviceId = 'device_id';
  static const String secureStorageKeyApiToken = 'api_token';
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const bool clearCacheOnLogout = true;

  static bool get enableWebViewDebugging =>
      dotenv.env['ENABLE_WEBVIEW_DEBUGGING']?.toLowerCase() == 'true';

  static const bool enableJavaScript = true;
  static const bool enableDomStorage = true;
  static const bool enableZoom = false;

  static bool get isDemoMode =>
      dotenv.env['DEMO_MODE']?.toLowerCase() == 'true';

  static Duration get effectiveIdleTimeout =>
      isDemoMode ? demoIdleTimeout : idleTimeout;
}

class AppDimensions {
  static const double sidebarWidth = 250;
  static const double cardElevation = 2;
  static const double cardBorderRadius = 12;
  static const double buttonBorderRadius = 8;
  static const double iconSize = 24;
  static const double largeIconSize = 48;
}

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