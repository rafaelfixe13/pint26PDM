import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Basededados {
  static final Basededados _instance = Basededados._internal();
  static Database? _database;

  factory Basededados() => _instance;
  Basededados._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'softinsa_cache.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Badges (catálogo completo + recomendados + do utilizador)
    await db.execute('''
      CREATE TABLE badges_cache (
        idbadge INTEGER PRIMARY KEY,
        nome TEXT,
        descricao TEXT,
        imagemurl TEXT,
        idnivel INTEGER,
        idarea INTEGER,
        idespecial INTEGER,
        pontos INTEGER,
        progresso_atual INTEGER,
        progresso_total INTEGER,
        json_completo TEXT,
        ultima_sync TEXT
      )
    ''');

    // Candidaturas do utilizador
    await db.execute('''
      CREATE TABLE candidaturas_cache (
        idcandidatura INTEGER PRIMARY KEY,
        user_id INTEGER,
        badge_id INTEGER,
        estado TEXT,
        progresso_atual INTEGER,
        progresso_total INTEGER,
        json_completo TEXT,
        ultima_sync TEXT
      )
    ''');

    // Sessão do utilizador (login persistente entre arranques da app)
    await db.execute('''
      CREATE TABLE sessao (
        idutilizador INTEGER PRIMARY KEY,
        json_completo TEXT,
        ultima_sync TEXT
      )
    ''');

    // Áreas, níveis e especiais (filtros do catálogo)
    await db.execute('''
      CREATE TABLE listas_auxiliares (
        tipo TEXT,
        json_completo TEXT,
        ultima_sync TEXT,
        PRIMARY KEY (tipo)
      )
    ''');

    await _criarTabelaLembretes(db);
    await _criarTabelaMarcos(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _criarTabelaLembretes(db);
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE lembretes ADD COLUMN utilizador_id INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      await _criarTabelaMarcos(db);
    }
  }

  Future<void> _criarTabelaMarcos(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS marcos_celebrados (
        id TEXT NOT NULL,
        utilizador_id INTEGER NOT NULL,
        celebrado_em TEXT,
        PRIMARY KEY (id, utilizador_id)
      )
    ''');
  }

  Future<void> _criarTabelaLembretes(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lembretes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        utilizador_id INTEGER NOT NULL DEFAULT 0,
        titulo TEXT NOT NULL,
        descricao TEXT,
        badge_id INTEGER,
        badge_nome TEXT,
        prazo TEXT NOT NULL,
        concluido INTEGER DEFAULT 0,
        criado_em TEXT
      )
    ''');
  }

  // ───────────── BADGES ─────────────
  Future<void> guardarBadges(List<dynamic> badges) async {
    final db = await database;
    final batch = db.batch();
    final agora = DateTime.now().toIso8601String();
    for (final b in badges) {
      batch.insert(
        'badges_cache',
        {
          'idbadge': b['idbadge'],
          'nome': b['nome'],
          'descricao': b['descricao'],
          'imagemurl': b['imagemurl'],
          'idnivel': b['idnivel'],
          'idarea': b['idarea'],
          'idespecial': b['idespecial'],
          'pontos': b['pontos'],
          'progresso_atual': b['progresso_atual'],
          'progresso_total': b['progresso_total'],
          'json_completo': jsonEncode(b),
          'ultima_sync': agora,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> listarBadgesLocal() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT json_completo FROM badges_cache ORDER BY idbadge ASC',
    );
    return rows
        .map((r) => jsonDecode(r['json_completo'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ───────────── CANDIDATURAS ─────────────
  Future<void> guardarCandidaturas(int userId, List<dynamic> candidaturas) async {
    final db = await database;
    await db.delete('candidaturas_cache', where: 'user_id = ?', whereArgs: [userId]);
    final batch = db.batch();
    final agora = DateTime.now().toIso8601String();
    for (final c in candidaturas) {
      batch.insert('candidaturas_cache', {
        'idcandidatura': c['idcandidatura'],
        'user_id': userId,
        'badge_id': c['badge_id'],
        'estado': c['estado'],
        'progresso_atual': c['progresso_atual'],
        'progresso_total': c['progresso_total'],
        'json_completo': jsonEncode(c),
        'ultima_sync': agora,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> listarCandidaturasLocal(int userId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT json_completo FROM candidaturas_cache WHERE user_id = ? ORDER BY idcandidatura DESC',
      [userId],
    );
    return rows
        .map((r) => jsonDecode(r['json_completo'] as String) as Map<String, dynamic>)
        .toList();
  }

  // ───────────── SESSÃO ─────────────
  Future<void> guardarSessao(Map<String, dynamic> user, String pwHash) async {
    final db = await database;
    await db.delete('sessao');
    final userComHash = Map<String, dynamic>.from(user);
    userComHash['_pw_hash'] = pwHash;
    await db.insert('sessao', {
      'idutilizador': user['idutilizador'],
      'json_completo': jsonEncode(userComHash),
      'ultima_sync': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> obterSessaoLocal() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT json_completo FROM sessao LIMIT 1');
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['json_completo'] as String) as Map<String, dynamic>;
  }

  Future<void> limparSessao() async {
    final db = await database;
    await db.delete('sessao');
  }

  // ───────────── LISTAS AUXILIARES (áreas, níveis, especiais) ─────────────
  Future<void> guardarLista(String tipo, List<dynamic> lista) async {
    final db = await database;
    await db.insert(
      'listas_auxiliares',
      {
        'tipo': tipo,
        'json_completo': jsonEncode(lista),
        'ultima_sync': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<dynamic>> obterListaLocal(String tipo) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT json_completo FROM listas_auxiliares WHERE tipo = ?',
      [tipo],
    );
    if (rows.isEmpty) return [];
    final decoded = jsonDecode(rows.first['json_completo'] as String);
    return decoded is List ? decoded : [];
  }

  // ───────────── DEBUG (para mostrar ao professor / testar) ─────────────
  Future<Map<String, int>> contagens() async {
    final db = await database;
    final b = await db.rawQuery('SELECT COUNT(*) as c FROM badges_cache');
    final c = await db.rawQuery('SELECT COUNT(*) as c FROM candidaturas_cache');
    final s = await db.rawQuery('SELECT COUNT(*) as c FROM sessao');
    final l = await db.rawQuery('SELECT COUNT(*) as c FROM listas_auxiliares');
    return {
      'badges': (b.first['c'] as int?) ?? 0,
      'candidaturas': (c.first['c'] as int?) ?? 0,
      'sessao': (s.first['c'] as int?) ?? 0,
      'listas_auxiliares': (l.first['c'] as int?) ?? 0,
    };
  }

  Future<void> debugMostrar() async {
    final c = await contagens();
    print('═══ SQLITE LOCAL ═══');
    print('  Badges: ${c['badges']}');
    print('  Candidaturas: ${c['candidaturas']}');
    print('  Sessão: ${c['sessao']}');
    print('  Listas aux: ${c['listas_auxiliares']}');
    print('════════════════════');
  }
}