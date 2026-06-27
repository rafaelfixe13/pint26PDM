import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'session.dart';

// Handler para mensagens recebidas em background (app minimizada/fechada).
// Tem de ser uma função de topo (não um método), anotada com @pragma para
// não ser removida pelo compilador.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('Mensagem em Background: ${message.messageId}');
  }
}

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Referência ao Navigator global (rootNavigatorKey em rotas.dart) para
  // conseguir mostrar popups a partir de qualquer lugar, mesmo sem um
  // BuildContext próprio (ex: quando a notificação chega em foreground).
  GlobalKey<NavigatorState>? _navKey;
  String? _ultimoToken;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Canal para notificações importantes.',
    importance: Importance.max,
  );

  Future<void> inicializar(GlobalKey<NavigatorState> navigatorKey) async {
    _navKey = navigatorKey;

    // 1. Permissões Firebase
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Inicializar Notificações Locais
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Tratar clique na notificação local
      },
    );

    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (platform != null) {
      await platform.createNotificationChannel(_channel);
    }

    // 3. Obter o Token FCM e subscrever ao tópico geral
    _ultimoToken = await _firebaseMessaging.getToken();
    await _firebaseMessaging.subscribeToTopic('todos');
    if (kDebugMode) {
      print('FCM TOKEN: $_ultimoToken');
    }
    await registarTokenServidor();

    // Sempre que o token mudar (reinstalação, troca de dispositivo, etc.),
    // guarda o novo valor e tenta atualizá-lo no servidor.
    _firebaseMessaging.onTokenRefresh.listen((novoToken) {
      _ultimoToken = novoToken;
      registarTokenServidor();
    });

    // 4. Handler para mensagens em background
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Listener para mensagens recebidas em foreground (app aberta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // A. Mostrar notificação no sistema (balão no topo)
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android.smallIcon,
            ),
          ),
        );

        // B. Mostrar popup (AlertDialog) no meio do ecrã
        _mostrarPopup(notification.title ?? 'Nova Notificação', notification.body ?? '');
      }
    });
  }

  // Envia o token FCM atual para o servidor, associando-o ao utilizador com
  // sessão iniciada. Sem efeito se ainda não houver sessão ou token.
  // Deve ser chamado também depois de um login bem-sucedido.
  Future<void> registarTokenServidor() async {
    final token = _ultimoToken;
    if (token == null || Session.id == 0) return;
    try {
      await ApiService.salvarFcmToken(Session.id, token);
    } catch (e) {
      if (kDebugMode) print('Erro ao registar token FCM no servidor: $e');
    }
  }

  void _mostrarPopup(String titulo, String corpo) {
    final context = _navKey?.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(corpo),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
