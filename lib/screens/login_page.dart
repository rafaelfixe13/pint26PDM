import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/cache_service.dart';
import '../services/session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _verPassword = false;
  bool _manterSessao = false;
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _erro = 'Preenche o email e a password');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _erro = 'Email inválido');
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      // Usa o CacheService → tenta API e guarda em SQLite,
      // ou faz fallback para sessão local em modo offline.
      final resultado = await CacheService.login(email, password);

      // guarda o utilizador na session em memória
      Session.iniciar(resultado['utilizador']);

      // Aviso opcional: se entrou em modo offline
      if (resultado['offline'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entraste em modo offline (sem ligação ao servidor).'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        context.go('/main');
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
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
                          style: TextStyle(color: Color(0xFF38BDF8))),
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
                child: Text('LOGIN',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                        letterSpacing: 3)),
              ),
              SizedBox(height: 40),
              AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                    SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        hintText: 'xxx@softinsa.pt',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Color(0xFF2563EB), width: 1.5)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14)),
                    SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_verPassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: 'Introduza a sua password',
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Color(0xFF2563EB), width: 1.5)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _verPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey),
                          onPressed: () =>
                              setState(() => _verPassword = !_verPassword),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _manterSessao,
                    onChanged: (v) =>
                        setState(() => _manterSessao = v ?? false),
                    activeColor: Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  Text('Manter sessão iniciada',
                      style: TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
              SizedBox(height: 8),
              if (_erro != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
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
                              color: Colors.white, strokeWidth: 2))
                      : Text('Entrar',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Text('Esqueceste-te da tua password?',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.underline)),
                ),
              ),
              SizedBox(height: 60),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Não tem conta? ',
                        style:
                            TextStyle(fontSize: 13, color: Colors.black87)),
                    GestureDetector(
                      onTap: () => context.push('/signup'),
                      child: Text('Registe-se.',
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600)),
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