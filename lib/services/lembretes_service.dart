import 'basededados.dart';
import 'session.dart';

class LembretesService {
  // ─── CRUD ────────────────────────────────────────────────────────────────

  static Future<int> criar({
    required String titulo,
    required String descricao,
    required DateTime prazo,
    int? badgeId,
    String? badgeNome,
  }) async {
    final db = await Basededados().database;
    return db.insert('lembretes', {
      'utilizador_id': Session.id,
      'titulo': titulo,
      'descricao': descricao,
      'badge_id': badgeId,
      'badge_nome': badgeNome,
      'prazo': prazo.toIso8601String(),
      'concluido': 0,
      'criado_em': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> listar() async {
    final db = await Basededados().database;
    return db.query(
      'lembretes',
      where: 'utilizador_id = ?',
      whereArgs: [Session.id],
      orderBy: 'concluido ASC, prazo ASC',
    );
  }

  static Future<void> concluir(int id) async {
    final db = await Basededados().database;
    await db.update(
      'lembretes',
      {'concluido': 1},
      where: 'id = ? AND utilizador_id = ?',
      whereArgs: [id, Session.id],
    );
  }

  static Future<void> eliminar(int id) async {
    final db = await Basededados().database;
    await db.delete(
      'lembretes',
      where: 'id = ? AND utilizador_id = ?',
      whereArgs: [id, Session.id],
    );
  }

  /// Devolve lembretes ativos com prazo até hoje + [diasAntecedencia] dias.
  /// Usado no arranque da app para mostrar avisos ao utilizador.
  static Future<List<Map<String, dynamic>>> verificarProximos({
    int diasAntecedencia = 3,
  }) async {
    final db = await Basededados().database;
    final limite = DateTime.now().add(Duration(days: diasAntecedencia));
    final rows = await db.query(
      'lembretes',
      where: 'utilizador_id = ? AND concluido = 0 AND prazo <= ?',
      whereArgs: [Session.id, limite.toIso8601String()],
      orderBy: 'prazo ASC',
    );
    return rows;
  }
}
