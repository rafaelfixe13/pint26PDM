import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/expiracao_service.dart';
import '../services/lembretes_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/base64_image_widget.dart';
import '../widgets/base64_pdf_widget.dart';
import 'package:go_router/go_router.dart';
import '../services/session.dart';

String? extractBase64Pdf(String? s) {
  if (s == null) return null;
  String t = s.trim();
  if (t.isEmpty) return null;

  t = t.replaceAll('https://data:application/pdf;base64,', '');
  t = t.replaceAll('http://data:application/pdf;base64,', '');
  t = t.replaceAll('data:application/pdf;base64,', '');
  t = t.trim();
  t = t.replaceAll(RegExp(r'^https?://'), '');
  t = t.trim();

  if (t.startsWith('data:')) {
    final idx = t.indexOf(',');
    if (idx >= 0 && idx + 1 < t.length) {
      t = t.substring(idx + 1).trim();
    }
  }

  final cleaned = t.replaceAll(RegExp(r'\s+'), '');
  if (cleaned.startsWith('JVBERi')) return cleaned;
  if (cleaned.length > 200 && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(cleaned)) return cleaned;
  return null;
}

class BadgeDetailPage extends StatefulWidget {
  final dynamic badge;
  final dynamic candidatura;
  final int? badgeId;

  const BadgeDetailPage({
    this.badge,
    this.candidatura,
    this.badgeId,
  });

  @override
  State<BadgeDetailPage> createState() => _BadgeDetailPageState();
}

class _BadgeDetailPageState extends State<BadgeDetailPage> {
  int _tab = 0;
  dynamic _badge;
  bool _loading = false;
  String? _erro;
  final ScrollController _scrollController = ScrollController();
  String? _selectedPdfData;
  String? _selectedPdfTitle;

  @override
  void initState() {
    super.initState();
    if (widget.badge != null) {
      _badge = widget.badge;
    } else if (widget.badgeId != null) {
      _carregarBadge();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarBadge() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final data = await ApiService.getBadgeById(widget.badgeId!);
      setState(() { _badge = data; });
    } catch (e) {
      setState(() { _erro = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_erro != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text(_erro!, style: const TextStyle(color: Colors.red))),
      );
    }
    if (_badge == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final badge = _badge;
    final int atual = int.tryParse(badge['progresso_atual']?.toString() ?? '0') ?? 0;
    final int total = int.tryParse(badge['progresso_total']?.toString() ?? '0') ?? 0;
    final candidatura = widget.candidatura;
    final isApproved = candidatura != null && candidatura['estado'] == 'APPROVED';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/badges'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.black),
            onPressed: _definirLembrete,
            tooltip: 'Definir lembrete',
          ),
          IconButton(
            icon: Icon(Icons.link, color: Colors.black),
            onPressed: _copiarLinkBadge,
            tooltip: 'Copiar link do badge',
          ),
          if (isApproved) ...[
            IconButton(
              icon: const Icon(Icons.business, color: Color(0xFF0A66C2)),
              tooltip: 'Partilhar no LinkedIn',
              onPressed: _shareBadgeImageLinkedIn,
            ),
            IconButton(
              icon: Icon(Icons.share, color: Colors.black),
              tooltip: 'Partilhar Certificado',
              onPressed: _partilharCertificado,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  badge['imagemurl'] != null
                      ? Base64ImageWidget(
                          imageData: badge['imagemurl']
                              .toString()
                              .replaceAll('localhost', '10.0.2.2')
                              .replaceAll('127.0.0.1', '10.0.2.2')
                              .replaceAll('100.105.58.22', '10.0.2.2')
                              .replaceAll('0.0.0.0', '10.0.2.2'),
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                          errorWidget: Icon(Icons.emoji_events, size: 160, color: Color(0xFF2563EB)),
                        )
                      : Icon(Icons.emoji_events, size: 160, color: Color(0xFF2563EB)),

                  SizedBox(height: 16),

                  Text(badge['nome'] ?? '',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),

                  SizedBox(height: 4),

                  Text(badge['descricao'] ?? '',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center),

                  SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.black, borderRadius: BorderRadius.circular(999)),
                        child: Text('Nível: ${badge['idnivel'] ?? 'N/A'}',
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

                  GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse('https://www.softinsa.pt'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.language, size: 14, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text(
                          'softinsa.pt',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_selectedPdfData != null) ...[
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Pré-visualização do Requisito',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(_selectedPdfTitle ?? '',
                                      style: TextStyle(fontWeight: FontWeight.bold))),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () => setState(
                                    () { _selectedPdfData = null; _selectedPdfTitle = null; }),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Base64PdfWidget(
                            pdfData: _selectedPdfData ?? '',
                            fileName: '${_selectedPdfTitle ?? 'requisito'}.pdf',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                  ],

                  SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('REQUISITOS', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  SizedBox(height: 8),
                  FutureBuilder<List<dynamic>>(
                    future: CacheService.getRequisitosBadge(badge['idbadge'] as int),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: 70,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                            ),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return SizedBox(
                          height: 70,
                          child: Center(
                            child: Text('Erro ao carregar requisitos',
                                style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        );
                      }

                      final requisitos = snapshot.data ?? [];

                      if (requisitos.isEmpty) {
                        return SizedBox(
                          height: 70,
                          child: Center(
                            child: Text('Sem requisitos',
                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: requisitos.map((req) {
                          final raw = req['imagemurl']?.toString();
                          final imageUrl = raw == null || raw.trim().isEmpty
                              ? null
                              : raw
                                  .replaceAll('localhost', '10.0.2.2')
                                  .replaceAll('127.0.0.1', '10.0.2.2')
                                  .replaceAll('100.105.58.22', '10.0.2.2')
                                  .replaceAll('0.0.0.0', '10.0.2.2')
                                  .trim();

                          final codigo = req['codigo'] as String? ?? 'REQ';
                          final nome = (req['titulo'] ?? req['nome'])?.toString() ?? 'Requisito';

                          return GestureDetector(
                            onTap: () {
                              try {
                                if (imageUrl == null) {
                                  _mostrarImagemDialog(context, '', nome);
                                  return;
                                }

                                final base64 = extractBase64Pdf(imageUrl);
                                if (base64 != null) {
                                  try {
                                    Base64PdfWidget.decodeBase64(base64);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('PDF inválido: $e'),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                    _mostrarImagemDialog(context, imageUrl, nome);
                                    return;
                                  }

                                  setState(() {
                                    _selectedPdfData = base64;
                                    _selectedPdfTitle = nome;
                                  });

                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (_scrollController.hasClients) {
                                      try {
                                        _scrollController.animateTo(
                                          _scrollController.position.maxScrollExtent,
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      } catch (e) {}
                                    }
                                  });
                                  return;
                                }

                                _mostrarImagemDialog(context, imageUrl, nome);
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Ocorreu um erro ao abrir o ficheiro'),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: Tooltip(
                              message: nome,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: imageUrl != null ? Color(0xFF2563EB) : Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: imageUrl != null
                                      ? null
                                      : Border.all(color: Color(0xFF2563EB), width: 1),
                                ),
                                child: Text(
                                  codigo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: imageUrl != null ? Colors.white : Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  SizedBox(height: 16),

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

          Padding(
            padding: EdgeInsets.all(16),
            child: widget.candidatura != null
                ? _buildCandidaturaStatus()
                : _buildCandidatarButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidaturaStatus() {
    final candidatura = widget.candidatura;
    final badge = _badge ?? widget.badge;
    final expList = ExpiracaoService.calcular([badge]);
    final BadgeExpiracao? expiracao = expList.isEmpty ? null : expList.first;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF2563EB), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Candidatura Submetida',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              SizedBox(height: 8),
              Text('Estado: ${candidatura['estado']}', style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text(
                  'Progresso: ${candidatura['progresso_atual']}/${candidatura['progresso_total']}',
                  style: TextStyle(fontSize: 12)),
              if (candidatura['datasubmissao'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Submetido em: ${candidatura['datasubmissao'].toString().split('T').first}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              if (expiracao != null) ...[
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      expiracao.expirado ? Icons.error_outline : Icons.access_time_outlined,
                      size: 14,
                      color: expiracao.cor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      expiracao.expirado
                          ? 'Expira em: Expirado'
                          : 'Expira em: ${expiracao.diasRestantes}d',
                      style: TextStyle(
                          fontSize: 12, color: expiracao.cor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 12),
        if (candidatura['estado'] == 'APPROVED')
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _guardarCertificado,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.download, color: Colors.white),
              label: Text('Guardar Certificado',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _mostrarDialogCandidatura(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Atualizar Candidatura',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
      ],
    );
  }

  Widget _buildCandidatarButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => _mostrarDialogCandidatura(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF2563EB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('Candidatar-me', style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  void _mostrarDialogCandidatura(BuildContext context) {
    final badge = _badge ?? widget.badge;
    final badgeId = badge['idbadge'] as int;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<dynamic>>(
          future: CacheService.getRequisitosBadge(badgeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('A carregar requisitos...'),
                content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Erro'),
                content: Text('${snapshot.error}'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar'))
                ],
              );
            }

            final requisitos = snapshot.data ?? [];

            if (requisitos.isEmpty) {
              return AlertDialog(
                title: Text('Sem Requisitos'),
                content: Text('Este badge não tem requisitos.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Fechar'))
                ],
              );
            }

            return _CandidaturaDialog(
              badge: badge,
              requisitos: requisitos,
              onClose: () => Navigator.pop(context),
            );
          },
        );
      },
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

  Future<void> _mostrarPdfDialog(BuildContext context, String pdfBase64, String titulo) async {
    final extracted = extractBase64Pdf(pdfBase64);
    if (extracted == null) {
      _mostrarImagemDialog(context, pdfBase64, titulo);
      return;
    }
    try {
      Base64PdfWidget.decodeBase64(extracted);
    } catch (e) {
      _mostrarImagemDialog(context, pdfBase64, titulo);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(20),
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB))),
                  GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.grey)),
                ],
              ),
              SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Base64PdfWidget(pdfData: extracted, fileName: '$titulo.pdf'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarImagemDialog(
      BuildContext context, String urlFicheiro, String titulo) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB))),
                  GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.grey)),
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF2563EB), width: 1),
                ),
                child: urlFicheiro.isNotEmpty
                    ? SelectableText(
                        urlFicheiro,
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF2563EB), fontFamily: 'monospace'),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, size: 72, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Imagem não disponível',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
              SizedBox(height: 16),
              Text('📌 Link do ficheiro (PDF, imagem, etc)',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: urlFicheiro.isNotEmpty
                          ? () {
                              Clipboard.setData(ClipboardData(text: urlFicheiro));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Link copiado!'),
                                    duration: Duration(seconds: 2)),
                              );
                            }
                          : null,
                      icon: Icon(Icons.copy, size: 18),
                      label: Text('Copiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            urlFicheiro.isNotEmpty ? Color(0xFF2563EB) : Colors.grey,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Como abrir?'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('1. Copie o link acima',
                                    style: TextStyle(fontSize: 13)),
                                SizedBox(height: 8),
                                Text('2. Abra um navegador web',
                                    style: TextStyle(fontSize: 13)),
                                SizedBox(height: 8),
                                Text('3. Cole o link na barra de endereço',
                                    style: TextStyle(fontSize: 13)),
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '⚠️ Certifique-se de que o link é direto ao ficheiro (PDF, JPG, etc)',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.orange.shade900),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Entendi'))
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.help_outline, size: 18),
                      label: Text('Como?'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF2563EB),
                        side: BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarCertificado() async {
    final badge = _badge ?? widget.badge;

    if (badge?['certificado'] == null || (badge['certificado'] as String).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificado não disponível')),
      );
      return;
    }

    final String certificadoBase64 = badge['certificado'];
    if (!certificadoBase64.startsWith('JVBERi')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Formato de certificado inválido'), backgroundColor: Colors.red),
      );
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final pdfBytes = base64Decode(certificadoBase64);
      final badgeName = (badge['nome'] ?? 'Certificado') as String;
      final safeFileName =
          badgeName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      final fileName = '$safeFileName.pdf';

      // Android: tentar guardar diretamente na pasta Downloads visível
      if (Platform.isAndroid) {
        try {
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
          }

          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (status.isGranted && await downloadsDir.exists()) {
            final file = File('${downloadsDir.path}/$fileName');
            await file.writeAsBytes(pdfBytes);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Guardado em Downloads: $fileName'),
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Abrir',
                    onPressed: () => OpenFile.open(file.path),
                  ),
                ),
              );
            }
            return;
          }
        } catch (_) {
          // pasta não acessível, usar partilha como fallback
        }
      }

      // iOS ou fallback Android: guardar temporariamente e abrir partilha nativa
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (mounted) Navigator.pop(context);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Certificado: $badgeName',
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao guardar certificado: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _copiarLinkBadge() {
    final badgeId = _badge?['idbadge'] ?? widget.badgeId;
    if (badgeId == null) return;
    final url = '${ApiService.baseUrl}/badge/$badgeId';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copiado: $url'),
        backgroundColor: Color(0xFF2563EB),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _definirLembrete() async {
    final badge = _badge ?? widget.badge;
    final badgeId = badge?['idbadge'] as int?;
    final badgeNome = badge?['nome'] as String?;

    final tituloCtrl = TextEditingController(
        text: badgeNome != null ? 'Completar badge: $badgeNome' : '');
    final descCtrl = TextEditingController();
    DateTime? prazo;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Definir Lembrete',
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
                      labelText: 'Objetivo / Nota (opcional)',
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
                      helpText: 'Prazo do lembrete',
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
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF2563EB)),
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
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

  Future<void> _shareBadgeImageLinkedIn() async {
    final badge = _badge ?? widget.badge;
    final badgeId = badge?['idbadge'] ?? badge?['id'] ?? badge?['badge_id'];

    if (badgeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID do badge inválido')),
      );
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final userId = Session.id;
      final uri = Uri.parse('${ApiService.baseUrl}/badges/$badgeId/generate-image');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (resp.statusCode != 200) {
        throw Exception('Erro ao gerar imagem: ${resp.statusCode}');
      }

      final data = jsonDecode(resp.body);
      final base64str = data['base64'] as String?;
      if (base64str == null || base64str.isEmpty) {
        throw Exception('Imagem não recebida do servidor');
      }

      final bytes = base64Decode(base64str);
      final tempDir = await getTemporaryDirectory();
      final fileName = 'badge_${badgeId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) Navigator.pop(context);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '🎉 Conquistei o badge "${badge?['nome']}"! #SoftinsaTalent',
          subject: 'Badge: ${badge?['nome']}',
        ),
      );
    } catch (e) {
      if (mounted) {
        try { Navigator.pop(context); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao partilhar no LinkedIn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _partilharCertificado() async {
    final badge = _badge ?? widget.badge;
    final certificado = badge?['certificado']?.toString() ?? '';

    if (certificado.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificado não disponível')),
      );
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final badgeName = (badge['nome'] ?? 'Certificado') as String;
      final safeFileName = '${badgeName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.pdf';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$safeFileName');

      // Suporta certificado como URL ou como base64
      if (certificado.startsWith('http')) {
        final response = await http.get(Uri.parse(certificado));
        if (response.statusCode != 200) throw Exception('Erro HTTP ${response.statusCode}');
        await file.writeAsBytes(response.bodyBytes);
      } else {
        final base64 = extractBase64Pdf(certificado);
        if (base64 == null) throw Exception('Formato de certificado inválido');
        await file.writeAsBytes(base64Decode(base64));
      }

      if (mounted) Navigator.pop(context);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          text: 'Conquistei o badge "$badgeName"! 🎉',
          subject: 'Certificado: $badgeName',
        ),
      );
    } catch (e) {
      if (mounted) {
        try { Navigator.pop(context); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao partilhar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

}

class _CandidaturaDialog extends StatefulWidget {
  final dynamic badge;
  final List<dynamic> requisitos;
  final VoidCallback onClose;

  const _CandidaturaDialog({
    required this.badge,
    required this.requisitos,
    required this.onClose,
  });

  @override
  State<_CandidaturaDialog> createState() => _CandidaturaDialogState();
}

class _CandidaturaDialogState extends State<_CandidaturaDialog> {
  late Map<int, String> selectedFiles;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    selectedFiles = {};
  }

  Future<void> _pickFile(int requisitoId) async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Selecionar da Galeria'),
            onTap: () async {
              Navigator.pop(context);
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setState(() { selectedFiles[requisitoId] = image.path; });
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Tirar Foto'),
            onTap: () async {
              Navigator.pop(context);
              final image = await picker.pickImage(source: ImageSource.camera);
              if (image != null) {
                setState(() { selectedFiles[requisitoId] = image.path; });
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Selecionar PDF'),
            onTap: () async {
              Navigator.pop(context);
              final file = await FilePicker.pickFile(
                type: FileType.custom,
                allowedExtensions: ['pdf'],
              );
              if (file != null && file.path != null) {
                setState(() { selectedFiles[requisitoId] = file.path!; });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitCandidatura() async {
    if (selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleciona pelo menos um ficheiro.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await ApiService.submitCandidatura(widget.badge['idbadge'] as int, selectedFiles);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Candidatura submetida com sucesso!')),
        );
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Candidatar-me a ${widget.badge['nome']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Seleciona ficheiros de evidência para os requisitos:',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 16),
            ...widget.requisitos.map((req) {
              final reqId = req['idrequisito'] as int;
              final reqNome =
                  (req['titulo'] ?? req['nome']) as String? ?? 'Requisito $reqId';
              final reqDescricao = req['descricao'] as String? ?? '';
              final imagemurl = req['imagemurl'] as String? ?? '';
              final hasFile = selectedFiles.containsKey(reqId);

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reqNome, style: TextStyle(fontWeight: FontWeight.w600)),
                    if (reqDescricao.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(reqDescricao,
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                    SizedBox(height: 6),

                    () {
                      final extracted = extractBase64Pdf(imagemurl);
                      if (extracted != null && extracted.isNotEmpty) {
                        try {
                          Base64PdfWidget.decodeBase64(extracted);
                        } catch (e) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.red.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(width: 8),
                                Expanded(child: Text('PDF inválido')),
                              ],
                            ),
                          );
                        }
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.blue.shade50,
                          ),
                          child: Base64PdfWidget(
                              pdfData: extracted, fileName: '$reqNome.pdf'),
                        );
                      }
                      return SizedBox.shrink();
                    }(),

                    GestureDetector(
                      onTap: () => _pickFile(reqId),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: hasFile ? Color(0xFF2563EB) : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: hasFile ? Color(0xFFEFF6FF) : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              hasFile ? Icons.check_circle : Icons.upload_file,
                              color: hasFile ? Color(0xFF2563EB) : Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasFile
                                    ? selectedFiles[reqId]!.split('/').last
                                    : 'Clica para selecionar ficheiro',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: hasFile ? Colors.black : Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onClose, child: Text('Cancelar')),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitCandidatura,
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2563EB)),
          child: isSubmitting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('Submeter', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
