import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinttest/services/api_service.dart';

class CandidaturaPage extends StatefulWidget {
  final dynamic badge;

  const CandidaturaPage({
    super.key,
    required this.badge,
  });

  @override
  State<CandidaturaPage> createState() => _CandidaturaPageState();
}

class _CandidaturaPageState extends State<CandidaturaPage> {
  late Future<List<dynamic>> _requisitosFuture;

  final ImagePicker _picker = ImagePicker();
  final Map<int, XFile?> _ficheirosPorRequisito = {};
  bool _aSubmeter = false;

  int get _badgeId {
    final raw = widget.badge['idbadge'] ?? widget.badge['badge_id'] ?? 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _requisitosFuture = ApiService.getRequisitosDoBadge(_badgeId);
  }

  Future<void> _recarregar() async {
    setState(() {
      _requisitosFuture = ApiService.getRequisitosDoBadge(_badgeId);
    });
    await _requisitosFuture;
  }

  Future<void> _selecionarImagem(int idRequisito) async {
    final XFile? result = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (result == null) return;

    setState(() {
      _ficheirosPorRequisito[idRequisito] = result;
    });
  }

  void _removerFicheiro(int idRequisito) {
    setState(() {
      _ficheirosPorRequisito.remove(idRequisito);
    });
  }

  String _nomeFicheiro(XFile? file) {
    if (file == null) return 'Nenhum ficheiro selecionado';
    return file.name;
  }

  Future<void> _submeter(List<dynamic> requisitos) async {
    final obrigatoriosEmFalta = requisitos.where((req) {
      final bool obrigatorio = req['ativo'] == true;
      if (!obrigatorio) return false;

      final int idReq = int.tryParse(req['idrequisito'].toString()) ?? 0;
      final bool temFicheiro = _ficheirosPorRequisito[idReq] != null;

      return !temFicheiro;
    }).toList();

    if (obrigatoriosEmFalta.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tens de anexar ficheiros para todos os requisitos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      setState(() {
        _aSubmeter = true;
      });

      await ApiService.submeterCandidaturaComImagens(
        badgeId: _badgeId,
        ficheirosPorRequisito: _ficheirosPorRequisito,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Candidatura submetida com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao submeter candidatura: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _aSubmeter = false;
        });
      }
    }
  }

  Widget _buildHeader(dynamic badge) {
    final imagemUrl = badge['imagemurl']?.toString();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF4FF),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagemUrl != null && imagemUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imagemUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackBadgeIcon(),
              ),
            )
          else
            _buildFallbackBadgeIcon(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.badge['nome']?.toString() ?? 'Badge',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.badge['descricao']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBadgeIcon() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.emoji_events,
        color: Color(0xFF2563EB),
        size: 36,
      ),
    );
  }

  Widget _buildFileIcon() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFE3E9FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.description_outlined,
        color: Color(0xFF5B5F97),
        size: 28,
      ),
    );
  }

  Widget _buildCardRequisito(dynamic req) {
    final int idRequisito = int.tryParse(req['idrequisito'].toString()) ?? 0;
    final String titulo = req['titulo']?.toString() ?? 'Requisito';
    final String descricao = req['descricao']?.toString() ?? '';
    final String codigo = req['codigo']?.toString() ?? '';
    final bool obrigatorio = req['ativo'] == true;
    final XFile? ficheiro = _ficheirosPorRequisito[idRequisito];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (codigo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Código: $codigo',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          if (descricao.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                descricao,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
          if (obrigatorio)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Obrigatório',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (ficheiro != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(ficheiro.path),
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  _buildFileIcon(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nomeFicheiro(ficheiro),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Imagem da galeria',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    TextButton.icon(
                      onPressed: () => _selecionarImagem(idRequisito),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.purple,
                      ),
                      label: Text(
                        ficheiro == null ? 'Anexar' : 'Editar',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (ficheiro != null)
                      TextButton(
                        onPressed: () => _removerFicheiro(idRequisito),
                        child: const Text(
                          'Remover',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Submeter requisitos',
          style: TextStyle(
            color: Color(0xFF1E3A5F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _recarregar,
        child: FutureBuilder<List<dynamic>>(
          future: _requisitosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.error_outline,
                    size: 54,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar requisitos.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            }

            final requisitos = snapshot.data ?? [];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(widget.badge),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ficheiros dos requisitos submetidos:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (requisitos.isEmpty)
                              const Text(
                                'Este badge não tem requisitos configurados.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ...requisitos.map(_buildCardRequisito).toList(),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _aSubmeter
                                    ? null
                                    : () => _submeter(requisitos),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3F6FAF),
                                  disabledBackgroundColor: Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _aSubmeter
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Submeter Candidatura',
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}