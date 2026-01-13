import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import '../config/environment.dart';
import '../core/kiosk_controller.dart';
import '../core/kiosk_wrapper.dart';

class EnterpriseWebViewScreen extends StatefulWidget {
  const EnterpriseWebViewScreen({super.key});

  @override
  State<EnterpriseWebViewScreen> createState() => _EnterpriseWebViewScreenState();
}

class _EnterpriseWebViewScreenState extends State<EnterpriseWebViewScreen> {
  late final WebViewController _webViewController;
  bool _isKioskLocked = true;

  @override
  void initState() {
    super.initState();
    _lockKiosk();
    _initializeWebView();
  }

  Future<void> _lockKiosk() async {
    await _setupFullscreen();
    await _enableWakelock();
    setState(() {
      _isKioskLocked = true;
    });
  }

  Future<void> _setupFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  Future<void> _enableWakelock() async {
    await WakelockPlus.enable();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterUnlock',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'unlock') {
            _unlockKiosk();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            _injectUnlockScript();
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(Environment.webAppUrl));
  }

  void _injectUnlockScript() {
    _webViewController.runJavaScript('''
      (function() {
        if (window.unlockInjected) return;
        window.unlockInjected = true;
        
        const style = document.createElement('style');
        style.textContent = \`
          #flutter-unlock-button {
            position: fixed;
            top: 8px;
            right: 20px;
            width: 60px;
            height: 60px;
            z-index: 999999;
            pointer-events: all;
            cursor: pointer;
          }
          #flutter-unlock-button .lock-part {
            transition: all 0.4s ease;
          }
          #flutter-unlock-button #lock-shackle {
            transform-origin: center;
            transition: transform 0.4s ease;
          }
          #flutter-unlock-button .badge {
            position: absolute;
            bottom: -8px;
            left: 50%;
            transform: translateX(-50%);
            background: #10B981;
            color: white;
            border-radius: 8px;
            padding: 3px 8px;
            font-size: 12px;
            font-weight: bold;
            box-shadow: 0 2px 4px rgba(16, 185, 129, 0.3);
          }
        \`;
        document.head.appendChild(style);
        
        const container = document.createElement('div');
        container.id = 'flutter-unlock-button';
        container.innerHTML = \`
          <svg width="60" height="60" viewBox="0 0 60 60">
            <g transform="translate(30, 30)">
              <path id="lock-shackle" class="lock-part"
                    d="M -8 2 L -8 -6 Q -8 -14 0 -14 Q 8 -14 8 -6 L 8 2" 
                    stroke="white" stroke-width="3.5" fill="none" stroke-linecap="round"/>
              <rect id="lock-body" class="lock-part"
                    x="-12" y="2" width="24" height="22" rx="3"
                    stroke="white" stroke-width="3.5" fill="none"/>
              <circle id="lock-keyhole" class="lock-part" cx="0" cy="13" r="2.5" fill="white"/>
            </g>
          </svg>
          <div class="badge" style="display: none;">0</div>
        \`;
        document.body.appendChild(container);
        
        let tapCount = 0;
        let tapTimer = null;
        const parts = ['lock-shackle', 'lock-body', 'lock-keyhole'];
        
        function updateLockParts(count) {
          const shackle = document.getElementById('lock-shackle');
          parts.forEach((partId, index) => {
            const part = document.getElementById(partId);
            if (!part) return;
            if (index < count) {
              if (partId === 'lock-keyhole') {
                part.setAttribute('fill', '#10B981');
              } else {
                part.setAttribute('stroke', '#10B981');
              }
            } else {
              if (partId === 'lock-keyhole') {
                part.setAttribute('fill', 'white');
              } else {
                part.setAttribute('stroke', 'white');
              }
            }
          });
          if (count >= 3) {
            shackle.style.transform = 'translate(0, -8px)';
          } else {
            shackle.style.transform = 'translate(0, 0)';
          }
        }
        
        container.addEventListener('click', function() {
          tapCount++;
          const badge = container.querySelector('.badge');
          updateLockParts(tapCount);
          if (tapCount > 0 && tapCount < 3) {
            badge.textContent = tapCount;
            badge.style.display = 'block';
          }
          if (tapTimer) clearTimeout(tapTimer);
          if (tapCount >= 3) {
            setTimeout(function() {
              badge.style.display = 'none';
              updateLockParts(0);
              tapCount = 0;
              window.FlutterUnlock.postMessage('unlock');
            }, 300);
          } else {
            tapTimer = setTimeout(function() {
              tapCount = 0;
              updateLockParts(0);
              badge.style.display = 'none';
            }, 2000);
          }
        });
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return KioskWrapper(
      child: Scaffold(
        body: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (!_isKioskLocked)
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_open, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kiosk modus er deaktivert',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _relockKiosk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Lås Kiosk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlockKiosk() async {
    await KioskController.unlockDevice();
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    setState(() {
      _isKioskLocked = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kiosk modus deaktivert'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _relockKiosk() async {
    await _lockKiosk();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.lock, color: Colors.white),
              SizedBox(width: 12),
              Text('Kiosk modus aktivert!'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }
}