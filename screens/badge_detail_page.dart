import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/badges'),
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
