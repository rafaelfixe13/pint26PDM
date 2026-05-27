import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class Base64PdfWidget extends StatefulWidget {
  final String pdfData;
  final String? fileName;
  final VoidCallback? onDownloadSuccess;
  final VoidCallback? onDownloadError;

  const Base64PdfWidget({super.key, 
    required this.pdfData,
    this.fileName,
    this.onDownloadSuccess,
    this.onDownloadError,
  });

  static bool isBase64(String data) {
    if (data.isEmpty) return false;
    return data.startsWith('JVBERi') || data.startsWith('data:application/pdf');
  }

  static Uint8List decodeBase64(String base64String) {
    String cleanBase64 = base64String.trim();
    if (cleanBase64.contains(',')) {
      final idx = cleanBase64.indexOf(',');
      cleanBase64 = cleanBase64.substring(idx + 1).trim();
    }
    return base64Decode(cleanBase64);
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
      // ignore
    }
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      String pdfData = widget.pdfData;
      if (pdfData.isEmpty) throw Exception('Dados do PDF vazios');
      if (!pdfData.startsWith('JVBERi') && !pdfData.startsWith('data:')) {
        throw Exception('Dados não parecem ser PDF em base64');
      }
      final pdfBytes = Base64PdfWidget.decodeBase64(pdfData);
      if (pdfBytes.isEmpty) throw Exception('Base64 descodificado vazio');

      final directory = await getApplicationDocumentsDirectory();
      final fileName = widget.fileName ?? 'cert_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      if (!file.existsSync()) throw Exception('Ficheiro não foi criado em $filePath');

      setState(() {
        _isDownloaded = true;
        _localFilePath = filePath;
        _isDownloading = false;
      });

      widget.onDownloadSuccess?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ PDF guardado com sucesso!')),
        );
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      widget.onDownloadError?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openPdf() async {
    if (_localFilePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caminho do ficheiro não definido')),
        );
      }
      return;
    }

    if (_localFilePath!.startsWith('data:') || _localFilePath!.startsWith('JVBERi')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro interno: caminho inválido'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final file = File(_localFilePath!);
    if (!file.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ficheiro não encontrado'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final result = await OpenFile.open(_localFilePath!);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não conseguiu abrir: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pdfData.isEmpty) return _buildErrorState('Sem dados de PDF');
    if (!Base64PdfWidget.isBase64(widget.pdfData)) {
      return _buildDownloadButton(
        label: 'Descarregar PDF',
        icon: Icons.cloud_download,
        onPressed: _downloadPdf,
      );
    }

    if (_isDownloaded && _localFilePath != null) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openPdf,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ),
        ],
      );
    }

    if (_isDownloading) {
      return _buildDownloadButton(label: 'Descarregando...', icon: Icons.hourglass_bottom, onPressed: null);
    }

    return _buildDownloadButton(label: 'Descarregar Certificado', icon: Icons.download, onPressed: _downloadPdf);
  }

  Widget _buildDownloadButton({required String label, required IconData icon, required VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed != null ? () => onPressed() : null,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), backgroundColor: Colors.blue, disabledBackgroundColor: Colors.grey),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
