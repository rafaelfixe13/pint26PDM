import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:go_router/go_router.dart';

import '../services/first_login_service.dart';
import '../services/cache_service.dart';

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
  String? _erro;
  List<dynamic> _areas = [];
  int? _areaSelecionada;
  bool _carregandoAreas = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _carregarAreas();
  }

  Future<void> _carregarAreas() async {
    setState(() => _carregandoAreas = true);
    try {
      final areas = await CacheService.getAreas();
      setState(() => _areas = areas);
    } catch (e) {
      print('Erro ao carregar áreas: $e');
    } finally {
      if (mounted) {
        setState(() => _carregandoAreas = false);
      }
    }
  }

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

    if (nome.isEmpty || email.isEmpty || password.isEmpty || confirmar.isEmpty) {
      setState(() => _erro = 'Preenche todos os campos');
      return;
    }

    if (_areaSelecionada == null) {
      setState(() => _erro = 'Seleciona uma área');
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
      final response = await http.post(
        Uri.parse('${FirstLoginService.baseUrl}/registro'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome,
          'email': email,
          'password': password,
          'idarea': _areaSelecionada,
        }),
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 201) {
        context.go('/check-email');
        return;
      }

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      setState(() {
        _erro = decoded['error']?.toString() ?? 'Não foi possível criar a conta';
      });
    } catch (e) {
      setState(() {
        _erro = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
              Text('Nome completo',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              SizedBox(height: 8),
              _campo(
                controller: _nomeController,
                hint: 'Ex: João Silva',
                icon: Icons.person_outline,
              ),
              SizedBox(height: 16),
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
              Text('Área de Atuação',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              SizedBox(height: 8),
              _carregandoAreas
                  ? Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _areaSelecionada != null
                              ? Color(0xFF2563EB)
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: _areaSelecionada,
                        hint: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            'Seleciona a tua área',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        underline: SizedBox.shrink(),
                        icon: Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ),
                        onChanged: (value) => setState(() => _areaSelecionada = value),
                        items: _areas
                            .map((area) => DropdownMenuItem<int>(
                                  value: area['idarea'] as int,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 16),
                                    child: Text(area['nome'] ?? ''),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
              SizedBox(height: 16),
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
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Já tens conta? ',
                        style:
                            TextStyle(fontSize: 13, color: Colors.black87)),
                    GestureDetector(
                      onTap: () => context.go('/'),
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
        filled: true,
        fillColor: Color(0xFFF1F5F9),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
              ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey),
          onPressed: onToggle,
        ),
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
}