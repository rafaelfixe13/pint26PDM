import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/session.dart';

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  bool notificacoes = true;
  bool notificacoesEmail = true;
  bool resultadosCandidatura = true;
  bool _rgpd = false;
  bool _aGuardarRgpd = false;

  @override
  void initState() {
    super.initState();
    _rgpd = Session.utilizador['rgpd'] == true;
  }

  Future<void> _atualizarRgpd(bool value) async {
    setState(() {
      _aGuardarRgpd = true;
      _rgpd = value;
    });

    try {
      final novoValor = await ApiService.atualizarRgpd(value);

      if (!mounted) return;
      setState(() {
        _rgpd = novoValor;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoValor
                ? 'Consentimento RGPD ativado com sucesso.'
                : 'Consentimento RGPD desativado com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _rgpd = !_rgpd;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar RGPD: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _aGuardarRgpd = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/main'),
        ),
        title: const Text(
          'Opções',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Divider(),
          _sectionTitle(
            icon: Icons.notifications_none_outlined,
            title: 'Notificações',
          ),
          const SizedBox(height: 12),

          _switchRow('Notificações', notificacoes, (v) {
            setState(() => notificacoes = v);
          }),
          _switchRow('Notificações por email', notificacoesEmail, (v) {
            setState(() => notificacoesEmail = v);
          }),
          _switchRow('Resultados de uma candidatura', resultadosCandidatura, (v) {
            setState(() => resultadosCandidatura = v);
          }),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          _sectionTitle(
            icon: Icons.shield_outlined,
            title: 'Segurança & Privacidade',
          ),
          const SizedBox(height: 18),

          const Text(
            'Sessão & Segurança',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),

          _actionButton(
            icon: '🔑',
            text: 'Alterar palavra-passe',
            onTap: () => context.go('/change-password'),
          ),

          const SizedBox(height: 24),

          const Text(
            'Privacidade',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                switchTheme: SwitchThemeData(
                  thumbColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? Colors.white
                          : Colors.grey.shade500),
                  trackColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected)
                          ? const Color(0xFF6B9FD4)
                          : Colors.grey.shade300),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                ),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Aceitar os termos RGPD',
                  style: TextStyle(fontSize: 15),
                ),
                subtitle: const Text(
                  'Autoriza o tratamento dos teus dados conforme a política de privacidade.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: _rgpd,
                onChanged: _aGuardarRgpd ? null : _atualizarRgpd,
              ),
            ),
          ),

          if (_aGuardarRgpd)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3F6AA3), size: 34),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _switchRow(
    String text,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? Colors.white
                    : Colors.grey.shade500),
            trackColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? const Color(0xFF6B9FD4)
                    : Colors.grey.shade300),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(text, style: const TextStyle(fontSize: 15)),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF3F6AA3), width: 1.5),
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF3F6AA3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}