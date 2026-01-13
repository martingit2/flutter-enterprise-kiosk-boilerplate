import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/device_registration_screen.dart';
import 'screens/enterprise_webview_screen.dart';
import 'core/network/auth_service.dart';
import 'core/security/security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const TaskhamsterApp());
}

class TaskhamsterApp extends StatelessWidget {
  const TaskhamsterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskhamster Hub',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const InitializationScreen(),
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final securityService = SecurityService();
    final authService = AuthService();
    final deviceId = await securityService.getDeviceId();
    final authResult = await authService.authenticateDevice(deviceId);

    if (!mounted) return;

    if (authResult.status == AuthStatus.authenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EnterpriseWebViewScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceRegistrationScreen(
            deviceId: deviceId,
            statusMessage: authResult.errorMessage,
            onRetry: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const InitializationScreen()),
              );
            },
            onManualOverride: (newDeviceId) async {
              await securityService.overrideDeviceId(newDeviceId);
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const InitializationScreen()),
                );
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}