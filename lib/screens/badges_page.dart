import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../services/expiracao_service.dart';
import '../widgets/base64_image_widget.dart';
import 'package:go_router/go_router.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});
  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  late Future<List<dynamic>> _badgesFuture;
  late Future<List<dynamic>> _areasFuture;
  late Future<List<dynamic>> _nivelsFuture;
  late Future<List<dynamic>> _especiaisFuture;

  List<dynamic> _todos = []; // lista completa da API
  List<dynamic> _visiveis = []; // lista filtrada + lazy
  List<dynamic> _filtrados = []; // lista após pesquisa
  List<dynamic> _areas = []; // lista de áreas
  List<dynamic> _niveis = []; // lista de níveis
  List<dynamic> _especiais = []; // lista de especiais

  final int _porPagina = 6; // quantos carregar de cada vez
  int _carregados = 0;
  bool _temMais = false;

  // Filtros
  String? _selectedArea;
  int? _selectedNivel;
  int? _selectedEspecial;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();

    // lazy loading: quando chega ao fundo carrega mais
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          _temMais) {
        _carregarMais();
      }
    });

    // pesquisa em tempo real
    _searchController.addListener(() {
      _filtrar(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _badgesFuture = CacheService
          .getBadgesDoUtilizador(); // antes: ApiService.getBadgesDoUtilizador()
      _areasFuture = CacheService.getAreas(); // antes: ApiService.getAreas()
      _nivelsFuture = CacheService.getNiveis(); // antes: ApiService.getNiveis()
      _especiaisFuture =
          CacheService.getEspeciais(); // antes: ApiService.getEspeciais()
    });
    _badgesFuture.then((lista) {
      setState(() {
        _todos = lista;
        _filtrar(_searchController.text);
      });
    });
    _areasFuture.then((lista) {
      setState(() {
        _areas = lista;
      });
    });
    _nivelsFuture.then((lista) {
      setState(() {
        _niveis = lista;
      });
    });
    _especiaisFuture.then((lista) {
      setState(() {
        _especiais = lista;
      });
    });
  }

  // filtra por nome, nível, área e especial e reinicia o lazy loading
  void _filtrar(String query) {
    setState(() {
      _filtrados = _todos.where((b) {
        // Filtro por nome
        final nomeMatch = query.isEmpty
            ? true
            : (b['nome'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());

        // Filtro por nível
        final nivelMatch = _selectedNivel == null
            ? true
            : (b['idnivel'] ?? 1) == _selectedNivel;

        // Filtro por área
        final areaMatch = _selectedArea == null
            ? true
            : (b['idarea']?.toString() ?? '') == _selectedArea;

        // Filtro por especial
        final especialMatch = _selectedEspecial == null
            ? true
            : (b['idespecial'] ?? -1) == _selectedEspecial;

        return nomeMatch && nivelMatch && areaMatch && especialMatch;
      }).toList();

      _carregados = 0;
      _visiveis = [];
      _carregarMais();
    });
  }

  void _carregarMais() {
    final novos = _filtrados.skip(_carregados).take(_porPagina).toList();
    setState(() {
      _visiveis.addAll(novos);
      _carregados = _visiveis.length;
      _temMais = _carregados < _filtrados.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/main'),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pesquisar badge...',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filtrar('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Filtro de Nível
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedNivel,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Nível',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ..._niveis.map((nivel) => DropdownMenuItem<int?>(
                            value: nivel['idnivel'],
                            child: Text(
                              nivel['nome'] ?? 'Nível ${nivel['idnivel']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedNivel = value);
                      _filtrar(_searchController.text);
                    },
                  ),
                ),
                SizedBox(width: 12),
                // Filtro de Área
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedArea,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Área',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                          value: null, child: Text('Todas')),
                      ..._areas.map((area) => DropdownMenuItem<String?>(
                            value: area['idarea'].toString(),
                            child: Text(
                              area['nome'] ?? 'Sem nome',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedArea = value);
                      _filtrar(_searchController.text);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Filtro de Especial
          Padding(
            padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedEspecial,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Especial',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ..._especiais.map((especial) => DropdownMenuItem<int?>(
                            value: especial['idespecial'],
                            child: Text(
                              especial['nome'] ??
                                  'Especial ${especial['idespecial']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedEspecial = value);
                      _filtrar(_searchController.text);
                    },
                  ),
                ),
              ],
            ),
          ),
          // Lista de badges
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _searchController.clear();
                _loadData();
                await _badgesFuture;
              },
              child: FutureBuilder<List<dynamic>>(
                future: _badgesFuture,
                builder: (context, snapshot) {
                  // loading inicial
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _todos.isEmpty) {
                    return ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 400),
                        Center(child: CircularProgressIndicator()),
                      ],
                    );
                  }

                  if (snapshot.hasError && _todos.isEmpty) {
                    return ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 400),
                        Center(child: Text('Erro: ${snapshot.error}')),
                      ],
                    );
                  }

                  if (_visiveis.isEmpty && _searchController.text.isNotEmpty) {
                    return ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 400),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Nenhum badge encontrado',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  if (_visiveis.isEmpty) {
                    return ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 400),
                        Center(child: Text('Sem badges')),
                      ],
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 250,
                    ),
                    itemCount: _visiveis.length + (_temMais ? 1 : 0),
                    itemBuilder: (context, index) {
                      // último item = indicador de carregamento
                      if (index == _visiveis.length) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final badge = _visiveis[index];
                      return GestureDetector(
                        onTap: () {
                          // O endpoint já devolve campos do candidaturasbadge via LEFT JOIN.
                          // Se 'estado' não for null, o utilizador já tem candidatura para este badge.
                          final candidatura = badge['estado'] != null
                              ? <String, dynamic>{
                                  'estado': badge['estado'],
                                  'progresso_atual': badge['progresso_atual'],
                                  'progresso_total': badge['progresso_total'],
                                  'datasubmissao': badge['datasubmissao'],
                                }
                              : null;
                          context.push('/badge_detail', extra: {
                            'badge': badge,
                            'candidatura': candidatura,
                          });
                        },
                        child: _BadgeCard(badge: badge),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final dynamic badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final int atual =
        int.tryParse(badge['progresso_atual']?.toString() ?? '0') ?? 0;
    final int total =
        int.tryParse(badge['progresso_total']?.toString() ?? '0') ?? 0;
    final expList = ExpiracaoService.calcular([badge]);
    final BadgeExpiracao? expiracao = expList.isEmpty ? null : expList.first;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              badge['imagemurl'] != null &&
                      badge['imagemurl'].toString().isNotEmpty
                  ? Base64ImageWidget(
                      imageData: badge['imagemurl']
                          .toString()
                          .replaceAll('localhost', '10.0.2.2')
                          .replaceAll('127.0.0.1', '10.0.2.2')
                          .replaceAll('100.105.58.22', '10.0.2.2')
                          .replaceAll('0.0.0.0', '10.0.2.2'),
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      errorWidget: Icon(Icons.emoji_events,
                          size: 80, color: Color(0xFF2563EB)),
                    )
                  : Icon(Icons.emoji_events,
                      size: 80, color: Color(0xFF2563EB)),
              SizedBox(height: 8),
              Text(
                badge['nome'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                    fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                badge['descricao'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      _getNivelNome(badge['idnivel']),
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.star, size: 12, color: Colors.amber),
                  SizedBox(width: 2),
                  Text('${badge['pontos'] ?? 0} pts',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progresso',
                      style: TextStyle(fontSize: 9, color: Colors.grey)),
                  Text('$atual/$total',
                      style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
              SizedBox(height: 4),
              LinearProgressIndicator(
                value: total > 0 ? (atual / total).clamp(0.0, 1.0) : 0,
                backgroundColor: Color(0xFFE5E7EB),
                color: Color(0xFF2563EB),
                minHeight: 4,
              ),
            ],
          ),
        ),
        if (expiracao != null)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: expiracao.cor,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    expiracao.expirado
                        ? Icons.error_outline
                        : Icons.access_time_outlined,
                    size: 11,
                    color: Colors.white,
                  ),
                  SizedBox(width: 3),
                  Text(
                    expiracao.expirado
                        ? 'Expirado'
                        : '${expiracao.diasRestantes}d',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _icon(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 15, color: color),
    );
  }

  String _getNivelNome(dynamic idnivel) {
    if (idnivel == null) return 'N/A';
    return 'Nível $idnivel';
  }
}
