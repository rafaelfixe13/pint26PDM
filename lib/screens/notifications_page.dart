import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class NotificationsPage extends StatefulWidget {
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> _notificacoesFuture;
  String _sortBy = 'nao_lido'; // 'nao_lido', 'lido', ou 'recente'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _notificacoesFuture = CacheService.getNotificacoes();
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

  List<dynamic> _sortNotificacoes(List<dynamic> lista) {
    final sorted = List<dynamic>.from(lista);
    
    if (_sortBy == 'nao_lido') {
      sorted.sort((a, b) {
        final aLido = a['lido'] == true;
        final bLido = b['lido'] == true;
        if (aLido == bLido) return 0;
        return aLido ? 1 : -1; // Não lidos 
      });
    } else if (_sortBy == 'lido') {
      sorted.sort((a, b) {
        final aLido = a['lido'] == true;
        final bLido = b['lido'] == true;
        if (aLido == bLido) return 0;
        return aLido ? -1 : 1; // Lidos 
      });
    }
    
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notificações',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            initialValue: _sortBy,
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'nao_lido',
                child: Row(
                  children: [
                    if (_sortBy == 'nao_lido')
                      Icon(Icons.check, size: 18, color: Color(0xFF2563EB))
                    else
                      SizedBox(width: 24),
                    SizedBox(width: 8),
                    Text('Não Lidos'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'lido',
                child: Row(
                  children: [
                    if (_sortBy == 'lido')
                      Icon(Icons.check, size: 18, color: Color(0xFF2563EB))
                    else
                      SizedBox(width: 24),
                    SizedBox(width: 8),
                    Text('Lidos'),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.sort, color: Colors.black87),
          ),
          TextButton(
            onPressed: () async {
              await ApiService.marcarTodasLidas();
              _loadData();
            },
            child: Text(
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
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 400),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 400),
                  Center(child: Text('Erro: ${snapshot.error}')),
                ],
              );
            }

            final lista = snapshot.data ?? [];

            if (lista.isEmpty) {
              return ListView(
                physics: AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 400),
                  Center(child: Text('Sem notificações')),
                ],
              );
            }

            final listaOrdenada = _sortNotificacoes(lista);

            return ListView.separated(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: listaOrdenada.length,
              separatorBuilder: (_, __) => Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final n = listaOrdenada[index];
                final bool lida = n['lido'] == true;
                final int id = n['idnotificacao'];

                return Container(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    color: Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        SizedBox(width: 12),

                        // Conteúdo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n['mensagem'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    lida ? 'Lida' : 'Não Lida',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: lida ? Colors.grey : Color(0xFF2563EB),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    ' · ${_tempoRelativo(n['dataenvio']?.toString())}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  Spacer(),

                                  // Botão marcar lida
                                  if (!lida)
                                    GestureDetector(
                                      onTap: () async {
                                        await ApiService.marcarLida(id);
                                        _loadData();
                                      },
                                      child: Icon(Icons.check,
                                          size: 18, color: Colors.grey),
                                    ),

                                  SizedBox(width: 12),

                                  // Botão apagar
                                  GestureDetector(
                                    onTap: () async {
                                      await ApiService.apagarNotificacao(id);
                                      _loadData();
                                    },
                                    child: Icon(Icons.delete_outline,
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
        return Icon(Icons.email_outlined, color: Colors.white);
      case 'PUSH':
        return Icon(Icons.notifications_outlined, color: Colors.white);
      default:
        return Icon(Icons.info_outline, color: Colors.white);
    }
  }
}
