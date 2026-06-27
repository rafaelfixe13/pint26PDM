import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/first_login_service.dart';

class FirstLoginTokenPage extends StatefulWidget {
  final int idutilizador;
  final String? nome;
  final String? email;

  const FirstLoginTokenPage({
    super.key,
    required this.idutilizador,
    this.nome,
    this.email,
  });

  @override
  State<FirstLoginTokenPage> createState() => _FirstLoginTokenPageState();
}

class _FirstLoginTokenPageState extends State<FirstLoginTokenPage> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await FirstLoginService.verifyFirstLogin(
      widget.idutilizador,
      _tokenController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (result['ok'] == true) {
      context.go('/first-login-change-password', extra: {
        'idutilizador': widget.idutilizador,
      });
      return;
    }

    final message = (result['data'] as Map<String, dynamic>?)?['error']?.toString() ??
        'Não foi possível validar o token';

    setState(() {
      _error = message;
    });
  }

  Future<void> _resendToken() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await FirstLoginService.sendFirstLoginToken(widget.idutilizador);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    final data = result['data'] as Map<String, dynamic>?;
    final message = result['ok'] == true
      ? (data != null && data['message'] != null
        ? data['message'].toString()
        : 'Token reenviado')
      : (data != null && data['error'] != null
        ? data['error'].toString()
        : 'Não foi possível reenviar o token');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF1E3A5F),
                    ),
                    children: [
                      TextSpan(text: 'S'),
                      TextSpan(text: 'O'),
                      TextSpan(text: 'F'),
                      TextSpan(
                        text: 'T',
                        style: TextStyle(color: Color(0xFF38BDF8)),
                      ),
                      TextSpan(text: 'I'),
                      TextSpan(text: 'N'),
                      TextSpan(text: 'S'),
                      TextSpan(text: 'A'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'PRIMEIRO ACESSO',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          size: 36,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      Text(
                        'Foi enviado um token para o seu email${widget.email != null ? ' (${widget.email})' : ''}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _tokenController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Introduza o token',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyToken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B4E8C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Confirmar token',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _resendToken,
                        child: const Text(
                          'Reenviar token',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}