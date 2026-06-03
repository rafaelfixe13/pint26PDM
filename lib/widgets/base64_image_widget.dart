import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget que detecta automaticamente se a imagem é Base64 ou URL
/// e exibe a imagem de forma apropriada
class Base64ImageWidget extends StatelessWidget {
  final String imageData;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const Base64ImageWidget({
    required this.imageData,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  /// Verifica se a string é base64
  static bool isBase64(String data) {
    if (data.isEmpty) return false;
    
    // Base64 de JPEG começa com /9j/
    // Base64 de PNG começa com iVBORw0KGgo
    // Ou pode começar com data:image
    return data.startsWith('/9j/') || 
           data.startsWith('iVBORw0KGgo') || 
           data.startsWith('data:image');
  }

  /// Decodifica base64 para bytes
  static Uint8List decodeBase64(String base64String) {
    // Se tiver prefixo data:image, remove
    String cleanBase64 = base64String;
    if (cleanBase64.startsWith('data:image')) {
      cleanBase64 = cleanBase64.split(',').last;
    }
    return base64Decode(cleanBase64);
  }

  @override
  Widget build(BuildContext context) {
    // Se vazio, mostrar ícone placeholder
    if (imageData.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Colors.grey[200],
        ),
        child: errorWidget ?? Icon(Icons.image_not_supported, size: width * 0.4),
      );
    }

    // Se é base64, usar Image.memory
    if (isBase64(imageData)) {
      try {
        final imageBytes = decodeBase64(imageData);
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Image.memory(
            imageBytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: Colors.grey[200],
                ),
                child: errorWidget ?? Icon(Icons.broken_image),
              );
            },
          ),
        );
      } catch (e) {
        // Se falhar decodificar, mostrar erro
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: Colors.red[100],
          ),
          child: errorWidget ?? Icon(Icons.error),
        );
      }
    }

    // Se é URL, usar CachedNetworkImage
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageData,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => 
            placeholder ?? _buildPlaceholder(),
        errorWidget: (context, url, error) => 
            errorWidget ?? Icon(Icons.broken_image),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }
}
