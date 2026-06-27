import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/lembretes_service.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _todosLembretes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final lista = await LembretesService.listar();
    if (mounted) setState(() { _todosLembretes = lista; _loading = false; });
  }

  /// Devolve os lembretes de um determinado dia.
  List<Map<String, dynamic>> _lembretesNoDia(DateTime dia) {
    return _todosLembretes.where((l) {
      final prazo = DateTime.parse(l['prazo'] as String);
      return prazo.year == dia.year &&
          prazo.month == dia.month &&
          prazo.day == dia.day;
    }).toList();
  }

  /// Devolve os lembretes ativos do mês em foco, ordenados por prazo.
  List<Map<String, dynamic>> _lembretesDoMes() {
    return _todosLembretes.where((l) {
      final prazo = DateTime.parse(l['prazo'] as String);
      return prazo.year == _focusedDay.year &&
          prazo.month == _focusedDay.month &&
          (l['concluido'] == 0);
    }).toList()
      ..sort((a, b) => a['prazo'].compareTo(b['prazo']));
  }

  Color _chipColor(int diff, bool concluido) {
    if (concluido) return Colors.grey;
    if (diff < 0) return Colors.red;
    if (diff == 0) return Colors.orange;
    if (diff <= 7) return Colors.orange;
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final doMes = _lembretesDoMes();
    final doSelecionado = _selectedDay != null ? _lembretesNoDia(_selectedDay!) : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/main'),
        ),
        title: const Text('Calendário',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF2563EB)),
            tooltip: 'Novo lembrete',
            onPressed: () async {
              await context.push('/lembretes');
              _carregar();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                children: [
                  // ── Calendário ──────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    child: TableCalendar<Map<String, dynamic>>(
                      firstDay: DateTime(2024),
                      lastDay: DateTime(2027),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                      eventLoader: _lembretesNoDia,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F)),
                        leftChevronIcon:
                            Icon(Icons.chevron_left, color: Color(0xFF2563EB)),
                        rightChevronIcon:
                            Icon(Icons.chevron_right, color: Color(0xFF2563EB)),
                      ),
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: const TextStyle(
                            color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle:
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        markerDecoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 3,
                        markerSize: 5,
                        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                        outsideDaysVisible: false,
                      ),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      onPageChanged: (focused) {
                        setState(() {
                          _focusedDay = focused;
                          _selectedDay = null;
                        });
                      },
                    ),
                  ),

                  // ── Lembretes do dia selecionado ─────────────────────────
                  if (_selectedDay != null && doSelecionado.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                      child: Text(
                        'Lembretes de ${_selectedDay!.day.toString().padLeft(2, '0')}/${_selectedDay!.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5),
                      ),
                    ),
                    ...doSelecionado.map((l) => _buildCard(l, hoje)),
                  ],

                  // ── Lembretes do mês ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lembretes de ${_nomesMeses[_focusedDay.month - 1]}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.5),
                        ),
                        TextButton(
                          onPressed: () async {
                            await context.push('/lembretes');
                            _carregar();
                          },
                          child: const Text('Ver todos',
                              style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                  ),
                  if (doMes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: const Center(
                          child: Text('Sem lembretes neste mês',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      ),
                    )
                  else
                    ...doMes.map((l) => _buildCard(l, hoje)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> l, DateTime hoje) {
    final prazo = DateTime.parse(l['prazo'] as String);
    final concluido = l['concluido'] == 1;
    final diff = DateTime(prazo.year, prazo.month, prazo.day)
        .difference(DateTime(hoje.year, hoje.month, hoje.day))
        .inDays;
    final color = _chipColor(diff, concluido);
    final label = concluido
        ? 'Concluído'
        : diff < 0
            ? 'Atrasado ${-diff}d'
            : diff == 0
                ? 'Hoje!'
                : 'Em ${diff}d';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                prazo.day.toString(),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l['titulo'] as String? ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: concluido ? Colors.grey : const Color(0xFF1E3A5F),
                    decoration: concluido ? TextDecoration.lineThrough : null,
                  ),
                ),
                if ((l['badge_nome'] as String?)?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(l['badge_nome'] as String,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF2563EB))),
                  ),
                if ((l['descricao'] as String?)?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(l['descricao'] as String,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
  }

  static const _nomesMeses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
}
