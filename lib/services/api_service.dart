import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/session.dart';

class ApiService {
  static const String baseUrl = "http://100.102.17.64:3000";
  static const _timeout = Duration(seconds: 10);

  static Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) async {
    try {
      return await http.get(uri, headers: headers).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Sem ligação ao servidor. Verifica a tua ligação à VPN/WiFi.');
    }
  }

  static Future<http.Response> _post(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      return await http.post(uri, headers: headers, body: body).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Sem ligação ao servidor. Verifica a tua ligação à VPN/WiFi.');
    }
  }

  static Future<http.Response> _patch(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      return await http.patch(uri, headers: headers, body: body).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Sem ligação ao servidor. Verifica a tua ligação à VPN/WiFi.');
    }
  }

  static Future<http.Response> _delete(Uri uri, {Map<String, String>? headers}) async {
    try {
      return await http.delete(uri, headers: headers).timeout(_timeout);
    } on TimeoutException {
      throw Exception('Sem ligação ao servidor. Verifica a tua ligação à VPN/WiFi.');
    }
  }

  static bool _isJson(String body) {
    final text = body.trim();
    return text.startsWith('{') || text.startsWith('[');
  }

  static dynamic _decodeJsonSafely(http.Response response) {
    final body = response.body.trim();
    if (_isJson(body)) {
      return jsonDecode(body);
    }
    throw Exception(
      'Resposta inválida do servidor (${response.statusCode}). O servidor devolveu HTML ou texto em vez de JSON.',
    );
  }

  static String _extractErrorMessage(
    http.Response response, {
    String fallback = 'Ocorreu um erro',
  }) {
    final body = response.body.trim();

    if (_isJson(body)) {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data['error']?.toString() ??
            data['message']?.toString() ??
            fallback;
      }
    }

    if (body.isNotEmpty) {
      return 'Erro ${response.statusCode}: resposta inválida do servidor';
    }

    return fallback;
  }

  static Future<List<dynamic>> getBadges() async {
    final response = await _get(
      Uri.parse('$baseUrl/badges'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar badges'),
    );
  }

  static Future<List<dynamic>> getBadgesRecomendados(int userId) async {
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await _get(
      Uri.parse('$baseUrl/utilizadores/$userId/recomendacoes'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(
        response,
        fallback: 'Erro ao carregar badges recomendados',
      ),
    );
  }

  static Future<List<dynamic>> getBadgesDoUtilizador() async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await _get(
      Uri.parse('$baseUrl/utilizadores/$userId/badges'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(
        response,
        fallback: 'Erro ao carregar badges do utilizador',
      ),
    );
  }

  static Future<List<dynamic>> getUtilizadores() async {
    final response = await _get(
      Uri.parse('$baseUrl/utilizadores'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar utilizadores'),
    );
  }

  static Future<List<dynamic>> getRanking() async {
    final response = await _get(
      Uri.parse('$baseUrl/utilizadores/ranking'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar ranking'),
    );
  }

  static Future<List<dynamic>> getCandidaturas() async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await _get(
      Uri.parse('$baseUrl/utilizadores/$userId/candidaturas'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar candidaturas'),
    );
  }

  static Future<Map<String, dynamic>> getBadgeById(int badgeId) async {
    final response = await _get(
      Uri.parse('$baseUrl/badges/$badgeId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as Map<String, dynamic>;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar badge'),
    );
  }

  static Future<String> atualizarFoto(
    int idUtilizador,
    String caminhoFicheiro,
  ) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/utilizadores/$idUtilizador/foto'),
    );

    request.headers.addAll({'Accept': 'application/json'});
    request.files.add(
      await http.MultipartFile.fromPath('foto', caminhoFicheiro),
    );

    try {
      final response = await request.send().timeout(_timeout);
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (!_isJson(body)) {
          throw Exception('Resposta inválida do servidor ao atualizar foto.');
        }

        final data = jsonDecode(body);
        String fotoUrl = data['fotourl'];

        fotoUrl = fotoUrl
            .replaceAll('localhost', '10.0.2.2')
            .replaceAll('127.0.0.1', '10.0.2.2')
            .replaceAll('100.105.58.22', '10.0.2.2')
            .replaceAll('0.0.0.0', '10.0.2.2');

        return fotoUrl;
      }

      throw Exception('Erro ao atualizar foto');
    } on TimeoutException {
      throw Exception('Sem ligação ao servidor. Verifica a tua ligação à VPN/WiFi.');
    }
  }

  static Future<String> atualizarFotoBase64(
    int idUtilizador,
    String fotoBase64,
  ) async {
    final response = await _patch(
      Uri.parse('$baseUrl/utilizadores/$idUtilizador/foto-base64'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'foto_base64': fotoBase64,
      }),
    );

    if (response.statusCode == 200) {
      final data = _decodeJsonSafely(response) as Map<String, dynamic>;
      return data['foto_base64'] ?? '';
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao atualizar foto'),
    );
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await _post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as Map<String, dynamic>;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao fazer login'),
    );
  }

  static Future<List<dynamic>> getAreas() async {
    final response = await _get(
      Uri.parse('$baseUrl/areas'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar áreas'),
    );
  }

  static Future<List<dynamic>> getNiveis() async {
    final response = await _get(
      Uri.parse('$baseUrl/niveis'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar níveis'),
    );
  }

  static Future<List<dynamic>> getEspeciais() async {
    final response = await _get(
      Uri.parse('$baseUrl/especiais'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar especiais'),
    );
  }

  static Future<Map<String, dynamic>> registro(
    String nome,
    String email,
    String password,
    int? idarea,
  ) async {
    final response = await _post(
      Uri.parse('$baseUrl/registro'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'password': password,
        'idarea': idarea,
      }),
    );

    if (response.statusCode == 201) {
      return _decodeJsonSafely(response) as Map<String, dynamic>;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao registar'),
    );
  }

  static Future<void> logout() async {
    try {
      await _post(
        Uri.parse('$baseUrl/logout'),
        headers: {'Accept': 'application/json'},
      );
    } catch (_) {
      // logout local mesmo sem rede
    }
  }

  static Future<Map<String, dynamic>> alterarPassword(
    String passwordAtual,
    String passwordNova,
  ) async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await _post(
      Uri.parse('$baseUrl/alterar-password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'idutilizador': userId,
        'passwordAtual': passwordAtual,
        'passwordNova': passwordNova,
      }),
    );

    final body = response.body.trim();

    if (response.statusCode == 200) {
      if (_isJson(body)) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
      return {'success': true};
    }

    if (_isJson(body)) {
      final data = jsonDecode(body);
      throw Exception(
        data['error']?.toString() ??
            data['message']?.toString() ??
            'Erro ao alterar password',
      );
    }

    throw Exception(
      'Erro ${response.statusCode}: o servidor devolveu HTML ou texto inválido.',
    );
  }

  static Future<bool> atualizarRgpd(bool valor) async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await _patch(
      Uri.parse('$baseUrl/utilizadores/$userId/rgpd'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'rgpd': valor,
      }),
    );

    if (response.statusCode == 200) {
      final data = _decodeJsonSafely(response) as Map<String, dynamic>;
      final utilizador = Map<String, dynamic>.from(data['utilizador'] ?? {});

      Session.iniciar({
        ...Session.utilizador,
        ...utilizador,
      });

      return utilizador['rgpd'] == true;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao atualizar RGPD'),
    );
  }

  static Future<void> recarregarDadosUtilizador() async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await _get(
      Uri.parse('$baseUrl/utilizadores/$userId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = _decodeJsonSafely(response) as Map<String, dynamic>;
      Session.iniciar(data);
    } else {
      throw Exception(
        _extractErrorMessage(response, fallback: 'Erro ao recarregar dados'),
      );
    }
  }

  static Future<List<dynamic>> getNotificacoes() async {
    final response = await _get(
      Uri.parse('$baseUrl/notificacoes?idutilizador=${Session.id}'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar notificações'),
    );
  }

  static Future<void> salvarFcmToken(int userId, String token) async {
    final response = await _patch(
      Uri.parse('$baseUrl/utilizadores/$userId/fcm-token'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response, fallback: 'Erro ao guardar token de notificações'),
      );
    }
  }

  static Future<void> marcarLida(int id) async {
    final response = await _patch(
      Uri.parse('$baseUrl/notificacoes/$id/lida'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          fallback: 'Erro ao marcar notificação como lida',
        ),
      );
    }
  }

  static Future<void> apagarNotificacao(int id) async {
    final response = await _delete(
      Uri.parse('$baseUrl/notificacoes/$id'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response, fallback: 'Erro ao apagar notificação'),
      );
    }
  }

  static Future<void> marcarTodasLidas() async {
    final response = await _patch(
      Uri.parse('$baseUrl/notificacoes/marcar-todas?idutilizador=${Session.id}'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          fallback: 'Erro ao marcar todas as notificações como lidas',
        ),
      );
    }
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final userId = Session.id;
    if (userId == 0) throw Exception('Sessão inválida. Faz login novamente.');

    final response = await _get(
      Uri.parse('$baseUrl/utilizadores/$userId/dashboard'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as Map<String, dynamic>;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar dashboard'),
    );
  }

  static Future<List<Map<String, dynamic>>> getLembretes() async {
    final userId = Session.id;
    if (userId == 0) throw Exception('Sessão inválida. Faz login novamente.');

    final response = await _get(
      Uri.parse('$baseUrl/utilizadores/$userId/lembretes'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final list = _decodeJsonSafely(response) as List;
      return list.cast<Map<String, dynamic>>();
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar lembretes'),
    );
  }

  static Future<Map<String, dynamic>> criarLembrete({
    required String titulo,
    required String descricao,
    required DateTime prazo,
    int? badgeId,
    String? badgeNome,
  }) async {
    final userId = Session.id;
    if (userId == 0) throw Exception('Sessão inválida. Faz login novamente.');

    final response = await _post(
      Uri.parse('$baseUrl/utilizadores/$userId/lembretes'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao.isEmpty ? null : descricao,
        'prazo': prazo.toIso8601String(),
        'badge_id': badgeId,
        'badge_nome': badgeNome,
      }),
    );

    if (response.statusCode == 201) {
      return _decodeJsonSafely(response) as Map<String, dynamic>;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao criar lembrete'),
    );
  }

  static Future<void> concluirLembrete(int id) async {
    final response = await _patch(
      Uri.parse('$baseUrl/lembretes/$id/concluir'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response, fallback: 'Erro ao concluir lembrete'),
      );
    }
  }

  static Future<void> eliminarLembrete(int id) async {
    final response = await _delete(
      Uri.parse('$baseUrl/lembretes/$id'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response, fallback: 'Erro ao eliminar lembrete'),
      );
    }
  }

  static Future<void> verificarExpiracaoNotificacoes(int userId) async {
    try {
      await _post(
        Uri.parse('$baseUrl/utilizadores/$userId/notificacoes-expiracao'),
        headers: {'Accept': 'application/json'},
      );
    } catch (_) {}
  }

  static Future<void> verificarLembretesNotificacoes(int userId) async {
    try {
      await _post(
        Uri.parse('$baseUrl/utilizadores/$userId/notificacoes-lembretes'),
        headers: {'Accept': 'application/json'},
      );
    } catch (_) {}
  }

  static Future<List<dynamic>> getRequisitosBadge(int badgeId) async {
    final response = await _get(
      Uri.parse('$baseUrl/badges/$badgeId/requisitos'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          response,
          fallback: 'Erro ao carregar requisitos do badge',
        ),
      );
    }

    return _decodeJsonSafely(response);
  }

  static Future<Map<String, dynamic>> submitCandidatura(
    int badgeId,
    Map<int, String> filesMap,
  ) async {
    final uri = Uri.parse('$baseUrl/candidaturas');
    final request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = Session.id.toString();
    request.fields['badge_id'] = badgeId.toString();

    for (final entry in filesMap.entries) {
      final requisitoId = entry.key;
      final filePath = entry.value;
      final file = await http.MultipartFile.fromPath(
        'file_$requisitoId',
        filePath,
      );
      request.files.add(file);
      request.fields['requisito_id_$requisitoId'] = requisitoId.toString();
    }

    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          _extractErrorMessage(
            response,
            fallback: 'Erro ao submeter candidatura',
          ),
        );
      }

      return _decodeJsonSafely(response);
    } on TimeoutException {
      throw Exception('Sem ligação ao servidor. Verifica a tua ligação à VPN/WiFi.');
    }
  }
}
