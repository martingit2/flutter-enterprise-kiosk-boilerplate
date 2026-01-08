import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../security/security_service.dart';

class WebViewBridgeHandler {
  static final WebViewBridgeHandler _instance = WebViewBridgeHandler._internal();
  factory WebViewBridgeHandler() => _instance;
  WebViewBridgeHandler._internal();

  final _security = SecurityService();

  static String get _bridgeSecret {
    final envSecret = dotenv.env['BRIDGE_SECRET'];
    if (envSecret != null && envSecret.isNotEmpty) {
      return envSecret;
    }

    const dartDefineSecret = String.fromEnvironment('BRIDGE_SECRET');
    if (dartDefineSecret.isNotEmpty) {
      return dartDefineSecret;
    }

    if (kDebugMode) {
      debugPrint('⚠️ WARNING: Using default bridge secret! Set BRIDGE_SECRET in .env');
      return 'CHANGE_THIS_IN_PRODUCTION';
    }

    throw Exception('BRIDGE_SECRET not configured! Set it in .env file.');
  }

  static const Set<String> _allowedCommands = {
    'REQUEST_UNLOCK',
    'ADMIN_UNLOCK',
    'LOG_EVENT',
    'USER_ACTIVITY',
    'GET_DEVICE_ID',
    'LOGOUT',
    'REFRESH_SESSION',
  };

  Future<String?> handleMessage(String rawMessage) async {
    try {
      if (kDebugMode) {
        final preview = rawMessage.substring(0, rawMessage.length > 100 ? 100 : rawMessage.length);
        debugPrint('🌐 WebView Message: $preview...');
      }

      final Map<String, dynamic> message;
      try {
        message = jsonDecode(rawMessage);
      } catch (e) {
        _logSecurityViolation('INVALID_JSON', rawMessage);
        return _errorResponse('Invalid message format');
      }

      if (!_validateMessageStructure(message)) {
        _logSecurityViolation('INVALID_STRUCTURE', message.toString());
        return _errorResponse('Invalid message structure');
      }

      if (!_validateSignature(message)) {
        _logSecurityViolation('INVALID_SIGNATURE', message.toString());
        return _errorResponse('Invalid signature');
      }

      final command = message['command'] as String;
      if (!_allowedCommands.contains(command)) {
        _logSecurityViolation('UNAUTHORIZED_COMMAND', command);
        return _errorResponse('Unauthorized command');
      }

      return await _processCommand(message);

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error handling WebView message: $e');
        debugPrint(stackTrace.toString());
      }
      return _errorResponse('Internal error');
    }
  }

  bool _validateMessageStructure(Map<String, dynamic> message) {
    if (!message.containsKey('command')) return false;
    if (!message.containsKey('timestamp')) return false;
    if (!message.containsKey('signature')) return false;
    if (!message.containsKey('payload')) return false;

    if (message['command'] is! String) return false;
    if (message['timestamp'] is! int && message['timestamp'] is! String) return false;
    if (message['signature'] is! String) return false;
    if (message['payload'] is! Map) return false;

    return true;
  }

  bool _validateSignature(Map<String, dynamic> message) {
    try {
      final command = message['command'] as String;
      final timestamp = message['timestamp'].toString();
      final payload = jsonEncode(message['payload']);
      final signature = message['signature'] as String;

      final messageTime = int.tryParse(timestamp);
      if (messageTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final age = now - messageTime;
        if (age > 300000) {
          if (kDebugMode) {
            debugPrint('⚠️ Message timestamp too old: ${age}ms');
          }
          return false;
        }
      }

      final data = '$command:$timestamp:$payload';
      final expectedSignature = _security.computeHMAC(data, _bridgeSecret);

      return signature == expectedSignature;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Signature validation error: $e');
      }
      return false;
    }
  }

  Future<String?> _processCommand(Map<String, dynamic> message) async {
    final command = message['command'] as String;
    final payload = message['payload'] as Map<String, dynamic>;

    if (kDebugMode) {
      debugPrint('✅ Processing command: $command');
    }

    switch (command) {
      case 'REQUEST_UNLOCK':
        return await _handleRequestUnlock(payload);
      case 'ADMIN_UNLOCK':
        return await _handleAdminUnlock(payload);
      case 'LOG_EVENT':
        return await _handleLogEvent(payload);
      case 'USER_ACTIVITY':
        return await _handleUserActivity(payload);
      case 'GET_DEVICE_ID':
        return await _handleGetDeviceId(payload);
      case 'LOGOUT':
        return await _handleLogout(payload);
      case 'REFRESH_SESSION':
        return await _handleRefreshSession(payload);
      default:
        return _errorResponse('Command not implemented');
    }
  }

  Future<String> _handleRequestUnlock(Map<String, dynamic> payload) async {
    if (kDebugMode) {
      debugPrint('🔓 Unlock requested from web');
    }
    return _successResponse({'message': 'Unlock request logged'});
  }

  Future<String> _handleAdminUnlock(Map<String, dynamic> payload) async {
    if (kDebugMode) {
      debugPrint('🔐 Admin unlock requested from web');
    }
    return _successResponse({'message': 'Admin unlock not implemented'});
  }

  Future<String> _handleLogEvent(Map<String, dynamic> payload) async {
    final eventName = payload['event'] as String?;
    if (kDebugMode && eventName != null) {
      debugPrint('📊 Event from web: $eventName');
    }
    return _successResponse({'logged': true});
  }

  Future<String> _handleUserActivity(Map<String, dynamic> payload) async {
    return _successResponse({'acknowledged': true});
  }

  Future<String> _handleGetDeviceId(Map<String, dynamic> payload) async {
    final deviceId = await _security.getDeviceId();
    return _successResponse({'device_id': deviceId});
  }

  Future<String> _handleLogout(Map<String, dynamic> payload) async {
    await _security.clearApiToken();
    if (kDebugMode) {
      debugPrint('👋 Logout from web');
    }
    return _successResponse({'logged_out': true});
  }

  Future<String> _handleRefreshSession(Map<String, dynamic> payload) async {
    return _successResponse({'session_refreshed': true});
  }

  void _logSecurityViolation(String type, String details) {
    if (kDebugMode) {
      debugPrint('⚠️ SECURITY VIOLATION: $type');
      debugPrint('   Details: $details');
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
      const BRIDGE_SECRET = '$_bridgeSecret';
      
      async function computeHMAC(message, secret) {
        const encoder = new TextEncoder();
        const keyData = encoder.encode(secret);
        const messageData = encoder.encode(message);
        
        const key = await crypto.subtle.importKey(
          'raw', keyData,
          { name: 'HMAC', hash: 'SHA-256' },
          false, ['sign']
        );
        
        const signature = await crypto.subtle.sign('HMAC', key, messageData);
        const hashArray = Array.from(new Uint8Array(signature));
        return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
      }
      
      window.FlutterBridge = {
        async sendCommand(command, payload = {}) {
          try {
            const timestamp = Date.now();
            const data = command + ':' + timestamp + ':' + JSON.stringify(payload);
            const signature = await computeHMAC(data, BRIDGE_SECRET);
            
            const message = JSON.stringify({
              command: command,
              timestamp: timestamp,
              payload: payload,
              signature: signature
            });
            
            if (window.FlutterKioskBridge) {
              window.FlutterKioskBridge.postMessage(message);
            }
          } catch (error) {
            console.error('Bridge error:', error);
          }
        },
        
        logEvent(event, data) {
          this.sendCommand('LOG_EVENT', { event, data });
        },
        
        userActivity(action) {
          this.sendCommand('USER_ACTIVITY', { action });
        },
        
        requestAdminUnlock() {
          this.sendCommand('ADMIN_UNLOCK', {});
        },
        
        logout() {
          this.sendCommand('LOGOUT', {});
        }
      };
      
      console.log('✅ Flutter Bridge ready (secret loaded from .env)');
    })();
    ''';
  }
}
