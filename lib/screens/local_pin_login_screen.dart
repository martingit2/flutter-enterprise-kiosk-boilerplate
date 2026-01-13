import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../core/security/security_service.dart';
import '../core/security/device_identification_service.dart';
import '../core/security/local_authentication_service.dart';

class LocalPinLoginScreen extends StatefulWidget {
  final Function(String userId) onLoginSuccess;

  const LocalPinLoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LocalPinLoginScreen> createState() => _LocalPinLoginScreenState();
}

class _LocalPinLoginScreenState extends State<LocalPinLoginScreen> {
  final _security = SecurityService();
  final _deviceId = DeviceIdentificationService();
  final _localAuth = LocalAuthenticationService();
  final _pinController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showDeviceInfo = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_pinController.text.isEmpty) {
      setState(() => _errorMessage = 'Vennligst skriv inn PIN-kode');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await _security.verifyAdminPin(_pinController.text);

      if (isValid) {
        final authResult = await _localAuth.registerDevice();

        if (authResult.success) {
          widget.onLoginSuccess(authResult.userId!);
        } else {
          setState(() {
            _errorMessage = 'Registration failed';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Feil PIN-kode';
          _isLoading = false;
        });
        _pinController.clear();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login feilet';
        _isLoading = false;
      });
    }
  }

  void _toggleDeviceInfo() {
    setState(() => _showDeviceInfo = !_showDeviceInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: AppColors.accentBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  AppConfig.appTitle,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enterprise Kiosk Mode',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Skriv inn PIN',
                          hintStyle: const TextStyle(
                            color: AppColors.textLight,
                            letterSpacing: 2,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                        ),
                        onSubmitted: (_) => _handleLogin(),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.errorRed,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.errorRed,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'LÅS OPP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                TextButton.icon(
                  onPressed: _toggleDeviceInfo,
                  icon: Icon(
                    _showDeviceInfo ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textLight,
                  ),
                  label: const Text(
                    'Device Information',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_showDeviceInfo)
                  FutureBuilder<DeviceInfo>(
                    future: _deviceId.getDeviceInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Text('Failed to load device info');
                      }

                      final info = snapshot.data!;

                      return Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.textLight.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('Fingerprint', info.fingerprint),
                            _buildInfoRow('Serial', info.serialNumber),
                            _buildInfoRow('Android ID', info.androidId),
                            _buildInfoRow('Manufacturer', info.manufacturer),
                            _buildInfoRow('Model', info.model),
                            _buildInfoRow('Brand', info.brand),
                            _buildInfoRow('Android', info.androidVersion),
                            _buildInfoRow('SDK', info.sdkVersion.toString()),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Denne enheten vil registreres for auto-login',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}