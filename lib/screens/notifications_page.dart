import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> _notificacoesFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _notificacoesFuture = ApiService.getNotificacoes();
    });
  }

  String _tempoRelativo(String? dataStr) {
    if (dataStr == null) return '';
    try {
      final data = DateTime.parse(dataStr);
      final diff = DateTime.now().difference(data);
      if (diff.inMinutes < 60) return 'Enviada há ${diff.inMinutes} minutos';
      if (diff.inHours < 24) return 'Enviada há ${diff.inHours} horas';
      return 'Enviada há ${diff.inDays} dias';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notificações',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () async {
              await ApiService.marcarTodasLidas();
              _loadData();
            },
            child: const Text(
              'Marcar todas',
              style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          await _notificacoesFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: _notificacoesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 400),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 400),
                  Center(child: Text('Erro: ${snapshot.error}')),
                ],
              );
            }

            final lista = snapshot.data ?? [];

            if (lista.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 400),
                  Center(child: Text('Sem notificações')),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final n = lista[index];
                final bool lida = n['lido'] == true;
                final int id = n['idnotificacao'];

                return Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Avatar com ponto azul se não lida
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade300,
                              child: _avatarIcon(n['tipo']),
                            ),
                            if (!lida)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(width: 12),

                        // Conteúdo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n['mensagem'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    lida ? 'Lida' : 'Não Lida',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: lida ? Colors.grey : const Color(0xFF2563EB),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ' · ${_tempoRelativo(n['dataenvio']?.toString())}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  const Spacer(),

                                  // Botão marcar lida
                                  if (!lida)
                                    GestureDetector(
                                      onTap: () async {
                                        await ApiService.marcarLida(id);
                                        _loadData();
                                      },
                                      child: const Icon(Icons.check,
                                          size: 18, color: Colors.grey),
                                    ),

                                  const SizedBox(width: 12),

                                  // Botão apagar
                                  GestureDetector(
                                    onTap: () async {
                                      await ApiService.apagarNotificacao(id);
                                      _loadData();
                                    },
                                    child: const Icon(Icons.delete_outline,
                                        size: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _avatarIcon(String? tipo) {
    switch (tipo) {
      case 'EMAIL':
        return const Icon(Icons.email_outlined, color: Colors.white);
      case 'PUSH':
        return const Icon(Icons.notifications_outlined, color: Colors.white);
      default:
        return const Icon(Icons.info_outline, color: Colors.white);
    }
  }
}
