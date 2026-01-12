import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/app_config.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _deviceInfo = DeviceInfoPlugin();

  Future<void> initializeAdminPin() async {
    final existingPin = await getAdminPin();
    if (existingPin == null) {
      await setAdminPin(AppConfig.defaultAdminPin);
    }
  }

  Future<String?> getAdminPin() async {
    return await _storage.read(key: AppConfig.secureStorageKeyAdminPin);
  }

  Future<void> setAdminPin(String pin) async {
    await _storage.write(key: AppConfig.secureStorageKeyAdminPin, value: pin);
  }

  Future<bool> verifyAdminPin(String enteredPin) async {
    final storedPin = await getAdminPin();
    return enteredPin == (storedPin ?? AppConfig.defaultAdminPin);
  }

  Future<String> getDeviceId() async {
    String? id = await _storage.read(key: AppConfig.secureStorageKeyDeviceId);
    if (id == null) {
      id = await _generateHardwareId();
      await _storage.write(key: AppConfig.secureStorageKeyDeviceId, value: id);
    }
    return id;
  }

  Future<void> overrideDeviceId(String newId) async {
    await _storage.write(key: AppConfig.secureStorageKeyDeviceId, value: newId);
  }

  Future<String> _generateHardwareId() async {
    String identifier = "";
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        identifier = "${androidInfo.model}-${androidInfo.hardware}-${androidInfo.fingerprint}";
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        identifier = iosInfo.identifierForVendor ?? iosInfo.model;
      }
    } catch (e) {
      identifier = DateTime.now().toIso8601String();
    }

    final bytes = utf8.encode(identifier);
    final hash = sha256.convert(bytes);

    return hash.toString().substring(0, 25).toLowerCase();
  }

  Future<void> clearApiToken() async {
    await _storage.delete(key: AppConfig.secureStorageKeyApiToken);
  }

  String computeHMAC(String message, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}