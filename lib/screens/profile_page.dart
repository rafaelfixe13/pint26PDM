import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinttest/services/session.dart';
import 'package:pinttest/services/api_service.dart';
import 'package:pinttest/screens/edit_photo_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Key _avatarKey = UniqueKey();

  List<dynamic> _badgesConquistados = [];
  bool _loadingBadges = true;

  @override
  void initState() {
    super.initState();
    _carregarBadges();
  }

  Future<void> _carregarBadges() async {
    try {
      final badges = await ApiService.getBadgesDoUtilizador();
      debugPrint('Badges recebidos: $badges');
      debugPrint('Utilizador sessão: ${Session.utilizador}');
      debugPrint('Pontos sessão: ${Session.pontos}');

      if (!mounted) return;
      setState(() {
        _badgesConquistados = badges;
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

  @override
  Widget build(BuildContext context) {
    final user = Session.utilizador;
    final fotoUrl = Session.fotoUrl.trim();
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
                        CircleAvatar(
                          key: _avatarKey,
                          radius: 50,
                          backgroundColor: Colors.purple.shade100,
                          child: ClipOval(
                            child: fotoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: fotoUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.purple,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.purple,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.purple,
                                  ),
                          ),
                        ),
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
                icon: Icons.phone_outlined,
                title: 'Número de Telefone',
                value: user['telefone']?.toString() ?? '—',
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
                    final imagem = badge['imagem']?.toString() ?? '';
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
                                ? CachedNetworkImage(
                                    imageUrl: imagem
                                        .replaceAll('localhost', '10.0.2.2')
                                        .replaceAll('127.0.0.1', '10.0.2.2')
                                        .replaceAll('100.105.58.22', '10.0.2.2')
                                        .replaceAll('0.0.0.0', '10.0.2.2'),
                                    width: 78,
                                    height: 78,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
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
                                    errorWidget: (context, url, error) =>
                                        Container(
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
                                Text(
                                  nome,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
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