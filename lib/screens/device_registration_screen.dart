import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';

class DeviceRegistrationScreen extends StatelessWidget {
  final String deviceId;
  final String? statusMessage;
  final VoidCallback onRetry;
  final Function(String) onManualOverride;

  const DeviceRegistrationScreen({
    super.key,
    required this.deviceId,
    this.statusMessage,
    required this.onRetry,
    required this.onManualOverride,
  });

  void _showManualDialog(BuildContext context) {
    final controller = TextEditingController(text: deviceId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Serial Override'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kun for admin: Overstyr Enhets-ID hvis databasen har en annen verdi.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Serial Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('AVBRYT')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onManualOverride(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('OPPDATER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isError = statusMessage != null && !statusMessage!.contains("Kobler til");

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onLongPress: () => _showManualDialog(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isError ? Colors.red.withValues(alpha: 0.1) : AppColors.accentOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError ? Icons.wifi_off : Icons.phonelink_setup,
                      size: 48,
                      color: isError ? Colors.red : AppColors.accentOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isError ? 'Tilkoblingsfeil' : 'Enhet ikke registrert',
                  style: AppTextStyles.heading1,
                  textAlign: TextAlign.center,
                ),
                if (statusMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isError ? Colors.red.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isError ? Colors.red.shade100 : Colors.blue.shade100),
                      ),
                      child: Text(
                        statusMessage!,
                        style: TextStyle(
                          color: isError ? Colors.red.shade800 : Colors.blue.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Text(
                      'Send ID nedenfor til administrator for å aktivere.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ENHETS-ID',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        deviceId,
                        style: const TextStyle(
                          fontFamily: 'Monospace',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.primaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Share.share("Kiosk Device ID: $deviceId"),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('DEL ID TIL ADMIN'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text("Vis QR-kode", textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: QrImageView(data: deviceId, size: 160),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'PRØV PÅ NYTT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}