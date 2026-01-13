import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/environment.dart';
import '../config/app_config.dart';
import '../widgets/admin_pin_dialog.dart';

class EnterpriseWebViewScreen extends StatefulWidget {
  final String initialUrl;

  const EnterpriseWebViewScreen({
    super.key,
    required this.initialUrl,
  });

  @override
  State<EnterpriseWebViewScreen> createState() => _EnterpriseWebViewScreenState();
}

class _EnterpriseWebViewScreenState extends State<EnterpriseWebViewScreen> {
  late final WebViewController _controller;

  bool _isLoading = true;
  double _loadingProgress = 0;
  bool _connectionError = false;
  bool _isOffline = false;
  String? _errorMessage;

  int _logoTaps = 0;
  Timer? _tapResetTimer;

  Timer? _sessionTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startConnectivityMonitoring();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _tapResetTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _initializeWebView() {
    try {
      final params = const PlatformWebViewControllerCreationParams();
      _controller = WebViewController.fromPlatformCreationParams(params);

      _controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(_buildNavigationDelegate());

      if (_controller.platform is AndroidWebViewController) {
        final androidController = _controller.platform as AndroidWebViewController;
        androidController.setMediaPlaybackRequiresUserGesture(false);
      }

      _loadWebApp();

      if (mounted) setState(() {});
    } catch (e) {
      _handleInitializationError(e);
    }
  }

  NavigationDelegate _buildNavigationDelegate() {
    return NavigationDelegate(
      onProgress: (int progress) {
        if (mounted) {
          setState(() => _loadingProgress = progress / 100);
        }
      },

      onPageStarted: (String url) {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _connectionError = false;
            _errorMessage = null;
          });
        }
      },

      onPageFinished: (String url) async {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        _resetSessionTimer();
      },

      onWebResourceError: (WebResourceError error) {
        _handleResourceError(error);
      },

      onNavigationRequest: (NavigationRequest request) {
        return _validateNavigation(request);
      },
    );
  }

  NavigationDecision _validateNavigation(NavigationRequest request) {
    try {
      final uri = Uri.parse(request.url);

      if (uri.scheme != 'https') {
        return NavigationDecision.prevent;
      }

      if (!Environment.allowedDomains.contains(uri.host)) {
        return NavigationDecision.prevent;
      }

      return NavigationDecision.navigate;

    } catch (e) {
      return NavigationDecision.prevent;
    }
  }

  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(AppConfig.sessionTimeout, () {
      _handleSessionTimeout();
    });
  }

  Future<void> _handleSessionTimeout() async {
    try {
      if (AppConfig.clearCacheOnLogout) {
        await _controller.clearCache();
        await _controller.clearLocalStorage();
      }

      await _loadWebApp();

    } catch (_) {
      // Silent failure
    }
  }

  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      final isConnected = result.isNotEmpty &&
          result.first != ConnectivityResult.none;

      if (mounted) {
        setState(() => _isOffline = !isConnected);
      }

      if (isConnected && _connectionError) {
        _loadWebApp();
      }
    });
  }

  void _handleInitializationError(dynamic error) {
    if (mounted) {
      setState(() {
        _connectionError = true;
        _errorMessage = 'Failed to initialize WebView';
        _isLoading = false;
      });
    }
  }

  void _handleResourceError(WebResourceError error) {
    if (mounted) {
      setState(() {
        _connectionError = true;
        _errorMessage = error.description;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWebApp() async {
    try {
      await _controller.loadRequest(Uri.parse(widget.initialUrl));
    } catch (e) {
      _handleInitializationError(e);
    }
  }

  void _handleLogoTap() {
    _logoTaps++;

    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 2), () {
      setState(() => _logoTaps = 0);
    });

    if (_logoTaps >= 5) {
      _tapResetTimer?.cancel();
      setState(() => _logoTaps = 0);
      _showAdminPinDialog();
    } else {
      setState(() {});
    }
  }

  Future<void> _showAdminPinDialog() async {
    await showAdminPinDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (!_connectionError && !_isOffline)
              WebViewWidget(controller: _controller),

            if (_isOffline) _buildOfflineUI(),

            if (_connectionError && !_isOffline) _buildErrorUI(),

            if (_isLoading && !_connectionError && !_isOffline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.transparent,
                  color: AppColors.accentBlue,
                  minHeight: 3,
                ),
              ),

            if (!_connectionError && !_isOffline)
              Positioned(
                top: 20,
                left: 20,
                child: GestureDetector(
                  onTap: _handleLogoTap,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _logoTaps > 0
                          ? Colors.blue.withValues(alpha: 0.1 * _logoTaps)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(40),
                      border: _logoTaps > 0
                          ? Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: _logoTaps > 0
                          ? Text(
                        '$_logoTaps',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.withValues(alpha: 0.7),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineUI() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 100, color: AppColors.textLight),
          const SizedBox(height: 24),
          const Text(
            'Ingen internettforbindelse',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Vennligst sjekk nettverkstilkoblingen',
            style: TextStyle(fontSize: 16, color: AppColors.textLight),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _loadWebApp,
            icon: const Icon(Icons.refresh),
            label: const Text('PRØV IGJEN'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 100, color: AppColors.errorRed),
          const SizedBox(height: 24),
          const Text(
            'Kunne ikke laste applikasjonen',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textLight),
              ),
            ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _loadWebApp,
            icon: const Icon(Icons.refresh),
            label: const Text('PRØV IGJEN'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}