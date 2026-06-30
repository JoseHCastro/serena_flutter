import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  void Function(String?)? onNotificationTap;

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onNotificationTap?.call(response.payload);
      },
    );

    // Solicitar permiso de notificaciones en Android 13+ (API 33+)
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'serena_alerts_channel',
      'Alertas Serena',
      channelDescription: 'Canal de notificaciones para alertas de análisis clínico',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _localNotifications.show(id, title, body, details, payload: payload);
  }
}
