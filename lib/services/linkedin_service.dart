import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LinkedInService {
  static const String _clientId = 'SEU_CLIENT_ID_AQUI';
  static const String _clientSecret = 'SEU_CLIENT_SECRET_AQUI';
  static const String _redirectUri = 'https://localhost/callback';
  static const String _tokenKey = 'linkedin_access_token';

  String getAuthorizationUrl() {
    final params = {
      'response_type': 'code',
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'scope': 'openid profile w_member_social',
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return 'https://www.linkedin.com/oauth/v2/authorization?$query';
  }

  Future<void> getAccessToken(String authCode) async {
    final response = await http.post(
      Uri.parse('https://www.linkedin.com/oauth/v2/accessToken'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': authCode,
        'redirect_uri': _redirectUri,
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao obter token LinkedIn: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null) throw Exception('Token não encontrado na resposta');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getSavedAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getSavedAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> getPersonUrn(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.linkedin.com/v2/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao obter perfil LinkedIn: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final sub = data['sub'] as String?;
    if (sub == null) throw Exception('ID de utilizador não encontrado');
    return 'urn:li:person:$sub';
  }

  Future<bool> shareTextPost({
    required String accessToken,
    required String personUrn,
    required String text,
    String visibility = 'PUBLIC',
  }) async {
    final body = jsonEncode({
      'author': personUrn,
      'lifecycleState': 'PUBLISHED',
      'specificContent': {
        'com.linkedin.ugc.ShareContent': {
          'shareCommentary': {'text': text},
          'shareMediaCategory': 'NONE',
        },
      },
      'visibility': {
        'com.linkedin.ugc.MemberNetworkVisibility': visibility,
      },
    });

    final response = await http.post(
      Uri.parse('https://api.linkedin.com/v2/ugcPosts'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'X-Restli-Protocol-Version': '2.0.0',
      },
      body: body,
    );

    return response.statusCode == 201;
  }
}
