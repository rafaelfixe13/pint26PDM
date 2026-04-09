import 'package:flutter/material.dart';
import 'package:pinttest/services/api_service.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _verPassword = false;
  bool _verConfirmar = false;
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmar = _confirmarPasswordController.text.trim();

    // validações
    if (nome.isEmpty || email.isEmpty || password.isEmpty || confirmar.isEmpty) {
      setState(() => _erro = 'Preenche todos os campos');
      return;
    }

    if (!email.contains('@')) {
      setState(() => _erro = 'Email inválido');
      return;
    }

    if (password.length < 6) {
      setState(() => _erro = 'A password deve ter pelo menos 6 caracteres');
      return;
    }

    if (password != confirmar) {
      setState(() => _erro = 'As passwords não coincidem');
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      await ApiService.registro(nome, email, password);

      // registo bem sucedido — vai para o login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conta criada com sucesso! Faz login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      }
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: 20),

              // Logo SOFTINSA
              Center(
                child: RichText(
                  text: TextSpan(
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

              SizedBox(height: 12),

              Center(
                child: Text(
                  'REGISTO',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                    letterSpacing: 3,
                  ),
                ),
              ),

              SizedBox(height: 32),

              // Nome
              Text('Nome completo',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              SizedBox(height: 8),
              _campo(
                controller: _nomeController,
                hint: 'Ex: João Silva',
                icon: Icons.person_outline,
              ),

              SizedBox(height: 16),

              // Email
              Text('Email',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              SizedBox(height: 8),
              _campo(
                controller: _emailController,
                hint: 'xxx@softinsa.pt',
                icon: Icons.email_outlined,
                tipo: TextInputType.emailAddress,
              ),

              SizedBox(height: 16),

              // Password
              Text('Password',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              SizedBox(height: 8),
              _campoPassword(
                controller: _passwordController,
                hint: 'Mínimo 6 caracteres',
                ver: _verPassword,
                onToggle: () => setState(() => _verPassword = !_verPassword),
              ),

              SizedBox(height: 16),

              // Confirmar Password
              Text('Confirmar Password',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              SizedBox(height: 8),
              _campoPassword(
                controller: _confirmarPasswordController,
                hint: 'Repete a password',
                ver: _verConfirmar,
                onToggle: () => setState(() => _verConfirmar = !_verConfirmar),
              ),

              SizedBox(height: 16),

              // Erro
              if (_erro != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _erro!,
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 8),

              // Botão Registar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _registar,
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
                          'Criar Conta',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              SizedBox(height: 24),

              // Já tem conta
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Já tens conta? ',
                        style:
                            TextStyle(fontSize: 13, color: Colors.black87)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      ),
                      child: Text(
                        'Inicia sessão.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
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

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType tipo = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _campoPassword({
    required TextEditingController controller,
    required String hint,
    required bool ver,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !ver,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
        filled: true,
        fillColor: Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(
            ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
