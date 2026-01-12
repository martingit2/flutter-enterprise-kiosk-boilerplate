import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/environment.dart';

enum AuthStatus { authenticated, deviceNotRegistered, networkError, serverError }

class AuthResult {
  final AuthStatus status;
  final String? targetUrl;
  final String? errorMessage;

  AuthResult({required this.status, this.targetUrl, this.errorMessage});
}

class AuthService {
  final http.Client _client = http.Client();
  final WebViewCookieManager _cookieManager = WebViewCookieManager();

  Future<AuthResult> authenticateDevice(String deviceId) async {
    final urlString = '${Environment.webAppUrl}/api/v1/autoauth';
    final url = Uri.parse(urlString);

    debugPrint('🛑 DEBUG START ------------------------------------------------');
    debugPrint('1. Prøver å koble til: $urlString');
    debugPrint('2. Enhets-ID (Serial): $deviceId');

    try {
      final request = http.Request('POST', url);
      request.bodyFields = {'serial': deviceId};

      request.followRedirects = false;

      debugPrint('3. Sender forespørsel nå (Timeout: 5 sekunder)...');

      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Klarte ikke å nå serveren innen 5 sekunder.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('4. Svar mottatt fra server!');
      debugPrint('   Status kode: ${response.statusCode}');
      debugPrint('   Headers: ${response.headers}');

      if (response.statusCode != 302) {
        debugPrint('   Body: ${response.body}');
      }

      if (response.statusCode == 302) {
        final String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          debugPrint('   Fant cookie, injiserer i WebView...');
          await _injectSessionCookie(rawCookie, url.host);
        }

        final String? location = response.headers['location'];
        if (location != null) {
          final targetUrl = location.startsWith('http')
              ? location
              : '${Environment.webAppUrl}$location';

          debugPrint('✅ SUKSESS! Omdirigerer til: $targetUrl');
          return AuthResult(
              status: AuthStatus.authenticated, targetUrl: targetUrl);
        }

        return AuthResult(
            status: AuthStatus.serverError,
            errorMessage: 'Mangler Location header i svar fra server');

      } else if (response.statusCode == 400) {
        debugPrint('⚠️ FEIL (400): Enheten er ikke registrert i Django Admin ennå.');
        return AuthResult(status: AuthStatus.deviceNotRegistered, errorMessage: response.body);

      } else {
        debugPrint('❌ SERVER FEIL: ${response.statusCode}');
        return AuthResult(
            status: AuthStatus.serverError,
            errorMessage: 'Status code: ${response.statusCode}');
      }

    } on SocketException catch (e) {
      debugPrint('❌ NETTVERKSFEIL (SocketException):');
      debugPrint('   Dette betyr at appen ikke finner serveren på $urlString');
      debugPrint('   Sjekk at serveren kjører og at IP-adressen er riktig.');
      debugPrint('   Feilmelding: ${e.message}');
      return AuthResult(
          status: AuthStatus.networkError,
          errorMessage: 'Ingen kontakt med server (Connection Refused)');

    } on TimeoutException {
      debugPrint('❌ TIMEOUT:');
      debugPrint('   Serveren svarte ikke. Dette er nesten alltid Windows Brannmur.');
      return AuthResult(
          status: AuthStatus.networkError,
          errorMessage: 'Tidsavbrudd - Sjekk brannmur på PC');

    } catch (e) {
      debugPrint('❌ UKJENT FEIL: $e');
      return AuthResult(
          status: AuthStatus.networkError,
          errorMessage: e.toString());
    } finally {
      debugPrint('🛑 DEBUG SLUTT ------------------------------------------------');
    }
  }

  Future<void> _injectSessionCookie(String rawCookie, String domain) async {
    try {
      final simpleCookie = rawCookie.split(';').first;
      final parts = simpleCookie.split('=');

      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();

        await _cookieManager.setCookie(
          WebViewCookie(
            name: key,
            value: value,
            domain: domain,
            path: '/',
          ),
        );
      }
    } catch (e) {
      debugPrint('Cookie injection failed: $e');
    }
  }
}