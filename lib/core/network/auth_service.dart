import 'dart:async';
import 'dart:io';
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

    try {
      final request = http.Request('POST', url);
      request.bodyFields = {'serial': deviceId};
      request.followRedirects = false;

      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 302) {
        final String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          await _injectSessionCookie(rawCookie, url.host);
        }

        final String? location = response.headers['location'];
        if (location != null) {
          final targetUrl = location.startsWith('http')
              ? location
              : '${Environment.webAppUrl}$location';

          return AuthResult(
              status: AuthStatus.authenticated, targetUrl: targetUrl);
        }

        return AuthResult(
            status: AuthStatus.serverError,
            errorMessage: 'Protocol Error');

      } else if (response.statusCode == 400) {
        return AuthResult(
            status: AuthStatus.deviceNotRegistered,
            errorMessage: response.body);

      } else {
        return AuthResult(
            status: AuthStatus.serverError,
            errorMessage: 'Server Error: ${response.statusCode}');
      }

    } on SocketException catch (_) {
      return AuthResult(
          status: AuthStatus.networkError,
          errorMessage: 'Connection Refused');

    } on TimeoutException {
      return AuthResult(
          status: AuthStatus.networkError,
          errorMessage: 'Connection Timeout');

    } catch (e) {
      return AuthResult(
          status: AuthStatus.networkError,
          errorMessage: 'Unknown Error');
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
    } catch (_) {}
  }
}