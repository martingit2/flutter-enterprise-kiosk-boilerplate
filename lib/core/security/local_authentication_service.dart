import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'device_identification_service.dart';

class LocalAuthenticationService {
  static final LocalAuthenticationService _instance = LocalAuthenticationService._internal();
  factory LocalAuthenticationService() => _instance;
  LocalAuthenticationService._internal();

  final _deviceId = DeviceIdentificationService();
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const String _registeredFingerprintKey = 'registered_fingerprint';
  static const String _registeredUserIdKey = 'registered_user_id';
  static const String _registrationTimestampKey = 'registration_timestamp';

  Future<bool> isDeviceRegistered() async {
    try {
      final storedFingerprint = await _secureStorage.read(key: _registeredFingerprintKey);
      if (storedFingerprint == null) return false;

      final currentFingerprint = await _deviceId.getDeviceFingerprint();

      if (storedFingerprint != currentFingerprint) {
        await clearRegistration();
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<AuthResult> attemptAutoLogin() async {
    try {
      if (!await isDeviceRegistered()) {
        return AuthResult.notRegistered('Device not registered');
      }

      final userId = await _secureStorage.read(key: _registeredUserIdKey);

      if (userId == null) {
        return AuthResult.failed('User ID not found');
      }

      return AuthResult.success(userId);
    } catch (e) {
      return AuthResult.failed('Auto-login error: $e');
    }
  }

  Future<AuthResult> registerDevice() async {
    try {
      final deviceInfo = await _deviceId.getDeviceInfo();
      final userId = 'user_${deviceInfo.serialNumber.isNotEmpty ? deviceInfo.serialNumber : deviceInfo.fingerprint.substring(0, 12)}';
      final timestamp = DateTime.now().toIso8601String();

      await _secureStorage.write(key: _registeredFingerprintKey, value: deviceInfo.fingerprint);
      await _secureStorage.write(key: _registeredUserIdKey, value: userId);
      await _secureStorage.write(key: _registrationTimestampKey, value: timestamp);

      await _deviceId.markDeviceRegistered();

      return AuthResult.success(userId);
    } catch (e) {
      return AuthResult.failed('Registration error: $e');
    }
  }

  Future<void> clearRegistration() async {
    await _secureStorage.delete(key: _registeredFingerprintKey);
    await _secureStorage.delete(key: _registeredUserIdKey);
    await _secureStorage.delete(key: _registrationTimestampKey);
    await _deviceId.clearDeviceRegistration();
  }

  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _registeredUserIdKey);
  }

  Future<Map<String, String?>> getRegistrationInfo() async {
    return {
      'fingerprint': await _secureStorage.read(key: _registeredFingerprintKey),
      'user_id': await _secureStorage.read(key: _registeredUserIdKey),
      'timestamp': await _secureStorage.read(key: _registrationTimestampKey),
    };
  }
}

class AuthResult {
  final bool success;
  final String? userId;
  final String? message;
  final AuthResultType type;

  AuthResult._({
    required this.success,
    required this.type,
    this.userId,
    this.message,
  });

  factory AuthResult.success(String userId) => AuthResult._(
    success: true,
    type: AuthResultType.success,
    userId: userId,
  );

  factory AuthResult.failed(String message) => AuthResult._(
    success: false,
    type: AuthResultType.failed,
    message: message,
  );

  factory AuthResult.notRegistered(String message) => AuthResult._(
    success: false,
    type: AuthResultType.notRegistered,
    message: message,
  );
}

enum AuthResultType {
  success,
  failed,
  notRegistered,
}