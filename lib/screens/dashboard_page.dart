import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final data = await ApiService.getDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/main'),
        ),
        title: const Text(
          'Learning Path',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? _buildErro()
              : RefreshIndicator(onRefresh: _carregar, child: _buildContent()),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              _erro ?? 'Erro desconhecido',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _data!;
    final lpNome = data['learningpath'] as String? ?? 'Jornada Técnica';
    final progresso = data['progresso'] as Map<String, dynamic>? ?? {};
    final aprovados = (progresso['badges_aprovados'] as num?)?.toInt() ?? 0;
    final total = (progresso['total_badges'] as num?)?.toInt() ?? 0;
    final pct = total > 0 ? aprovados / total : 0.0;
    final servicelines = data['servicelines'] as List<dynamic>? ?? [];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildHeader(lpNome, aprovados, total, pct),
        const SizedBox(height: 20),
        if (servicelines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Sem dados de Learning Path disponíveis.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final sl in servicelines) ...[
                  _buildServiceLine(sl),
                  const SizedBox(height: 24),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(String nome, int aprovados, int total, double pct) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Jornada Técnica',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$aprovados de $total badges conquistados',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha:0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).toInt()}% completo',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceLine(dynamic sl) {
    final nome = sl['nome'] as String? ?? '';
    final areas = sl['areas'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nome,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final area in areas) ...[
          _buildAreaCard(area),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildAreaCard(dynamic area) {
    final nome = area['nome'] as String? ?? '';
    final niveis = area['niveis'] as List<dynamic>? ?? [];

    final aprovados = niveis.where((n) => n['estado'] == 'APPROVED').length;
    final emProgresso = niveis.where((n) {
      final e = n['estado'] as String? ?? 'NAO_INICIADO';
      return e == 'SUBMITTED' || e == 'UNDER_REVIEW' || e == 'OPEN';
    }).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusChip(aprovados, emProgresso, niveis.length),
            ],
          ),
          const SizedBox(height: 16),
          _buildNiveisRow(niveis),
        ],
      ),
    );
  }

  Widget _statusChip(int aprovados, int emProgresso, int total) {
    if (aprovados == total && total > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Completo',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (emProgresso > 0 || aprovados > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha:0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$aprovados/$total',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '0/$total',
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNiveisRow(List<dynamic> niveis) {
    // Sempre no máximo 5 grupos (A-E)
    final items = niveis.take(5).toList();
    return Row(
      children: List.generate(items.length, (i) {
        final nivel = items[i];
        final estado = nivel['estado'] as String? ?? 'NAO_INICIADO';
        // nivel_grupo é CHR(65+pos): A, B, C, D, E
        final letra = nivel['nivel_grupo'] as String? ?? '?';
        // Conector à esquerda é verde se o nivel ANTERIOR foi aprovado
        final prevAprovado = i > 0 &&
            (items[i - 1]['estado'] as String? ?? '') == 'APPROVED';

        return Expanded(
          child: Row(
            children: [
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: prevAprovado
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              _buildNivelDot(letra, estado),
              if (i < items.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: estado == 'APPROVED'
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNivelDot(String letra, String estado) {
    Color bgColor;
    Color textColor;
    Widget dotChild;

    switch (estado) {
      case 'APPROVED':
        bgColor = const Color(0xFF10B981);
        textColor = Colors.white;
        dotChild = const Icon(Icons.check, color: Colors.white, size: 18);
        break;
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        bgColor = const Color(0xFF2563EB);
        textColor = Colors.white;
        dotChild = Text(letra,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w800, fontSize: 14));
        break;
      case 'OPEN':
        bgColor = const Color(0xFFFFF7ED);
        textColor = const Color(0xFFF59E0B);
        dotChild = Text(letra,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w800, fontSize: 14));
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF9CA3AF);
        dotChild = Text(letra,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w800, fontSize: 14));
    }

    Color labelColor;
    switch (estado) {
      case 'APPROVED':
        labelColor = const Color(0xFF10B981);
        break;
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        labelColor = const Color(0xFF2563EB);
        break;
      default:
        labelColor = const Color(0xFF9CA3AF);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: estado == 'OPEN'
                ? Border.all(color: const Color(0xFFF59E0B), width: 2)
                : null,
            boxShadow: estado == 'APPROVED'
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(child: dotChild),
        ),
        const SizedBox(height: 6),
        Text(
          _nomeGrupo(letra),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Mapeia a letra do grupo (A-E) para o nome do nível
  String _nomeGrupo(String letra) {
    const nomes = {
      'A': 'Júnior',
      'B': 'Interm.',
      'C': 'Sénior',
      'D': 'Expert',
      'E': 'Líder',
    };
    return nomes[letra.toUpperCase()] ?? letra;
  }
}
