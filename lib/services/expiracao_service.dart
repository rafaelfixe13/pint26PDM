import 'package:flutter/material.dart';

class BadgeExpiracao {
  final String nome;
  final DateTime dataExpiracao;
  final int diasRestantes;

  const BadgeExpiracao({
    required this.nome,
    required this.dataExpiracao,
    required this.diasRestantes,
  });

  bool get expirado => diasRestantes < 0;
  bool get critico => !expirado && diasRestantes <= 7;
  bool get aviso => !expirado && diasRestantes > 7 && diasRestantes <= 30;

  Color get cor {
    if (expirado) return const Color(0xFFEF4444);
    if (critico) return const Color(0xFFF97316);
    if (aviso) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String get etiqueta {
    if (expirado) return 'Expirado há ${-diasRestantes}d';
    if (diasRestantes == 0) return 'Expira hoje!';
    return 'Expira em ${diasRestantes}d';
  }
}

class ExpiracaoService {
  // Calcula badges aprovados que expiram (ou já expiraram) a partir dos dados de candidaturas.
  // Só considera badges com expiremeses > 0.
  static List<BadgeExpiracao> calcular(List<dynamic> candidaturas) {
    final resultado = <BadgeExpiracao>[];
    final hoje = DateTime.now();

    for (final c in candidaturas) {
      if (c['estado'] != 'SUBMITTED') continue;

      final meses = int.tryParse(c['expiremeses']?.toString() ?? '0') ?? 0;
      if (meses <= 0) continue;

      final raw = c['datasubmissao']?.toString() ?? '';
      if (raw.isEmpty) continue;
      final dataSubmissao = DateTime.tryParse(raw);
      if (dataSubmissao == null) continue;

      // Adicionar meses à data de submissão
      int ano = dataSubmissao.year;
      int mes = dataSubmissao.month + meses;
      while (mes > 12) { mes -= 12; ano++; }
      final dia = dataSubmissao.day.clamp(1, _diasNoMes(ano, mes));
      final dataExpiracao = DateTime(ano, mes, dia);

      final diasRestantes = dataExpiracao.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;

      // Alerta apenas se expirar nos próximos 60 dias ou já expirou
      if (diasRestantes <= 60) {
        resultado.add(BadgeExpiracao(
          nome: c['nome']?.toString() ?? 'Badge',
          dataExpiracao: dataExpiracao,
          diasRestantes: diasRestantes,
        ));
      }
    }

    resultado.sort((a, b) => a.diasRestantes.compareTo(b.diasRestantes));
    return resultado;
  }

  static int _diasNoMes(int ano, int mes) {
    return DateUtils.getDaysInMonth(ano, mes);
  }
}
