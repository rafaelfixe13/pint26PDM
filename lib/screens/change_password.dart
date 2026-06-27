import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/basededados.dart';
import '../services/cache_service.dart';
import '../services/session.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _loading = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  String? _error;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF2F6FED), width: 2),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Colors.grey,
        ),
        onPressed: onToggle,
      ),
    );
  }

  Future<void> _alterarPassword() async {
    FocusScope.of(context).unfocus();

    final current = _currentPassController.text.trim();
    final nova = _newPassController.text.trim();
    final confirmar = _confirmPassController.text.trim();

    setState(() => _error = null);

    if (current.isEmpty || nova.isEmpty || confirmar.isEmpty) {
      setState(() => _error = 'Preenche todos os campos.');
      return;
    }

    if (nova != confirmar) {
      setState(() => _error = 'A nova password e a confirmação não coincidem.');
      return;
    }

    if (nova.length < 6) {
      setState(() => _error = 'A nova password deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiService.alterarPassword(current, nova);
      await Basededados().guardarSessao(Session.utilizador, CacheService.hashPassword(nova));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password alterada com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/main');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
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
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => context.go('/main'),
        ),
        title: const Text(
          'Alterar Password',
          style: TextStyle(color: Colors.grey),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Alterar a Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A6EAB),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Password Atual',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _currentPassController,
                obscureText: !_showCurrent,
                autofillHints: const [AutofillHints.password],
                decoration: _inputDecoration(
                  hint: 'Introduz a password atual',
                  obscure: !_showCurrent,
                  onToggle: () => setState(() => _showCurrent = !_showCurrent),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Password Nova',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPassController,
                obscureText: !_showNew,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _inputDecoration(
                  hint: 'Introduz a password nova',
                  obscure: !_showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Confirmar Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPassController,
                obscureText: !_showConfirm,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _inputDecoration(
                  hint: 'Confirma a nova password',
                  obscure: !_showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _loading ? null : _alterarPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4579B2),
                    disabledBackgroundColor: const Color(0xFF4579B2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Alterar e Entrar',
                          style: TextStyle(
                            fontSize: 19,
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
    );
  }
}