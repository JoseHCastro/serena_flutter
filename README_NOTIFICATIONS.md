# Documentación del Sistema de Notificaciones Locales

Este documento detalla el diseño, la arquitectura y el funcionamiento de la integración de notificaciones push locales en la aplicación móvil Serena Flutter.

---

## 1. Arquitectura de Notificaciones

La solución se divide en tres capas desacopladas para mantener la consistencia arquitectónica del proyecto:

### A. Capa de Servicios: NotificationService
Ubicación: `lib/services/notification_service.dart`
Es la clase encargada de encapsular las APIs del paquete `flutter_local_notifications`. Sus funciones principales son:
* **Inicialización**: Configura el canal de comunicación nativo en Android (ID: `serena_alerts_channel`) y solicita permisos de sonido, alertas y emblemas (badges) en Darwin/iOS.
* **Envío de Notificaciones**: Expone el método `showNotification` que emite de forma nativa la alerta en la bandeja del dispositivo con prioridad alta y sonido.
* **Mapeo de Interacciones**: Define el callback `onNotificationTap` que captura el evento cuando el usuario presiona la notificación.

### B. Capa de Providers y Watcher Reactivo
Ubicación: `lib/providers/notification_provider.dart`
* **notificationServiceProvider**: Provee la instancia singleton de `NotificationService`.
* **alertNotificationWatcher**: Es un listener reactivo que vigila el estado del proveedor de alertas (`alertsProvider`). Al recibir actualizaciones de la lista de alertas:
  1. Compara el estado anterior con el nuevo para identificar alertas recientemente creadas.
  2. Filtra que la alerta no haya sido confirmada (isAcknowledged == false).
  3. Ejecuta `showNotification` por cada alerta nueva detectada, asignándole un identificador único basado en el hash del ID de la alerta.

### C. Ciclo de Vida e Inicialización de la Aplicación
Ubicación: `lib/main.dart`
Durante la inicialización del widget raíz `SerenaApp`:
1. Se inicializa el servicio `NotificationService`.
2. Se vincula el callback `onNotificationTap` con el enrutador de la aplicación (`GoRouter`). Al pulsar una notificación con un payload de ruta (por ejemplo, `/sessions/uuid`), se invoca `router.go(payload)` para redirigir directamente al terapeuta.
3. Se activa el watcher reactivo llamando a `ref.watch(alertNotificationWatcher)` en el método `build` para que permanezca activo durante toda la sesión del usuario.

---

## 2. Funcionalidades Integradas

El sistema responde activamente a los dos flujos clínicos principales:

### A. Alertas Clínicas del Paciente
Cuando el backend genera una alerta biométrica por rebasar los límites establecidos (ejemplo: picos de ansiedad, estrés sostenido o fluctuaciones drásticas en las emociones dominantes del paciente):
* La app detecta el cambio en su consulta periódica.
* Emite una notificación local titulada "Alerta Serena" con la severidad del caso (Alta, Media, Crítica) y el mensaje clínico correspondiente.
* Al pulsarla, redirige de inmediato a la pantalla de detalles de la sesión donde se originó la alerta.

### B. Notificación de Análisis de Sesión Finalizado
El procesamiento de video y la extracción de métricas se ejecuta asíncronamente en el servidor. 
* Una vez que el backend culmina el análisis y genera la alerta de tipo sesión completada, el polling de la app móvil captura el registro.
* Dispara una notificación local avisando al terapeuta que el reporte ya está listo.
* Facilita el acceso directo al informe de deltas emocionales y gráficos de evolución con un solo toque.

---

## 3. Mecanismo de Sincronización (Polling Silencioso)
Ubicación: `lib/providers/alerts_provider.dart`
Dado que el procesamiento se ejecuta en segundo plano en el servidor, se implementó un temporizador cíclico (`Timer.periodic`) en el proveedor de alertas:
* Consulta la API del backend cada 30 segundos si el usuario está autenticado.
* Actualiza de forma transparente la lista de alertas.
* Permite que la app reciba las actualizaciones en tiempo real sin requerir una conexión persistente por WebSockets.

---

## 4. Configuración del Compilador Android (Gradle Desugaring)
Ubicación: `android/app/build.gradle.kts`
El programador interno del paquete de notificaciones locales hace uso de librerías modernas de tiempo de Java (java.time). Para asegurar compatibilidad con dispositivos Android antiguos sin causar fallos en tiempo de compilación, se configuró el Desugaring de API en el archivo de construcción Kotlin DSL:
1. Activación de desugaring en `compileOptions`:
   ```kotlin
   compileOptions {
       isCoreLibraryDesugaringEnabled = true
       sourceCompatibility = JavaVersion.VERSION_17
       targetCompatibility = JavaVersion.VERSION_17
   }
   ```
2. Adición de la dependencia en el bloque de dependencias:
   ```kotlin
   dependencies {
       coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
   }
   ```
