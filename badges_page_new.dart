import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'badge_detail_page.dart';

class BadgesPage extends StatefulWidget {
  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  late Future<List<dynamic>> _badgesFuture;
  late Future<List<dynamic>> _areasFuture;

  List<dynamic> _todos = [];
  List<dynamic> _visiveis = [];
  List<dynamic> _filtrados = [];
  List<dynamic> _areas = [];

  final int _porPagina = 6;
  int _carregados = 0;
  bool _temMais = false;

  String? _selectedArea;
  int? _selectedNivel;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          _temMais) {
        _carregarMais();
      }
    });

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
  }

  void _filtrar(String query) {
    setState(() {
      _filtrados = _todos.where((b) {
        final nomeMatch = query.isEmpty
            ? true
            : (b['nome'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());

        final nivelMatch = _selectedNivel == null
            ? true
            : (b['nivel'] ?? 1) == _selectedNivel;

        final areaMatch = _selectedArea == null
            ? true
            : (b['idarea']?.toString() ?? '') == _selectedArea;

        return nomeMatch && nivelMatch && areaMatch;
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedNivel,
                    decoration: InputDecoration(
                      labelText: 'Nível',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                          value: null, child: Text('Todos')),
                      DropdownMenuItem<int?>(value: 1, child: Text('1')),
                      DropdownMenuItem<int?>(value: 2, child: Text('2')),
                      DropdownMenuItem<int?>(value: 3, child: Text('3')),
                      DropdownMenuItem<int?>(value: 4, child: Text('4')),
                      DropdownMenuItem<int?>(value: 5, child: Text('5')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedNivel = value);
                      _filtrar(_searchController.text);
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedArea,
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

                  if (_visiveis.isEmpty &&
                      _searchController.text.isNotEmpty) {
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
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58,
                    ),
                    itemCount: _visiveis.length + (_temMais ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _visiveis.length) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final badge = _visiveis[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BadgeDetailPage(badge: badge),
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
            style: TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFEBF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Nível ${badge['nivel'] ?? 1}',
              style: TextStyle(fontSize: 10, color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }
}
