import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CheckEmailPage extends StatelessWidget {
  const CheckEmailPage({super.key});

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
                  'CONFIRMAÇÃO',
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
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 36,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Foi enviado um email de confirmação.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Verifique a sua caixa de entrada e siga as instruções antes de iniciar sessão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.go('/'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B4E8C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Voltar ao login',
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
            ],
          ),
        ),
      ),
    );
  }
}