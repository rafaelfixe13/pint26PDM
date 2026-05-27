import 'package:flutter/material.dart';
import './help_page.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import '../base64_image_widget.dart';
import '../widgets/badge_progress.dart';
import './badges_page.dart';
import './badge_detail_page.dart';
import './profile_page.dart';
import './notifications_page.dart';
import './login_page.dart';
import './ranking_page.dart';
import './options_page.dart';
import './change_password.dart';
import './candidaturas.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

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
    _badgesFuture = ApiService.getBadges();
    _candidaturasFuture = ApiService.getCandidaturas();
    _notificacoesFuture = ApiService.getNotificacoes();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fotoUrl = Session.fotoUrl.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: '...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
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
                        color: Colors.black87,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsPage(),
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
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$naoLidas',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
                  final badgeId = int.tryParse(c?['idbadge']?.toString() ?? '') ??
                      (c?['id'] is int ? c['id'] as int : 0);
                  if (badgeId > 0) candidaturasByBadgeId[badgeId] = c;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meta Definida',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Conseguiste alcançar 5 badges nos últimos 4 meses!',
                              style: TextStyle(fontSize: 13),
                            ),
                            const Text(
                              'Faltam 5 badges para alcançar a meta definida',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Badges conquistados',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
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
                                            const EdgeInsets.only(right: 8),
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundColor:
                                              Colors.blue.shade100,
                                          child: b != null && b['imagemurl'] != null
                                              ? ClipOval(
                                                  child: Base64ImageWidget(
                                                    imageData: b['imagemurl'].toString()
                                                        .replaceAll('localhost', '10.0.2.2')
                                                        .replaceAll('127.0.0.1', '10.0.2.2')
                                                        .replaceAll('100.105.58.22', '10.0.2.2')
                                                        .replaceAll('0.0.0.0', '10.0.2.2'),
                                                    width: 44,
                                                    height: 44,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.emoji_events,
                                                  size: 22,
                                                  color: Colors.blue,
                                                ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Candidaturas Submetidas',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                const SizedBox(height: 12),
                      Row(
                        children: (candidaturas.isEmpty
                                ? List.filled(2, null)
                                : candidaturas)
                            .take(2)
                            .map<Widget>(
                              (c) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
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

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Badges Recomendados',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BadgesPage()),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              size: 18,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: (listaBadges.isEmpty
                                ? List.filled(2, null)
                                : listaBadges)
                            .take(2)
                            .map<Widget>((b) {
                              if (b == null) {
                                return const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: SizedBox.shrink(),
                                  ),
                                );
                              }

                              final badgeId = int.tryParse(b['idbadge']?.toString() ?? '') ??
                                  (b['id'] is int ? b['id'] as int : 0);

                              final candidatura = candidaturasByBadgeId[badgeId];

                              // If there's a candidatura for this badge, merge its progress
                              // into the badge object so _miniCard can read progresso_atual/total.
                              dynamic renderedBadge = b;
                              if (candidatura != null) {
                                try {
                                  renderedBadge = Map<String, dynamic>.from(b as Map)
                                    ..['progresso_atual'] = candidatura['progresso_atual']
                                    ..['progresso_total'] = candidatura['progresso_total'];
                                } catch (_) {
                                  renderedBadge = b;
                                }
                              }

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _miniCard(
                                    renderedBadge,
                                    showProgress: candidatura != null,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BadgeDetailPage(
                                          badge: b,
                                          candidatura: candidatura,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );

                if (resultado == true || mounted) {
                  setState(() {});
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.purple.shade100,
                      child: ClipOval(
                        child: Session.utilizador['foto_base64'] != null &&
                                Session.utilizador['foto_base64'].toString().isNotEmpty
                            ? Base64ImageWidget(
                                imageData:
                                    Session.utilizador['foto_base64'].toString(),
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              )
                            : (fotoUrl.isNotEmpty
                                ? (Base64ImageWidget.isBase64(fotoUrl)
                                    ? Base64ImageWidget(
                                        imageData: fotoUrl,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        fotoUrl,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.person,
                                          color: Colors.purple,
                                          size: 30,
                                        ),
                                      ))
                                : const Icon(
                                    Icons.person,
                                    color: Colors.purple,
                                    size: 30,
                                  )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Session.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Talent Management',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            _drawerItem(
              Icons.home,
              'Home',
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
                  MaterialPageRoute(builder: (_) => const BadgesPage()),
                );
              },
            ),

            _drawerItem(
              Icons.bar_chart,
              'Rankings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RankingPage()),
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
                  MaterialPageRoute(builder: (_) => const CandidaturasPage()),
                );
              },
            ),

            _drawerItem(
              Icons.settings_outlined,
              'Configurações',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OptionsPage()),
                );
              },
            ),

            _drawerItem(Icons.calendar_today_outlined, 'Calendário'),

            _drawerItem(
              Icons.logout,
              'Terminar Sessão',
              onTap: () {
                Session.terminar();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),

            const Spacer(),
            const Divider(),
            _drawerItem(Icons.info_outline, 'Sobre'),
            _drawerItem(Icons.help_outline, 'Ajuda', onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AjudaPage()),
              );
            }),

            _drawerItem(
              Icons.lock_outline,
              'Change Password',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                );
              },
            ),

            const SizedBox(height: 8),
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
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Colors.white : Colors.grey[700],
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.grey[800],
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: selected ? const Color(0xFF2563EB) : null,
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _miniCard(dynamic badge, {required bool showProgress, VoidCallback? onTap}) {
    final int atual =
        int.tryParse(badge?['progresso_atual']?.toString() ?? '0') ?? 0;
    final int total =
        int.tryParse(badge?['progresso_total']?.toString() ?? '0') ?? 0;
    // progress percentage not used here; remove unused local

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          badge == null || badge['imagemurl'] == null
              ? const Icon(Icons.emoji_events, size: 50, color: Colors.grey)
              : (Base64ImageWidget.isBase64(badge['imagemurl'].toString())
                  ? Base64ImageWidget(
                      imageData: badge['imagemurl'].toString(),
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      badge['imagemurl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.emoji_events,
                        size: 50,
                        color: Colors.grey,
                      ),
                    )),
          const SizedBox(height: 6),
          Text(
            badge?['nome'] ?? 'Badge',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          // Always show a compact progress indicator (number of requirements completed)
          BadgeProgress(atual: atual, total: total, compact: true),
          const SizedBox(height: 6),
        ],
      ),
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }
}