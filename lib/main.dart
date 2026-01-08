import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'config/environment.dart';
import 'config/app_config.dart';
import 'core/security/security_service.dart';
import 'core/security/tamper_detection_service.dart';
import 'core/kiosk_wrapper.dart';
import 'screens/enterprise_webview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Print configuration
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

  bool _isInitialized = false;
  bool _initializationFailed = false;
  String? _errorMessage;
  bool _deviceTampered = false;

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
    // Re-hide system UI when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _hideSystemUI();
    }
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Enable wakelock
      await WakelockPlus.enable();
      debugPrint('✅ Wakelock enabled');

      // 2. Hide system UI AGGRESSIVELY
      await _hideSystemUI();
      debugPrint('✅ System UI hidden');

      // 3. Initialize security (encrypted storage, PIN)
      await _security.initializeAdminPin();
      debugPrint('✅ Security initialized');

      // 4. Check device integrity
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

      // 5. All checks passed
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
    // KRITISK: Disse må kalles i rekkefølge for å fungere
    try {
      // 1. Først sett immersive sticky mode
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [], // Ingen overlays i det hele tatt
      );

      // 2. Deretter tvinger vi landscape (dette "reloader" systemet)
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);

      // 3. Til slutt skjuler vi status/navigation bars eksplisitt
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );

      debugPrint('✅ System UI hidden (immersiveSticky)');
    } catch (e) {
      debugPrint('⚠️ Failed to hide system UI: $e');
    }
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

    return const KioskWrapper(
      child: EnterpriseWebViewScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Laster Taskhamster...',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textDark,
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