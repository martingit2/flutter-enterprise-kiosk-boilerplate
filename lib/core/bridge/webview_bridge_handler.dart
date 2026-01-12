import 'dart:convert';
import '../security/security_service.dart';
import '../kiosk_controller.dart';

class WebViewBridgeHandler {
  static final WebViewBridgeHandler _instance = WebViewBridgeHandler._internal();
  factory WebViewBridgeHandler() => _instance;
  WebViewBridgeHandler._internal();

  final _security = SecurityService();

  static const Set<String> _allowedCommands = {
    'REQUEST_UNLOCK',
    'ADMIN_UNLOCK',
    'LOG_EVENT',
    'USER_ACTIVITY',
    'GET_DEVICE_ID',
    'LOGOUT',
  };

  Future<String?> handleMessage(String rawMessage) async {
    try {
      final Map<String, dynamic> message = jsonDecode(rawMessage);

      if (!_validateMessageStructure(message)) {
        return _errorResponse('Invalid message structure');
      }

      final command = message['command'] as String;
      if (!_allowedCommands.contains(command)) {
        return _errorResponse('Unauthorized command');
      }

      return await _processCommand(message);
    } catch (e) {
      return _errorResponse('Internal bridge error');
    }
  }

  bool _validateMessageStructure(Map<String, dynamic> message) {
    return message.containsKey('command') &&
        message.containsKey('payload') &&
        message['command'] is String &&
        message['payload'] is Map;
  }

  Future<String?> _processCommand(Map<String, dynamic> message) async {
    final command = message['command'] as String;

    switch (command) {
      case 'ADMIN_UNLOCK':
      case 'REQUEST_UNLOCK':
        await KioskController.unlockDevice();
        return _successResponse({'unlocked': true});

      case 'GET_DEVICE_ID':
        final id = await _security.getDeviceId();
        return _successResponse({'device_id': id});

      case 'USER_ACTIVITY':
        return _successResponse({'status': 'acknowledged'});

      case 'LOGOUT':
        return _successResponse({'status': 'session_cleared'});

      default:
        return _errorResponse('Command execution failed');
    }
  }

  String _successResponse(Map<String, dynamic> data) {
    return jsonEncode({
      'success': true,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  String _errorResponse(String message) {
    return jsonEncode({
      'success': false,
      'error': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static String generateBridgeScript() {
    return '''
    (function() {
      window.FlutterBridge = {
        async sendCommand(command, payload = {}) {
          try {
            const message = JSON.stringify({
              command: command,
              timestamp: Date.now(),
              payload: payload
            });
            
            if (window.FlutterKioskBridge) {
              window.FlutterKioskBridge.postMessage(message);
            }
          } catch (error) {
            console.error('Bridge error:', error);
          }
        },
        
        userActivity() {
          this.sendCommand('USER_ACTIVITY', {});
        },
        
        requestAdminUnlock() {
          this.sendCommand('ADMIN_UNLOCK', {});
        },
        
        getDeviceId() {
          return this.sendCommand('GET_DEVICE_ID', {});
        }
      };
    })();
    ''';
  }
}