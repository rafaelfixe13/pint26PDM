import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/session.dart';
import '../../../services/api_service.dart';
import '../../../services/cache_service.dart';
import '../../../services/milestone_service.dart';
import '../../../widgets/base64_image_widget.dart';
import './edit_photo_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Key _avatarKey = UniqueKey();

  List<dynamic> _badgesConquistados = [];
  bool _loadingBadges = true;
  List<Map<String, dynamic>> _marcos = [];

  @override
  void initState() {
    super.initState();
    _carregarBadges();
    _carregarMarcos();
  }

  Future<void> _carregarMarcos() async {
    final lista = await MilestoneService.listarCelebrados();
    if (mounted) setState(() => _marcos = lista);
  }

  Future<void> _carregarBadges() async {
    try {
      // Tenta recarregar dados do utilizador da API (inclui pontos atualizados)
      try {
        await ApiService.recarregarDadosUtilizador();
      } catch (e) {
        debugPrint('Aviso: Não conseguiu recarregar dados do utilizador: $e');
        // Continua mesmo se não conseguir recarregar pontos
      }

      final badges = await CacheService.getBadgesDoUtilizador();
      debugPrint('Badges recebidos: $badges');
      debugPrint('Utilizador sessão: ${Session.utilizador}');
      debugPrint('Pontos sessão: ${Session.pontos}');

      // Filtrar apenas badges aprovados
      final badgesAprovados = badges
          .where((b) => b['estado'] == 'APPROVED')
          .toList();

      if (!mounted) return;
      setState(() {
        _badgesConquistados = badgesAprovados;
        _loadingBadges = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar badges: $e');

      if (!mounted) return;
      setState(() {
        _badgesConquistados = [];
        _loadingBadges = false;
      });
    }
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'Data indisponível';
    final texto = data.toString();
    if (texto.length >= 10) {
      return texto.substring(0, 10);
    }
    return texto;
  }

  ImageProvider _getBackgroundImage(String fotoUrl) {
    if (fotoUrl.isEmpty) {
      return AssetImage('assets/placeholder.png'); // ou NetworkImage vazio
    }

    // Se é base64
    if (Base64ImageWidget.isBase64(fotoUrl)) {
      try {
        final imageBytes = Base64ImageWidget.decodeBase64(fotoUrl);
        return MemoryImage(imageBytes);
      } catch (e) {
        debugPrint('Erro ao decodificar base64: $e');
        return NetworkImage(''); // Fallback para evitar crash
      }
    }

    // Se é URL
    return NetworkImage(fotoUrl);
  }

  CircleAvatar _getDefaultAvatar({double radius = 50}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.purple.shade100,
      child: Icon(
        Icons.person,
        color: Colors.purple,
        size: radius * 0.8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.utilizador;
    final fotoUrl = Session.fotoUrl
        .trim()
        .replaceAll('localhost', '10.0.2.2')
        .replaceAll('127.0.0.1', '10.0.2.2')
        .replaceAll('100.105.58.22', '10.0.2.2')
        .replaceAll('0.0.0.0', '10.0.2.2');
    final totalBadges = _badgesConquistados.length;
    final pontos = Session.pontos;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarBadges,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        fotoUrl.isNotEmpty
                            ? CircleAvatar(
                                key: _avatarKey,
                                radius: 50,
                                backgroundColor: Colors.purple.shade100,
                                backgroundImage: _getBackgroundImage(fotoUrl),
                                child: null,
                              )
                            : _getDefaultAvatar(radius: 50),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () async {
                              final atualizado = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditPhotoPage(),
                                ),
                              );

                              if (atualizado == true) {
                                setState(() {
                                  _avatarKey = UniqueKey();
                                });
                              }
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      Session.nome,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Talent Management',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              Text(
                'Informações Pessoais',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),

              _infoCard(
                icon: Icons.email_outlined,
                title: 'Email',
                value: Session.email,
              ),
              SizedBox(height: 8),
              _infoCard(
                icon: Icons.work_outline,
                title: 'Área',
                value: user['area_nome']?.toString() ?? '—',
              ),
              SizedBox(height: 8),
              _infoCard(
                icon: Icons.badge_outlined,
                title: 'Estado da Conta',
                value: user['estadoconta']?.toString() ?? '—',
              ),
              SizedBox(height: 8),
              _infoCard(
                icon: Icons.stars_rounded,
                title: 'Pontos',
                value: '$pontos pontos',
              ),

              SizedBox(height: 24),

              Text(
                'Badges Conquistados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _loadingBadges
                    ? 'A carregar badges...'
                    : '$totalBadges badges conquistados',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(height: 12),

              if (_loadingBadges)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                  ),
                )
              else if (_badgesConquistados.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Text(
                    'Ainda não tens badges conquistados.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                )
              else
                ListView.separated(
                  itemCount: _badgesConquistados.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final badge = _badgesConquistados[index];
                    final imagem = (badge['imagem']?.toString() ?? badge['imagemurl']?.toString() ?? '')
                        .replaceAll('localhost', '10.0.2.2')
                        .replaceAll('127.0.0.1', '10.0.2.2')
                        .replaceAll('100.105.58.22', '10.0.2.2')
                        .replaceAll('0.0.0.0', '10.0.2.2');
                    final nome = badge['nome']?.toString() ?? 'Badge';
                    final descricao =
                        badge['descricao']?.toString() ?? 'Sem descrição';
                    final progressoAtual =
                        int.tryParse('${badge['progresso_atual'] ?? 0}') ?? 0;
                    final progressoTotal =
                        int.tryParse('${badge['progresso_total'] ?? 0}') ?? 0;
                    final dataConquista =
                        _formatarData(badge['data_conquista']);

                    return Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: imagem.isNotEmpty
                                ? Base64ImageWidget(
                                    imageData: imagem
                                        .replaceAll('localhost', '10.0.2.2')
                                        .replaceAll('127.0.0.1', '10.0.2.2')
                                        .replaceAll('100.105.58.22', '10.0.2.2')
                                        .replaceAll('0.0.0.0', '10.0.2.2'),
                                    width: 78,
                                    height: 78,
                                    fit: BoxFit.cover,
                                    placeholder: Container(
                                      width: 78,
                                      height: 78,
                                      color: Colors.grey.shade200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    errorWidget: Container(
                                      width: 78,
                                      height: 78,
                                      color: Colors.blue.shade50,
                                      child: Icon(
                                        Icons.emoji_events,
                                        color: Colors.blue,
                                        size: 34,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 78,
                                    height: 78,
                                    color: Colors.blue.shade50,
                                    child: Icon(
                                      Icons.emoji_events,
                                      color: Colors.blue,
                                      size: 34,
                                    ),
                                  ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nome,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check,
                                            color: Colors.green,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Aprovado',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  descricao,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Conquistado em $dataConquista',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progressoTotal > 0
                                      ? progressoAtual / progressoTotal
                                      : 1,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF2563EB),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '$progressoAtual / $progressoTotal',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              SizedBox(height: 24),

              Text(
                'Estatísticas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statCard('Badges Conquistados', '$totalBadges'),
                  _statCard('Melhor posição no rank', '2'),
                  _statCard('Pontos totais obtidos', '$pontos'),
                ],
              ),

              SizedBox(height: 24),

              // ── Marcos Alcançados ──
              if (_marcos.isNotEmpty) ...[
                Text(
                  'Marcos Alcançados',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  '${_marcos.length} marco${_marcos.length == 1 ? '' : 's'} conquistado${_marcos.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.55,
                  ),
                  itemCount: _marcos.length,
                  itemBuilder: (context, i) {
                    final marco = _marcos[i]['milestone'] as Milestone;
                    final data = _marcos[i]['celebrado_em'] as String;
                    final dataFormatada = data.length >= 10 ? data.substring(0, 10) : data;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(marco.emoji, style: const TextStyle(fontSize: 26)),
                          const Spacer(),
                          Text(
                            marco.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dataFormatada,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF2563EB)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      width: 160,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}