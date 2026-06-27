import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../services/first_login_service.dart';
import '../services/basededados.dart';
import 'package:go_router/go_router.dart';
import '../services/cache_service.dart';
import '../services/session.dart';
import '../services/push_notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _verPassword = false;
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${FirstLoginService.baseUrl}/login'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final utilizador = _extractUser(decoded);
        final emailConfirmado = utilizador['emailconfirmado'] == true;
        final idutilizador = utilizador['idutilizador'];

        if (emailConfirmado == false && idutilizador is int) {
          await FirstLoginService.sendFirstLoginToken(idutilizador);

          if (!mounted) {
            return;
          }

          context.go('/first-login-token', extra: {
            'idutilizador': idutilizador,
            'nome': utilizador['nome']?.toString(),
            'email': utilizador['email']?.toString(),
          });
          return;
        }

        Session.iniciar(utilizador);
        await Basededados().guardarSessao(
          utilizador,
          CacheService.hashPassword(_passwordController.text),
        );
        await PushNotificationService.instance.registarTokenServidor();

        if (!mounted) return;
        context.go('/main');
        return;
      }

      if (response.statusCode == 403 && decoded['requireFirstLoginToken'] == true) {
        final idutilizador = decoded['idutilizador'];
        if (idutilizador is int) {
          await FirstLoginService.sendFirstLoginToken(idutilizador);
          if (!mounted) {
            return;
          }

          context.go('/first-login-token', extra: {
            'idutilizador': idutilizador,
            'nome': decoded['nome']?.toString(),
            'email': decoded['email']?.toString(),
          });
          return;
        }
      }

      setState(() {
        _erro = decoded['error']?.toString() ?? 'Credenciais inválidas';
      });
    } catch (err) {
      if (!mounted) {
        return;
      }

      setState(() {
        _erro = err.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> decoded) {
    final utilizador = decoded['utilizador'];
    if (utilizador is Map<String, dynamic>) {
      return utilizador;
    }

    return decoded;
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