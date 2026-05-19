import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

/// Widget que detecta automaticamente se o PDF é Base64 ou URL
/// e permite fazer download para o dispositivo
class Base64PdfWidget extends StatefulWidget {
  final String pdfData;
  final String? fileName;
  final VoidCallback? onDownloadSuccess;
  final VoidCallback? onDownloadError;

  const Base64PdfWidget({
    required this.pdfData,
    this.fileName,
    this.onDownloadSuccess,
    this.onDownloadError,
  });

  /// Verifica se a string é base64
  static bool isBase64(String data) {
    if (data.isEmpty) return false;
    
    // PDFs em base64 geralmente começam com JVBERi ou data:application/pdf
    return data.startsWith('JVBERi') || 
           data.startsWith('data:application/pdf');
  }

  /// Decodifica base64 para bytes
  static Uint8List decodeBase64(String base64String) {
    String cleanBase64 = base64String.trim();
    
    print('[PDF] Input length: ${cleanBase64.length}');
    print('[PDF] Starts with: ${cleanBase64.substring(0, 50)}');
    
    // REMOVER PREFIXO data: se existir
    if (cleanBase64.contains(',')) {
      final idx = cleanBase64.indexOf(',');
      print('[PDF] Comma found at index: $idx');
      cleanBase64 = cleanBase64.substring(idx + 1).trim();
      print('[PDF] After comma removal: ${cleanBase64.substring(0, 50)}');
      print('[PDF] New length: ${cleanBase64.length}');
    }
    
    try {
      final decoded = base64Decode(cleanBase64);
      print('[PDF] Successfully decoded: ${decoded.length} bytes');
      return decoded;
    } catch (e) {
      print('[PDF] ERROR decoding: $e');
      print('[PDF] String to decode: $cleanBase64');
      rethrow;
    }
  }

  @override
  State<Base64PdfWidget> createState() => _Base64PdfWidgetState();
}

class _Base64PdfWidgetState extends State<Base64PdfWidget> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    print('═══════ BASE64PDF INITSTATE ═══════');
    print('[BASE64PDF] initState called');
    print('[BASE64PDF] pdfData length: ${widget.pdfData.length}');
    print('[BASE64PDF] pdfData start: ${widget.pdfData.substring(0, 50)}');
    _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    try {
      final fileName = widget.fileName ?? 'certificado.pdf';
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      
      if (File(filePath).existsSync()) {
        setState(() {
          _isDownloaded = true;
          _localFilePath = filePath;
        });
      }
    } catch (e) {
      // Silenciosamente ignorar erros de verificação
    }
  }

  Future<void> _downloadPdf() async {
    print('========== _downloadPdf() COMEÇOU ==========');
    
    if (_isDownloading) {
      print('[DOWNLOAD] JÁ está a descarregar, returning');
      return;
    }
    
    print('[DOWNLOAD] INICIANDO...');
    setState(() => _isDownloading = true);

    try {
      print('[DOWNLOAD] Pegando pdfData do widget...');
      String pdfData = widget.pdfData;
      print('[DOWNLOAD] pdfData length: ${pdfData.length}');
      print('[DOWNLOAD] pdfData first 100 chars: ${pdfData.substring(0, 100)}');
      
      // Validação: se o pdfData é vazio ou não é base64
      if (pdfData.isEmpty) {
        print('[DOWNLOAD] ERRO: pdfData vazio!');
        throw Exception('Dados do PDF vazios');
      }
      
      // Se não é base64, lançar erro
      if (!pdfData.startsWith('JVBERi') && !pdfData.startsWith('data:')) {
        print('[DOWNLOAD] ERRO: Não começa com JVBERi ou data:');
        throw Exception('Dados não parecem ser PDF em base64');
      }

      print('[DOWNLOAD] Chamando decodeBase64...');
      // Descodificar base64 para bytes
      final pdfBytes = Base64PdfWidget.decodeBase64(pdfData);
      
      print('[DOWNLOAD] decodeBase64 retornou ${pdfBytes.length} bytes');
      
      if (pdfBytes.isEmpty) {
        print('[DOWNLOAD] ERRO: pdfBytes vazio!');
        throw Exception('Base64 descodificado vazio');
      }

      // Guardar ficheiro
      print('[DOWNLOAD] Obtendo directory...');
      final directory = await getApplicationDocumentsDirectory();
      print('[DOWNLOAD] Directory: ${directory.path}');
      
      final fileName = widget.fileName ?? 'cert_${DateTime.now().millisecondsSinceEpoch}.pdf';
      print('[DOWNLOAD] Filename: $fileName');
      
      final filePath = '${directory.path}/$fileName';
      print('[DOWNLOAD] Full path: $filePath');
      
      print('[DOWNLOAD] Criando File object...');
      final file = File(filePath);
      
      print('[DOWNLOAD] Escrevendo bytes ao ficheiro...');
      await file.writeAsBytes(pdfBytes);
      print('[DOWNLOAD] Bytes escritos com sucesso!');

      // Validação: ficheiro foi criado?
      final exists = file.existsSync();
      print('[DOWNLOAD] File exists after write: $exists');
      
      if (!exists) {
        print('[DOWNLOAD] ERRO: Ficheiro não foi criado!');
        throw Exception('Ficheiro não foi criado em $filePath');
      }

      print('[DOWNLOAD] SUCESSO! Updating state...');
      setState(() {
        _isDownloaded = true;
        _localFilePath = filePath;
        _isDownloading = false;
      });
      print('[DOWNLOAD] State updated');

      widget.onDownloadSuccess?.call();
      print('[DOWNLOAD] Mostrando SnackBar de sucesso...');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ PDF guardado com sucesso!')),
        );
      }
      print('[DOWNLOAD] CONCLUÍDO COM SUCESSO!');
      
    } catch (e) {
      print('[DOWNLOAD] APANHEI ERRO: $e');
      print('[DOWNLOAD] Error type: ${e.runtimeType}');
      
      setState(() => _isDownloading = false);
      widget.onDownloadError?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
    print('========== _downloadPdf() TERMINOU ==========');
  }

  Future<void> _openPdf() async {
    print('[OPEN] _localFilePath: $_localFilePath');
    print('[OPEN] _isDownloaded: $_isDownloaded');
    
    if (_localFilePath == null) {
      print('[OPEN] ERROR: _localFilePath é null');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Caminho do ficheiro não definido')),
        );
      }
      return;
    }

    // Validar que é um caminho e não base64
    if (_localFilePath!.startsWith('data:') || _localFilePath!.startsWith('JVBERi')) {
      print('[OPEN] ERROR: _localFilePath é base64, não caminho: ${_localFilePath!.substring(0, 50)}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro interno: caminho inválido'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final file = File(_localFilePath!);
    if (!file.existsSync()) {
      print('[OPEN] ERROR: Ficheiro não existe: $_localFilePath');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ficheiro não encontrado'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      print('[OPEN] Abrindo ficheiro: $_localFilePath');
      final result = await OpenFile.open(_localFilePath!);
      print('[OPEN] Resultado: ${result.type}');
      
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não conseguiu abrir: ${result.message}')),
        );
      }
    } catch (e) {
      print('[OPEN] ERRO ao abrir: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[BUILD] pdfData empty: ${widget.pdfData.isEmpty}');
    print('[BUILD] isBase64: ${Base64PdfWidget.isBase64(widget.pdfData)}');
    print('[BUILD] _isDownloaded: $_isDownloaded, _localFilePath: $_localFilePath');
    
    if (widget.pdfData.isEmpty) {
      return _buildErrorState('Sem dados de PDF');
    }

    if (!Base64PdfWidget.isBase64(widget.pdfData)) {
      // Se não for base64, assume que é URL
      return _buildDownloadButton(
        label: 'Descarregar PDF',
        icon: Icons.cloud_download,
        onPressed: _downloadPdf,
      );
    }

    // Se já descarregou, mostrar opção de abrir
    if (_isDownloaded && _localFilePath != null) {
      print('[BUILD] Mostrar botões de ABRIR e ATUALIZAR');
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openPdf,
              icon: Icon(Icons.open_in_new),
              label: Text('Abrir PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _downloadPdf,
              icon: Icon(Icons.refresh),
              label: Text('Atualizar'),
            ),
          ),
        ],
      );
    }

    // Se está a descarregar
    if (_isDownloading) {
      print('[BUILD] Mostrar estado DESCARREGANDO');
      return _buildDownloadButton(
        label: 'Descarregando...',
        icon: Icons.hourglass_bottom,
        onPressed: null,
      );
    }

    // Botão para descarregar
    print('[BUILD] Mostrar botão DESCARREGAR');
    return _buildDownloadButton(
      label: 'Descarregar Certificado',
      icon: Icons.download,
      onPressed: _downloadPdf,
    );
  }

  Widget _buildDownloadButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed != null
          ? () {
              print('[BUTTON] Clicado: $label');
              onPressed();
            }
          : null,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.blue,
        disabledBackgroundColor: Colors.grey,
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
