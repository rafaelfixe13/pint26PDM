import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class FirstLoginService {
  static String get baseUrl => ApiService.baseUrl;

  // O servidor (Render, plano gratuito) pode demorar a "acordar" depois de
  // inativo, daí um limite generoso em vez do timeout por defeito (infinito).
  static const _timeout = Duration(seconds: 40);

  static Future<Map<String, dynamic>> sendFirstLoginToken(
    int idutilizador,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/send-first-login-token'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'idutilizador': idutilizador}),
        )
        .timeout(_timeout);

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> verifyFirstLogin(
    int idutilizador,
    String token,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/first-login-verify'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idutilizador': idutilizador,
            'token': token,
          }),
        )
        .timeout(_timeout);

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> changePasswordFirstLogin(
    int idutilizador,
    String passwordNova,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/change-password-first-login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idutilizador': idutilizador,
            'passwordNova': passwordNova,
          }),
        )
        .timeout(_timeout);

    return _decodeResponse(response);
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    return {
      'statusCode': response.statusCode,
      'ok': response.statusCode >= 200 && response.statusCode < 300,
      'data': decoded,
    };
  }
}