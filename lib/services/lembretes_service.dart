import 'api_service.dart';

class LembretesService {
  // ─── CRUD ────────────────────────────────────────────────────────────────

  static Future<int> criar({
    required String titulo,
    required String descricao,
    required DateTime prazo,
    int? badgeId,
    String? badgeNome,
  }) async {
    final result = await ApiService.criarLembrete(
      titulo: titulo,
      descricao: descricao,
      prazo: prazo,
      badgeId: badgeId,
      badgeNome: badgeNome,
    );
    return result['id'] as int;
  }

  static Future<List<Map<String, dynamic>>> listar() async {
    final lista = await ApiService.getLembretes();
    return lista.map((l) => _normalizar(l)).toList();
  }

  static Future<void> concluir(int id) async {
    await ApiService.concluirLembrete(id);
  }

  static Future<void> eliminar(int id) async {
    await ApiService.eliminarLembrete(id);
  }

  /// Devolve lembretes ativos com prazo até hoje + [diasAntecedencia] dias.
  /// Usado no arranque da app para mostrar avisos ao utilizador.
  static Future<List<Map<String, dynamic>>> verificarProximos({
    int diasAntecedencia = 3,
  }) async {
    final lista = await ApiService.getLembretes();
    final limite = DateTime.now().add(Duration(days: diasAntecedencia));
    return lista
        .where((l) =>
            l['concluido'] == false &&
            (DateTime.tryParse(l['prazo']?.toString() ?? '')
                    ?.isBefore(limite) ==
                true))
        .map((l) => _normalizar(l))
        .toList();
  }

  // Normaliza dados da API (PostgreSQL) para compatibilidade com a UI:
  // - concluido: bool → int (0/1)
  // - prazo: timestamptz → string ISO
  static Map<String, dynamic> _normalizar(Map<String, dynamic> l) {
    return {
      ...l,
      'concluido': (l['concluido'] == true) ? 1 : 0,
      'prazo': l['prazo']?.toString() ?? '',
    };
  }
}
