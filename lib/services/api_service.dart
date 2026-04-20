import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/session.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000";

  // ─────────────────────────────────────────
  // BADGES
  // ─────────────────────────────────────────

  static Future<List<dynamic>> getBadges() async {
    final response = await http.get(Uri.parse('$baseUrl/badges'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception('Erro ao carregar badges');
    }
  }

  // ─────────────────────────────────────────
  // UTILIZADORES
  // ─────────────────────────────────────────

  static Future<List<dynamic>> getUtilizadores() async {
    final response = await http.get(Uri.parse('$baseUrl/utilizadores'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception('Erro ao carregar utilizadores');
    }
  }

  static Future<List<dynamic>> getRanking() async {
    final response =
        await http.get(Uri.parse('$baseUrl/utilizadores/ranking'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception('Erro ao carregar ranking');
    }
  }

  static Future<String> atualizarFoto(
      int idUtilizador, String caminhoFicheiro) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/utilizadores/$idUtilizador/foto'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('foto', caminhoFicheiro),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(body);
      String fotoUrl = data['fotourl'];

      fotoUrl = fotoUrl
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2')
          .replaceAll('100.105.58.22', '10.0.2.2')
          .replaceAll('0.0.0.0', '10.0.2.2');

      return fotoUrl;
    } else {
      throw Exception('Erro ao atualizar foto');
    }
  }

  // ─────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final erro = jsonDecode(response.body);
      throw Exception(erro['error'] ?? 'Erro ao fazer login');
    }
  }

  static Future<Map<String, dynamic>> registro(
      String nome, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'nome': nome, 'email': email, 'password': password}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final erro = jsonDecode(response.body);
      throw Exception(erro['error'] ?? 'Erro ao registar');
    }
  }

  static Future<void> logout() async {
    await http.post(Uri.parse('$baseUrl/logout'));
  }

  // ─────────────────────────────────────────
  // NOTIFICAÇÕES
  // ─────────────────────────────────────────

  static Future<List<dynamic>> getNotificacoes() async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/notificacoes?idutilizador=${Session.id}'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception('Erro ao carregar notificações');
    }
  }

  static Future<void> marcarLida(int id) async {
    final response = await http
        .patch(Uri.parse('$baseUrl/notificacoes/$id/lida'));
    if (response.statusCode != 200) {
      throw Exception('Erro ao marcar notificação como lida');
    }
  }

  static Future<void> apagarNotificacao(int id) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/notificacoes/$id'));
    if (response.statusCode != 200) {
      throw Exception('Erro ao apagar notificação');
    }
  }

  static Future<void> marcarTodasLidas() async {
    final response = await http.patch(
      Uri.parse(
          '$baseUrl/notificacoes/marcar-todas?idutilizador=${Session.id}'),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Erro ao marcar todas as notificações como lidas');
    }
  }
}
