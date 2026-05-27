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

  Widget _icon(IconData icon, Color color, {bool selected = false}) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : Color.fromARGB((0.15 * 255).round(), (color.r * 255).round(), (color.g * 255).round(), (color.b * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: selected ? Border.all(color: const Color(0xFF2563EB), width: 2) : null,
      ),
      child: Icon(icon, size: 26, color: selected ? const Color(0xFF2563EB) : color),
      );
    }

    Future<void> _compartilharPDF() async {
    try {
      // Check if badge has certificate in Base64
      final certificadoBase64 = widget.badge['certificado'];
      if (certificadoBase64 == null || certificadoBase64.isEmpty) {
        throw Exception('Certificado não disponível');
      }

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A preparar certificado...')),
      );

      // Decode Base64 to bytes
      final pdfBytes = base64.decode(certificadoBase64);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = '${widget.badge['nome']?.replaceAll(' ', '_') ?? 'certificado'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Share via Share Sheet
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Certificado: ${widget.badge['nome']}',
        text: 'Conquistei o certificado "${widget.badge['nome']}"! 🎖️',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _CandidaturaDialog extends StatefulWidget {
  final dynamic badge;
  final List<dynamic> requisitos;
  final int? candidaturaId;
  final VoidCallback onClose;

  const _CandidaturaDialog({
    required this.badge,
    required this.requisitos,
    this.candidaturaId,
    required this.onClose,
  });

  @override
  State<_CandidaturaDialog> createState() => _CandidaturaDialogState();
}

class _CandidaturaDialogState extends State<_CandidaturaDialog> {
  late Map<int, String> selectedFiles;
  late Map<int, dynamic> submittedRequisitos;
  bool isSubmitting = false;
  bool isLoadingSubmitted = true;

  @override
  void initState() {
    super.initState();
    selectedFiles = {};
    submittedRequisitos = {};
    if (widget.candidaturaId != null) {
      _loadSubmittedRequisitos();
    } else {
      isLoadingSubmitted = false;
    }
  }

  Future<void> _loadSubmittedRequisitos() async {
    try {
      final submitted =
          await ApiService.getCandidaturaRequisitos(widget.candidaturaId!);
      if (!mounted) return;
      setState(() {
        for (var req in submitted) {
          submittedRequisitos[req['idrequisito']] = req;
        }
        isLoadingSubmitted = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingSubmitted = false;
      });
    }
  }

  Future<void> _viewFile(String fileUrl) async {
    if (fileUrl.isEmpty) return;

    final extension = fileUrl.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
    final isPdf = extension == 'pdf';

    // Treat data URIs / base64 as images as well
    if (isImage || Base64ImageWidget.isBase64(fileUrl)) {
      _showImageViewer(fileUrl);
    } else if (isPdf) {
      _downloadAndOpenPdf(fileUrl);
    } else {
      // For other file types, try to open with device app
      try {
        await launchUrl(Uri.parse(fileUrl));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o ficheiro')),
          );
        }
      }
    }
  }

  void _showImageViewer(String imageUrl) {
    showDialog(
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

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = pdfUrl.split('/').last;
        final file = File('${tempDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);

        final result = await OpenFile.open(file.path);

        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Não foi possível abrir o PDF')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao descarregar ficheiro')),
          );
        }
      }
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
