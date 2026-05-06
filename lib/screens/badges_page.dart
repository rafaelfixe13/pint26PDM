import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'badge_detail_page.dart';

class BadgesPage extends StatefulWidget {
  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  late Future<List<dynamic>> _badgesFuture;

  List<dynamic> _todos = [];       // lista completa da API
  List<dynamic> _visiveis = [];    // lista filtrada + lazy
  List<dynamic> _filtrados = [];   // lista após pesquisa

  final int _porPagina = 6;        // quantos carregar de cada vez
  int _carregados = 0;
  bool _temMais = false;

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
    });
    _badgesFuture.then((lista) {
      setState(() {
        _todos = lista;
        _filtrar(_searchController.text);
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
    final proximo = _carregados + _porPagina;
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
          onPressed: () => Navigator.pop(context),
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
      body: RefreshIndicator(
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
                childAspectRatio: 0.58,
              ),
              // +1 para o indicador de "a carregar mais" no fundo
              itemCount: _visiveis.length + (_temMais ? 1 : 0),
              itemBuilder: (context, index) {
                // último item = indicador de carregamento
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          badge['imagemurl'] != null &&
                  badge['imagemurl'].toString().isNotEmpty
              ? Image.network(
                  badge['imagemurl'],
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.emoji_events,
                      size: 80, color: Color(0xFF2563EB)),
                )
              : Icon(Icons.emoji_events, size: 80, color: Color(0xFF2563EB)),

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
                child: Text(badge['nivel'] ?? 'N/A',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
              SizedBox(width: 6),
              Icon(Icons.star, size: 12, color: Colors.amber),
              SizedBox(width: 2),
              Text('${badge['pontos'] ?? 0} pts',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),

          SizedBox(height: 8),

          Align(
            alignment: Alignment.centerLeft,
            child: Text('REQUISITOS',
                style: TextStyle(fontSize: 9, color: Colors.grey)),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              _icon(Icons.emoji_events, Colors.orange),
              SizedBox(width: 4),
              _icon(Icons.star, Colors.red),
              SizedBox(width: 4),
              _icon(Icons.description, Colors.grey),
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
}
