import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/first_login_service.dart';

class FirstLoginChangePasswordPage extends StatefulWidget {
  final int idutilizador;

  const FirstLoginChangePasswordPage({
    super.key,
    required this.idutilizador,
  });

  @override
  State<FirstLoginChangePasswordPage> createState() => _FirstLoginChangePasswordPageState();
}

class _FirstLoginChangePasswordPageState extends State<FirstLoginChangePasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (password != confirm) {
      setState(() {
        _error = 'As passwords não coincidem';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await FirstLoginService.changePasswordFirstLogin(
      widget.idutilizador,
      password,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (result['ok'] == true) {
      context.go('/');
      return;
    }

    final message = (result['data'] as Map<String, dynamic>?)?['error']?.toString() ??
        'Não foi possível alterar a password';

    setState(() {
      _error = message;
    });
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
                  'ALTERAR PASSWORD',
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
                          Icons.lock_reset_outlined,
                          size: 36,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const Text(
                        'Defina uma nova password para concluir o primeiro acesso.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          hintText: 'Nova password',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
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
                      const SizedBox(height: 14),
                      TextField(
                        controller: _confirmController,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          hintText: 'Confirmar password',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
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
                          onPressed: _isLoading ? null : _changePassword,
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
                                  'Guardar password',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}