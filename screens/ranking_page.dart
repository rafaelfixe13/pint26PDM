import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import 'package:go_router/go_router.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  late Future<List<dynamic>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = ApiService.getRanking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD6EAF8),
      appBar: AppBar(
        backgroundColor: Color(0xFFD6EAF8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () { context.go('/main');
          },
        ),
        title: Text(
          'Ranking',
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF1E3A5F),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _rankingFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro ao carregar ranking'));
          }

          final lista = snap.data ?? [];
          if (lista.isEmpty) {
            return Center(child: Text('Sem utilizadores no ranking'));
          }

          // top 3
          final top1 = lista.length > 0 ? lista[0] : null;
          final top2 = lista.length > 1 ? lista[1] : null;
          final top3 = lista.length > 2 ? lista[2] : null;

          // resto da lista (4º em diante)
          final resto = lista.length > 3 ? lista.sublist(3) : [];

          return Column(
            children: [
              SizedBox(height: 16),

              // ── TOP 3 ─────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 2º lugar
                    if (top2 != null)
                      Expanded(
                        child: _TopCard(
                          utilizador: top2,
                          posicao: 2,
                          avatarRadius: 38,
                          isCurrentUser: top2['idutilizador'].toString() ==
                              Session.id.toString(),
                        ),
                      ),

                    SizedBox(width: 8),

                    // 1º lugar (maior)
                    if (top1 != null)
                      Expanded(
                        child: _TopCard(
                          utilizador: top1,
                          posicao: 1,
                          avatarRadius: 50,
                          showCrown: true,
                          isCurrentUser: top1['idutilizador'].toString() ==
                              Session.id.toString(),
                        ),
                      ),

                    SizedBox(width: 8),

                    // 3º lugar
                    if (top3 != null)
                      Expanded(
                        child: _TopCard(
                          utilizador: top3,
                          posicao: 3,
                          avatarRadius: 34,
                          isCurrentUser: top3['idutilizador'].toString() ==
                              Session.id.toString(),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // ── LISTA (4º em diante) ──────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: resto.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, i) {
                      final u = resto[i];
                      final posicao = i + 4;
                      final isYou = u['idutilizador'].toString() ==
                          Session.id.toString();

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isYou
                              ? Color(0xFF2563EB)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            _Avatar(
                              fotoUrl: u['fotourl'],
                              nome: u['nome'],
                              radius: 24,
                            ),
                            SizedBox(width: 12),
                            // Nome
                            Expanded(
                              child: Text(
                                isYou ? 'You' : (u['nome'] ?? ''),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isYou
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            // Posição
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Color(0xFF1E3A5F),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$posicao',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            // Pontos
                            Text(
                              '${u['pontos'] ?? 0}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isYou
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Widget: Top 3 Card ────────────────────────────────────────────

class _TopCard extends StatelessWidget {
  final dynamic utilizador;
  final int posicao;
  final double avatarRadius;
  final bool showCrown;
  final bool isCurrentUser;

  const _TopCard({
    required this.utilizador,
    required this.posicao,
    required this.avatarRadius,
    this.showCrown = false,
    this.isCurrentUser = false,
  });

  Color get _borderColor {
    if (posicao == 1) return Color(0xFFFFD700); // ouro
    if (posicao == 2) return Color(0xFF4A90D9); // azul
    return Color(0xFF2E7D32); // verde
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showCrown)
          Text('👑', style: TextStyle(fontSize: 28)),

        Stack(
          alignment: Alignment.center,
          children: [
            // Borda colorida
            Container(
              width: avatarRadius * 2 + 8,
              height: avatarRadius * 2 + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor, width: 3),
              ),
            ),
            _Avatar(
              fotoUrl: utilizador['fotourl'],
              nome: utilizador['nome'],
              radius: avatarRadius,
            ),
            // Número da posição
            Positioned(
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _borderColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$posicao',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 6),

        Text(
          isCurrentUser ? 'You' : (utilizador['nome'] ?? ''),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1E3A5F),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        Text(
          '${utilizador['pontos'] ?? 0}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: _borderColor,
          ),
        ),
      ],
    );
  }
}

// ─── Widget: Avatar ────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final dynamic fotoUrl;
  final dynamic nome;
  final double radius;

  const _Avatar({
    required this.fotoUrl,
    required this.nome,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl?.toString() ?? '';

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.purple.shade100,
      child: ClipOval(
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Icon(Icons.person, size: radius, color: Colors.purple),
              )
            : Icon(Icons.person, size: radius, color: Colors.purple),
      ),
    );
  }
}
