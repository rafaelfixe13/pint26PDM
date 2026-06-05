import 'package:sqflite/sqflite.dart';
import 'basededados.dart';
import 'session.dart';

class Milestone {
  final String id;
  final String emoji;
  final String titulo;
  final String descricao;

  const Milestone({
    required this.id,
    required this.emoji,
    required this.titulo,
    required this.descricao,
  });
}

class MilestoneService {
  static const _milestones = <Milestone>[
    // Candidaturas submetidas (total)
    Milestone(id: 'cand_1',  emoji: '🚀', titulo: 'Primeira Candidatura!',  descricao: 'Submeteste a tua primeira candidatura. O teu percurso começa agora!'),
    Milestone(id: 'cand_3',  emoji: '🎯', titulo: '3 Candidaturas!',         descricao: 'Já tens 3 candidaturas submetidas. Continua a crescer!'),
    Milestone(id: 'cand_5',  emoji: '⭐', titulo: '5 Candidaturas!',         descricao: 'Estás a meio caminho das 10 candidaturas. Não pares!'),
    Milestone(id: 'cand_10', emoji: '🔥', titulo: '10 Candidaturas!',        descricao: 'Incrível! 10 candidaturas submetidas. És um exemplo de dedicação!'),
    // Badges aprovados
    Milestone(id: 'apr_1',   emoji: '🥇', titulo: 'Primeiro Badge Aprovado!',  descricao: 'O teu primeiro badge foi aprovado. Parabéns pelo esforço!'),
    Milestone(id: 'apr_3',   emoji: '🏅', titulo: '3 Badges Aprovados!',       descricao: 'Já tens 3 badges aprovados. O teu perfil está a crescer!'),
    Milestone(id: 'apr_5',   emoji: '💎', titulo: '5 Badges Aprovados!',       descricao: '5 badges aprovados! Estás a tornar-te num especialista!'),
    // Período: 3 candidaturas nos últimos 30 dias
    Milestone(id: 'period_3_30d', emoji: '⚡', titulo: '3 em 30 dias!', descricao: 'Submeteste 3 candidaturas no último mês. Que ritmo incrível!'),
  ];

  static Future<List<Milestone>> verificarNovos(List<dynamic> candidaturas) async {
    if (Session.id == 0) return [];

    final novos = <Milestone>[];
    final total = candidaturas.length;
    final aprovados = candidaturas.where((c) => c['estado'] == 'APPROVED').length;

    final limite30d = DateTime.now().subtract(const Duration(days: 30));
    final ultimos30d = candidaturas.where((c) {
      final raw = c['datacriacao']?.toString() ?? c['datasubmissao']?.toString() ?? '';
      if (raw.isEmpty) return false;
      try { return DateTime.parse(raw).isAfter(limite30d); } catch (_) { return false; }
    }).length;

    for (final m in _milestones) {
      if (await _jaCelebrado(m.id)) continue;

      bool atingido = false;
      switch (m.id) {
        case 'cand_1':       atingido = total >= 1; break;
        case 'cand_3':       atingido = total >= 3; break;
        case 'cand_5':       atingido = total >= 5; break;
        case 'cand_10':      atingido = total >= 10; break;
        case 'apr_1':        atingido = aprovados >= 1; break;
        case 'apr_3':        atingido = aprovados >= 3; break;
        case 'apr_5':        atingido = aprovados >= 5; break;
        case 'period_3_30d': atingido = ultimos30d >= 3; break;
      }

      if (atingido) {
        novos.add(m);
        await _marcarCelebrado(m.id);
      }
    }

    return novos;
  }

  static Future<bool> _jaCelebrado(String id) async {
    final db = await Basededados().database;
    final rows = await db.query(
      'marcos_celebrados',
      where: 'id = ? AND utilizador_id = ?',
      whereArgs: [id, Session.id],
    );
    return rows.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> listarCelebrados() async {
    if (Session.id == 0) return [];
    final db = await Basededados().database;
    final rows = await db.query(
      'marcos_celebrados',
      where: 'utilizador_id = ?',
      whereArgs: [Session.id],
      orderBy: 'celebrado_em DESC',
    );
    return rows.map((row) {
      final m = _milestones.firstWhere(
        (m) => m.id == row['id'],
        orElse: () => Milestone(id: '', emoji: '🏆', titulo: '', descricao: ''),
      );
      return {
        'milestone': m,
        'celebrado_em': row['celebrado_em']?.toString() ?? '',
      };
    }).where((r) => (r['milestone'] as Milestone).id.isNotEmpty).toList();
  }

  static Future<void> _marcarCelebrado(String id) async {
    final db = await Basededados().database;
    await db.insert(
      'marcos_celebrados',
      {
        'id': id,
        'utilizador_id': Session.id,
        'celebrado_em': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
