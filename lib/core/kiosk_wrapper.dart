import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../config/theme.dart';
import 'kiosk_controller.dart';

class KioskWrapper extends StatefulWidget {
  final Widget child;
  const KioskWrapper({super.key, required this.child});

  @override
  State<KioskWrapper> createState() => _KioskWrapperState();
}

class _KioskWrapperState extends State<KioskWrapper> with WidgetsBindingObserver {
  Timer? _idleTimer;
  bool _isDimmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(seconds: 2), () => KioskController.lockDevice());

    _resetBrightness();
    _restartIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      KioskController.lockDevice();
      _resetBrightness();
      _restartIdleTimer();
    }
  }

  void _handleUserInteraction() {
    if (_isDimmed) _resetBrightness();
    _restartIdleTimer();
  }

  Future<void> _resetBrightness() async {
    try {
      await ScreenBrightness().resetScreenBrightness();
      if (mounted) setState(() => _isDimmed = false);
    } catch (e) { debugPrint("$e"); }
  }

  Future<void> _dimScreen() async {
    try {
      // Kun fysisk dimming
      await ScreenBrightness().setScreenBrightness(AppConfig.dimmedBrightness);
      if (mounted) setState(() => _isDimmed = true);
    } catch (e) { debugPrint("$e"); }
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(AppConfig.idleTimeout, _dimScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _handleUserInteraction(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          widget.child,

          // USYNLIG TOUCH-VERN
          // Dette laget er nå 100% gjennomsiktig (Colors.transparent).
          // Jobben dens er KUN å fange opp det første trykket når skjermen er dimmet.
          if (_isDimmed)
            Positioned.fill(
              child: Container(
                color: Colors.transparent, // Ingen farge, slipper alt lys gjennom
              ),
            ),
        ],
      ),
    );
  }
}