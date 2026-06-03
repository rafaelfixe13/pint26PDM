
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'api_service.dart';
import 'basededados.dart';
import 'session.dart';

class CacheService {
  /// Tenta buscar da API. Se conseguir, atualiza o cache local e devolve.
  /// Se a API falhar, devolve o que estiver guardado em SQLite.
  static Future<List<dynamic>> getBadgesDoUtilizador() async {
    try {
      final dados = await ApiService.getBadgesDoUtilizador();
      await Basededados().guardarBadges(dados);
      return dados;
    } catch (e) {
      print('API falhou (badges utilizador), a usar cache local: $e');
      return await Basededados().listarBadgesLocal();
    }
  }

  static Future<List<dynamic>> getBadgesRecomendados(int userId) async {
    try {
      final dados = await ApiService.getBadgesRecomendados(userId);
      // Não substituímos o cache geral aqui (são só os recomendados)
      return dados;
    } catch (e) {
      print('API falhou (recomendados), a usar cache local: $e');
      // Fallback: devolve do cache filtrado pela área do utilizador, se possível
      final todos = await Basededados().listarBadgesLocal();
      return todos;
    }
  }

  static Future<List<dynamic>> getCandidaturas() async {
    try {
      final dados = await ApiService.getCandidaturas();
      await Basededados().guardarCandidaturas(Session.id, dados);
      return dados;
    } catch (e) {
      print('API falhou (candidaturas), a usar cache local: $e');
      return await Basededados().listarCandidaturasLocal(Session.id);
    }
  }

  static Future<List<dynamic>> getAreas() async {
    try {
      final dados = await ApiService.getAreas();
      await Basededados().guardarLista('areas', dados);
      return dados;
    } catch (e) {
      return await Basededados().obterListaLocal('areas');
    }
  }

  static Future<List<dynamic>> getNiveis() async {
    try {
      final dados = await ApiService.getNiveis();
      await Basededados().guardarLista('niveis', dados);
      return dados;
    } catch (e) {
      return await Basededados().obterListaLocal('niveis');
    }
  }

  static Future<List<dynamic>> getEspeciais() async {
    try {
      final dados = await ApiService.getEspeciais();
      await Basededados().guardarLista('especiais', dados);
      return dados;
    } catch (e) {
      return await Basededados().obterListaLocal('especiais');
    }
  }

  static Future<List<dynamic>> getRequisitosBadge(int badgeId) async {
    try {
      final dados = await ApiService.getRequisitosBadge(badgeId);
      await Basededados().guardarLista('requisitos_$badgeId', dados);
      return dados;
    } catch (e) {
      print('API falhou (requisitos badge $badgeId), a usar cache local: $e');
      return await Basededados().obterListaLocal('requisitos_$badgeId');
    }
  }

  static Future<List<dynamic>> getRanking() async {
    try {
      final dados = await ApiService.getRanking();
      await Basededados().guardarLista('ranking', dados);
      return dados;
    } catch (e) {
      print('API falhou (ranking), a usar cache local: $e');
      return await Basededados().obterListaLocal('ranking');
    }
  }

  static Future<List<dynamic>> getNotificacoes() async {
    try {
      final dados = await ApiService.getNotificacoes();
      await Basededados().guardarLista('notificacoes', dados);
      return dados;
    } catch (e) {
      print('API falhou (notificacoes), a usar cache local: $e');
      return await Basededados().obterListaLocal('notificacoes');
    }
  }

  static String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  /// Login: tenta a API, se conseguir guarda o utilizador em SQLite.
  /// Se falhar e houver sessão guardada para esse email e password correcta, deixa entrar offline.
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final resp = await ApiService.login(email, password);
      final user = resp['utilizador'] as Map<String, dynamic>;
      await Basededados().guardarSessao(user, hashPassword(password));
      return resp;
    } catch (e) {
      final local = await Basededados().obterSessaoLocal();
      if (local != null) {
        final emailGuardado = local['email']?.toString().toLowerCase() ?? '';
        final hashGuardado = local['_pw_hash']?.toString() ?? '';
        if (emailGuardado == email.toLowerCase()) {
          if (hashGuardado == hashPassword(password)) {
            return {'success': true, 'utilizador': local, 'offline': true};
          }
          throw Exception('Password incorreta.');
        }
        throw Exception('Sem ligação ao servidor. A sessão offline guardada pertence a outro utilizador.');
      }
      throw Exception('Sem ligação ao servidor. Inicia sessão com ligação à VPN/WiFi pelo menos uma vez para activar o modo offline.');
    }
  }
}