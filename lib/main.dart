import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/environment.dart';
import 'config/app_config.dart';
import 'core/security/security_service.dart';
import 'core/security/tamper_detection_service.dart';
import 'core/security/device_identification_service.dart';
import 'core/security/local_authentication_service.dart';
import 'core/kiosk_wrapper.dart';
import 'screens/enterprise_webview_screen.dart';
import 'screens/local_pin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env file loaded successfully');
  } catch (e) {
    debugPrint('⚠️ Failed to load .env file: $e');
    debugPrint('⚠️ Using default/fallback values');
  }

  Environment.printConfig();

  runApp(const TaskhamsterApp());
}

class TaskhamsterApp extends StatefulWidget {
  const TaskhamsterApp({super.key});

  @override
  State<TaskhamsterApp> createState() => _TaskhamsterAppState();
}

class _TaskhamsterAppState extends State<TaskhamsterApp> with WidgetsBindingObserver {
  final _security = SecurityService();
  final _tamperDetection = TamperDetectionService();
  final _deviceId = DeviceIdentificationService();
  final _localAuth = LocalAuthenticationService();

  bool _isInitialized = false;
  bool _initializationFailed = false;
  String? _errorMessage;
  bool _deviceTampered = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _hideSystemUI();
    }
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 Initializing app...');

      await WakelockPlus.enable();
      debugPrint('✅ Wakelock enabled');

      await _hideSystemUI();
      debugPrint('✅ System UI hidden');

      await _security.initializeAdminPin();
      debugPrint('✅ Security initialized');

      final deviceInfo = await _deviceId.getDeviceInfo();
      debugPrint('📱 Device Info:');
      debugPrint('   Fingerprint: ${deviceInfo.fingerprint}');
      debugPrint('   Serial: ${deviceInfo.serialNumber}');
      debugPrint('   Model: ${deviceInfo.model}');
      debugPrint('   Manufacturer: ${deviceInfo.manufacturer}');

      if (Environment.enableJailbreakDetection) {
        final integrityResult = await _tamperDetection.checkDeviceIntegrity();
        _deviceTampered = integrityResult.isTampered;

        if (_deviceTampered) {
          _errorMessage = 'Device integrity compromised';
          _initializationFailed = true;

          debugPrint('⚠️ Device tampered: ${integrityResult.details}');

          if (mounted) setState(() => _isInitialized = true);
          return;
        }
      }

      debugPrint('🔐 Attempting auto-login...');
      final authResult = await _localAuth.attemptAutoLogin();

      if (authResult.success) {
        debugPrint('✅ Auto-login successful - User: ${authResult.userId}');
        _isAuthenticated = true;
      } else {
        debugPrint('⚠️ Auto-login failed: ${authResult.message}');
        debugPrint('   User needs to log in with PIN');
        _isAuthenticated = false;
      }

      _isInitialized = true;
      if (mounted) setState(() {});

      debugPrint('✅ App initialization complete');
      debugPrint('🌐 Loading: ${Environment.webAppUrl}');

    } catch (e, stackTrace) {
      debugPrint('❌ App initialization failed: $e');
      debugPrint('$stackTrace');

      _initializationFailed = true;
      _errorMessage = 'Initialization failed: ${e.toString()}';

      if (mounted) setState(() => _isInitialized = true);
    }
  }

  Future<void> _hideSystemUI() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);

      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );

      debugPrint('✅ System UI hidden (immersiveSticky)');
    } catch (e) {
      debugPrint('⚠️ Failed to hide system UI: $e');
    }
  }

  void _onLoginSuccess(String userId) {
    debugPrint('✅ Login successful - User: $userId');
    setState(() => _isAuthenticated = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accentBlue),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    if (_initializationFailed) {
      if (_deviceTampered) {
        return _buildTamperedDeviceScreen();
      }
      return _buildErrorScreen();
    }

    if (!_isAuthenticated) {
      return LocalPinLoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    return const KioskWrapper(
      child: EnterpriseWebViewScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Laster ${AppConfig.appTitle}...',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sjekker device fingerprint...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 24),
              const Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                    _initializationFailed = false;
                    _errorMessage = null;
                  });
                  _initializeApp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('PRØV IGJEN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTamperedDeviceScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security,
                size: 80,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 24),
              const Text(
                'Sikkerhetsadvarsel',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Denne enheten er rooted/jailbreaket og kan ikke kjøre denne applikasjonen av sikkerhetsgrunner.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Kontakt IT-support for hjelp.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}