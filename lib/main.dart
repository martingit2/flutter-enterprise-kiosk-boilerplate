import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_config.dart';
import 'core/security/security_service.dart';
import 'core/network/auth_service.dart';
import 'core/kiosk_wrapper.dart';
import 'screens/enterprise_webview_screen.dart';
import 'screens/device_registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await dotenv.load(fileName: ".env"); } catch (_) {}
  runApp(const TaskhamsterApp());
}

class TaskhamsterApp extends StatefulWidget {
  const TaskhamsterApp({super.key});
  @override
  State<TaskhamsterApp> createState() => _TaskhamsterAppState();
}

class _TaskhamsterAppState extends State<TaskhamsterApp> {
  final _security = SecurityService();
  final _auth = AuthService();

  bool _isInitialized = false;
  bool _isFatalError = false;
  String? _statusMessage;
  String? _deviceId;
  String? _targetUrl;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await WakelockPlus.enable();
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await _security.initializeAdminPin();

      _deviceId = await _security.getDeviceId();

      await _runAuth();
    } catch (e) {
      setState(() {
        _statusMessage = "CRITICAL BOOT ERROR: $e";
        _isFatalError = true;
        _isInitialized = true;
      });
    }
  }

  Future<void> _runAuth() async {
    if (_deviceId == null) return;

    setState(() => _statusMessage = "Kobler til server...");

    final result = await _auth.authenticateDevice(_deviceId!);

    if (mounted) {
      setState(() {
        if (result.status == AuthStatus.authenticated) {
          _isRegistered = true;
          _targetUrl = result.targetUrl;
          _statusMessage = null;
        } else if (result.status == AuthStatus.deviceNotRegistered) {
          _isRegistered = false;
          _statusMessage = "Enhet ikke registrert i database (400)";
        } else {
          _isRegistered = false;
          _statusMessage = "Nettverksfeil: ${result.errorMessage}";
        }
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accentBlue),
        useMaterial3: true,
      ),
      home: _buildRoot(),
    );
  }

  Widget _buildRoot() {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isFatalError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(_statusMessage ?? 'Fatal Error', style: const TextStyle(color: Colors.red)),
          ),
        ),
      );
    }

    if (!_isRegistered) {
      return DeviceRegistrationScreen(
        deviceId: _deviceId ?? 'UNKNOWN',
        statusMessage: _statusMessage,
        onRetry: _runAuth,
        onManualOverride: (String manualId) async {
          await _security.overrideDeviceId(manualId);
          setState(() {
            _deviceId = manualId;
            _statusMessage = "ID oppdatert. Prøver på nytt...";
          });
          _runAuth();
        },
      );
    }

    return KioskWrapper(
      child: EnterpriseWebViewScreen(initialUrl: _targetUrl!),
    );
  }
}