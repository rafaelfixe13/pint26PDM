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
import './change_password.dart';
import './candidaturas.dart';

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
                  candidaturasByBadgeId[c['badge_id'] as int] = c;
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                  'Bom Dia!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
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
                                  padding: const EdgeInsets.only(right: 8),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.blue.shade100,
                                    backgroundImage:
                                        b != null && b['imagemurl'] != null
                                            ? NetworkImage(b['imagemurl'])
                                            : null,
                                    child: b == null || b['imagemurl'] == null
                                        ? const Icon(
                                            Icons.emoji_events,
                                            size: 22,
                                            color: Colors.blue,
                                          )
                                        : null,
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: (candidaturas.isEmpty ? List.filled(2, null) : candidaturas)
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BadgesPage()),
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
                  children: (listaBadges.isEmpty ? List.filled(2, null) : listaBadges)
                      .take(2)
                      .map<Widget>(
                        (b) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _miniCard(
                              b,
                              showProgress: false,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BadgeDetailPage(
                                    badge: b,
                                    candidatura: candidaturasByBadgeId[b['idbadge'] as int],
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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
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
                        child: fotoUrl.isNotEmpty
                            ? Image.network(
                                fotoUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.purple,
                                  size: 30,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.purple,
                                size: 30,
                              ),
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
                  MaterialPageRoute(builder: (_) => BadgesPage()),
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
                  MaterialPageRoute(builder: (_) => LoginPage()),
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
                MaterialPageRoute(builder: (_) => AjudaPage()),
              );
            }),

            _drawerItem(
              Icons.lock_outline,
              'Change Password',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChangePasswordPage()),
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
    final double pct = total > 0 ? (atual / total).clamp(0.0, 1.0) : 0.5;

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
                ),
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
          if (showProgress) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progresso',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFFE5E7EB),
              color: const Color(0xFF2563EB),
              minHeight: 4,
            ),
            const SizedBox(height: 6),
            const Text(
              '10 dias restantes',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }
}