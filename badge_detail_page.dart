import 'package:flutter/material.dart';
import 'package:pinttest/screens/candidatura_page.dart';

class BadgeDetailPage extends StatefulWidget {
  final dynamic badge;

  const BadgeDetailPage({super.key, required this.badge});

  @override
  State<BadgeDetailPage> createState() => _BadgeDetailPageState();
}

class _BadgeDetailPageState extends State<BadgeDetailPage> {
  int _tab = 0;

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
    }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;

    final int atual = _toInt(badge['progresso_atual']);
    final int total = _toInt(badge['progresso_total']);

    final String estadoVisual =
        (badge['estado_visual']?.toString().trim().isNotEmpty ?? false)
            ? badge['estado_visual'].toString()
            : '$atual/$total';

    final bool submetido = estadoVisual.toLowerCase() == 'submetido';

    final double progresso =
        total > 0 ? (atual / total).clamp(0.0, 1.0).toDouble() : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  badge['imagemurl'] != null &&
                          badge['imagemurl'].toString().isNotEmpty
                      ? Image.network(
                          badge['imagemurl'],
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.emoji_events,
                            size: 160,
                            color: Color(0xFF2563EB),
                          ),
                        )
                      : const Icon(
                          Icons.emoji_events,
                          size: 160,
                          color: Color(0xFF2563EB),
                        ),
                  const SizedBox(height: 16),
                  Text(
                    badge['nome']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge['descricao']?.toString() ?? '',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Nível: ${badge['nivel'] ?? 'N/A'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${badge['pontos'] ?? 0} pts',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (badge['linkpublicobase'] != null &&
                      badge['linkpublicobase'].toString().isNotEmpty)
                    Text(
                      badge['linkpublicobase'].toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'REQUISITOS',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _icon(Icons.emoji_events, Colors.orange),
                      const SizedBox(width: 8),
                      _icon(Icons.star, Colors.red),
                      const SizedBox(width: 8),
                      _icon(Icons.description, Colors.blueAccent, selected: true),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: submetido
                          ? Colors.green.withOpacity(0.10)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: submetido
                            ? Colors.green.withOpacity(0.25)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progresso',
                          style: TextStyle(
                            color: submetido
                                ? Colors.green.shade800
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          estadoVisual,
                          style: TextStyle(
                            color: submetido
                                ? Colors.green.shade700
                                : const Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progresso,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: submetido
                          ? Colors.green
                          : const Color(0xFF2563EB),
                      minHeight: 8,
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _tabBtn('Descrição do Badge', 0),
                      const SizedBox(width: 8),
                      _tabBtn('Competências do Badge', 1),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _tab == 0
                          ? (badge['descricao']?.toString() ?? 'Sem descrição.')
                          : (badge['competencias']?.toString() ?? 'Sem competências.'),
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submetido
                    ? null
                    : () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CandidaturaPage(badge: badge),
                          ),
                        );

                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: submetido
                      ? Colors.grey.shade400
                      : const Color(0xFF2563EB),
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  submetido ? 'Submetido' : 'Candidatar-me',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? null : Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontSize: 12,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _icon(IconData icon, Color color, {bool selected = false}) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: selected
            ? Border.all(color: const Color(0xFF2563EB), width: 2)
            : null,
      ),
      child: Icon(
        icon,
        size: 26,
        color: selected ? const Color(0xFF2563EB) : color,
      ),
    );
  }
}