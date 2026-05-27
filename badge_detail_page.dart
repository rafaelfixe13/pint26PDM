import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/api_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../widgets/base64_image_widget.dart';
import '../services/session.dart';

class BadgeDetailPage extends StatefulWidget {
  final dynamic badge;
  final dynamic candidatura; // Optional candidatura data
  
  const BadgeDetailPage({
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isApproved)
            IconButton(
              icon: Icon(Icons.business, color: Color(0xFF0A66C2)),
              onPressed: _shareBadgeImageLinkedIn,
              tooltip: 'Partilhar no LinkedIn',
            ),
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: _compartilharPDF,
            tooltip: 'Partilhar Certificado',
          ),
        ],
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

                  // Link público
                  if (badge['linkpublicobase'] != null)
                    Text(badge['linkpublicobase'],
                        style: TextStyle(fontSize: 12, color: Colors.grey)),

                  SizedBox(height: 16),

                  // Requisitos (Dinâmicos)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('REQUISITOS',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  SizedBox(height: 8),
                  FutureBuilder<List<dynamic>>(
                    future: ApiService.getRequisitosBadge(badge['idbadge'] as int),
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
                            child: Text(
                              'Erro ao carregar requisitos',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        );
                      }

                      final requisitos = snapshot.data ?? [];

                      if (requisitos.isEmpty) {
                        return SizedBox(
                          height: 70,
                          child: Center(
                            child: Text(
                              'Sem requisitos',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: requisitos.map((req) {
                          final imageUrl = (req['imagemurl'] as String?)
                              ?.replaceAll('localhost', '10.0.2.2')
                              .replaceAll('127.0.0.1', '10.0.2.2')
                              .replaceAll('100.105.58.22', '10.0.2.2')
                              .replaceAll('0.0.0.0', '10.0.2.2');
                          final codigo = req['codigo'] as String? ?? 'REQ';
                          final nome = req['nome'] as String? ?? 'Requisito';

                          return GestureDetector(
                            onTap: imageUrl != null && imageUrl.isNotEmpty
                                ? () => _mostrarImagemDialog(context, imageUrl, nome)
                                : null,
                            child: Tooltip(
                              message: nome,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: imageUrl != null && imageUrl.isNotEmpty
                                      ? Color(0xFF2563EB)
                                      : Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: imageUrl != null && imageUrl.isNotEmpty
                                      ? null
                                      : Border.all(color: Color(0xFF2563EB), width: 1),
                                ),
                                child: Text(
                                  codigo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: imageUrl != null && imageUrl.isNotEmpty
                                        ? Colors.white
                                        : Color(0xFF2563EB),
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

          // Botão Candidatar-me ou Status da Candidatura
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
              Text(
                'Candidatura Submetida',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Estado: ${candidatura['estado']}',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                'Progresso: ${candidatura['progresso_atual']}/${candidatura['progresso_total']}',
                style: TextStyle(fontSize: 12),
              ),
              if (candidatura['datasubmissao'] != null) ...[
                SizedBox(height: 4),
                Text(
                  'Submetido em: ${candidatura['datasubmissao'].toString().split('T').first}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 12),
        // Se estado é APPROVED, mostra botão verde de guardar certificado
        if (candidatura['estado'] == 'APPROVED')
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _guardarCertificado,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10B981), // Verde
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.download, color: Colors.white),
              label: Text(
                'Guardar Certificado',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
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
          backgroundColor: Color(0xFF2563EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
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

    selectedFiles = {};

    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<dynamic>>(
          future: ApiService.getRequisitosBadge(badgeId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('A carregar requisitos...'),
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Erro'),
                content: Text('${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fechar'),
                  ),
                ],
              );
            }

            final requisitos = snapshot.data ?? [];

            if (requisitos.isEmpty) {
              return AlertDialog(
                title: Text('Sem Requisitos'),
                content: Text('Este badge não tem requisitos.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fechar'),
                  ),
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

  Future<void> _mostrarImagemDialog(BuildContext context, String urlFicheiro, String titulo) async {
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
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.grey),
                  ),
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
                child: SelectableText(
                  urlFicheiro,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '📌 Link do ficheiro (PDF, imagem, etc)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: urlFicheiro));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Link copiado!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(Icons.copy, size: 18),
                      label: Text('Copiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                                Text(
                                  '1. Copie o link acima',
                                  style: TextStyle(fontSize: 13),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '2. Abra um navegador web',
                                  style: TextStyle(fontSize: 13),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '3. Cole o link na barra de endereço',
                                  style: TextStyle(fontSize: 13),
                                ),
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '⚠️ Certifique-se de que o link é direto ao ficheiro (PDF, JPG, etc)',
                                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Entendi'),
                              ),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
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
    try {
      final badge = widget.badge;
      
      // Se existe certificado em base64 no badge
      if (badge?['certificado'] != null && badge['certificado'].isNotEmpty) {
        final certificadoBase64 = badge['certificado'];
        
        // Verificar se é realmente base64
        if (!certificadoBase64.startsWith('JVBERi')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Formato de certificado inválido. Esperado: Base64'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          // Descodificar base64 para bytes
          final pdfBytes = base64Decode(certificadoBase64);
          
          // Determinar pasta de Downloads conforme a plataforma
          late Directory downloadDir;
          
          if (Platform.isAndroid) {
            // Android: usar getExternalStorageDirectory para pasta Downloads
            // Esta pasta não requer permissões adicionais quando usada corretamente
            final externalDir = await getExternalStorageDirectory();
            
            if (externalDir == null) {
              throw Exception('Não conseguimos aceder à pasta externa do dispositivo');
            }
            
            // Criar pasta Downloads dentro da app
            downloadDir = Directory('${externalDir.path}/Downloads');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
          } else {
            // iOS: usar documentos da app
            downloadDir = await getApplicationDocumentsDirectory();
          }

          final fileName = '${badge['nome'] ?? 'Certificado'}.pdf';
          final filePath = '${downloadDir.path}/$fileName';
          final file = File(filePath);
          
          await file.writeAsBytes(pdfBytes);
          
          if (mounted) Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' Certificado guardado em Downloads! '),
              duration: Duration(seconds: 4),
            ),
          );
        } catch (e) {
          if (mounted) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao guardar certificado: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Certificado não disponível')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _linkedin() async {
    try {
      // Tentar vários schemes do LinkedIn
      final schemes = [
        'linkedin://',
        'linkedin://app',
        'com.linkedin.android://',
      ];
      
      bool opened = false;
      
      for (String scheme in schemes) {
        try {
          if (await canLaunchUrl(Uri.parse(scheme))) {
            await launchUrl(
              Uri.parse(scheme),
              mode: LaunchMode.externalApplication,
            );
            opened = true;
            break;
          }
        } catch (e) {
          // Continua para o próximo scheme
          continue;
        }
      }
      
      // Se nenhum scheme funcionou, tentar URL web como fallback
      if (!opened) {
        try {
          const linkedinWebUrl = 'https://www.linkedin.com/login?lipi=urn%3Ali%3Apage%3Adeeplink_linkedinmobileapp%3BRYni3FqGSSOWdWB4T0GD%2FA%3D%3D&destType=web&fromSignIn=true&trk=guest_homepage-basic_nav-header-signin';
          await launchUrl(
            Uri.parse(linkedinWebUrl),
            mode: LaunchMode.externalApplication,
          );
          opened = true;
        } catch (e) {
          // Falhou
        }
      }
      
      if (!opened) {
        throw Exception('Não foi possível abrir o LinkedIn');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir LinkedIn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _compartilharLinkedIn() async {
    try {
      final badge = widget.badge;
      final badgeName = badge['nome'] ?? 'Badge';
      final badgeDescricao = badge['descricao'] ?? '';
      
      // Verificar se existe certificado
      if (badge?['certificado'] == null || badge['certificado'].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificado não disponível'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mostrar carregamento
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      try {
        final certificadoBase64 = badge['certificado'];
        
        // Verificar se é realmente Base64
        if (!certificadoBase64.startsWith('JVBERi')) {
          if (mounted) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formato de certificado inválido'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Descodificar Base64 para bytes
        final pdfBytes = base64Decode(certificadoBase64);
        
        // Guardar ficheiro temporário
        final tempDir = await getTemporaryDirectory();
        final fileName = '${badgeName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        // Texto de partilha
        final shareText = '🎉 Conquistei o badge "$badgeName" em Softinsa Talent Management!\n\n📝 $badgeDescricao\n\n💪 Estou a desenvolver as minhas competências através de um sistema de gamificação inovador!\n\n#SoftinsaTalent #BadgeSystem #Desenvolvimento #Competências';

        if (mounted) Navigator.pop(context);

        // Partilhar usando Share Plus (abre opções de partilha incluindo LinkedIn)
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          text: shareText,
          subject: 'Badge: $badgeName',
        );

      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar certificado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _abrirLinkedIn() async {
    try {
      // Try platform-specific LinkedIn deep links
      final linkedinSchemes = [
        // Android LinkedIn app
        'com.linkedin.android://home',
        // iOS LinkedIn app
        'linkedin://app',
        // Web fallback
        'https://www.linkedin.com',
      ];

      bool opened = false;

      for (String scheme in linkedinSchemes) {
        try {
          final uri = Uri.parse(scheme);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            opened = true;
            break;
          }
        } catch (e) {
          debugPrint('LinkedIn scheme failed: $scheme');
          continue;
        }
      }

      if (!opened) {
        // Last resort - try web
        await launchUrl(
          Uri.parse('https://www.linkedin.com'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir LinkedIn: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        SnackBar(content: Text('A preparar certificado...')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao partilhar no LinkedIn: $e'), backgroundColor: Colors.red),
      );
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
      builder: (BuildContext context) => Container(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Selecionar da Galeria'),
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
              leading: Icon(Icons.camera_alt),
              title: Text('Tirar Foto'),
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
      await ApiService.submitCandidatura(
        widget.badge['idbadge'] as int,
        selectedFiles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Candidatura submetida com sucesso!')),
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
            Text(
              'Seleciona ficheiros de evidência para os requisitos:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ...widget.requisitos.map((req) {
              final reqId = req['idrequisito'] as int;
              final reqNome = req['nome'] as String? ?? 'Requisito $reqId';
              final hasFile = selectedFiles.containsKey(reqId);

              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reqNome, style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
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
                                  color: hasFile ? Colors.black : Colors.grey,
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
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onClose,
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitCandidatura,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2563EB),
          ),
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
