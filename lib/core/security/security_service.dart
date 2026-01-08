import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';


/// Handles encrypted storage, PIN management, and authentication
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // ============================================================================
  // PIN MANAGEMENT (Secure Storage)
  // ============================================================================

  /// Initialize admin PIN on first launch
  Future<void> initializeAdminPin() async {
    try {
      final existingPin = await getAdminPin();
      if (existingPin == null) {
        await setAdminPin(AppConfig.defaultAdminPin);
        if (kDebugMode) {
          print('🔐 Admin PIN initialized');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing admin PIN: $e');
      }
      rethrow;
    }
  }

  /// Get admin PIN from secure storage
  Future<String?> getAdminPin() async {
    try {
      return await _storage.read(key: AppConfig.secureStorageKeyAdminPin);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reading admin PIN: $e');
      }
      return null;
    }
  }

  /// Set admin PIN in secure storage
  Future<void> setAdminPin(String pin) async {
    try {
      await _storage.write(
        key: AppConfig.secureStorageKeyAdminPin,
        value: pin,
      );
      if (kDebugMode) {
        print('✅ Admin PIN updated');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting admin PIN: $e');
      }
      rethrow;
    }
  }

  /// Verify admin PIN
  Future<bool> verifyAdminPin(String enteredPin) async {
    try {
      final storedPin = await getAdminPin();
      if (storedPin == null) {
        return enteredPin == AppConfig.defaultAdminPin;
      }
      return enteredPin == storedPin;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error verifying admin PIN: $e');
      }
      return false;
    }
  }

  // ============================================================================
  // DEVICE ID MANAGEMENT
  // ============================================================================

  /// Get or create device ID
  Future<String> getDeviceId() async {
    try {
      String? deviceId = await _storage.read(key: AppConfig.secureStorageKeyDeviceId);

      if (deviceId == null) {
        deviceId = _generateDeviceId();
        await _storage.write(
          key: AppConfig.secureStorageKeyDeviceId,
          value: deviceId,
        );
        if (kDebugMode) {
          print('🆔 Generated device ID: $deviceId');
        }
      }

      return deviceId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device ID: $e');
      }
      return _generateDeviceId();
    }
  }

  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final combined = '$timestamp-$random';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 16);
  }

  // ============================================================================
  // API TOKEN MANAGEMENT
  // ============================================================================

  /// Store API authentication token
  Future<void> storeApiToken(String token) async {
    try {
      await _storage.write(
        key: AppConfig.secureStorageKeyApiToken,
        value: token,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing API token: $e');
      }
      rethrow;
    }
  }

  /// Retrieve API authentication token
  Future<String?> getApiToken() async {
    try {
      return await _storage.read(key: AppConfig.secureStorageKeyApiToken);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error reading API token: $e');
      }
      return null;
    }
  }

  /// Clear API token (logout)
  Future<void> clearApiToken() async {
    try {
      await _storage.delete(key: AppConfig.secureStorageKeyApiToken);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing API token: $e');
      }
    }
  }

  // ============================================================================
  // HMAC SIGNATURE (for WebView message validation)
  // ============================================================================

  /// Compute HMAC-SHA256 signature for message validation
  String computeHMAC(String message, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Verify HMAC signature
  bool verifyHMAC(String message, String signature, String secret) {
    final computed = computeHMAC(message, secret);
    return computed == signature;
  }

  // ============================================================================
  // GENERAL SECURE STORAGE
  // ============================================================================

  Future<void> writeSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readSecure(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    if (kDebugMode) {
      print('⚠️ All secure storage cleared');
    }
  }
}