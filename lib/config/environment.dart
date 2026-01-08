import 'package:flutter/foundation.dart';

/// Application Environment Configuration
class Environment {
  // WebView URL - Dette er hovedsiden som lastes
  static const String webAppUrl = 'https://app.taskhamster.no';

  // Allowed Domains - Kun disse domenene kan navigeres til
  static const List<String> allowedDomains = [
    'app.taskhamster.no',
    'api.taskhamster.no'
  ];

  // SSL Certificate Pins (SHA-256 hashes)
  // TODO: Erstatt med faktiske sertifikat-fingeravtrykk
  // Generer med: openssl s_client -connect app.taskhamster.no:443 | openssl x509 -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
  static const Map<String, List<String>> certificatePins = {
    'taskhamster.no': [
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // TODO: Erstatt
      'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // Backup sertifikat
    ],
  };

  // Security Features
  static const bool enableSSLPinning = false; // Sett til true når sertifikater er konfigurert
  static const bool enableJailbreakDetection = false; // DEAKTIVERT: Pakken har kompatibilitetsproblemer

  // Debug
  static bool get isDevelopment => kDebugMode;

  static void printConfig() {
    if (kDebugMode) {
      print('🚀 Taskhamster Configuration');
      print('🌐 WebView URL: $webAppUrl');
      print('🔒 SSL Pinning: $enableSSLPinning');
      print('🔐 Jailbreak Detection: $enableJailbreakDetection (temporarily disabled)');
    }
  }
}