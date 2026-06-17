import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class FirstLoginService {
  static String get baseUrl => ApiService.baseUrl;

  static Future<Map<String, dynamic>> sendFirstLoginToken(
    int idutilizador,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-first-login-token'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'idutilizador': idutilizador}),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> verifyFirstLogin(
    int idutilizador,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/first-login-verify'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idutilizador': idutilizador,
        'token': token,
      }),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> changePasswordFirstLogin(
    int idutilizador,
    String passwordNova,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password-first-login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idutilizador': idutilizador,
        'passwordNova': passwordNova,
      }),
    );

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