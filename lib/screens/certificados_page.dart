import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../widgets/base64_pdf_widget.dart';

class CertificatosPage extends StatefulWidget {
  @override
  State<CertificatosPage> createState() => _CertificatosPageState();
}

class _CertificatosPageState extends State<CertificatosPage> {
  late Future<List<dynamic>> _certificadosFuture;

  @override
  void initState() {
    super.initState();
    _certificadosFuture = _carregarCertificados();
  }

  Future<List<dynamic>> _carregarCertificados() async {
    try {
  
      return CacheService.getBadgesDoUtilizador();
    } catch (e) {
      throw Exception('Erro ao carregar certificados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD6EAF8),
      appBar: AppBar(
        backgroundColor: Color(0xFFD6EAF8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Certificados',
          style: TextStyle(
            fontFamily: 'serif',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF1E3A5F),
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _certificadosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Erro ao carregar certificados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _certificadosFuture = _carregarCertificados();
                        });
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final certificados = snapshot.data ?? [];
          
          // Filtrar apenas badges com certificado
          final comCertificado = certificados
              .where((badge) => badge['certificado'] != null && badge['certificado'].toString().isNotEmpty)
              .toList();

          if (comCertificado.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Sem certificados disponíveis'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: comCertificado.length,
            itemBuilder: (context, index) {
              final badge = comCertificado[index];
              final cert = badge['certificado']?.toString() ?? '';
              
              print('[CERT] Badge ${badge['nome']}: cert_length=${cert.length}, starts_with=${cert.substring(0, 50)}');
              
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge['nome'] ?? 'Sem nome',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        badge['descricao'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 16),
                      Base64PdfWidget(
                        pdfData: cert,
                        fileName: '${badge['nome']}_certificado.pdf',
                        onDownloadSuccess: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Certificado descarregado com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        onDownloadError: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao descarregar certificado'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
