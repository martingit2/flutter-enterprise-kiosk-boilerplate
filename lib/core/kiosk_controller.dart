import 'dart:io';
import 'package:flutter/services.dart';

class KioskController {
  static const platform = MethodChannel('com.taskhamster.kiosk/control');

  static Future<void> lockDevice() async {
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('startLockTask');
      } catch (_) {}
    }
  }

  static Future<void> unlockDevice() async {
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('stopLockTask');
      } catch (_) {}
    }
  }
}