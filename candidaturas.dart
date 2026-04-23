import 'package:flutter/material.dart';
import 'package:pinttest/services/api_service.dart';
import 'package:pinttest/screens/badge_detail_page.dart';

class CandidaturasPage extends StatefulWidget {
  const CandidaturasPage({super.key});

  @override
  State<CandidaturasPage> createState() => _CandidaturasPageState();
}

class _CandidaturasPageState extends State<CandidaturasPage> {
  late Future<List<dynamic>> _candidaturasFuture;

  @override
  void initState() {
    super.initState();
    _candidaturasFuture = ApiService.getCandidaturas();
  }

  Future<void> _recarregar() async {
    setState(() {
      _candidaturasFuture = ApiService.getCandidaturas();
    });
    await _candidaturasFuture;
  }

  Color _corEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'UNDER_REVIEW':
        return Colors.orange;
      case 'SUBMITTED':
        return const Color(0xFF2563EB);
      case 'OPEN':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _textoEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'APPROVED':
        return 'Aprovada';
      case 'REJECTED':
        return 'Rejeitada';
      case 'UNDER_REVIEW':
        return 'Em revisão';
      case 'SUBMITTED':
        return 'Submetida';
      case 'OPEN':
        return 'Aberta';
      default:
        return estado;
    }
  }

  String _formatarData(dynamic data) {
    if (data == null) return 'Sem data';
    final texto = data.toString().trim();
    if (texto.isEmpty) return 'Sem data';
    if (texto.contains('T')) return texto.split('T').first;
    return texto;
  }

  void _abrirBadge(dynamic candidatura) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BadgeDetailPage(badge: candidatura),
      ),
    );
  }

  Widget _buildEstadoChip(String estado) {
    final cor = _corEstado(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _textoEstado(estado),
        style: TextStyle(
          color: cor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImagemBadge(dynamic candidatura) {
    final imagemUrl = candidatura['imagemurl']?.toString();

    if (imagemUrl != null && imagemUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imagemUrl,
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
        ),
      );
    }

    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Candidaturas',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<List<dynamic>>(
          future: _candidaturasFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.error_outline,
                    size: 54,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar candidaturas.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }

            final candidaturas = snapshot.data ?? [];

            if (candidaturas.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Ainda não existem candidaturas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: candidaturas.length,
              itemBuilder: (context, index) {
                final candidatura = candidaturas[index];
                final estado = candidatura['estado']?.toString() ?? 'OPEN';
                final nome = candidatura['nome']?.toString() ?? 'Badge';
                final descricao = candidatura['descricao']?.toString() ?? '';
                final comentario = candidatura['comentariogeral']?.toString() ?? '';
                final nivel = candidatura['nivel']?.toString() ?? 'N/A';
                final pontos = candidatura['pontos']?.toString() ?? '0';
                final atual = int.tryParse(
                      candidatura['progresso_atual']?.toString() ?? '0',
                    ) ??
                    0;
                final total = int.tryParse(
                      candidatura['progresso_total']?.toString() ?? '0',
                    ) ??
                    0;
                final progresso = total > 0 ? (atual / total).clamp(0.0, 1.0) : 0.0;
                final data = _formatarData(
                  candidatura['datasubmissao'] ?? candidatura['datacriacao'],
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    shadowColor: Colors.black12,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _abrirBadge(candidatura),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildImagemBadge(candidatura),
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
                                        descricao.isEmpty
                                            ? 'Sem descrição disponível.'
                                            : descricao,
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
                                _buildEstadoChip(estado),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Nível: $nivel',
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
                                  '$pontos pts',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Progresso',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '$atual/$total',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: progresso,
                              backgroundColor: const Color(0xFFE5E7EB),
                              color: const Color(0xFF2563EB),
                              minHeight: 6,
                            ),
                            if (comentario.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              const Text(
                                'Comentário',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comentario,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
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
                                    data,
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
            );
          },
        ),
      ),
    );
  }
}