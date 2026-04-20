import 'package:flutter/material.dart';
import '../screens/change_password.dart';

class OptionsPage extends StatefulWidget {
  const OptionsPage({super.key});

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  bool notificacoes = true;
  bool notificacoesEmail = true;
  bool notificacoesSmartphone = false;
  bool alertasBadges = false;
  bool resultadosCandidatura = true;
  bool rgpd = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
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
          _switchRow('Notificações no smartphone', notificacoesSmartphone, (v) {
            setState(() => notificacoesSmartphone = v);
          }),
          _switchRow('Alertas de expiração de badges', alertasBadges, (v) {
            setState(() => alertasBadges = v);
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _actionButton(
            icon: '🔐',
            text: 'Autenticação em 2 passos (ativar)',
            onTap: () {},
          ),
          const SizedBox(height: 12),

          _actionButton(
            icon: '📱',
            text: 'Gerir dispositivos com sessão ativa',
            onTap: () {},
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

          CheckboxListTile(
            value: rgpd,
            onChanged: (value) {
              setState(() => rgpd = value ?? false);
            },
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFF3F6AA3),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Aceitar os termos RGPD',
              style: TextStyle(fontSize: 15),
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
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          text,
          style: const TextStyle(fontSize: 15),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF9DBCF2),
        activeTrackColor: const Color(0xFF9DBCF2),
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