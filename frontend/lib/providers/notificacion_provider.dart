import 'package:flutter/material.dart';
import '../services/notificacion_service.dart';

class NotificacionProvider with ChangeNotifier {
  Future<bool> programarNotificacion({
    required int idVehiculo,
    required String titulo,
    required String mensaje,
    required DateTime fechaProgramada,
  }) async {
    final exito = await NotificacionService.programarNotificacion(
      idVehiculo: idVehiculo,
      titulo: titulo,
      mensaje: mensaje,
      fechaProgramada: fechaProgramada, // el service lo envía en UTC
    );

    if (exito) {
      // Si necesitas refrescar listas/estado, descomenta:
      // notifyListeners();
    }

    return exito;
  }
}
