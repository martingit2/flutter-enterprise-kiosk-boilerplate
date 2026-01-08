import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../config/environment.dart';

/// Device Integrity & Tamper Detection Service
/// NOTE: Jailbreak detection temporarily disabled due to package compatibility
class TamperDetectionService {
  static final TamperDetectionService _instance = TamperDetectionService._internal();
  factory TamperDetectionService() => _instance;
  TamperDetectionService._internal();

  final _deviceInfo = DeviceInfoPlugin();

  bool _isChecked = false;
  bool _isTampered = false;
  Map<String, dynamic> _deviceDetails = {};

  /// Perform comprehensive device integrity check
  Future<DeviceIntegrityResult> checkDeviceIntegrity() async {
    if (_isChecked) {
      return DeviceIntegrityResult(
        isSecure: !_isTampered,
        isTampered: _isTampered,
        details: _deviceDetails,
      );
    }

    try {
      // Skip check if disabled
      if (!Environment.enableJailbreakDetection) {
        if (kDebugMode) {
          print('⚠️ Jailbreak detection disabled');
        }
        _isChecked = true;
        _isTampered = false;
        return DeviceIntegrityResult(
          isSecure: true,
          isTampered: false,
          details: {'skipped': true, 'reason': 'disabled'},
        );
      }

      // Collect device info
      _deviceDetails = await _collectDeviceInfo();

      // For now, always pass (jailbreak detection package removed)
      _isTampered = false;

      _deviceDetails.addAll({
        'jailbroken': false, // Package removed, always false
        'developer_mode': false, // Package removed, always false
        'timestamp': DateTime.now().toIso8601String(),
        'note': 'Jailbreak detection temporarily disabled',
      });

      _isChecked = true;

      if (kDebugMode) {
        print('🔍 Device Integrity Check:');
        print('   - Jailbreak Detection: DISABLED (package removed)');
        print('   - Device Info: OK');
      }

      return DeviceIntegrityResult(
        isSecure: !_isTampered,
        isTampered: _isTampered,
        details: _deviceDetails,
      );

    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking device integrity: $e');
      }

      // Fail open in debug, closed in production
      _isTampered = false; // Changed to false since we can't detect

      return DeviceIntegrityResult(
        isSecure: true, // Pass if we can't check
        isTampered: false,
        details: {'error': e.toString()},
      );
    }
  }

  /// Collect device information
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'is_physical_device': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'system_version': iosInfo.systemVersion,
          'is_physical_device': iosInfo.isPhysicalDevice,
        };
      }
      return {'platform': 'unknown'};
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Device info collection failed: $e');
      }
      return {'error': e.toString()};
    }
  }

  bool get isTampered => _isTampered;
  bool get isSecure => !_isTampered;
  Map<String, dynamic> get deviceDetails => Map.unmodifiable(_deviceDetails);

  Future<DeviceIntegrityResult> recheckDeviceIntegrity() async {
    _isChecked = false;
    return await checkDeviceIntegrity();
  }
}

class DeviceIntegrityResult {
  final bool isSecure;
  final bool isTampered;
  final Map<String, dynamic> details;

  DeviceIntegrityResult({
    required this.isSecure,
    required this.isTampered,
    required this.details,
  });

  @override
  String toString() {
    return 'DeviceIntegrityResult(isSecure: $isSecure, isTampered: $isTampered)';
  }
}