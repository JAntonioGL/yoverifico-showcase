import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class PermisoNotificacionesService {
  const PermisoNotificacionesService();

  /// Devuelve true si las notificaciones están realmente habilitadas.
  /// Mantiene exactamente la lógica que ya usas: permission_handler + verificación en Android.
  Future<bool> isEnabled() async {
    // 1) Estado del permiso (Android 13+/iOS)
    final status = await Permission.notification.status;

    bool enabled;
    if (status.isDenied || status.isPermanentlyDenied) {
      enabled = false;
    } else if (status.isGranted) {
      enabled = true;
    } else {
      // Otros estados (restringido/limitado) los tratamos como deshabilitado.
      enabled = false;
    }

    // 2) En Android, confirma con areNotificationsEnabled() (canales/app bloqueados)
    if (Platform.isAndroid) {
      final fln = FlutterLocalNotificationsPlugin();
      final impl = fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final bool? sysEnabled = await impl?.areNotificationsEnabled();
      enabled = sysEnabled ?? enabled;
    }

    return enabled;
  }

  /// Abre los ajustes del sistema de la app.
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
