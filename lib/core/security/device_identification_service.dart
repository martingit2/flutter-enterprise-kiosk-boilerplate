import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentificationService {
  static final DeviceIdentificationService _instance = DeviceIdentificationService._internal();
  factory DeviceIdentificationService() => _instance;
  DeviceIdentificationService._internal();

  final _deviceInfo = DeviceInfoPlugin();
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );

  static const String _deviceIdKey = 'device_fingerprint';
  static const String _deviceRegistrationKey = 'device_registered';

  Future<String> getDeviceFingerprint() async {
    final cached = await _secureStorage.read(key: _deviceIdKey);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final fingerprint = await _generateDeviceFingerprint();
    await _secureStorage.write(key: _deviceIdKey, value: fingerprint);

    return fingerprint;
  }

  Future<String> _generateDeviceFingerprint() async {
    final androidInfo = await _deviceInfo.androidInfo;

    final components = <String>[
      androidInfo.serialNumber,
      androidInfo.id,
      androidInfo.board,
      androidInfo.bootloader,
      androidInfo.brand,
      androidInfo.device,
      androidInfo.hardware,
      androidInfo.manufacturer,
      androidInfo.model,
      androidInfo.product,
    ];

    final combined = components.where((c) => c.isNotEmpty).join('|');
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }

  Future<String?> getHardwareSerial() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.serialNumber;
    } catch (e) {
      return null;
    }
  }

  Future<DeviceInfo> getDeviceInfo() async {
    final androidInfo = await _deviceInfo.androidInfo;
    final fingerprint = await getDeviceFingerprint();

    return DeviceInfo(
      fingerprint: fingerprint,
      serialNumber: androidInfo.serialNumber,
      androidId: androidInfo.id,
      manufacturer: androidInfo.manufacturer,
      model: androidInfo.model,
      brand: androidInfo.brand,
      device: androidInfo.device,
      androidVersion: androidInfo.version.release,
      sdkVersion: androidInfo.version.sdkInt,
      buildId: androidInfo.id,
    );
  }

  Future<bool> isDeviceRegistered() async {
    final registered = await _secureStorage.read(key: _deviceRegistrationKey);
    return registered == 'true';
  }

  Future<void> markDeviceRegistered() async {
    await _secureStorage.write(key: _deviceRegistrationKey, value: 'true');
  }

  Future<void> clearDeviceRegistration() async {
    await _secureStorage.delete(key: _deviceRegistrationKey);
  }

  Future<bool> validateDeviceIntegrity() async {
    try {
      final stored = await _secureStorage.read(key: _deviceIdKey);
      if (stored == null) return true;

      final current = await _generateDeviceFingerprint();
      return stored == current;
    } catch (e) {
      return false;
    }
  }

  Future<DeviceAttestation> generateAttestation() async {
    final deviceInfo = await getDeviceInfo();
    final timestamp = DateTime.now().toUtc().toIso8601String();

    final payload = {
      'fingerprint': deviceInfo.fingerprint,
      'serial': deviceInfo.serialNumber,
      'timestamp': timestamp,
      'model': deviceInfo.model,
      'manufacturer': deviceInfo.manufacturer,
    };

    final payloadJson = jsonEncode(payload);
    final bytes = utf8.encode(payloadJson);
    final signature = sha256.convert(bytes).toString();

    return DeviceAttestation(
      payload: payload,
      signature: signature,
      timestamp: timestamp,
    );
  }
}

class DeviceInfo {
  final String fingerprint;
  final String serialNumber;
  final String androidId;
  final String manufacturer;
  final String model;
  final String brand;
  final String device;
  final String androidVersion;
  final int sdkVersion;
  final String buildId;

  DeviceInfo({
    required this.fingerprint,
    required this.serialNumber,
    required this.androidId,
    required this.manufacturer,
    required this.model,
    required this.brand,
    required this.device,
    required this.androidVersion,
    required this.sdkVersion,
    required this.buildId,
  });

  Map<String, dynamic> toJson() => {
    'fingerprint': fingerprint,
    'serial_number': serialNumber,
    'android_id': androidId,
    'manufacturer': manufacturer,
    'model': model,
    'brand': brand,
    'device': device,
    'android_version': androidVersion,
    'sdk_version': sdkVersion,
    'build_id': buildId,
  };

  String toReadableString() {
    return '''
Device Fingerprint: $fingerprint
Serial Number: $serialNumber
Android ID: $androidId
Manufacturer: $manufacturer
Model: $model
Brand: $brand
Device: $device
Android Version: $androidVersion
SDK Version: $sdkVersion
Build ID: $buildId
''';
  }
}

class DeviceAttestation {
  final Map<String, dynamic> payload;
  final String signature;
  final String timestamp;

  DeviceAttestation({
    required this.payload,
    required this.signature,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'payload': payload,
    'signature': signature,
    'timestamp': timestamp,
  };
}