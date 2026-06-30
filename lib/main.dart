import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/notification_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SerenaApp()));
}

class SerenaApp extends ConsumerStatefulWidget {
  const SerenaApp({super.key});

  @override
  ConsumerState<SerenaApp> createState() => _SerenaAppState();
}

class _SerenaAppState extends ConsumerState<SerenaApp> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.init();
    notificationService.onNotificationTap = (payload) {
      if (payload != null && payload.isNotEmpty) {
        ref.read(routerProvider).go(payload);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    // Activa el watcher de notificaciones para escuchar nuevas alertas
    ref.watch(alertNotificationWatcher);

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Serena',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
