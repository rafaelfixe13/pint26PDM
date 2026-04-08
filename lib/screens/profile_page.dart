import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pinttest/services/session.dart';
import 'package:pinttest/screens/edit_photo_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Key _avatarKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final user = Session.utilizador;
    final fotoUrl = Session.fotoUrl.trim();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        key: _avatarKey,
                        radius: 50,
                        backgroundColor: Colors.purple.shade100,
                        child: ClipOval(
                          child: fotoUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: fotoUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.purple,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.purple,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.purple,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () async {
                            final atualizado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditPhotoPage(),
                              ),
                            );

                            if (atualizado == true) {
                              setState(() {
                                _avatarKey = UniqueKey();
                              });
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    Session.nome,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Talent Management',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            Text(
              'Informações Pessoais',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),

            _infoCard(
              icon: Icons.email_outlined,
              title: 'Email',
              value: Session.email,
            ),
            SizedBox(height: 8),
            _infoCard(
              icon: Icons.phone_outlined,
              title: 'Número de Telefone',
              value: user['telefone']?.toString() ?? '—',
            ),
            SizedBox(height: 8),
            _infoCard(
              icon: Icons.badge_outlined,
              title: 'Estado da Conta',
              value: user['estadoconta']?.toString() ?? '—',
            ),

            SizedBox(height: 24),

            Text(
              'Badges Conquistados',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '10 Badges Conquistados',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                10,
                (i) => CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue[(i % 8 + 2) * 100],
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),

            Text(
              'Estatísticas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statCard('Badges Conquistados', '10'),
                _statCard('Melhor posição no rank', '2'),
                _statCard('Pontos totais obtidos', '2000'),
              ],
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF2563EB)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}