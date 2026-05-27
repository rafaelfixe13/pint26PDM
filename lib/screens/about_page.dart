import 'package:flutter/material.dart';




class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Sobre',
          style: TextStyle(
            color: Color.fromARGB(255, 37, 99, 235),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              const Text(
                //texto
                'Esta plataforma gere e valida as competências dos consultores da Softinsa através de badges. O objetivo é reconhecer o talento e apoiar o crescimento profissional de forma transparente.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

              const SizedBox(height: 16), // separador
              Divider(color: Colors.grey.shade300, thickness: 1), //separador
              const SizedBox(height: 16), //separador

              const Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Color.fromARGB(255, 37, 99, 235),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    //titulo do coiso
                    'Sistema de badges',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 8), // separador de titulo e explicaçao

              const Text(
                //texto
                'Badges representam competências certificadas, associados a áreas técnicas e comportamentais, com níveis de senioridade de Júnior a Líder de Conhecimento.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

              const SizedBox(height: 16), // separador
              Divider(color: Colors.grey.shade300, thickness: 1), //separador
              const SizedBox(height: 16), //separador

              const Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Color.fromARGB(255, 37, 99, 235),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    //titulo do coiso
                    'Perfis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 8), // separador de titulo e explicaçao

              const Text(
                //titulo do coiso
                'Consultor',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),

              const Text(
                //texto
                'Submete pedidos, faz upload de evidências e acompanha progresso',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8), // separador de titulo e explicaçao

              const Text(
                //titulo do coiso
                'Talent Manager',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),

              const Text(
                //texto
                'Valida evidências e assegura cumprimento de SLA',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8), // separador de titulo e explicaçao

              const Text(
                //titulo do coiso
                'Service Line Leader',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),

              const Text(
                //texto
                'Realiza validação final e aprova pedidos',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

              const SizedBox(height: 16), // separador
              Divider(color: Colors.grey.shade300, thickness: 1), //separador
              const SizedBox(height: 16), //separador

              const Row(
                children: [
                  Icon(
                    Icons.route,
                    color: Color.fromARGB(255, 37, 99, 235),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Como Funciona',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildStep('1', 'Consultor submete pedido com evidências'),
              const SizedBox(height: 12),
              _buildStep('2', 'Talent Manager valida evidências'),
              const SizedBox(height: 12),
              _buildStep('3', 'Service Line Leader faz validação final'),
              const SizedBox(height: 12),
              _buildStep('4', 'Badge é aprovado ou devolvido com feedback'),

              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 16),

              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                  children: [
                    TextSpan(
                      text: 'Privacidade: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text:
                          'Cumprimento de RGPD. Partilha de badges apenas com consentimento.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color.fromARGB(255, 59, 106, 160),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }
}
