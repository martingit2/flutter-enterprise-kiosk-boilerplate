import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../security/security_service.dart';

/// Secure WebView Bridge Handler
/// Validates and processes messages from web content to native code
class WebViewBridgeHandler {
  static final WebViewBridgeHandler _instance = WebViewBridgeHandler._internal();
  factory WebViewBridgeHandler() => _instance;
  WebViewBridgeHandler._internal();

  final _security = SecurityService();

  // Context for showing dialogs
  BuildContext? _context;

  void setContext(BuildContext context) {
    _context = context;
  }

  // ⚠️ SECURITY WARNING:
  // Dette er bridge secret som brukes til HMAC-validering.
  // I PRODUKSJON bør dette:
  // 1. Genereres dynamisk ved build-tid (--dart-define)
  //
  // Generer med: openssl rand -base64 32
  static const String _bridgeSecret = String.fromEnvironment(
    'BRIDGE_SECRET',
    defaultValue: 'CHANGE_THIS_IN_PRODUCTION',  // Fallback for testing
  );

  // Whitelist of allowed commands
  static const Set<String> _allowedCommands = {
    'REQUEST_UNLOCK',
    'ADMIN_UNLOCK',        // Admin unlock fra logo klikk
    'LOG_EVENT',
    'USER_ACTIVITY',
    'GET_DEVICE_ID',
    'LOGOUT',
    'REFRESH_SESSION',
  };

  /// Handle incoming message from WebView
  Future<String?> handleMessage(String rawMessage) async {
    try {
      if (kDebugMode) {
        print('🌐 WebView Message: ${rawMessage.substring(0, rawMessage.length > 100 ? 100 : rawMessage.length)}...');
      }

      // Parse JSON message
      final Map<String, dynamic> message;
      try {
        message = jsonDecode(rawMessage);
      } catch (e) {
        _logSecurityViolation('INVALID_JSON', rawMessage);
        return _errorResponse('Invalid message format');
      }

      // Validate message structure
      if (!_validateMessageStructure(message)) {
        _logSecurityViolation('INVALID_STRUCTURE', message.toString());
        return _errorResponse('Invalid message structure');
      }

      // Validate HMAC signature
      if (!_validateSignature(message)) {
        _logSecurityViolation('INVALID_SIGNATURE', message.toString());
        return _errorResponse('Invalid signature');
      }

      // Validate command whitelist
      final command = message['command'] as String;
      if (!_allowedCommands.contains(command)) {
        _logSecurityViolation('UNAUTHORIZED_COMMAND', command);
        return _errorResponse('Unauthorized command');
      }

      // Process command
      return await _processCommand(message);

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error handling WebView message: $e');
        print(stackTrace);
      }
      return _errorResponse('Internal error');
    }
  }

  /// Validate message structure
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

  /// Validate HMAC signature
  bool _validateSignature(Map<String, dynamic> message) {
    try {
      final command = message['command'] as String;
      final timestamp = message['timestamp'].toString();
      final payload = jsonEncode(message['payload']);
      final signature = message['signature'] as String;

      // Check timestamp freshness (within 5 minutes)
      final messageTime = int.tryParse(timestamp);
      if (messageTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final age = now - messageTime;
        if (age > 300000) { // 5 minutes
          if (kDebugMode) {
            print('⚠️ Message timestamp too old: ${age}ms');
          }
          return false;
        }
      }

      // Compute expected signature
      final data = '$command:$timestamp:$payload';
      final expectedSignature = _security.computeHMAC(data, _bridgeSecret);

      return signature == expectedSignature;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Signature validation error: $e');
      }
      return false;
    }
  }

  /// Process validated command
  Future<String?> _processCommand(Map<String, dynamic> message) async {
    final command = message['command'] as String;
    final payload = message['payload'] as Map<String, dynamic>;

    if (kDebugMode) {
      print('✅ Processing command: $command');
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

  /// Command handlers
  Future<String> _handleRequestUnlock(Map<String, dynamic> payload) async {
    if (kDebugMode) {
      print('🔓 Unlock requested from web');
    }
    return _successResponse({'message': 'Unlock request logged'});
  }

  /// NEW: Handle admin unlock from logo click
  Future<String> _handleAdminUnlock(Map<String, dynamic> payload) async {
    if (kDebugMode) {
      print('🔐 Admin unlock requested from web (logo click)');
    }

    if (_context == null) {
      return _errorResponse('No context available');
    }

    try {
      // Import the dialog dynamically
      final module = await import('../widgets/admin_pin_dialog.dart');
      final showAdminPinDialog = module.showAdminPinDialog as Future<bool> Function(BuildContext);

      final unlocked = await showAdminPinDialog(_context!);

      if (unlocked) {
        return _successResponse({
          'unlocked': true,
          'message': 'Device unlocked successfully'
        });
      } else {
        return _errorResponse('Unlock cancelled or failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Admin unlock error: $e');
      }
      return _errorResponse('Failed to show unlock dialog');
    }
  }

  Future<String> _handleLogEvent(Map<String, dynamic> payload) async {
    final eventName = payload['event'] as String?;
    if (kDebugMode && eventName != null) {
      print('📊 Event from web: $eventName');
    }
    return _successResponse({'logged': true});
  }

  Future<String> _handleUserActivity(Map<String, dynamic> payload) async {
    // Reset idle timers, etc.
    return _successResponse({'acknowledged': true});
  }

  Future<String> _handleGetDeviceId(Map<String, dynamic> payload) async {
    final deviceId = await _security.getDeviceId();
    return _successResponse({'device_id': deviceId});
  }

  Future<String> _handleLogout(Map<String, dynamic> payload) async {
    await _security.clearApiToken();
    if (kDebugMode) {
      print('👋 Logout from web');
    }
    return _successResponse({'logged_out': true});
  }

  Future<String> _handleRefreshSession(Map<String, dynamic> payload) async {
    return _successResponse({'session_refreshed': true});
  }

  /// Security logging
  void _logSecurityViolation(String type, String details) {
    if (kDebugMode) {
      print('⚠️ SECURITY VIOLATION: $type');
      print('   Details: $details');
    }
  }

  /// Response helpers
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

  /// Generate JavaScript code for web app
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
      
      // EXAMPLE: Logo click handler (add to your logo element)
      // let logoClickCount = 0;
      // let logoClickTimer = null;
      //
      // document.querySelector('.your-logo-class').addEventListener('click', () => {
      //   logoClickCount++;
      //   
      //   clearTimeout(logoClickTimer);
      //   logoClickTimer = setTimeout(() => {
      //     logoClickCount = 0;
      //   }, 2000);
      //   
      //   if (logoClickCount === 5) {
      //     logoClickCount = 0;
      //     window.FlutterBridge.requestAdminUnlock();
      //   }
      // });
      
      console.log('✅ Flutter Bridge ready');
    })();
    ''';
  }
}

// Helper function for dynamic import (fallback if not available)
Future<dynamic> import(String path) async {
  // This is a placeholder - in real Flutter, use actual import
  throw UnsupportedError('Dynamic import not supported in Flutter');
}