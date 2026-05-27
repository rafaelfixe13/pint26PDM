import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/session.dart';
import '../services/api_service.dart';
import '../base64_image_widget.dart';
import './edit_photo_page.dart';
import './badge_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
      // Try to refresh user data (pontos, foto_base64) from the API
      try {
        await ApiService.recarregarDadosUtilizador();
      } catch (e) {
        debugPrint('Aviso: Não conseguiu recarregar dados do utilizador: $e');
      }

      final badges = await ApiService.getBadgesDoUtilizador();
      // Filter only approved / awarded badges. Server responses vary, so
      // accept several indicators: top-level 'estado' == 'APPROVED', a
      // nested 'candidatura' with 'estado' == 'APPROVED', or a
      // non-empty 'data_conquista'. This prevents unapproved items from
      // appearing in the "Badges Conquistados" list.
      final approved = badges.where((b) {
        try {
          final estado = b['estado']?.toString().toUpperCase();
          if (estado == 'APPROVED') return true;

          final cand = b['candidatura'];
          if (cand is Map && cand['estado']?.toString().toUpperCase() == 'APPROVED') return true;

          final data = b['data_conquista'];
          if (data != null && data.toString().trim().isNotEmpty) return true;
        } catch (_) {}
        return false;
      }).toList();
      debugPrint('Badges recebidos: $badges');
      debugPrint('Utilizador sessão: ${Session.utilizador}');
      debugPrint('Pontos sessão: ${Session.pontos}');

      if (!mounted) return;
      setState(() {
        _badgesConquistados = approved;
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
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarBadges,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              child: Session.utilizador['foto_base64'] != null &&
                                      Session.utilizador['foto_base64'].toString().isNotEmpty
                                  ? Base64ImageWidget(
                                      imageData: Session.utilizador['foto_base64'].toString(),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : (fotoUrl.isNotEmpty
                                      ? (Base64ImageWidget.isBase64(fotoUrl)
                                          ? Base64ImageWidget(
                                              imageData: fotoUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: fotoUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => const Center(
                                                child: CircularProgressIndicator(
                                                  color: Colors.purple,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => const Icon(
                                                Icons.person,
                                                size: 50,
                                                color: Colors.purple,
                                              ),
                                            ))
                                      : const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.purple,
                                        )),
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
                                  builder: (_) => const EditPhotoPage(),
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
                                color: const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      Session.nome,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Talent Management',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Informações Pessoais',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              _infoCard(
                icon: Icons.email_outlined,
                title: 'Email',
                value: Session.email,
              ),
              const SizedBox(height: 8),
              _infoCard(
                icon: Icons.work_outline,
                title: 'Área',
                value: user['area_nome']?.toString() ?? '—',
              ),
              const SizedBox(height: 8),
              _infoCard(
                icon: Icons.badge_outlined,
                title: 'Estado da Conta',
                value: user['estadoconta']?.toString() ?? '—',
              ),
              const SizedBox(height: 8),
              _infoCard(
                icon: Icons.stars_rounded,
                title: 'Pontos',
                value: '$pontos pontos',
              ),

              const SizedBox(height: 24),

              const Text(
                'Badges Conquistados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _loadingBadges
                    ? 'A carregar badges...'
                    : '$totalBadges badges conquistados',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),

              if (_loadingBadges)
                const Center(
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
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
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final badge = _badgesConquistados[index];
                    final imagem = badge['imagem']?.toString() ?? '';
                    final nome = badge['nome']?.toString() ?? 'Badge';
                    final descricao = badge['descricao']?.toString() ?? '';
                    
                    final dataConquista = _formatarData(badge['data_conquista']);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 0),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black12,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BadgeDetailPage(badge: badge, candidatura: badge['candidatura']),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: imagem.isNotEmpty
                                          ? (Base64ImageWidget.isBase64(imagem)
                                              ? Base64ImageWidget(
                                                  imageData: imagem,
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.network(
                                                  imagem.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2').replaceAll('100.105.58.22', '10.0.2.2').replaceAll('0.0.0.0', '10.0.2.2'),
                                                  width: 56,
                                                  height: 56,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEFF6FF),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: const Icon(
                                                      Icons.emoji_events,
                                                      color: Color(0xFF2563EB),
                                                      size: 28,
                                                    ),
                                                  ),
                                                ))
                                          : Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.emoji_events,
                                                color: Color(0xFF2563EB),
                                                size: 28,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nome,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E3A5F),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            descricao.isEmpty ? 'Sem descrição disponível.' : descricao,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F4EA),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Aprovado',
                                        style: TextStyle(
                                          color: Color(0xFF059669),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Nível: ${badge['nivel'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.star, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${badge['pontos'] ?? 0} pts',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        dataConquista,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'Abrir badge',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              const Text(
                'Estatísticas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statCard('Badges Conquistados', '$totalBadges'),
                  _statCard('Melhor posição no rank', '2'),
                  _statCard('Pontos totais obtidos', '$pontos'),
                ],
              ),

              const SizedBox(height: 32),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}