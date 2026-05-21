import 'package:flutter/material.dart';
import './help_page.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import './badges_page.dart';
import './badge_detail_page.dart';
import './profile_page.dart';
import './notifications_page.dart';
import './login_page.dart';
import './ranking_page.dart';
import './options_page.dart';
import './candidaturas.dart';
import '../widgets/base64_image_widget.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<List<dynamic>> _badgesFuture;
  late Future<List<dynamic>> _candidaturasFuture;
  late Future<List<dynamic>> _notificacoesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _badgesFuture = ApiService.getBadgesRecomendados(Session.id);
    _candidaturasFuture = ApiService.getCandidaturas();
    _notificacoesFuture = ApiService.getNotificacoes();
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
                final naoLidas =
                    (notifSnap.data ?? []).where((n) => n['lido'] == false).length;

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
          await Future.wait([_badgesFuture, _candidaturasFuture, _notificacoesFuture]);
        },
        child: FutureBuilder<List<dynamic>>(
          future: _badgesFuture,
          builder: (context, badgeSnap) {
            final listaBadges = badgeSnap.data ?? [];

            return FutureBuilder<List<dynamic>>(
              future: _candidaturasFuture,
              builder: (context, candidaturaSnap) {
                final candidaturas = candidaturaSnap.data ?? [];
                
                // Create a map of badge IDs to candidaturas for quick lookup
                final candidaturasByBadgeId = <int, dynamic>{};
                for (final c in candidaturas) {
                  candidaturasByBadgeId[c['badge_id'] as int] = c;
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
                      padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card de Meta - Design Novo
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1,
                              ),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        const Text(
                                          '5 de 10 Badges',
                                          style: TextStyle(
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
                                        color: const Color(0xFF0052CC)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '50%',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0052CC),
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
                                    value: 0.5,
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
                                            padding:
                                                const EdgeInsets.only(right: 10),
                                            child: _buildBadgeAvatar(b),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

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
                          Row(
                            children: (candidaturas.isEmpty
                                    ? List.filled(2, null)
                                    : candidaturas)
                                .take(2)
                                .map<Widget>(
                                  (c) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: _miniCard(
                                        c,
                                        showProgress: true,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BadgeDetailPage(
                                              badge: c,
                                              candidatura: c,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),

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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => BadgesPage()),
                                ),
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
                            'Badges Recomendados para a tua Área',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: (listaBadges.isEmpty
                                    ? List.filled(2, null)
                                    : listaBadges)
                                .take(2)
                                .map<Widget>(
                                  (b) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: _miniCard(
                                        b,
                                        showProgress: false,
                                        onTap: b != null
                                            ? () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        BadgeDetailPage(
                                                      badge: b,
                                                      candidatura:
                                                          candidaturasByBadgeId[
                                                              b['idbadge']
                                                                  as int],
                                                    ),
                                                  ),
                                                )
                                            : null,
                                      ),
                                    ),
                                  ),
                                )
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
                                      errorBuilder: (context, error, stackTrace) {
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
                                      errorBuilder: (context, error, stackTrace) {
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
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    Icons.emoji_events_outlined,
                    'Catálogo de Badges',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BadgesPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.bar_chart_outlined,
                    'Ranking',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RankingPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.assignment_outlined,
                    'Candidaturas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CandidaturasPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.settings_outlined,
                    'Definições',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OptionsPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.calendar_today_outlined,
                    'Calendário',
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
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AjudaPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.info_outline,
                    'Sobre',
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
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => LoginPage()),
                                  (route) => false,
                                );
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
      tileColor:
          selected ? const Color(0xFF0052CC).withOpacity(0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minLeadingWidth: 0,
      dense: true,
      onTap: onTap,
    );
  }

  Widget _miniCard(dynamic badge, {required bool showProgress, VoidCallback? onTap}) {
    final int atual =
        int.tryParse(badge?['progresso_atual']?.toString() ?? '0') ?? 0;
    final int total =
        int.tryParse(badge?['progresso_total']?.toString() ?? '0') ?? 0;
    final double pct = total > 0 ? (atual / total).clamp(0.0, 1.0) : 0.5;

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
            const SizedBox(height: 6),
            const Text(
              '10 dias restantes',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }
}