import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class KioskController {
  static const platform = MethodChannel('com.taskhamster.kiosk/control');

  static Future<void> lockDevice() async {
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('startLockTask');
      } catch (e) {
        debugPrint("Kiosk Lock Error: $e");
      }
    }
  }

  static Future<void> unlockDevice() async {
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('stopLockTask');
      } catch (e) {
        debugPrint("Kiosk Unlock Error: $e");
      }
    }
  }
}