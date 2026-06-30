import 'package:flutter/material.dart';
import '../base64_image_widget.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/badge_progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/session.dart';

class BadgeDetailPage extends StatefulWidget {
  final dynamic badge;
  final dynamic candidatura; // Optional candidatura data
  
  const BadgeDetailPage({super.key, 
    required this.badge,
    this.candidatura,
  });

  @override
  State<BadgeDetailPage> createState() => _BadgeDetailPageState();
}

class _BadgeDetailPageState extends State<BadgeDetailPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;

    if (badge == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Badge indisponível', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isApproved)
            IconButton(
              icon: const Icon(Icons.share, color: Color(0xFF0A66C2)),
              onPressed: _shareBadgeImageLinkedIn,
              tooltip: 'Partilhar',
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
            onPressed: _compartilharPDF,
            tooltip: 'Partilhar Certificado',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                    // Imagem grande (suporta Base64 ou URL)
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
                        errorWidget: const Icon(Icons.emoji_events, size: 160, color: Color(0xFF2563EB)),
                      )
                      : const Icon(Icons.emoji_events, size: 160, color: Color(0xFF2563EB)),

                  const SizedBox(height: 16),

                  // Nome
                  Text(badge['nome'] ?? '',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB))),

                  const SizedBox(height: 4),

                  // Descrição
                  Text(badge['descricao'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center),

                  const SizedBox(height: 12),

                  // Nível + Pontos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('Nível: ${badge['nivel'] ?? 'N/A'}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${badge['pontos'] ?? 0} pts',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Link público
                  if (badge['linkpublicobase'] != null)
                    Text(badge['linkpublicobase'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),

                  const SizedBox(height: 16),

                  // Requisitos
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('REQUISITOS',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
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

                  // Progresso
                  BadgeProgress(atual: atual, total: total),

                  const SizedBox(height: 24),

                  // Tabs
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
                          ? (badge['descricao'] ?? 'Sem descrição.')
                          : (badge['competencias'] ?? 'Sem competências.'),
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botão Candidatar-me ou Status da Candidatura
          Padding(
            padding: const EdgeInsets.all(16),
            child: widget.candidatura != null
                ? _buildCandidaturaStatus()
                : _buildCandidatarButton(),
          ),
        ],
      ),
    );
  }

  Future<void> _shareBadgeImageLinkedIn() async {
    try {
      final badge = widget.badge;
      final badgeId = badge['idbadge'] ?? badge['id'] ?? badge['badge_id'];

      if (badgeId == null) {
        throw Exception('ID do badge inválido');
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Call server to generate image (returns base64)
      final userId = Session.id;
      final uri = Uri.parse('${ApiService.baseUrl}/badges/$badgeId/generate-image?user_id=$userId');
      final resp = await http.post(uri);

      if (resp.statusCode != 200) {
        throw Exception('Erro ao gerar imagem: ${resp.statusCode}');
      }

      final data = json.decode(resp.body);
      final base64str = data['base64'] as String?;

      if (base64str == null || base64str.isEmpty) {
        throw Exception('Imagem não recebida do servidor');
      }

      final bytes = base64.decode(base64str);

      final tempDir = await getTemporaryDirectory();
      final fileName = 'badge_${badgeId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      final shareText = '🎉 Conquistei o badge "${badge['nome']}"! #SoftinsaTalent';

      if (mounted) Navigator.pop(context);

      // Use share sheet (Share Plus). The user can pick LinkedIn.
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: shareText,
        subject: 'Badge: ${badge['nome']}',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao partilhar no LinkedIn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildCandidaturaStatus() {
    final candidatura = widget.candidatura;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2563EB), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Candidatura Submetida',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estado: ${candidatura['estado']}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Progresso: ${candidatura['progresso_atual']}/${candidatura['progresso_total']}',
                style: const TextStyle(fontSize: 12),
              ),
              if (candidatura['datasubmissao'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Submetido em: ${candidatura['datasubmissao'].toString().split('T').first}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _mostrarDialogCandidatura(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Atualizar Candidatura',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
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
          backgroundColor: const Color(0xFF2563EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Candidatar-me',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  late Map<int, String> selectedFiles;

  void _mostrarDialogCandidatura(BuildContext context) {
    final badge = widget.badge;
    final badgeId = badge['idbadge'] as int;
    final candidaturaId = widget.candidatura?['idcandidatura'] as int?;

    selectedFiles = {};

    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<dynamic>>(
          future: ApiService.getRequisitosBadge(badgeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('A carregar requisitos...'),
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Erro'),
                content: Text('${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              );
            }

            final requisitos = snapshot.data ?? [];

            if (requisitos.isEmpty) {
              return AlertDialog(
                title: const Text('Sem Requisitos'),
                content: const Text('Este badge não tem requisitos.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              );
            }

            return _CandidaturaDialog(
              badge: badge,
              requisitos: requisitos,
              candidaturaId: candidaturaId,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.transparent,
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

  /// Obtém o PDF base64 do certificado, gerando-o via API se necessário.
  /// Verifica primeiro no badge/candidatura, depois tenta gerar.
  Future<String?> _obterCertificadoPdfBase64() async {
    final badge = _badge ?? widget.badge;

    // 1. Tentar certificado_pdf_base64 da candidatura (personalizado)
    if (badge?['certificado_pdf_base64'] != null &&
        (badge['certificado_pdf_base64'] as String).isNotEmpty) {
      return badge['certificado_pdf_base64'] as String;
    }

    // 2. Tentar certificado genérico do badge
    if (badge?['certificado'] != null && (badge['certificado'] as String).isNotEmpty) {
      final cert = badge['certificado'] as String;
      final extracted = extractBase64Pdf(cert);
      if (extracted != null) return extracted;
    }

    // 3. Tentar gerar via API
    try {
      final badgeId = badge?['idbadge'] ?? badge?['badge_id'];
      if (badgeId != null) {
        final result = await ApiService.gerarCertificado(badgeId as int);
        final pdfBase64 = result['certificado_pdf_base64'] as String?;
        if (pdfBase64 != null && pdfBase64.isNotEmpty) {
          // Atualizar no badge local para não chamar outra vez
          badge?['certificado_pdf_base64'] = pdfBase64;
          return pdfBase64;
        }
      }
    } catch (e) {
      debugPrint('Erro ao gerar certificado: $e');
    }

    return null;
  }

  Future<void> _guardarCertificado() async {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final pdfBase64 = await _obterCertificadoPdfBase64();
      if (pdfBase64 == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Certificado não disponível')),
          );
        }
        return;
      }

      final pdfBytes = base64Decode(pdfBase64);
      final badge = _badge ?? widget.badge;
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
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.black87,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Ver Imagem', style: TextStyle(color: Colors.white)),
            ),
            Expanded(
              child: Container(
                color: Colors.black87,
                child: Base64ImageWidget.isBase64(imageUrl)
                    ? Base64ImageWidget(
                        imageData: imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        headers: const {
                          'Accept': 'image/*',
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'A carregar...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                const Text(
                                  'Erro ao carregar imagem',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndOpenPdf(String pdfUrl) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A descarregar PDF...')),
      );

      final response = await http.get(Uri.parse(pdfUrl));

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
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final pdfBase64 = await _obterCertificadoPdfBase64();
      if (pdfBase64 == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Certificado não disponível')),
          );
        }
        return;
      }

      final badge = _badge ?? widget.badge;
      final badgeName = (badge['nome'] ?? 'Certificado') as String;
      final safeFileName = '${badgeName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}.pdf';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$safeFileName');

      await file.writeAsBytes(base64Decode(pdfBase64));

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickFile(int requisitoId) async {
    final picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Selecionar da Galeria'),
            onTap: () async {
              Navigator.pop(context);
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setState(() {
                  selectedFiles[requisitoId] = image.path;
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tirar Foto'),
            onTap: () async {
              Navigator.pop(context);
              final image = await picker.pickImage(source: ImageSource.camera);
              if (image != null) {
                setState(() {
                  selectedFiles[requisitoId] = image.path;
                });
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
        const SnackBar(content: Text('Seleciona pelo menos um ficheiro.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await ApiService.submitCandidatura(
        widget.badge['idbadge'] as int,
        selectedFiles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidatura submetida com sucesso!')),
        );
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
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
            const Text(
              'Seleciona ficheiros de evidência para os requisitos:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (isLoadingSubmitted)
              const Center(child: CircularProgressIndicator())
            else
              ...widget.requisitos.map((req) {
                final reqId = req['idrequisito'] as int;
                final reqNome = req['titulo'] as String? ?? 'Requisito $reqId';
                final hasNewFile = selectedFiles.containsKey(reqId);
                final submitted = submittedRequisitos[reqId];
                final hasSubmitted = submitted != null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(reqNome, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (hasSubmitted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, color: Colors.green, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Submetido',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (hasSubmitted)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.green.shade50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ficheiro anterior:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  final url = submitted['evidencia_url']?.toString();
                                  if (url != null && url.isNotEmpty) {
                                    _viewFile(url);
                                  }
                                },
                                child: Text(
                                  submitted['evidencia_url']?.toString() ?? 'Ficheiro não disponível',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      GestureDetector(
                        onTap: () => _pickFile(reqId),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hasNewFile ? const Color(0xFF2563EB) : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: hasNewFile ? const Color(0xFFEFF6FF) : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                hasNewFile ? Icons.check_circle : Icons.upload_file,
                                color: hasNewFile ? const Color(0xFF2563EB) : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hasNewFile
                                      ? selectedFiles[reqId]!.split('/').last
                                      : 'Clica para ${hasSubmitted ? 'atualizar' : 'selecionar'} ficheiro',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: hasNewFile ? Colors.black : Colors.grey,
                                  ),
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
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onClose,
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitCandidatura,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submeter', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
