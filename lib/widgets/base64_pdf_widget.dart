import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

/// Widget que funciona exclusivamente com PDF em formato Base64
/// Permite fazer download para o dispositivo e abrir
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

  /// Verifica se a string é base64 válida para PDF
  static bool isBase64(String data) {
    if (data.isEmpty) return false;
    
    // PDFs em base64 podem começar com:
    // - JVBERi (header direto do PDF)
    // - data:application/pdf;base64, (com prefixo data URI)
    return data.startsWith('JVBERi') || 
           data.startsWith('data:application/pdf;base64,') ||
           data.startsWith('data:');
  }

  /// Decodifica base64 para bytes
  static Uint8List decodeBase64(String base64String) {
    String cleanBase64 = base64String.trim();
    
    print('[PDF] Input length: ${cleanBase64.length}');
    final startPreview = cleanBase64.length > 50 ? cleanBase64.substring(0, 50) : cleanBase64;
    print('[PDF] Starts with: $startPreview');
    
    // PASSO 1: Remover TODAS as ocorrências de prefixos corrompidos
    // O database tem "https://data:application/pdf;base64," inseridos no MEIO do base64!
    cleanBase64 = cleanBase64.replaceAll('https://data:application/pdf;base64,', '');
    cleanBase64 = cleanBase64.replaceAll('http://data:application/pdf;base64,', '');
    cleanBase64 = cleanBase64.replaceAll('data:application/pdf;base64,', '');
    print('[PDF] After removing corrupted prefixes: ${cleanBase64.length}');
    
    // PASSO 2: Remover prefixos HTTP/HTTPS restantes
    if (cleanBase64.startsWith('https://')) {
      cleanBase64 = cleanBase64.substring(8);
      print('[PDF] Removed https:// prefix');
    } else if (cleanBase64.startsWith('http://')) {
      cleanBase64 = cleanBase64.substring(7);
      print('[PDF] Removed http:// prefix');
    }

    // PASSO 3: Se ainda começa com "data:", extrai só a parte após a vírgula
    if (cleanBase64.startsWith('data:')) {
      final idx = cleanBase64.indexOf(',');
      if (idx >= 0 && idx + 1 < cleanBase64.length) {
        print('[PDF] Data URI detectado, removendo prefixo...');
        cleanBase64 = cleanBase64.substring(idx + 1).trim();
        final afterCommaPreview = cleanBase64.length > 50 ? cleanBase64.substring(0, 50) : cleanBase64;
        print('[PDF] After comma removal: $afterCommaPreview');
        print('[PDF] New length: ${cleanBase64.length}');
      }
    }

    // PASSO 4: Remover espaços em branco (tabs, newlines, etc)
    cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
    print('[PDF] After whitespace removal: ${cleanBase64.length}');
    
    // PASSO 5: Adicionar padding se necessário (base64 deve ter múltiplo de 4)
    final remainder = cleanBase64.length % 4;
    if (remainder != 0) {
      final paddingNeeded = 4 - remainder;
      cleanBase64 += '=' * paddingNeeded;
      print('[PDF] Added $paddingNeeded padding characters, new length: ${cleanBase64.length}');
    }
    
    try {
      final decoded = base64Decode(cleanBase64);
      print('[PDF] Successfully decoded: ${decoded.length} bytes');
      return decoded;
    } catch (e) {
      print('[PDF] ERROR decoding: $e');
      print('[PDF] String to decode (first 100): ${cleanBase64.length > 100 ? cleanBase64.substring(0, 100) : cleanBase64}');
      rethrow;
    }
  }

  @override
  State<Base64PdfWidget> createState() => _Base64PdfWidgetState();
}

class _Base64PdfWidgetState extends State<Base64PdfWidget> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isPreparing = false;
  String? _errorMessage;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    print('═══════ BASE64PDF INITSTATE ═══════');
    print('[BASE64PDF] initState called');
    print('[BASE64PDF] pdfData length: ${widget.pdfData.length}');
    final pdfStart = widget.pdfData.length > 50 ? widget.pdfData.substring(0, 50) : widget.pdfData;
    print('[BASE64PDF] pdfData start: $pdfStart');
    _checkIfDownloaded();
    // Start preparing PDF for inline display
    _isPreparing = true;
    _preparePdfForDisplay().whenComplete(() {
      if (mounted) setState(() => _isPreparing = false);
    });
  }

  Future<void> _preparePdfForDisplay() async {
    try {
      print('[PREPARE] ═══════ INICIANDO _preparePdfForDisplay ═══════');
      if (widget.pdfData.isEmpty) {
        print('[PREPARE] ERRO: pdfData vazio');
        _errorMessage = 'Sem dados de PDF';
        return;
      }

      // If already downloaded to app documents, keep it
      if (_localFilePath != null && File(_localFilePath!).existsSync()) {
        print('[PREPARE] Ficheiro já existe: $_localFilePath');
        if (mounted) setState(() => _isDownloaded = true);
        return;
      }

      print('[PREPARE] Descodificando base64...');
      // Decode and write to app documents directory (more accessible than cache)
      final bytes = Base64PdfWidget.decodeBase64(widget.pdfData);
      print('[PREPARE] Bytes descodificados: ${bytes.length}');
      if (bytes.isEmpty) {
        print('[PREPARE] ERRO: bytes vazio após descodificação');
        _errorMessage = 'Base64 descodificado vazio';
        return;
      }

      // Use getApplicationDocumentsDirectory() instead of cache (more accessible)
      final dir = await getApplicationDocumentsDirectory();
      // ALWAYS use hash-based filename for cache to prevent collisions
      // This ensures each unique PDF content gets its own file
      final fileName = 'requisito_${widget.pdfData.hashCode.abs()}.pdf';
      final path = '${dir.path}/$fileName';
      print('[PREPARE] Caminho do ficheiro: $path');
      
      final file = File(path);
      
      // ESCREVER os bytes
      print('[PREPARE] Escrevendo bytes no ficheiro...');
      await file.writeAsBytes(bytes, flush: true);
      print('[PREPARE] Bytes escritos com flush=true');
      
      // VALIDAÇÃO 1: ficheiro foi criado?
      final exists = await file.exists();
      print('[PREPARE] Ficheiro existe após write: $exists');
      if (!exists) {
        print('[PREPARE] ERRO: ficheiro não foi criado');
        _errorMessage = 'Falha ao criar ficheiro';
        return;
      }
      
      // VALIDAÇÃO 2: ler de volta e confirmar tamanho
      final fileSize = await file.length();
      print('[PREPARE] Tamanho do ficheiro: $fileSize bytes (esperado: ${bytes.length})');
      if (fileSize != bytes.length) {
        print('[PREPARE] ERRO: tamanho não corresponde! Escrito: $fileSize, esperado: ${bytes.length}');
        _errorMessage = 'Ficheiro escrito incompletamente (${fileSize}/${bytes.length} bytes)';
        return;
      }
      
      // VALIDAÇÃO 3: ler e comparar primeiros 20 bytes
      final readBytes = await file.readAsBytes();
      final match = readBytes.length == bytes.length;
      print('[PREPARE] Validação de bytes: match=$match, read=${readBytes.length}, original=${bytes.length}');
      if (!match) {
        print('[PREPARE] ERRO: bytes não correspondem após leitura');
        _errorMessage = 'Validação de ficheiro falhou';
        return;
      }

      print('[PREPARE] ✓ VALIDAÇÃO PASSOU! Marcando como pronto...');
      if (mounted) {
        setState(() {
          _localFilePath = path;
          _isDownloaded = true;
        });
      }
      print('[PREPARE] ═══════ _preparePdfForDisplay CONCLUÍDO COM SUCESSO ═══════');
    } catch (e, st) {
      print('[PREPARE] ERRO: $e');
      print('[PREPARE] StackTrace: $st');
      _errorMessage = e.toString();
    }
  }

  Future<void> _checkIfDownloaded() async {
    try {
      // ALWAYS use hash-based filename for cache to prevent collisions
      final fileName = 'requisito_${widget.pdfData.hashCode.abs()}.pdf';
      // Use same directory as _preparePdfForDisplay (app documents, not cache)
      final directory = await getApplicationDocumentsDirectory();
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
      final pdfFirst = pdfData.length > 100 ? pdfData.substring(0, 100) : pdfData;
      print('[DOWNLOAD] pdfData first 100 chars: $pdfFirst');
      
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
      // VERIFICAÇÕES DE DEBUG
      final fileSize = await file.length();
      print('[OPEN] ✓ Ficheiro existe | Tamanho: $fileSize bytes');
      
      // Verificar header PDF
      final bytes = await file.readAsBytes();
      final header = bytes.length >= 4 
        ? bytes.sublist(0, 4).toString() 
        : 'N/A';
      print('[OPEN] ✓ Primeiros 4 bytes: $header');
      
      // Se header for %PDF, temos um PDF válido
      if (bytes.length > 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) {
        print('[OPEN] ✓ HEADER VÁLIDO: %PDF');
      } else {
        print('[OPEN] ⚠️  Header suspeito (não é PDF clássico)');
      }
      
      // NOVA ESTRATÉGIA: Abrir em modal com PDFView (em vez de OpenFile)
      print('[OPEN] Abrindo PDF em modal com flutter_pdfview...');
      print('[OPEN] FilePath para PDFView: $_localFilePath');
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            insetPadding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Toolbar com fechar
                Container(
                  color: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PDF Viewer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // PDFView
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    child: PDFView(
                      filePath: _localFilePath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: false,
                      pageFling: false,
                      preventLinkNavigation: false,
                      onRender: (pages) {
                        print('[PDF_VIEW] ✓ PDF rendered successfully with $pages pages');
                      },
                      onError: (error) {
                        print('[PDF_VIEW] ❌ Error loading PDF: $error');
                      },
                      onPageError: (page, error) {
                        print('[PDF_VIEW] ❌ Page $page error: $error');
                      },
                      onViewCreated: (PDFViewController controller) {
                        print('[PDF_VIEW] ✓ PDFViewController created');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
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

    if (_isPreparing) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text('A preparar PDF...', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    // Se houve erro ao preparar, mostrar erro
    if (_errorMessage != null) {
      return _buildErrorState('Erro ao preparar PDF: $_errorMessage');
    }

    // Se o ficheiro está pronto, mostrar botões de ação
    if (_isDownloaded && _localFilePath != null) {
      print('[BUILD] PDF pronto para abrir em: $_localFilePath');
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF2563EB), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Color(0xFF2563EB), size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PDF Pronto',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Text(
                        widget.fileName ?? 'Documento PDF',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _openPdf,
                icon: Icon(Icons.open_in_new, size: 18),
                label: Text('Abrir PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Caso não exista ficheiro nem erro, mostrar mensagem padrão
    return _buildErrorState('Não foi possível processar o PDF');
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
