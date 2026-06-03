import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// ─── Content model ───────────────────────────────────────────────────────────

abstract class AjudaContent {}

class TextContent extends AjudaContent {
  final String text;
  TextContent(this.text);
}

class StepsContent extends AjudaContent {
  final List<String> steps;
  StepsContent(this.steps);
}

class BulletContent extends AjudaContent {
  final List<String> items;
  BulletContent(this.items);
}

class NoteContent extends AjudaContent {
  final String note;
  NoteContent(this.note);
}

class AjudaItem {
  final IconData icon;
  final String title;
  final List<AjudaContent> content;

  const AjudaItem({
    required this.icon,
    required this.title,
    required this.content,
  });
}

// ─── Data ─────────────────────────────────────────────────────────────────────

final List<AjudaItem> ajudaItems = [
  AjudaItem(
    icon: Icons.diamond_outlined,
    title: 'Sistema de Badges',
    content: [
      TextContent(
        'Os badges são certificações digitais que reconhecem competências e conquistas profissionais. '
        'Cada badge é validado por um Talent Manager e fica visível no teu perfil.',
      ),
      BulletContent([
        'Badges de Competência — validam skills técnicas ou comportamentais',
        'Badges de Projeto — reconhecem contribuições em projetos específicos',
        'Badges de Formação — certificam conclusão de cursos internos',
      ]),
    ],
  ),
  AjudaItem(
    icon: Icons.description_outlined,
    title: 'Como pedir um Badge',
    content: [
      StepsContent([
        'Acede ao Catálogo de Badges',
        'Seleciona o badge pretendido',
        'Consulta os requisitos e critérios',
        'Submete o pedido com evidências',
        'Aguarda validação do Talent Manager',
      ]),
      NoteContent('Pedidos incompletos podem ser devolvidos.'),
    ],
  ),
  AjudaItem(
    icon: Icons.check_circle_outline,
    title: 'Evidências aceites',
    content: [
      TextContent('São aceites os seguintes tipos de evidências:'),
      BulletContent([
        'Certificados digitais ou físicos digitalizados',
        'Capturas de ecrã de projetos ou entregas',
        'Links para repositórios ou portfólios públicos',
        'Relatórios de desempenho emitidos pela empresa',
        'Avaliações de chefias ou pares (peer review)',
      ]),
      NoteContent(
          'As evidências devem ser legíveis e estar em português ou inglês.'),
    ],
  ),
  AjudaItem(
    icon: Icons.cancel_outlined,
    title: 'Pedido devolvido ou rejeitado',
    content: [
      TextContent('O teu pedido pode ter dois resultados negativos:'),
      BulletContent([
        'Devolvido — faltam evidências; podes corrigir e resubmeter',
        'Rejeitado — critérios não cumpridos; podes recandidatar-te em 90 dias',
      ]),
      TextContent(
          'Em ambos os casos receberás uma notificação com o motivo detalhado.'),
      NoteContent(
          'Contacta o teu Talent Manager se tiveres dúvidas sobre a decisão.'),
    ],
  ),
  AjudaItem(
    icon: Icons.schedule_outlined,
    title: 'SLA — Tempo de Resposta',
    content: [
      BulletContent([
        'Avaliação inicial: até 2 dias úteis',
        'Validação completa: 3 a 5 dias úteis',
        'Períodos de alta demanda: até 10 dias úteis',
      ]),
      NoteContent(
          'Os prazos contam a partir da submissão com todas as evidências completas.'),
    ],
  ),
  AjudaItem(
    icon: Icons.notifications_outlined,
    title: 'Notificações',
    content: [
      TextContent('Recebes notificações automáticas nos seguintes momentos:'),
      BulletContent([
        'Pedido recebido e em avaliação',
        'Pedido devolvido para correção',
        'Badge aprovado e atribuído',
        'Novo badge disponível no catálogo',
      ]),
      TextContent(
          'Gere as tuas preferências em Definições → Notificações.'),
    ],
  ),
  AjudaItem(
    icon: Icons.ios_share_outlined,
    title: 'Partilha de Badges',
    content: [
      StepsContent([
        'Acede ao teu perfil',
        'Seleciona o badge que queres partilhar',
        'Toca em "Partilhar"',
        'Escolhe a plataforma (LinkedIn, email, etc.)',
      ]),
      NoteContent(
          'O link de partilha é público e verificável por qualquer pessoa.'),
    ],
  ),
  AjudaItem(
    icon: Icons.trending_up_outlined,
    title: 'Acompanhamento',
    content: [
      TextContent('Na secção "O Meu Percurso" podes acompanhar:'),
      BulletContent([
        'Estado de todos os pedidos submetidos',
        'Histórico de badges conquistados',
        'Progresso em direção a novos badges',
        'Feedback dos Talent Managers',
      ]),
    ],
  ),
  AjudaItem(
    icon: Icons.help_outline,
    title: 'Precisa de mais ajuda?',
    content: [
      TextContent(
          'Se não encontraste a resposta que procuras, estamos aqui para ajudar:'),
      BulletContent([
        'Email: suporte@badges.pt',
        'Chat na app: dias úteis, 9h–18h',
        'FAQ completo em badges.pt/ajuda',
      ]),
      NoteContent('O tempo médio de resposta por email é de 1 dia útil.'),
    ],
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class AjudaPage extends StatefulWidget {
  const AjudaPage({super.key});
  @override
  State<AjudaPage> createState() => _AjudaPageState();
}

class _AjudaPageState extends State<AjudaPage> {
  static const Color _primaryBlue = Color(0xFF1A3C8F);
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.go('/main'),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.black87, size: 24),
                    ),
                  ),
                  const Text(
                    'Ajuda',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── List ──
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: ajudaItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _AjudaTile(
                    item: ajudaItems[index],
                    isExpanded: _expanded.contains(index),
                    primaryBlue: _primaryBlue,
                    onTap: () => setState(() {
                      _expanded.contains(index)
                          ? _expanded.remove(index)
                          : _expanded.add(index);
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _AjudaTile extends StatelessWidget {
  final AjudaItem item;
  final bool isExpanded;
  final Color primaryBlue;
  final VoidCallback onTap;

  const _AjudaTile({
    required this.item,
    required this.isExpanded,
    required this.primaryBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row header ──
                  Row(
                    children: [
                      Icon(item.icon, color: primaryBlue, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(Icons.keyboard_arrow_down,
                            color: primaryBlue, size: 22),
                      ),
                    ],
                  ),

                  // ── Expandable body ──
                  AnimatedCrossFade(
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.content
                            .map((c) => _buildContent(c))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AjudaContent content) {
    // ── Plain text ──
    if (content is TextContent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          content.text,
          style: const TextStyle(
            fontSize: 13.5,
            color: Colors.black54,
            height: 1.55,
          ),
        ),
      );
    }

    // ── Numbered steps ──
    if (content is StepsContent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content.steps.asMap().entries.map((entry) {
            final num = entry.key + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$num',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    // ── Bullet list ──
    if (content is BulletContent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content.items.map((text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    // ── Warning note ──
    if (content is NoteContent) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Color(0xFFFFC107), width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                content.note,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A5800),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}