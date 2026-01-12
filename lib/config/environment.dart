import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get webAppUrl =>
      dotenv.env['WEBAPP_URL'] ?? 'https://app.taskhamster.no';

  static List<String> get allowedDomains {
    final domains = dotenv.env['ALLOWED_DOMAINS'] ?? 'app.taskhamster.no,api.taskhamster.no';
    return domains.split(',').map((d) => d.trim()).toList();
  }

  static bool get enableSSLPinning =>
      dotenv.env['ENABLE_SSL_PINNING']?.toLowerCase() == 'true';

  static Map<String, List<String>> get certificatePins {
    final pinsString = dotenv.env['SSL_CERT_PINS_TASKHAMSTER'] ?? '';
    if (pinsString.isEmpty) {
      return {};
    }

    final pins = pinsString.split(',').map((p) => p.trim()).toList();
    return {
      'taskhamster.no': pins,
    };
  }

  static bool get isDevelopment => kDebugMode;

  static void printConfig() {
    if (kDebugMode) {
      print('🚀 Taskhamster Configuration');
      print('🌐 WebView URL: $webAppUrl');
      print('🔒 Allowed Domains: ${allowedDomains.join(', ')}');
      print('🔐 SSL Pinning: $enableSSLPinning');
      print('📝 Config loaded from: .env');
    }
  }
}