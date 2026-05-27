import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/base64_pdf_widget.dart';

class CertificatosPage extends StatefulWidget {
  const CertificatosPage({super.key});

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
      return ApiService.getBadgesDoUtilizador();
    } catch (e) {
      throw Exception('Erro ao carregar certificados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6EAF8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Erro ao carregar certificados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _certificadosFuture = _carregarCertificados();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final certificados = snapshot.data ?? [];

          if (certificados.isEmpty) {
            return const Center(
              child: Text('Nenhum certificado disponível.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: certificados.length,
            itemBuilder: (context, index) {
              final cert = certificados[index];
              final titulo = cert['titulo'] ?? cert['nomebadge'] ?? 'Certificado';
              final pdfBase64 = cert['pdf_base64']?.toString() ?? '';
              return Card(
                child: ListTile(
                  title: Text(titulo),
                  trailing: Base64PdfWidget(pdfData: pdfBase64),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
