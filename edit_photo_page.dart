import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinttest/services/api_service.dart';
import 'package:pinttest/services/session.dart';

class EditPhotoPage extends StatefulWidget {
  @override
  State<EditPhotoPage> createState() => _EditPhotoPageState();
}

class _EditPhotoPageState extends State<EditPhotoPage> {
  File? _imagemSelecionada;
  bool _loading = false;
  String? _erro;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selecionarImagem(ImageSource source) async {
    try {
      final XFile? imagem = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (imagem != null) {
        setState(() {
          _imagemSelecionada = File(imagem.path);
          _erro = null;
        });
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao selecionar imagem');
    }
  }

  Future<void> _guardar() async {
    if (_imagemSelecionada == null) {
      setState(() => _erro = 'Seleciona uma imagem primeiro');
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      // ← só limpa cache se já tiver foto
      if (Session.fotoUrl.isNotEmpty) {
        await CachedNetworkImage.evictFromCache(Session.fotoUrl);
      }

      final novaUrl = await ApiService.atualizarFoto(
        Session.id,
        _imagemSelecionada!.path,
      );

      Session.utilizador['fotourl'] = novaUrl;

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Alterar Foto',
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),

            // Preview da imagem
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.purple.shade100,
                    child: ClipOval(
                      child: _imagemSelecionada != null
                          ? Image.file(
                              _imagemSelecionada!,
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                            )
                          : Session.fotoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: Session.fotoUrl,
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.purple,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.person,
                                          size: 70,
                                          color: Colors.purple),
                                )
                              : Icon(Icons.person,
                                  size: 70, color: Colors.purple),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child:
                          Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            Text(
              Session.nome,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A5F),
              ),
            ),

            SizedBox(height: 40),

            // Botão galeria
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _selecionarImagem(ImageSource.gallery),
                icon: Icon(Icons.photo_library_outlined,
                    color: Color(0xFF2563EB)),
                label: Text(
                  'Escolher da Galeria',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Botão câmara
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _selecionarImagem(ImageSource.camera),
                icon: Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF2563EB)),
                label: Text(
                  'Tirar Fotografia',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            SizedBox(height: 32),

            // Erro
            if (_erro != null)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(_erro!,
                          style:
                              TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),

            // Botão Guardar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2B4E8C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Guardar Foto',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
