import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/lembretes_service.dart';

class LembretesPage extends StatefulWidget {
  const LembretesPage({super.key});

  @override
  State<LembretesPage> createState() => _LembretesPageState();
}

class _LembretesPageState extends State<LembretesPage> {
  List<Map<String, dynamic>> _lembretes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await LembretesService.listar();
    if (mounted) setState(() { _lembretes = lista; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final ativos = _lembretes.where((l) => l['concluido'] == 0).toList();
    final concluidos = _lembretes.where((l) => l['concluido'] == 1).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>  context.go('/main'),
        ),
        title: const Text('Lembretes',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _mostrarDialogAdicionar(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lembretes.isEmpty
              ? _buildVazio()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      if (ativos.isNotEmpty) ...[
                        _secTitle('Ativos (${ativos.length})'),
                        const SizedBox(height: 8),
                        ...ativos.map((l) => _buildCard(l)),
                      ],
                      if (concluidos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _secTitle('Concluídos (${concluidos.length})'),
                        const SizedBox(height: 8),
                        ...concluidos.map((l) => _buildCard(l)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Sem lembretes definidos',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Toca no + para criar um',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _secTitle(String label) => Text(label,
      style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.bold,
          color: Colors.grey, letterSpacing: 0.8));

  Widget _buildCard(Map<String, dynamic> l) {
    final prazo = DateTime.parse(l['prazo'] as String);
    final concluido = l['concluido'] == 1;
    final now = DateTime.now();
    final diff = DateTime(prazo.year, prazo.month, prazo.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    Color chipColor;
    String chipLabel;
    if (concluido) {
      chipColor = Colors.grey;
      chipLabel = 'Concluído';
    } else if (diff < 0) {
      chipColor = Colors.red;
      chipLabel = 'Atrasado ${-diff}d';
    } else if (diff == 0) {
      chipColor = Colors.orange;
      chipLabel = 'Hoje!';
    } else if (diff <= 7) {
      chipColor = Colors.orange;
      chipLabel = 'Em ${diff}d';
    } else {
      chipColor = const Color(0xFF2563EB);
      chipLabel = 'Em ${diff}d';
    }

    return Dismissible(
      key: Key('lem_${l['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        await LembretesService.eliminar(l['id'] as int);
        _carregar();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
          border: concluido
              ? null
              : Border.all(color: chipColor.withOpacity(0.25), width: 1),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: chipColor.withOpacity(0.12),
            child: Icon(
              concluido ? Icons.check_circle : Icons.notifications_active,
              color: chipColor, size: 22,
            ),
          ),
          title: Text(
            l['titulo'] as String? ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              decoration: concluido ? TextDecoration.lineThrough : null,
              color: concluido ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((l['badge_nome'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.emoji_events, size: 11, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(l['badge_nome'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                ]),
              ],
              if ((l['descricao'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Text(l['descricao'] as String,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today, size: 11, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${prazo.day.toString().padLeft(2, '0')}/${prazo.month.toString().padLeft(2, '0')}/${prazo.year}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ]),
            ],
          ),
          trailing: concluido
              ? null
              : Chip(
                  label: Text(chipLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 10)),
                  backgroundColor: chipColor,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
          onTap: concluido ? null : () => _mostrarOpcoes(l),
        ),
      ),
    );
  }

  void _mostrarOpcoes(Map<String, dynamic> l) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: const Text('Marcar como concluído'),
              onTap: () async {
                Navigator.pop(ctx);
                await LembretesService.concluir(l['id'] as int);
                _carregar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar lembrete'),
              onTap: () async {
                Navigator.pop(ctx);
                await LembretesService.eliminar(l['id'] as int);
                _carregar();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogAdicionar({int? badgeId, String? badgeNome}) async {
    final tituloCtrl = TextEditingController(
        text: badgeNome != null ? 'Completar badge: $badgeNome' : '');
    final descCtrl = TextEditingController();
    DateTime? prazo;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Novo Lembrete',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Título *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Nota / Objetivo (opcional)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                      helpText: 'Seleciona o prazo',
                    );
                    if (picked != null) setD(() => prazo = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18,
                            color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Text(
                          prazo == null
                              ? 'Selecionar prazo *'
                              : '${prazo!.day.toString().padLeft(2, '0')}/${prazo!.month.toString().padLeft(2, '0')}/${prazo!.year}',
                          style: TextStyle(
                              color: prazo == null ? Colors.grey.shade500 : Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB)),
              onPressed: () async {
                if (tituloCtrl.text.trim().isEmpty || prazo == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preenche o título e o prazo')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                await LembretesService.criar(
                  titulo: tituloCtrl.text.trim(),
                  descricao: descCtrl.text.trim(),
                  prazo: prazo!,
                  badgeId: badgeId,
                  badgeNome: badgeNome,
                );
                _carregar();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lembrete criado! Notificação agendada.'),
                      backgroundColor: Color(0xFF2563EB),
                    ),
                  );
                }
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
