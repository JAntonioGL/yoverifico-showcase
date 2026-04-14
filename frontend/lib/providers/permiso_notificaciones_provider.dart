import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permiso_notificaciones_service.dart';

class PermisoNotificacionesProvider extends ChangeNotifier {
  final PermisoNotificacionesService _service;

  bool _bannerVisible = false;
  bool get bannerVisible => _bannerVisible;

  bool _pendingFlow = false;

  PermisoNotificacionesProvider(this._service);

  /// Checa el estado actual y actualiza visibilidad del banner.
  Future<void> refresh() async {
    final enabled = await _service.isEnabled();
    final newVisible = !enabled;
    if (newVisible != _bannerVisible) {
      _bannerVisible = newVisible;
      notifyListeners();
    }
  }

  /// CTA del banner: marcamos flujo pendiente y abrimos ajustes.
  Future<void> startSettingsFlow() async {
    _pendingFlow = true;
    await _service.openSettings();
  }

  /// Útil si conectas este provider con AppLifecycleState.resumed.
  /// Mantiene el comportamiento sin modificar la lógica de permisos.
  Future<void> onAppResumed() async {
    if (_pendingFlow) {
      _pendingFlow = false;
      await refresh();
      return;
    }
    // Incluso si no veníamos de ajustes, refrescar no afecta la UI actual.
    await refresh();
  }

  /// Útil si lo llamas desde didPopNext() con RouteObserver.
  Future<void> onRoutePopNext() async {
    await refresh();
  }

  /// (Opcional) expone el status crudo si algún día lo necesitas.
  Future<PermissionStatus> rawPermissionStatus() async {
    return Permission.notification.status;
  }
}
