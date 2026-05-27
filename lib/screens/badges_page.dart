import 'package:flutter/material.dart';
import '../base64_image_widget.dart';
import '../services/api_service.dart';
import 'badge_detail_page.dart';
import '../widgets/badge_progress.dart';

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

  List<dynamic> _todos = [];       // lista completa da API
  List<dynamic> _visiveis = [];    // lista filtrada + lazy
  List<dynamic> _filtrados = [];   // lista após pesquisa
  List<dynamic> _areas = [];       // lista de áreas
  List<dynamic> _niveis = [];      // lista de níveis
  List<dynamic> _especiais = [];   // lista de especiais

  final int _porPagina = 6;        // quantos carregar de cada vez
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
      _badgesFuture = ApiService.getBadgesDoUtilizador();
      _areasFuture = ApiService.getAreas();
      _nivelsFuture = ApiService.getNiveis();
      _especiaisFuture = ApiService.getEspeciais();
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

  // filtra por nome e reinicia o lazy loading
  void _filtrar(String query) {
    setState(() {
      _filtrados = query.isEmpty
          ? List.from(_todos)
          : _todos
              .where((b) => (b['nome'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();

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
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pesquisar badge...',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _filtrar('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Filtro de Nível
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedNivel,
                    decoration: InputDecoration(
                      labelText: 'Nível',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ..._niveis.map((nivel) => DropdownMenuItem<int?>(
                        value: nivel['idnivel'],
                        child: Text(nivel['nome'] ?? 'Nível ${nivel['idnivel']}'),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedNivel = value);
                      _filtrar(_searchController.text);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Filtro de Área
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedArea,
                    decoration: InputDecoration(
                      labelText: 'Área',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                      ..._areas.map((area) => DropdownMenuItem<String?>(
                        value: area['idarea'].toString(),
                        child: Text(area['nome'] ?? 'Sem nome'),
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
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedEspecial,
                    decoration: InputDecoration(
                      labelText: 'Especial',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                      ..._especiais.map((especial) => DropdownMenuItem<int?>(
                        value: especial['idespecial'],
                        child: Text(especial['nome'] ?? 'Especial ${especial['idespecial']}'),
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
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 400),
                        Center(child: CircularProgressIndicator()),
                      ],
                    );
                  }

                  if (snapshot.hasError && _todos.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 400),
                        Center(child: Text('Erro: ${snapshot.error}')),
                      ],
                    );
                  }

                  if (_visiveis.isEmpty && _searchController.text.isNotEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 400),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey),
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
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 400),
                        Center(child: Text('Sem badges')),
                      ],
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: _visiveis.length + (_temMais ? 1 : 0),
                    itemBuilder: (context, index) {
                      // último item = indicador de carregamento
                      if (index == _visiveis.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final badge = _visiveis[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BadgeDetailPage(badge: badge),
                          ),
                        ),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
            badge['imagemurl'] != null && badge['imagemurl'].toString().isNotEmpty
              ? (Base64ImageWidget.isBase64(badge['imagemurl'].toString())
                ? Base64ImageWidget(
                  imageData: badge['imagemurl'].toString(),
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                )
                : Image.network(
                  badge['imagemurl'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events,
                    size: 80, color: Color(0xFF2563EB)),
                ))
              : const Icon(Icons.emoji_events, size: 80, color: Color(0xFF2563EB)),

          const SizedBox(height: 8),

          Text(
            badge['nome'] ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
                fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          Text(
            badge['descricao'] ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(badge['nivel'] ?? 'N/A',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 2),
              Text('${badge['pontos'] ?? 0} pts',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),

          const SizedBox(height: 8),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('REQUISITOS',
                style: TextStyle(fontSize: 9, color: Colors.grey)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _icon(Icons.emoji_events, Colors.orange),
              const SizedBox(width: 4),
              _icon(Icons.star, Colors.red),
              const SizedBox(width: 4),
              _icon(Icons.description, Colors.grey),
            ],
          ),

          const SizedBox(height: 8),

          // Progress (compact)
          BadgeProgress(atual: atual, total: total, compact: true),
        ],
      ),
    );
  }

  Widget _icon(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
          color: Color.fromARGB((0.15 * 255).round(), (color.r * 255).round(), (color.g * 255).round(), (color.b * 255).round()),
          borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 15, color: color),
    );
  }
}
