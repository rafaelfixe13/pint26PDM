import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/session.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000";

  static bool _isJson(String body) {
    final text = body.trim();
    return text.startsWith('{') || text.startsWith('[');
  }

  static dynamic _decodeJsonSafely(http.Response response) {
    final body = response.body.trim();
    if (_isJson(body)) return jsonDecode(body);
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
    final response = await http.get(
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

  static Future<List<dynamic>> getBadgesDoUtilizador() async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await http.get(
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
    final response = await http.get(
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
    final response = await http.get(
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

  static Future<String> atualizarFoto(
    int idUtilizador,
    String caminhoFicheiro,
  ) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/utilizadores/$idUtilizador/foto'),
    );
    request.headers.addAll({'Accept': 'application/json'});
    request.files.add(await http.MultipartFile.fromPath('foto', caminhoFicheiro));
    final response = await request.send();
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
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
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

    throw Exception(_extractErrorMessage(response, fallback: 'Erro ao fazer login'));
  }

  static Future<Map<String, dynamic>> registro(
    String nome,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registro'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return _decodeJsonSafely(response) as Map<String, dynamic>;
    }

    throw Exception(_extractErrorMessage(response, fallback: 'Erro ao registar'));
  }

  static Future<void> logout() async {
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {'Accept': 'application/json'},
    );
  }

  static Future<Map<String, dynamic>> alterarPassword(
    String passwordAtual,
    String passwordNova,
  ) async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await http.post(
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

  static Future<List<dynamic>> getNotificacoes() async {
    final response = await http.get(
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

  static Future<void> marcarLida(int id) async {
    final response = await http.patch(
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
    final response = await http.delete(
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
    final response = await http.patch(
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
}