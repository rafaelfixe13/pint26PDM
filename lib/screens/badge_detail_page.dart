import 'package:flutter/material.dart';

class BadgeDetailPage extends StatefulWidget {
  final dynamic badge;
  const BadgeDetailPage({required this.badge});

  @override
  State<BadgeDetailPage> createState() => _BadgeDetailPageState();
}

class _BadgeDetailPageState extends State<BadgeDetailPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final int atual = int.tryParse(badge['progresso_atual']?.toString() ?? '0') ?? 0;
    final int total = int.tryParse(badge['progresso_total']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [

                  // Imagem grande
                  badge['imagemurl'] != null
                      ? Image.network(badge['imagemurl'], width: 160, height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.emoji_events, size: 160, color: Color(0xFF2563EB)))
                      : Icon(Icons.emoji_events, size: 160, color: Color(0xFF2563EB)),

                  SizedBox(height: 16),

                  // Nome
                  Text(badge['nome'] ?? '',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB))),

                  SizedBox(height: 4),

                  // Descrição
                  Text(badge['descricao'] ?? '',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center),

                  SizedBox(height: 12),

                  // Nível + Pontos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('Nível: ${badge['nivel'] ?? 'N/A'}',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.star, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('${badge['pontos'] ?? 0} pts',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Link público
                  if (badge['linkpublicobase'] != null)
                    Text(badge['linkpublicobase'],
                        style: TextStyle(fontSize: 12, color: Colors.grey)),

                  SizedBox(height: 16),

                  // Requisitos
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('REQUISITOS',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _icon(Icons.emoji_events, Colors.orange),
                      SizedBox(width: 8),
                      _icon(Icons.star, Colors.red),
                      SizedBox(width: 8),
                      _icon(Icons.description, Colors.blueAccent, selected: true),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Progresso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progresso', style: TextStyle(color: Colors.grey)),
                      Text('$atual/$total', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: total > 0 ? (atual / total).clamp(0.0, 1.0) : 0,
                    backgroundColor: Color(0xFFE5E7EB),
                    color: Color(0xFF2563EB),
                    minHeight: 6,
                  ),

                  SizedBox(height: 24),

                  // Tabs
                  Row(
                    children: [
                      _tabBtn('Descrição do Badge', 0),
                      SizedBox(width: 8),
                      _tabBtn('Competências do Badge', 1),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _tab == 0
                          ? (badge['descricao'] ?? 'Sem descrição.')
                          : (badge['competencias'] ?? 'Sem competências.'),
                      style: TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botão Candidatar-me
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Candidatar-me',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.black54,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _icon(IconData icon, Color color, {bool selected = false}) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: selected ? Color(0xFFEFF6FF) : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: selected ? Border.all(color: Color(0xFF2563EB), width: 2) : null,
      ),
      child: Icon(icon, size: 26, color: selected ? Color(0xFF2563EB) : color),
    );
  }
}
