import 'package:flutter/material.dart';
import '../services/session.dart';
import '../widgets/base64_image_widget.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/lembretes_service.dart';
import '../services/milestone_service.dart';
import '../services/expiracao_service.dart';
import '../widgets/milestone_dialog.dart';
import 'package:go_router/go_router.dart';
import 'notifications_page.dart';
import 'profile_page.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<List<dynamic>> _badgesFuture;
  late Future<List<dynamic>> _candidaturasFuture;
  late Future<List<dynamic>> _notificacoesFuture;
  late Future<List<Map<String, dynamic>>> _lembretesFuture;
  late Future<Map<String, dynamic>?> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _verificarRgpd();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _verificarLembretes();
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _verificarMarcos();
      });
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) _verificarExpiracao();
      });
    });
  }

  Future<void> _verificarRgpd() async {
    if (Session.rgpdVerificado) return;
    Session.rgpdVerificado = true;
    if (Session.utilizador['rgpd'] == true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.privacy_tip_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Consentimento RGPD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ]),
        content: const Text(
          'Para podermos partilhar os teus badges (ex: LinkedIn, certificados) e cumprir o RGPD, '
          'precisamos do teu consentimento explícito para o tratamento destes dados. '
          'Podes alterar esta escolha a qualquer momento em Definições.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Não aceito'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final novoValor = await ApiService.atualizarRgpd(true);
                await Session.atualizarRgpdPersistente(novoValor);
              } catch (_) {}
            },
            child: const Text('Aceito', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _verificarExpiracao() async {
    if (Session.expiracaoVerificada) return;
    Session.expiracaoVerificada = true;
    try {
      // Cria notificações no servidor para badges a expirar
      await ApiService.verificarExpiracaoNotificacoes(Session.id);
      final candidaturas = await CacheService.getCandidaturas();
      final expirando = ExpiracaoService.calcular(candidaturas);
      if (expirando.isEmpty || !mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Badges a Expirar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: expirando.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final b = expirando[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(
                              '${b.dataExpiracao.day.toString().padLeft(2,'0')}/${b.dataExpiracao.month.toString().padLeft(2,'0')}/${b.dataExpiracao.year}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: b.cor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(b.etiqueta, style: TextStyle(fontSize: 11, color: b.cor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  Future<void> _verificarMarcos() async {
    if (Session.marcosVerificados) return;
    Session.marcosVerificados = true;
    try {
      final candidaturas = await CacheService.getCandidaturas();
      final novos = await MilestoneService.verificarNovos(candidaturas);
      if (novos.isEmpty || !mounted) return;
      for (final marco in novos) {
        if (!mounted) break;
        await MilestoneDialog.mostrar(context, marco);
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (_) {}
  }

  Future<void> _verificarLembretes() async {
    if (Session.lembretesMostrados) return;
    Session.lembretesMostrados = true;
    // Cria notificações + push no servidor para lembretes próximos do prazo
    await ApiService.verificarLembretesNotificacoes(Session.id);
    final proximos = await LembretesService.verificarProximos(diasAntecedencia: 3);
    if (proximos.isEmpty || !mounted) return;

    final hoje = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.notifications_active, color: Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text('${proximos.length == 1 ? 'Lembrete' : 'Lembretes'} próximo${proximos.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: proximos.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final l = proximos[i];
              final prazo = DateTime.parse(l['prazo'] as String);
              final diff = DateTime(prazo.year, prazo.month, prazo.day)
                  .difference(DateTime(hoje.year, hoje.month, hoje.day))
                  .inDays;
              final label = diff < 0
                  ? 'Atrasado ${-diff}d'
                  : diff == 0
                      ? 'Hoje!'
                      : 'Em ${diff}d';
              final color = diff <= 0 ? Colors.red : Colors.orange;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l['titulo'] as String? ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if ((l['badge_nome'] as String?)?.isNotEmpty == true)
                            Text(l['badge_nome'] as String,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(label,
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                      backgroundColor: color,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/lembretes');
            },
            child: const Text('Ver todos'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _loadData() {
    _badgesFuture = CacheService.getBadgesRecomendados(Session.id);
    _candidaturasFuture = CacheService.getCandidaturas();
    _notificacoesFuture = CacheService.getNotificacoes();
    _lembretesFuture = LembretesService.verificarProximos(diasAntecedencia: 7);
    _dashboardFuture = ApiService.getDashboard().catchError((_) => <String, dynamic>{});
    if (mounted) setState(() {});
  }

  Widget _buildBadgeAvatar(dynamic badge) {
    if (badge == null || badge['imagemurl'] == null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.emoji_events,
            size: 24,
            color: Color(0xFF0052CC),
          ),
        ),
      );
    }

    final url = badge['imagemurl']
        .toString()
        .replaceAll('localhost', '10.0.2.2')
        .replaceAll('127.0.0.1', '10.0.2.2')
        .replaceAll('100.105.58.22', '10.0.2.2')
        .replaceAll('0.0.0.0', '10.0.2.2');
    if (Base64ImageWidget.isBase64(url)) {
      try {
        final imageBytes = Base64ImageWidget.decodeBase64(url);
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.memory(
              imageBytes,
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFEF5350),
              width: 1,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.error,
              size: 16,
              color: Color(0xFFEF5350),
            ),
          ),
        );
      }
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFF0F4FF),
              child: const Center(
                child: Icon(
                  Icons.emoji_events,
                  size: 24,
                  color: Color(0xFF0052CC),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = Session.fotoUrl.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0052CC),
        elevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'Softinsa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FutureBuilder<List<dynamic>>(
              future: _notificacoesFuture,
              builder: (context, notifSnap) {
                final naoLidas = (notifSnap.data ?? [])
                    .where((n) => n['lido'] == false)
                    .length;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsPage(),
                          ),
                        );
                        _loadData();
                      },
                    ),
                    if (naoLidas > 0)
                      Positioned(
                        right: 6,
                        top: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5252),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$naoLidas',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, fotoUrl),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          await Future.wait(
              [_badgesFuture, _candidaturasFuture, _notificacoesFuture]);
        },
        child: FutureBuilder<List<dynamic>>(
          future: _badgesFuture,
          builder: (context, badgeSnap) {
            final listaBadges = badgeSnap.data ?? [];

            return FutureBuilder<List<dynamic>>(
              future: _candidaturasFuture,
              builder: (context, candidaturaSnap) {
                final candidaturas = candidaturaSnap.data ?? [];

                // Mapa badge_id → candidatura com conversão segura de tipos
                final candidaturasByBadgeId = <int, dynamic>{};
                for (final c in candidaturas) {
                  final id = int.tryParse(c['badge_id']?.toString() ?? '');
                  if (id != null) candidaturasByBadgeId[id] = c;
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  children: [
                    // Header com fundo colorido
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF0052CC).withOpacity(0.08),
                            const Color(0xFF0052CC).withOpacity(0.02),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bem-vindo!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Continua a conquistar Badges e a desenvolver as tuas competências',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          const EdgeInsets.only(top: 24, left: 20, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card de Meta
                          FutureBuilder<Map<String, dynamic>?>(
                            future: _dashboardFuture,
                            builder: (context, dashSnap) {
                              final dash = dashSnap.data ?? {};
                              final progresso = dash['progresso'] as Map<String, dynamic>? ?? {};
                              final aprovados = (progresso['badges_aprovados'] as num?)?.toInt() ?? 0;
                              final total = (progresso['total_badges'] as num?)?.toInt() ?? 0;
                              final pct = total > 0 ? (aprovados / total).clamp(0.0, 1.0) : 0.0;
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'A tua Meta',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF999999),
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '$aprovados de $total Badges',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 22,
                                                color: Color(0xFF1E3A5F),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0052CC).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${(pct * 100).toInt()}%',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0052CC),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: const Color(0xFFE5E7EB),
                                        color: const Color(0xFF0052CC),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: (listaBadges.isEmpty
                                                ? List.filled(5, null)
                                                : listaBadges)
                                            .take(5)
                                            .map<Widget>(
                                              (b) => Padding(
                                                padding: const EdgeInsets.only(right: 10),
                                                child: _buildBadgeAvatar(b),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // ── Lembretes próximos ──
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _lembretesFuture,
                            builder: (context, snap) {
                              final lembretes = snap.data ?? [];
                              if (lembretes.isEmpty) return const SizedBox.shrink();
                              final hoje = DateTime.now();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Lembretes',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1E3A5F),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.push('/lembretes'),
                                        child: const Text('Ver todos',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...lembretes.take(3).map((l) {
                                    final prazo = DateTime.parse(l['prazo'] as String);
                                    final diff = DateTime(prazo.year, prazo.month, prazo.day)
                                        .difference(DateTime(hoje.year, hoje.month, hoje.day))
                                        .inDays;
                                    final color = diff < 0
                                        ? Colors.red
                                        : diff == 0
                                            ? Colors.orange
                                            : const Color(0xFF2563EB);
                                    final label = diff < 0
                                        ? 'Atrasado ${-diff}d'
                                        : diff == 0
                                            ? 'Hoje!'
                                            : 'Em ${diff}d';
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: color.withValues(alpha: 0.25)),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.notifications_active, color: color, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(l['titulo'] as String? ?? '',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 13,
                                                        color: Color(0xFF1E3A5F))),
                                                if ((l['badge_nome'] as String?)?.isNotEmpty == true)
                                                  Text(l['badge_nome'] as String,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(0xFF2563EB))),
                                              ],
                                            ),
                                          ),
                                          Chip(
                                            label: Text(label,
                                                style: const TextStyle(color: Colors.white, fontSize: 10)),
                                            backgroundColor: color,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),

                          // Seção de Candidaturas
                          const Text(
                            'Candidaturas em Progresso',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Builder(builder: (context) {
                            final emProgresso = candidaturas
                                .where((c) => c['estado'] != 'APPROVED')
                                .toList();
                            if (emProgresso.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 36, color: Color(0xFFB0B8C1)),
                                    SizedBox(height: 8),
                                    Text(
                                      'Sem candidaturas em progresso',
                                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Row(
                              children: emProgresso
                                  .take(2)
                                  .map<Widget>(
                                    (c) => Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _miniCard(
                                          c,
                                          showProgress: true,
                                          mostrarExpiracao: true,
                                          onTap: () => context.push(
                                            '/badge_detail',
                                            extra: {
                                              'badge': c,
                                              'candidatura': c,
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          }),

                          const SizedBox(height: 32),

                          // Seção de Catálogo Completo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Catálogo de Badges Completo',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/badges'),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0052CC)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: Color(0xFF0052CC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Seção de Badges Recomendados
                          const Text(
                            'Badges Recomendados',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (listaBadges.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.workspace_premium_outlined, size: 36, color: Color(0xFFB0B8C1)),
                                  SizedBox(height: 8),
                                  Text(
                                    'Sem badges disponíveis',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            )
                          else
                            Row(
                              children: listaBadges
                                  .take(2)
                                  .map<Widget>((b) {
                                    final badgeId = int.tryParse(b['idbadge']?.toString() ?? '');
                                    final candidatura = badgeId != null ? candidaturasByBadgeId[badgeId] : null;
                                    dynamic renderedBadge = b;
                                    if (candidatura != null) {
                                      try {
                                        renderedBadge = Map<String, dynamic>.from(b as Map)
                                          ..['progresso_atual'] = candidatura['progresso_atual']
                                          ..['progresso_total'] = candidatura['progresso_total'];
                                      } catch (_) {}
                                    }
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: _miniCard(
                                          renderedBadge,
                                          showProgress: candidatura != null,
                                          onTap: () => context.push(
                                            '/badge_detail',
                                            extra: {
                                              'badge': b,
                                              'candidatura': candidatura,
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, String fotoUrl) {
    return Drawer(
      backgroundColor: const Color(0xFFFAFBFC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Drawer
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );

                if (resultado == true) {
                  _loadData();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    fotoUrl.isNotEmpty
                        ? Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF0052CC),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Base64ImageWidget.isBase64(fotoUrl)
                                  ? Image.memory(
                                      Base64ImageWidget.decodeBase64(fotoUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFFF0F4FF),
                                          child: const Icon(Icons.person,
                                              color: Color(0xFF0052CC)),
                                        );
                                      },
                                    )
                                  : Image.network(
                                      fotoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFFF0F4FF),
                                          child: const Icon(Icons.person,
                                              color: Color(0xFF0052CC)),
                                        );
                                      },
                                    ),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF0052CC),
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.person,
                                color: Color(0xFF0052CC), size: 24),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Session.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF1E3A5F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Gestão de Talentos',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _drawerItem(
                    Icons.home_outlined,
                    'Início',
                    selected: true,
                    onTap: () => context.go('/main'),
                  ),
                  _drawerItem(
                    Icons.emoji_events_outlined,
                    'Catálogo de Badges',
                    onTap: () => context.go('/badges'),
                  ),
                  _drawerItem(
                    Icons.route_outlined,
                    'Learning Path',
                    onTap: () => context.go('/dashboard'),
                  ),
                  _drawerItem(
                    Icons.bar_chart_outlined,
                    'Ranking',
                    onTap: () => context.go('/ranking'),
                  ),
                  _drawerItem(
                    Icons.assignment_outlined,
                    'Candidaturas',
                    onTap: () => context.go('/candidaturas'),
                  ),
                  _drawerItem(
                    Icons.notifications_outlined,
                    'Lembretes',
                    onTap: () => context.go('/lembretes'),
                  ),
                  _drawerItem(Icons.settings_outlined, 'Definições',
                      onTap: () => context.go('/options')),
                  _drawerItem(
                    Icons.calendar_today_outlined,
                    'Calendário',
                    onTap: () => context.go('/calendario'),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _drawerItem(
                    Icons.help_outline,
                    'Ajuda',
                    onTap: () => context.go('/help'),
                  ),
                  _drawerItem(
                    Icons.info_outline,
                    'Sobre',
                    onTap: () => context.go('/about'),
                  ),
                  const SizedBox(height: 8),
                  _drawerItem(
                    Icons.logout_outlined,
                    'Terminar Sessão',
                    isDanger: true,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Terminar Sessão'),
                          content: const Text(
                            'Tens a certeza que desejas terminar a sessão?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                Session.terminar();
                                context.go('/');
                              },
                              child: const Text(
                                'Terminar',
                                style: TextStyle(
                                  color: Color(0xFFEF5350),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  ListTile _drawerItem(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool selected = false,
    bool isDanger = false,
  }) {
    final color = isDanger
        ? const Color(0xFFEF5350)
        : selected
            ? const Color(0xFF0052CC)
            : const Color(0xFF666666);

    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: selected || isDanger ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      tileColor: selected ? const Color(0xFF0052CC).withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minLeadingWidth: 0,
      dense: true,
      onTap: onTap,
    );
  }

  Widget _miniCard(dynamic badge,
      {required bool showProgress, VoidCallback? onTap, bool mostrarExpiracao = false}) {
    final int atual =
        int.tryParse(badge?['progresso_atual']?.toString() ?? '0') ?? 0;
    final int total =
        int.tryParse(badge?['progresso_total']?.toString() ?? '0') ?? 0;
    final double pct = total > 0 ? (atual / total).clamp(0.0, 1.0) : 0.5;

    BadgeExpiracao? expiracao;
    if (mostrarExpiracao && badge != null) {
      final expList = ExpiracaoService.calcular([badge]);
      if (expList.isNotEmpty) expiracao = expList.first;
    }

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: badge == null || badge['imagemurl'] == null
                  ? const Icon(Icons.emoji_events,
                      size: 32, color: Color(0xFF0052CC))
                  : Base64ImageWidget(
                      imageData: badge['imagemurl']
                          .toString()
                          .replaceAll('localhost', '10.0.2.2')
                          .replaceAll('127.0.0.1', '10.0.2.2')
                          .replaceAll('100.105.58.22', '10.0.2.2')
                          .replaceAll('0.0.0.0', '10.0.2.2'),
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorWidget: const Icon(
                        Icons.emoji_events,
                        size: 32,
                        color: Color(0xFF0052CC),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            badge?['nome'] ?? 'Badge',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A5F),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (expiracao != null) ...[
            const SizedBox(height: 6),
            Text(
              'Expira em:',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
            Text(
              expiracao.expirado ? 'Expirado' : '${expiracao.diasRestantes}d',
              style: TextStyle(
                fontSize: 11,
                color: expiracao.cor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (showProgress) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0052CC).withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(pct * 100).toInt()}% completo',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF0052CC),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: const Color(0xFFE5E7EB),
                color: const Color(0xFF0052CC),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );

    final content = expiracao == null
        ? card
        : Stack(
            children: [
              card,
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: expiracao.cor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        expiracao.expirado ? Icons.error_outline : Icons.access_time_outlined,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        expiracao.expirado ? 'Expirado' : '${expiracao.diasRestantes}d',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }
}
