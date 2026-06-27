import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'rotas.dart';
import 'services/basededados.dart';
import 'services/session.dart';
import 'services/push_notification_service.dart';
import 'widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tenta restaurar a sessão guardada localmente
  final sessaoLocal = await Basededados().obterSessaoLocal();
  if (sessaoLocal != null) {
    Session.iniciar(sessaoLocal);
  }

  // Debug: mostrar o que está em cache
  await Basededados().debugMostrar();

  try {
    await Firebase.initializeApp();
    await PushNotificationService.instance.inicializar(rootNavigatorKey);
  } catch (e) {
    debugPrint('Erro a inicializar Firebase: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Softinsa',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF2563EB),
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) => OfflineBanner(child: child!),
    );
  }
}