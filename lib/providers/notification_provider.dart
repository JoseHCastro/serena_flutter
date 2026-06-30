import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import '../services/notification_service.dart';
import 'alerts_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Watcher que escucha el listado de alertas y dispara notificaciones locales
final alertNotificationWatcher = Provider<void>((ref) {
  ref.listen<AsyncValue<List<AlertModel>>>(alertsProvider, (previous, next) {
    final nextAlerts = next.valueOrNull;
    final prevAlerts = previous?.valueOrNull;
    if (nextAlerts == null) return;

    // Solo notificar si la alerta no estaba en el estado previo y no está confirmada
    final newAlerts = nextAlerts.where((alert) {
      if (alert.isAcknowledged) return false;
      if (prevAlerts == null) return false; // Evitar notificaciones masivas en el primer inicio
      return !prevAlerts.any((p) => p.id == alert.id);
    });

    final notifier = ref.read(notificationServiceProvider);
    for (final alert in newAlerts) {
      notifier.showNotification(
        id: alert.id.hashCode,
        title: '⚠️ Alerta Serena: ${alert.severity.label.toUpperCase()}',
        body: alert.message,
        payload: '/sessions/${alert.sessionId}',
      );
    }
  });
});
