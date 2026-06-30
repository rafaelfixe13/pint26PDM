import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/session.dart';

class ApiService {
  //static const String baseUrl = "https://pint26pdm-api.onrender.com";
  static const String baseUrl = "http://192.168.1.225:3000";
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

  static Future<String> atualizarFotoBase64(int idUtilizador, String fotoBase64) async {
    final response = await http.post(
      Uri.parse('$baseUrl/utilizadores/$idUtilizador/foto-base64'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'foto_base64': fotoBase64}),
    );

    if (response.statusCode == 200) {
      final decoded = _decodeJsonSafely(response) as Map<String, dynamic>;
      return decoded['foto_base64']?.toString() ?? '';
    }

    throw Exception(_extractErrorMessage(response, fallback: 'Erro ao atualizar foto'));
  }

  static Future<List<dynamic>> getAreas() async {
    final response = await http.get(Uri.parse('$baseUrl/areas'));
    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(_extractErrorMessage(response, fallback: 'Erro ao obter áreas'));
  }

  static Future<List<dynamic>> getNiveis() async {
    final response = await http.get(Uri.parse('$baseUrl/niveis'));
    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(_extractErrorMessage(response, fallback: 'Erro ao obter níveis'));
  }

  static Future<List<dynamic>> getEspeciais() async {
    final response = await http.get(Uri.parse('$baseUrl/especialidades'));
    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }
    // If endpoint not found, return empty list instead of throwing to
    // allow the client to continue (server may not expose this endpoint).
    if (response.statusCode == 404) return <dynamic>[];

    throw Exception(_extractErrorMessage(response, fallback: 'Erro ao obter especialidades'));
  }

  static Future<void> recarregarDadosUtilizador() async {
    final response = await http.get(Uri.parse('$baseUrl/utilizadores/me'));
    if (response.statusCode == 200) {
      final decoded = _decodeJsonSafely(response) as Map<String, dynamic>;
      Session.iniciar(decoded);
      return;
    }

    throw Exception(_extractErrorMessage(response, fallback: 'Erro ao recarregar dados do utilizador'));
  }

  static dynamic _decodeJsonSafely(http.Response response) {
    final body = response.body.trim();
    if (_isJson(body)) {
      return jsonDecode(body);
    }
    throw Exception(
      'Resposta inválida do servidor (${response.statusCode}). O servidor devolveu HTML ou texto em vez de JSON.',
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
      return 'Erro ${response.statusCode}: resposta inválida do servidor';
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

  static Future<List<dynamic>> getBadgesRecomendados(int userId) async {
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await http.get(
      // Use the personalized recommendations endpoint
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
      throw Exception('Sessão inválida. Faz login novamente.');
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

  static Future<List<dynamic>> getCandidaturas() async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await http.get(
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
    final response = await http.get(
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

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      if (!_isJson(body)) {
        throw Exception('Resposta inválida do servidor ao atualizar foto.');
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

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
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

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao fazer login'),
    );
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

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao registar'),
    );
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
      throw Exception('Sessão inválida. Faz login novamente.');
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
      'Erro ${response.statusCode}: o servidor devolveu HTML ou texto inválido.',
    );
  }

  static Future<bool> atualizarRgpd(bool valor) async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await http.patch(
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

  static Future<List<dynamic>> getNotificacoes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notificacoes?idutilizador=${Session.id}'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as List;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao carregar notificações'),
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
          fallback: 'Erro ao marcar notificação como lida',
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
        _extractErrorMessage(response, fallback: 'Erro ao apagar notificação'),
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
          fallback: 'Erro ao marcar todas as notificações como lidas',
        ),
      );
    }
  }
  static Future<List<dynamic>> getRequisitosBadge(int badgeId) async {
    final response = await http.get(
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

    // Add form fields
    request.fields['user_id'] = Session.id.toString();
    request.fields['badge_id'] = badgeId.toString();

    // Add files
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

    final streamedResponse = await request.send();
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

  /// Gera (ou obtém em cache) a imagem PNG e o certificado PDF para um badge.
  /// Devolve { base64, certificado_pdf_base64 }.
  static Future<Map<String, dynamic>> gerarCertificado(int badgeId) async {
    final userId = Session.id;
    if (userId == 0) {
      throw Exception('Sessão inválida. Faz login novamente.');
    }

    final response = await _post(
      Uri.parse('$baseUrl/badges/$badgeId/generate-image'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      return _decodeJsonSafely(response) as Map<String, dynamic>;
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Erro ao gerar certificado'),
    );
  }
}
